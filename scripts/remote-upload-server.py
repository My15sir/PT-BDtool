#!/usr/bin/env python3
import os
import sys
from http.server import BaseHTTPRequestHandler, HTTPServer
from pathlib import Path
from urllib.parse import parse_qs, unquote, urlparse


def main() -> int:
    port = int(sys.argv[1]) if len(sys.argv) > 1 else 18080
    save_dir = Path(os.environ.get("PTBD_SAVE_DIR", str(Path.home() / "Desktop")))
    save_dir.mkdir(parents=True, exist_ok=True)

    class Handler(BaseHTTPRequestHandler):
        def do_PUT(self):
            parsed = urlparse(self.path)
            if parsed.path != "/upload":
                self.send_response(404)
                self.end_headers()
                self.wfile.write(b"not found")
                return

            qs = parse_qs(parsed.query)
            filename = os.path.basename(unquote(qs.get("filename", ["ptbd-upload.bin"])[0])) or "ptbd-upload.bin"
            length = int(self.headers.get("Content-Length", "0"))
            data = self.rfile.read(length)
            target = save_dir / filename
            target.write_bytes(data)
            out = str(target).encode()

            self.send_response(200)
            self.send_header("Content-Type", "text/plain; charset=utf-8")
            self.send_header("Content-Length", str(len(out)))
            self.end_headers()
            self.wfile.write(out)

        def log_message(self, fmt, *args):
            return

    HTTPServer(("127.0.0.1", port), Handler).serve_forever()
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
