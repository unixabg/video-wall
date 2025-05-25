#!/usr/bin/env python3
import asyncio
import websockets
from http.server import HTTPServer, SimpleHTTPRequestHandler
from urllib.parse import urlparse, parse_qs
import threading
import re
import socket

# -------------------------------
# HTTP Redirect Handler
# -------------------------------
class RedirectHandler(SimpleHTTPRequestHandler):
    def do_GET(self):
        parsed = urlparse(self.path)
        params = parse_qs(parsed.query)

        if "hostname" in params:
            host = params["hostname"][0]
            match = re.match(r"(\d+)-(\d+)", host)
            if match:
                row, col = match.groups()
                # Controller hostname must be in format row-col-rows-cols
                local_hostname = socket.gethostname()
                ctrl_match = re.match(r"^\d+-\d+-(\d+)-(\d+)$", local_hostname)
                if not ctrl_match:
                    self.send_error(500, f"Controller hostname '{local_hostname}' does not encode grid size")
                    return

                rows, cols = ctrl_match.groups()

                redirect_url = f"/index.html?part={row},{col}&rows={rows}&cols={cols}"
                self.send_response(302)
                self.send_header("Location", redirect_url)
                self.end_headers()
                return

        # Serve files normally
        super().do_GET()

# -------------------------------
# WebSocket Handler
# -------------------------------
connected = set()

async def ws_handler(ws):
    connected.add(ws)
    try:
        async for message in ws:
            if message in {"play", "pause", "stop", "reload", "sync"}:
                await asyncio.gather(*(c.send(message) for c in connected))
    finally:
        connected.remove(ws)

# -------------------------------
# Main entry
# -------------------------------
def start_http_server():
    port = 8080
    print(f"[HTTP] Serving on port {port}...")
    httpd = HTTPServer(("", port), RedirectHandler)
    httpd.serve_forever()

async def start_websocket_server():
    print("[WebSocket] Serving on port 12345...")
    async with websockets.serve(ws_handler, "0.0.0.0", 12345):
        await asyncio.Future()  # run forever

def main():
    threading.Thread(target=start_http_server, daemon=True).start()
    asyncio.run(start_websocket_server())

if __name__ == "__main__":
    main()

