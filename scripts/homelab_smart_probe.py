#!/usr/bin/env python3
"""Exporteur Prometheus (port 9188 par defaut) : sante NVMe + metriques vzdump.

Refactor non bloquant (anti-flapping) :
- ThreadingHTTPServer : chaque scrape est servi depuis un cache memoire (O(ms)),
  plus jamais de scrape_timeout (10 s) => fini le flapping CibleInjoignable.
- Thread de fond : rafraichit le cache (smartctl + parse du dernier log vzdump)
  toutes les SMART_PROBE_REFRESH secondes (defaut 55 s).
- Prefiltre grep du log de tache vzdump : un job vzdump rate peut produire un
  log de ~1 Go (1,4 M lignes d'erreur) ; l'ancienne lecture Python ligne a
  ligne depassait le scrape_timeout Prometheus => up=0 en boucle.
- Configurable pour les tests sandbox : SMART_PROBE_PORT, SMART_PROBE_REFRESH,
  SMART_PROBE_DEVICE, SMART_PROBE_TASK_GLOB.
"""
import glob
import http.server
import io
import os
import re
import subprocess
import threading
import time

PORT = int(os.environ.get("SMART_PROBE_PORT", "9188"))
REFRESH_INTERVAL = int(os.environ.get("SMART_PROBE_REFRESH", "55"))
NVME_DEVICE = os.environ.get("SMART_PROBE_DEVICE", "/dev/nvme0n1")
# Matche les jobs planifies (vzdump::root@pam:) ET les runs par VM
# (vzdump:105:root@pam:) — un glob "*vzdump::*" raterait ces derniers.
TASK_GLOB = os.environ.get("SMART_PROBE_TASK_GLOB", "/var/log/pve/tasks/?/*vzdump:*")
FS_PATH = os.environ.get("SMART_PROBE_FS_PATH", "/mnt/backup2to")

# Prefiltre grep (vitesse C) : ne garde que les lignes utiles au parse.
# Un log d'echec de ~1 Go est reduit a quelques Ko avant le parse Python.
LOG_PREFILTER = (
    r"INFO: (Starting Backup of VM|VM Name:|CT Name:|archive file size:"
    r"|Total bytes written:|Finished Backup of VM)"
    r"|ERROR: Backup of VM"
    r"|Backup job finished with errors"
    r"|TASK ERROR"
)

_lock = threading.Lock()
_payload = ""


def parse_duration_str(dstr):
    parts = dstr.split(":")
    if len(parts) == 3:
        return int(parts[0]) * 3600 + int(parts[1]) * 60 + int(parts[2])
    elif len(parts) == 2:
        return int(parts[0]) * 60 + int(parts[1])
    return 0


def parse_size_str(sstr):
    m = re.match(r"^([0-9.]+)\s*([A-Za-z]+)$", sstr.strip())
    if not m:
        return 0
    val, unit = float(m.group(1)), m.group(2).upper()
    units = {
        "B": 1,
        "KB": 10**3, "KIB": 2**10,
        "MB": 10**6, "MIB": 2**20,
        "GB": 10**9, "GIB": 2**30,
        "TB": 10**12, "TIB": 2**40,
    }
    return int(val * units.get(unit, 1))


def read_task_log(path):
    """Retourne un file-like ne contenant que les lignes utiles du log.

    grep -a : le log peut contenir des octets non UTF-8.
    timeout 120 s : borne le pire cas, l'appelant garde l'ancien cache.
    """
    res = subprocess.run(
        ["grep", "-aE", LOG_PREFILTER, path],
        capture_output=True, text=True, errors="ignore", timeout=120,
    )
    return io.StringIO(res.stdout)


