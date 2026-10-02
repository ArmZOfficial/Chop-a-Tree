"""assets/localization/strings.csv -> src/shared/Config/Strings.luau (Thai table keyed by English text).
Catalog/config names (weapons, pets, seeds, eggs, zones) are NOT copied: Shared.Locale reads their `.thai`
fields at runtime. Run after editing the CSV:  python3 tools/gen_strings.py
"""
import csv, json
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent

def lua(s):
    return json.dumps(s, ensure_ascii=False)

rows = list(csv.DictReader((ROOT / "assets/localization/strings.csv").open(encoding="utf-8")))
keep = sorted((r for r in rows if r["th"] and r["th"] != r["key"] and r.get("note") not in ("config", "unused")
               and not r["context"].startswith("catalog:")), key=lambda r: r["key"])
lines = ["-- สร้างอัตโนมัติจาก assets/localization/strings.csv ด้วย tools/gen_strings.py — ห้ามแก้ไฟล์นี้ด้วยมือ",
         "-- th[English text] = Thai. {1}/{2}... are template slots (see Shared.Locale). English needs no table.",
         "return table.freeze({", "\tth = table.freeze({"]
lines += [f"\t\t[{lua(r['key'])}] = {lua(r['th'])}," for r in keep]
lines += ["\t}),", "})", ""]
(ROOT / "src/shared/Config/Strings.luau").write_text("\n".join(lines), encoding="utf-8")
print(f"Strings.luau: {len(keep)} Thai entries")
