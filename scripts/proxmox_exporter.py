#!/usr/bin/env python3
"""
Proxmox VE Metrics Exporter
Exporte l'état, le CPU et la RAM de tous les LXC et VMs sur le port 9221.

Les noms de séries sont stables : les règles d'enregistrement (monitoring/rules/power.yml)
et les alertes en dépendent.
"""
import http.server
import json
import os
import subprocess

PORT = int(os.environ.get("PVE_EXPORTER_PORT", "9221"))
NODE = os.environ.get("PVE_NODE", "EVA-002")
PVESH_TIMEOUT = 5


def esc(value):
    """Échappe une valeur de label (format texte Prometheus : \\, " et saut de ligne)."""
    return str(value).replace("\\", "\\\\").replace('"', '\\"').replace("\n", "\\n")


def vmid_of(guest):
    """vmid entier, ou None si l'API renvoie autre chose (la ligne est alors ignorée)."""
    try:
        return int(guest.get("vmid"))
    except (TypeError, ValueError):
        return None


def pvesh(kind):
    out = subprocess.check_output(
        ["pvesh", "get", f"/nodes/{NODE}/{kind}", "--output-format", "json"],
        timeout=PVESH_TIMEOUT,
    )
    data = json.loads(out.decode())
    return [g for g in data if vmid_of(g) is not None]


def cpu_seconds(path):
    """Temps CPU cumulé lu dans cpu.stat (cgroup v2), None si le fichier est absent."""
    try:
        with open(path) as fh:
            for line in fh:
                if line.startswith("usage_usec"):
                    return int(line.split()[1]) / 1e6
    except (OSError, ValueError, IndexError):
        return None
    return None


def series(lines, metric, help_text, mtype, guests, value):
    lines.append(f"# HELP {metric} {help_text}")
    lines.append(f"# TYPE {metric} {mtype}")
    for g in guests:
        v = value(g)
        if v is None:
            continue
        lines.append(f'{metric}{{vmid="{vmid_of(g)}",name="{esc(g.get("name", ""))}"}} {v}')


def running(g):
    return g.get("status") == "running"


def collect():
    lines = []
    try:
        lxcs = pvesh("lxc")
        vms = pvesh("qemu")
    except (OSError, subprocess.SubprocessError, ValueError) as e:
        # Seul le type d'exception est exposé, pas son message.
        return [f"# Erreur de collecte : {type(e).__name__}", "pve_exporter_status 0"]

    series(lines, "pve_lxc_status", "Statut du conteneur LXC (1 = running, 0 = stopped)",
           "gauge", lxcs, lambda g: 1 if running(g) else 0)
    series(lines, "pve_lxc_cpu_usage_ratio", "Utilisation CPU du LXC (0.0 a 1.0)",
           "gauge", lxcs, lambda g: f'{float(g.get("cpu", 0)):.4f}')
    series(lines, "pve_lxc_memory_used_bytes", "Memoire RAM utilisee par le LXC",
           "gauge", lxcs, lambda g: int(g.get("mem", 0)))
    series(lines, "pve_lxc_memory_total_bytes", "Memoire RAM allouee au LXC",
           "gauge", lxcs, lambda g: int(g.get("maxmem", 0)))

    series(lines, "pve_qemu_status", "Statut de la VM QEMU (1 = running, 0 = stopped)",
           "gauge", vms, lambda g: 1 if running(g) else 0)
    series(lines, "pve_qemu_cpu_usage_ratio", "Utilisation CPU de la VM",
           "gauge", vms, lambda g: f'{float(g.get("cpu", 0)):.4f}')
    series(lines, "pve_qemu_memory_used_bytes", "RAM utilisee par la VM",
           "gauge", vms, lambda g: int(g.get("mem", 0)))

    # Temps CPU cumulé (cgroup v2) : base du calcul de puissance par invité.
    # Le chemin est construit à partir d'un vmid déjà converti en int (pas d'injection de chemin).
    def cgroup_cpu(template):
        def value(g):
            if not running(g):
                return None
            v = cpu_seconds(template.format(vmid=vmid_of(g)))
            return None if v is None else f"{v:.3f}"
        return value

    series(lines, "pve_lxc_cpu_seconds_total", "Temps CPU cumule du LXC (cgroup cpu.stat)",
           "counter", lxcs, cgroup_cpu("/sys/fs/cgroup/lxc/{vmid}/cpu.stat"))
    series(lines, "pve_qemu_cpu_seconds_total", "Temps CPU cumule de la VM (cgroup cpu.stat)",
           "counter", vms, cgroup_cpu("/sys/fs/cgroup/qemu.slice/{vmid}.scope/cpu.stat"))

    lines.append("pve_exporter_status 1")
    return lines


class ProxmoxHandler(http.server.BaseHTTPRequestHandler):
    # Coupe une connexion client qui n'envoie rien (évite un thread bloqué indéfiniment).
    timeout = 10

    def log_message(self, format, *args):
        return

    def do_GET(self):
        if self.path != "/metrics":
            self.send_response(404)
            self.end_headers()
            return
        payload = ("\n".join(collect()) + "\n").encode("utf-8")
        self.send_response(200)
        self.send_header("Content-Type", "text/plain; version=0.0.4; charset=utf-8")
        self.send_header("Content-Length", str(len(payload)))
        self.end_headers()
        self.wfile.write(payload)


class Server(http.server.ThreadingHTTPServer):
    # Un client lent ne bloque plus les scrapes suivants.
    daemon_threads = True
    allow_reuse_address = True


if __name__ == "__main__":
    print(f"Demarrage pve_exporter sur le port {PORT} (noeud {NODE})...", flush=True)
    with Server(("", PORT), ProxmoxHandler) as httpd:
        httpd.serve_forever()