def collect_backup_lines():
    files = glob.glob(TASK_GLOB)
    if not files:
        return []

    latest_file = max(files, key=lambda f: os.path.getmtime(f))
    mtime = int(os.path.getmtime(latest_file))

    guests = {}
    current_vmid = None
    job_name = "backup-5f818dd2-f52f"
    overall_status = 1

    re_start = re.compile(r"INFO:\s+Starting Backup of VM\s+(\d+)\s+\((qemu|lxc)\)")
    re_name_vm = re.compile(r"INFO:\s+VM Name:\s+(.+)")
    re_name_ct = re.compile(r"INFO:\s+CT Name:\s+(.+)")
    re_size_archive = re.compile(r"INFO:\s+archive file size:\s+([0-9.]+\s*[A-Za-z]+)")
    re_bytes_written = re.compile(r"INFO:\s+Total bytes written:\s+(\d+)")
    re_finish = re.compile(r"INFO:\s+Finished Backup of VM\s+(\d+)\s+\(([^)]+)\)")
    re_fail = re.compile(r"ERROR:\s+Backup of VM\s+(\d+)\s+failed")
    re_job_err = re.compile(r"(Backup job finished with errors|TASK ERROR:)")

    with read_task_log(latest_file) as f:
        for line in f:
            if re_job_err.search(line):
                overall_status = 0
            m = re_start.search(line)
            if m:
                current_vmid = m.group(1)
                guest_type = m.group(2)
                guests[current_vmid] = {
                    "vmid": current_vmid,
                    "type": guest_type,
                    "name": current_vmid,
                    "status": 0,
                    "size_bytes": 0,
                    "duration_seconds": 0,
                }
                continue
            if not current_vmid:
                continue
            m = re_name_vm.search(line) or re_name_ct.search(line)
            if m:
                guests[current_vmid]["name"] = m.group(1).strip()
                continue
            m = re_size_archive.search(line)
            if m:
                guests[current_vmid]["size_bytes"] = parse_size_str(m.group(1))
                continue
            m = re_bytes_written.search(line)
            if m and guests[current_vmid]["size_bytes"] == 0:
                guests[current_vmid]["size_bytes"] = int(m.group(1))
                continue
            m = re_finish.search(line)
            if m and m.group(1) == current_vmid:
                guests[current_vmid]["status"] = 1
                guests[current_vmid]["duration_seconds"] = parse_duration_str(m.group(2))
                current_vmid = None
                continue
            m = re_fail.search(line)
            if m and m.group(1) == current_vmid:
                guests[current_vmid]["status"] = 0
                current_vmid = None
                continue

    ok_cnt = sum(1 for g in guests.values() if g["status"] == 1)
    fail_cnt = sum(1 for g in guests.values() if g["status"] == 0)
    total_size = sum(g["size_bytes"] for g in guests.values())
    total_dur = sum(g["duration_seconds"] for g in guests.values())

    if fail_cnt > 0:
        overall_status = 0

    lines = [
        f'pve_backup_last_run_timestamp_seconds{{job="{job_name}"}} {mtime}',
        f'pve_backup_last_status{{job="{job_name}"}} {overall_status}',
        f'pve_backup_last_duration_seconds{{job="{job_name}"}} {total_dur}',
        f'pve_backup_last_size_bytes{{job="{job_name}"}} {total_size}',
        f'pve_backup_guests_ok{{job="{job_name}"}} {ok_cnt}',
        f'pve_backup_guests_failed{{job="{job_name}"}} {fail_cnt}',
    ]

    for vmid, g in sorted(guests.items(), key=lambda x: int(x[0])):
        escaped_name = g["name"].replace('"', '\\"')
        lines.append(f'pve_backup_guest_status{{vmid="{vmid}",name="{escaped_name}",type="{g["type"]}"}} {g["status"]}')
        lines.append(f'pve_backup_guest_size_bytes{{vmid="{vmid}",name="{escaped_name}",type="{g["type"]}"}} {g["size_bytes"]}')
        lines.append(f'pve_backup_guest_duration_seconds{{vmid="{vmid}",name="{escaped_name}",type="{g["type"]}"}} {g["duration_seconds"]}')

    return lines


