"""Extract player-facing strings (gettext style: the English text is the key) into
assets/localization/strings.csv, keeping existing Thai. Concatenations become templates:
  "Fused to ★"..n          ->  "Fused to ★{1}"
Run: python3 tools/locale_extract.py   (then fill the `th` column, then python3 tools/gen_strings.py)
Checks: prints missing Thai and keys no longer found in source (kept, marked unused).
"""
import csv, json, os, re, sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
CSV = ROOT / "assets" / "localization" / "strings.csv"
SOURCES = ["src/client", "src/server/Services", "src/shared"]
SKIP_FILES = {"PhoneLayouts.luau", "SwordPack.luau", "Weapons.luau", "LegacyWeaponMap.luau", "WeaponCatalog.luau", "Admins.luau", "AdminTabs.luau",
              "Strings.luau", "Locale.luau", "BalanceConfig.luau", "UIIcons.luau", "UIArt.luau", "NumberFormat.luau", "Net.luau",
              "WeaponVisual.luau", "PetVisual.luau", "Balance.luau", "AdminService.luau", "LiveEventMath.luau", "ChestIconRenderer.luau",
              "FeatureService.luau", "Features.luau"}
NOT_TEXT_CALLS = {"FindFirstChild", "WaitForChild", "GetAttribute", "SetAttribute", "GetService", "new", "IsA", "FindFirstChildOfClass",
                  "FindFirstChildWhichIsA", "GetTagged", "HasTag", "AddTag", "RemoveTag", "Event", "Function", "Get", "Set", "Increment",
                  "IsEnabled", "Art", "Icon", "Symbol", "Skin", "require", "GetAttributeChangedSignal", "GetPropertyChangedSignal",
                  "AddCurrency", "GetCurrency", "SetCurrency", "find", "match", "gsub", "gmatch", "split", "format", "rep", "sub",
                  "FireServer", "FireClient", "FireAllClients", "InvokeServer", "BindAction", "UnbindAction", "BindActionAtPriority",
                  "Register", "warn", "print", "error", "assert", "B", "part", "block", "wedge", "ball", "cyl", "Part", "add", "fromName", "Window", "Capsule", "SetBadge", "SetTab", "InfoBar", "Pill", "Badge"}
NAME_KEYS = {"Name", "name_", "key", "id", "kind", "stat", "kind_", "tab", "color", "atlas", "sprite", "icon", "symbol", "egg", "boss", "path", "cat", "category"}
TOKEN = re.compile(r'''--\[(=*)\[.*?\]\1\]|--[^\n]*|\[(=*)\[(.*?)\]\2\]|"((?:[^"\\\n]|\\.)*)"|'((?:[^'\\\n]|\\.)*)'|\.\.\.|\.\.|[A-Za-z_][A-Za-z0-9_]*|\d[\d.xXa-fA-F_]*|==|~=|<=|>=|\+=|-=|\*=|/=|//|::|\S''', re.S)
BOUND = {"(", ")", "[", "]", "{", "}", ",", ";", "=", "then", "do", "else", "elseif", "return", "local", "if", "while", "until",
         "end", "function", "and", "or", "not", "in", "for", "repeat", "+=", "-=", "==", "~=", "<", ">", "<=", ">="}


def unescape(s):
    try:
        return json.loads('"' + s.replace('\\\'', "'") + '"')
    except Exception:
        return s


def tokens(src):
    for m in TOKEN.finditer(src):
        t = m.group(0)
        if t.startswith("--"):
            continue
        if m.group(4) is not None:
            yield ("str", unescape(m.group(4)))
        elif m.group(5) is not None:
            yield ("str", unescape(m.group(5)))
        elif m.group(3) is not None:
            yield ("str", m.group(3))
        else:
            yield ("tok", t)


def is_text(s):
    s2 = s.strip()
    if not re.search(r"[A-Za-z]{2,}", s2):
        return False
    if re.search(r"rbxasset|https?://|\.luau|^[A-Za-z]+\.[A-Za-z.]+$|^Enum\.|%[sdfx]", s2):
        return False
    if " " in s2 or re.search(r"[!?.:•★×]", s2):
        return True
    return bool(re.match(r"^([A-Z][a-z]+|[A-Z]{2,}!?)$", s2))


def keep(s):
    t = s.strip()
    if not t or t.startswith("[") or re.match(r"^[a-z]", t):
        return False
    if " " not in t and re.search(r"[_.]", t):
        return False
    if path_only_chest and not t.endswith("Chest"):
        return False
    return True


path_only_chest = False


