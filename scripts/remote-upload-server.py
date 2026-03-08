#!/usr/bin/env python3
import os
import sys
from http.server import BaseHTTPRequestHandler, HTTPServer
from pathlib import Path
from urllib.parse import parse_qs, unquote, urlparse

CHUNK_SIZE = 1024 * 1024


def main() -> int:
    port = int(sys.argv[1]) if len(sys.argv) > 1 else 18080
    save_dir = Path(os.environ.get("PTBD_SAVE_DIR", str(Path.home() / "Desktop")))
    save_dir.mkdir(parents=True, exist_ok=True)

    class Handler(BaseHTTPRequestHandler):
        protocol_version = "HTTP/1.1"

        def handle_expect_100(self):
            self.send_response_only(100)
            self.end_headers()
            return True

        def do_PUT(self):
            parsed = urlparse(self.path)
            if parsed.path != "/upload":
                self.send_response(404)
                self.send_header("Connection", "close")
                self.end_headers()
                try:
                    self.wfile.write(b"not found")
                except BrokenPipeError:
                    pass
                return

            qs = parse_qs(parsed.query)
            filename = os.path.basename(unquote(qs.get("filename", ["ptbd-upload.bin"])[0])) or "ptbd-upload.bin"
            length = int(self.headers.get("Content-Length", "0"))
            target = save_dir / filename
            out = str(target).encode()
            remaining = length

            with target.open("wb") as handle:
                while remaining > 0:
                    chunk = self.rfile.read(min(CHUNK_SIZE, remaining))
                    if not chunk:
                        break
                    handle.write(chunk)
                    remaining -= len(chunk)

            if remaining != 0:
                self.send_response(400)
                self.send_header("Connection", "close")
                self.end_headers()
                try:
                    self.wfile.write(b"incomplete upload")
                except BrokenPipeError:
                    pass
                return

            self.send_response(200)
            self.send_header("Content-Type", "text/plain; charset=utf-8")
            self.send_header("Content-Length", str(len(out)))
            self.send_header("Connection", "close")
            self.end_headers()
            try:
                self.wfile.write(out)
            except BrokenPipeError:
                pass

        def log_message(self, fmt, *args):
            return

    HTTPServer(("127.0.0.1", port), Handler).serve_forever()
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