def collect_smart_lines():
    lines = []
    try:
        out = subprocess.check_output(
            ["smartctl", "-A", NVME_DEVICE], text=True, timeout=30
        )
        used = re.search(r"Percentage Used:\s+(\d+)%", out).group(1)
        temp = re.search(r"Temperature:\s+(\d+)\s+Celsius", out).group(1)
        tbw = re.search(r"Data Units Written:\s+[\d,]+\s+\[([\d\.]+)\s+TB\]", out).group(1)
        lines.append(f'smart_ssd_percentage_used{{host="proxmox",device="nvme0n1",model="Crucial P3 500G"}} {used}')
        lines.append(f'smart_ssd_temperature_celsius{{host="proxmox",device="nvme0n1",model="Crucial P3 500G"}} {temp}')
        lines.append(f'smart_ssd_tbw_terabytes{{host="proxmox",device="nvme0n1",model="Crucial P3 500G"}} {tbw}')
    except Exception as e:
        lines.append(f"# Error SMART: {e}")
    return lines


def collect_fs_lines():
    """Test d'ecriture reel sur le fs de backup.

    Un ext4 passe en emergency_ro garde son mountpoint dans /proc/mounts (rw
    affiche) : seule une ecriture echoue. Le node-exporter ne scrape pas ce
    mountpoint, donc l'exporter 9188 (root sur EVA-002) est le seul endroit
    fiable pour le tester.
    1 = inscriptible, 0 = lecture seule (emergency_ro).
    """
    lines = []
    try:
        probe = os.path.join(FS_PATH, ".hermes-ro-probe")
        with open(probe, "w") as f:
            f.write(str(int(time.time())) + "\n")
        os.unlink(probe)
        lines.append("pve_backup_fs_readonly 0")
    except OSError:
        lines.append("pve_backup_fs_readonly 1")
    try:
        st = os.statvfs(FS_PATH)
        avail = st.f_bavail * st.f_frsize
        total = st.f_blocks * st.f_frsize
        pct = (avail / total * 100) if total else 0
        lines.append(f"pve_backup_fs_free_percent {pct:.1f}")
    except OSError:
        lines.append("pve_backup_fs_free_percent 0")
    return lines


def refresh_once():
    """Reconstruit le payload complet (SMART + backups) dans le cache."""
    global _payload
    lines = collect_smart_lines()
    try:
        lines.extend(collect_backup_lines())
    except Exception as e:
        lines.append(f"# Error collecting backup metrics: {e}")
    try:
        lines.extend(collect_fs_lines())
    except Exception as e:
        lines.append(f"# Error collecting fs metrics: {e}")
    payload = "\n".join(lines) + "\n"
    with _lock:
        _payload = payload


def refresh_loop():
    while True:
        try:
            refresh_once()
        except Exception:
            pass  # on garde le dernier payload valide
        time.sleep(REFRESH_INTERVAL)


class Handler(http.server.BaseHTTPRequestHandler):
    def log_message(self, format, *args):
        return

    def do_GET(self):
        with _lock:
            payload = _payload
        if not payload:
            refresh_once()
            with _lock:
                payload = _payload
        body = payload.encode()
        self.send_response(200)
        self.send_header("Content-Type", "text/plain; version=0.0.4")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        try:
            self.wfile.write(body)
        except (BrokenPipeError, ConnectionResetError):
            pass  # scrape interrompu par le client, sans importance


if __name__ == "__main__":
    # Le port est ouvert AVANT le premier refresh : meme si le parse du log
    # vzdump est lent (log de ~1 Go), les scrapes sont servis (cache vide
    # puis rempli par le thread de fond) au lieu de timeouter sur port ferme.
    httpd = http.server.ThreadingHTTPServer(("", PORT), Handler)
    threading.Thread(target=refresh_loop, daemon=True, name="refresh").start()
    httpd.serve_forever()