def extract(path):
    global path_only_chest
    path_only_chest = path.name == "ChestBuilder.luau"
    toks = list(tokens(path.read_text(encoding="utf-8")))
    found = []
    in_concat = set()
    for j, t in enumerate(toks):
        if t[0] == "str" and ((j + 1 < len(toks) and toks[j + 1] == ("tok", "..")) or (j >= 1 and toks[j - 1] == ("tok", ".."))):
            in_concat.add(j)
    i = 0
    # plain literals with simple context filtering
    for j, (k, v) in enumerate(toks):
        if k != "str" or not is_text(v) or j in in_concat:
            continue
        p1 = toks[j - 1][1] if j >= 1 else ""
        p2 = toks[j - 2][1] if j >= 2 else ""
        if p1 == "(" and p2 in NOT_TEXT_CALLS:
            continue
        if p1 == "=" and p2 in NAME_KEYS:
            continue
        if p1 == "[" or (j + 1 < len(toks) and toks[j + 1][1] == "]"):
            continue
        found.append(v)
    # concatenation templates: brackets nest (a call stays inside its operand, its args are parsed
    # on their own); other boundary tokens end a context; operands split on top-level '..'
    OPEN = {"(": ")", "[": "]", "{": "}"}
    def emit(ctx):
        if ("tok", "..") not in ctx:
            return
        parts, cur = [], []
        for t in ctx:
            if t == ("tok", ".."):
                parts.append(cur); cur = []
            else:
                cur.append(t)
        parts.append(cur)
        out, n = "", 0
        for part in parts:
            if len(part) == 1 and part[0][0] == "str":
                out += part[0][1]
            else:
                n += 1; out += "{%d}" % n
        lits = re.sub(r"\{\d+\}", "", out)
        if re.search(r"[A-Za-z]{2,}", lits) and n > 0:
            found.append(out)
    def seq(i, closer):
        ctx = []
        while i < len(toks):
            t = toks[i]
            if t[0] == "tok" and t[1] == closer:
                emit(ctx); return i + 1
            if t[0] == "tok" and t[1] in OPEN:
                i = seq(i + 1, OPEN[t[1]])
                ctx.append(("grp", ""))
                continue
            if t[0] == "tok" and t[1] in (")", "]", "}"):
                emit(ctx); return i + 1
            if t[0] == "tok" and t[1] in BOUND:
                emit(ctx); ctx = []
            else:
                ctx.append(t)
            i += 1
        emit(ctx)
        return i
    seq(0, None)
    return [f for f in found if keep(f)]


def main():
    rows = {}
    if CSV.exists():
        with CSV.open(encoding="utf-8", newline="") as f:
            for r in csv.DictReader(f):
                rows[r["key"]] = r
    seen = {}
    for base in SOURCES:
        for p in sorted((ROOT / base).rglob("*.luau")):
            if p.name in SKIP_FILES:
                continue
            for s in extract(p):
                seen.setdefault(s, p.stem)
    # catalog names with authored Thai
    for data, field in (("swords.json", "thai"), ("weapons.json", "thai")):
        for w in json.loads((ROOT / "data" / data).read_text(encoding="utf-8")):
            seen.setdefault(w["name"], "catalog:" + data)
            if w["name"] not in rows or not rows[w["name"]]["th"]:
                rows[w["name"]] = {"key": w["name"], "en": w["name"], "th": w[field], "context": "catalog:" + data, "note": ""}
    # names with authored Thai in Config (Pets/Seeds/Eggs/Zones/...) are authoritative
    pair = re.compile(r'name\s*=\s*"([^"]+)"\s*,\s*thai\s*=\s*"([^"]+)"')
    for p in sorted((ROOT / "src/shared/Config").glob("*.luau")):
        if p.name in SKIP_FILES:
            continue
        for en, th in pair.findall(p.read_text(encoding="utf-8")):
            if re.search(r"[\u0E00-\u0E7F]", th):
                seen.setdefault(en, p.stem)
                rows[en] = {"key": en, "en": en, "th": th, "context": p.stem, "note": "config"}
    for k, ctx in seen.items():
        r = rows.get(k) or {"key": k, "en": k, "th": "", "context": ctx, "note": ""}
        r["context"] = ctx
        if r.get("note") in ("unused",):
            r["note"] = ""
        rows[k] = r
    for k, r in rows.items():
        if k not in seen and r.get("note") != "manual":
            r["note"] = "unused"
    CSV.parent.mkdir(parents=True, exist_ok=True)
    with CSV.open("w", encoding="utf-8", newline="") as f:
        w = csv.DictWriter(f, fieldnames=["key", "en", "th", "context", "note"], lineterminator="\n")
        w.writeheader()
        for k in sorted(rows, key=lambda k: (rows[k]["context"], k)):
            w.writerow(rows[k])
    missing = [k for k, r in rows.items() if not r["th"] and r.get("note") != "unused"]
    unused = [k for k, r in rows.items() if r.get("note") == "unused"]
    print(f"keys={len(rows)} missing_th={len(missing)} unused={len(unused)}")
    return 1 if "--check" in sys.argv and missing else 0


if __name__ == "__main__":
    sys.exit(main())
