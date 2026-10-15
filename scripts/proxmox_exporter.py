#!/usr/bin/env python3
"""
Proxmox VE Metrics Exporter
Exporte l'état, le CPU, la RAM, et le Disk de tous les LXC et VMs sur le port 9221.
"""
import http.server
import socketserver
import subprocess
import json
import time

PORT = 9221

class ProxmoxHandler(http.server.BaseHTTPRequestHandler):
    def log_message(self, format, *args):
        return

    def do_GET(self):
        if self.path != "/metrics":
            self.send_response(404)
            self.end_headers()
            return

        lines = []
        try:
            # 1. LXC Containers
            cmd = ["pvesh", "get", "/nodes/EVA-002/lxc", "--output-format", "json"]
            out = subprocess.check_output(cmd, timeout=5)
            lxcs = json.loads(out.decode())

            lines.append("# HELP pve_lxc_status Statut du conteneur LXC (1 = running, 0 = stopped)")
            lines.append("# TYPE pve_lxc_status gauge")
            for c in lxcs:
                vmid = c.get("vmid")
                name = c.get("name")
                status = 1 if c.get("status") == "running" else 0
                lines.append(f'pve_lxc_status{{vmid="{vmid}",name="{name}"}} {status}')

            lines.append("# HELP pve_lxc_cpu_usage_ratio Utilisation CPU du LXC (0.0 a 1.0)")
            lines.append("# TYPE pve_lxc_cpu_usage_ratio gauge")
            for c in lxcs:
                vmid = c.get("vmid")
                name = c.get("name")
                lines.append(f'pve_lxc_cpu_usage_ratio{{vmid="{vmid}",name="{name}"}} {c.get("cpu", 0):.4f}')

            lines.append("# HELP pve_lxc_memory_used_bytes Memoire RAM utilisee par le LXC")
            lines.append("# TYPE pve_lxc_memory_used_bytes gauge")
            for c in lxcs:
                vmid = c.get("vmid")
                name = c.get("name")
                lines.append(f'pve_lxc_memory_used_bytes{{vmid="{vmid}",name="{name}"}} {c.get("mem", 0)}')

            lines.append("# HELP pve_lxc_memory_total_bytes Memoire RAM allouee au LXC")
            lines.append("# TYPE pve_lxc_memory_total_bytes gauge")
            for c in lxcs:
                vmid = c.get("vmid")
                name = c.get("name")
                lines.append(f'pve_lxc_memory_total_bytes{{vmid="{vmid}",name="{name}"}} {c.get("maxmem", 0)}')

            # 2. VMs QEMU
            cmd_qemu = ["pvesh", "get", "/nodes/EVA-002/qemu", "--output-format", "json"]
            out_q = subprocess.check_output(cmd_qemu, timeout=5)
            vms = json.loads(out_q.decode())

            lines.append("# HELP pve_qemu_status Statut de la VM QEMU (1 = running, 0 = stopped)")
            lines.append("# TYPE pve_qemu_status gauge")
            for v in vms:
                vmid = v.get("vmid")
                name = v.get("name")
                status = 1 if v.get("status") == "running" else 0
                lines.append(f'pve_qemu_status{{vmid="{vmid}",name="{name}"}} {status}')

            lines.append("# HELP pve_qemu_cpu_usage_ratio Utilisation CPU de la VM")
            lines.append("# TYPE pve_qemu_cpu_usage_ratio gauge")
            for v in vms:
                vmid = v.get("vmid")
                name = v.get("name")
                lines.append(f'pve_qemu_cpu_usage_ratio{{vmid="{vmid}",name="{name}"}} {v.get("cpu", 0):.4f}')

            lines.append("# HELP pve_qemu_memory_used_bytes RAM utilisee par la VM")
            lines.append("# TYPE pve_qemu_memory_used_bytes gauge")
            for v in vms:
                vmid = v.get("vmid")
                name = v.get("name")
                lines.append(f'pve_qemu_memory_used_bytes{{vmid="{vmid}",name="{name}"}} {v.get("mem", 0)}')


            # 3. Temps CPU cumule (cgroup v2) : base du calcul de puissance par invite
            def _cpu_sec(path):
                try:
                    for l in open(path):
                        if l.startswith("usage_usec"):
                            return int(l.split()[1]) / 1e6
                except Exception:
                    return None
            lines.append("# HELP pve_lxc_cpu_seconds_total Temps CPU cumule du LXC (cgroup cpu.stat)")
            lines.append("# TYPE pve_lxc_cpu_seconds_total counter")
            for c in lxcs:
                if c.get("status") != "running":
                    continue
                v = _cpu_sec(f"/sys/fs/cgroup/lxc/{c['vmid']}/cpu.stat")
                if v is not None:
                    lines.append(f'pve_lxc_cpu_seconds_total{{vmid="{c["vmid"]}",name="{c.get("name")}"}} {v:.3f}')
            lines.append("# HELP pve_qemu_cpu_seconds_total Temps CPU cumule de la VM (cgroup cpu.stat)")
            lines.append("# TYPE pve_qemu_cpu_seconds_total counter")
            for v_ in vms:
                if v_.get("status") != "running":
                    continue
                v = _cpu_sec(f"/sys/fs/cgroup/qemu.slice/{v_['vmid']}.scope/cpu.stat")
                if v is not None:
                    lines.append(f'pve_qemu_cpu_seconds_total{{vmid="{v_["vmid"]}",name="{v_.get("name")}"}} {v:.3f}')

            lines.append("pve_exporter_status 1")
        except Exception as e:
            lines.append("pve_exporter_status 0")
            lines.append(f"# Error: {e}")

        payload = "\n".join(lines) + "\n"
        self.send_response(200)
        self.send_header("Content-Type", "text/plain; version=0.0.4; charset=utf-8")
        self.end_headers()
        self.wfile.write(payload.encode("utf-8"))

if __name__ == "__main__":
    print(f"Demarrage pve_exporter sur le port {PORT}...")
    socketserver.TCPServer.allow_reuse_address = True
    with socketserver.TCPServer(("", PORT), ProxmoxHandler) as httpd:
        httpd.serve_forever()
