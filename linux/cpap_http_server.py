#!/usr/bin/env python3
"""
CPAP HTTP Server — Linux
Local HTTP server for polling mask-off alert status.

GitHub: https://github.com/discocracker02/cpap-mask-monitor
License: MIT
"""

import http.server
import sys
from pathlib import Path

BASE_DIR  = Path(__file__).parent
FLAG_FILE = BASE_DIR / "cpap_alert_flag.txt"
PORT      = 8765

class Handler(http.server.BaseHTTPRequestHandler):
    def do_GET(self):
        if self.path == "/status":
            if FLAG_FILE.exists():
                status = FLAG_FILE.read_text().strip()
                self.send_response(200)
                self.end_headers()
                self.wfile.write(status.encode())
            else:
                self.send_response(200)
                self.end_headers()
                self.wfile.write(b"OK")

        elif self.path == "/clear":
            FLAG_FILE.unlink(missing_ok=True)
            self.send_response(200)
            self.end_headers()
            self.wfile.write(b"CLEARED")

        else:
            self.send_response(404)
            self.end_headers()

    def log_message(self, format, *args):
        pass

print(f"CPAP HTTP server running on port {PORT}", flush=True)
try:
    http.server.HTTPServer(("0.0.0.0", PORT), Handler).serve_forever()
except KeyboardInterrupt:
    print("HTTP server stopped.")
    sys.exit(0)
