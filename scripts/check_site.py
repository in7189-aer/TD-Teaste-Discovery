#!/usr/bin/env python3
"""Basic offline checks for TD static website, no third-party dependencies."""
from html.parser import HTMLParser
from pathlib import Path
import subprocess
import tempfile

root = Path(__file__).resolve().parents[1]
html = (root / "index.html").read_text(encoding="utf-8")
class Parser(HTMLParser):
    def __init__(self):
        super().__init__()
        self.scripts = []
        self.inside = False
        self.ids = set()
    def handle_starttag(self, tag, attrs):
        d = dict(attrs)
        if "id" in d:
            if d["id"] in self.ids:
                raise AssertionError("Duplicate HTML id: " + d["id"])
            self.ids.add(d["id"])
        if tag == "script" and "src" not in d:
            self.inside = True
    def handle_endtag(self, tag):
        if tag == "script":
            self.inside = False
    def handle_data(self, data):
        if self.inside:
            self.scripts.append(data)

p = Parser()
p.feed(html)
assert p.scripts, "No inline application JavaScript"
assert 'rel="manifest"' in html, "Missing PWA manifest"
assert 'serviceWorker.register' in html, "Service worker registration missing"
for name in ["manifest.webmanifest", "icon.svg", "sw.js", "README.md", "database/schema.sql"]:
    assert (root / name).is_file(), f"Missing required file: {name}"
import json
manifest = json.loads((root / "manifest.webmanifest").read_text(encoding="utf-8"))
assert manifest["start_url"] == "./"
assert (root / manifest["icons"][0]["src"]).is_file()
with tempfile.TemporaryDirectory() as d:
    js = Path(d) / "inline.js"
    js.write_text("\n".join(p.scripts), encoding="utf-8")
    subprocess.run(["node", "--check", str(js)], check=True)
print("TD static checks passed")
