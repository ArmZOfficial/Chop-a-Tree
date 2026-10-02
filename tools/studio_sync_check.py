"""Compare Studio script hashes with the repo.
In Studio (execute_luau, Edit) build "FullName|hash;..." where hash = h(Source:gsub("\r\n","\n"):gsub("%s+$",""))
with h(s) = (h*31+byte) % 2147483647, then: python3 tools/studio_sync_check.py < dump.txt
"""
import os, sys
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
PREFIX = [("ReplicatedStorage.Shared.", "src/shared/"), ("ServerScriptService.Server.", "src/server/"),
          ("StarterPlayer.StarterPlayerScripts.Client.", "src/client/"), ("ServerStorage.AdminUI.", "src/admin/"),
          ("ServerStorage.MapTools.", "tools/map/")]
def h(b):
    x = 0
    for c in b: x = (x * 31 + c) % 2147483647
    return x
def repo_path(full):
    for a, b in PREFIX:
        if full.startswith(a):
            base = os.path.join(ROOT, b + full[len(a):].replace(".", "/"))
            for ext in (".luau", ".server.luau", ".client.luau"):
                if os.path.exists(base + ext): return base + ext
            return None
    return None
seen, bad = set(), 0
for item in sys.stdin.read().strip().split(";"):
    full, hs = item.rsplit("|", 1)
    p = repo_path(full)
    if not p:
        print("STUDIO ONLY", full); bad += 1; continue
    seen.add(os.path.normpath(p))
    b = open(p, "rb").read().replace(b"\r\n", b"\n").rstrip()
    if h(b) != int(hs): print("DIFF", full); bad += 1
for root in ("src",):
    for dp, dn, fn in os.walk(os.path.join(ROOT, root)):
        for f in fn:
            if f.endswith(".luau") and os.path.normpath(os.path.join(dp, f)) not in seen: print("REPO ONLY", os.path.join(dp, f)[len(ROOT)+1:])
print("mismatches:", bad)
