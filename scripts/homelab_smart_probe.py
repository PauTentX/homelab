#!/usr/bin/env python3
"""
Homelab SMART Probe Exporter
Lit les métriques NVMe (endurance % usé, température, TBW) via smartctl et expose sur le port 9188.
"""
import http.server
import socketserver
import subprocess
import re

PORT = 9188

class Handler(http.server.BaseHTTPRequestHandler):
    def log_message(self, format, *args):
        return

    def do_GET(self):
        lines = []
        try:
            out = subprocess.check_output(["smartctl", "-A", "/dev/nvme0n1"], text=True)
            used_match = re.search(r"Percentage Used:\s+(\d+)%", out)
            temp_match = re.search(r"Temperature:\s+(\d+)\s+Celsius", out)
            tbw_match = re.search(r"Data Units Written:\s+[\d,]+\s+\[([\d\.]+)\s+TB\]", out)
            
            used = used_match.group(1) if used_match else "0"
            temp = temp_match.group(1) if temp_match else "0"
            tbw = tbw_match.group(1) if tbw_match else "0"

            lines.append(f'smart_ssd_percentage_used{{host="proxmox",device="nvme0n1",model="NVMe Storage"}} {used}')
            lines.append(f'smart_ssd_temperature_celsius{{host="proxmox",device="nvme0n1",model="NVMe Storage"}} {temp}')
            lines.append(f'smart_ssd_tbw_terabytes{{host="proxmox",device="nvme0n1",model="NVMe Storage"}} {tbw}')
        except Exception as e:
            lines.append(f'# Error: {e}')

        payload = "\n".join(lines) + "\n"
        self.send_response(200)
        self.send_header("Content-Type", "text/plain")
        self.end_headers()
        self.wfile.write(payload.encode())

if __name__ == "__main__":
    with socketserver.TCPServer(("", PORT), Handler) as httpd:
        httpd.serve_forever()
