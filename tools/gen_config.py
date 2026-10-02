"""แปลงไฟล์ข้อมูลใน data/ เป็น Luau ModuleScript ใน src/shared/Config/
รัน: python3 tools/gen_config.py   (รันใหม่ทุกครั้งที่แก้ data/*.json)
"""
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
OUT = ROOT / "src" / "shared" / "Config"


def lua_str(s):
    return '"' + str(s).replace("\\", "\\\\").replace('"', '\\"') + '"'


def gen_weapons():
    data = json.loads((ROOT / "data" / "weapons.json").read_text(encoding="utf-8"))
    lines = [
        "-- สร้างอัตโนมัติจาก data/weapons.json ด้วย tools/gen_config.py — ห้ามแก้ไฟล์นี้ด้วยมือ",
        "-- basePower = Power ที่ Item Level 1 (โซน 1) ดูสูตรใน Shared.Balance",
        "",
        "export type Weapon = {",
        "\tid: string, name: string, thai: string, rarity: string, element: string?,",
        "\tmove: string?, basePower: number, speed: number, area: number, retired: boolean?,",
        "}",
        "",
        "local list: { Weapon } = {",
    ]
    for w in data:
        el = "nil" if w["element"] == "–" else lua_str(w["element"])
        mv = "nil" if w["move"] == "–" else lua_str(w["move"])
        lines.append(
            f'\t{{ id = {lua_str(w["id"])}, name = {lua_str(w["name"])}, thai = {lua_str(w["thai"])}, '
            f'rarity = {lua_str(w["rarity"])}, element = {el}, move = {mv}, '
            f'basePower = {w["basePower"]}, speed = {w["speed"]}, area = {w["area"]} }},'
        )
    lines += [
        "}",
        "",
        "local byId: { [string]: Weapon } = {}",
        "for _, w in list do",
        "\tassert(byId[w.id] == nil, \"duplicate weapon id \" .. w.id)",
        "\tbyId[w.id] = w",
        "end",
        "",
        "return table.freeze({ List = list, ById = byId })",
        "",
    ]
    (OUT / "Weapons.luau").write_text("\n".join(lines), encoding="utf-8")
    return len(data)


def lua_opt(v):
    return "nil" if v == "–" else lua_str(v)


def gen_swords():
    data = json.loads((ROOT / "data" / "swords.json").read_text(encoding="utf-8"))
    rar = ["Common", "Rare", "Epic", "Legendary", "Mythic"]
    els = sorted({w["element"] for w in data if w["element"] != "–"})
    shp = list(dict.fromkeys(w["swordShape"] for w in data))
    grd = list(dict.fromkeys(w["guardStyle"] for w in data))
    hnd = list(dict.fromkeys(w["handleStyle"] for w in data))
    arr = lambda xs: "{ " + ", ".join(lua_str(x) for x in xs) + " }"
    lines = [
        "-- สร้างอัตโนมัติจาก data/swords.json ด้วย tools/gen_config.py — ห้ามแก้ไฟล์นี้ด้วยมือ",
        "-- Sword Pack 380: stable IDs swd_001..swd_380 (tools/gen_swords.py). basePower = Power at Item Level 1.",
        "-- Row: id, name, thai, rarity#, element# (0 = none), move, basePower, speed, area, shape#, guard#, handle#",
        "",
        "export type Sword = {",
        "\tid: string, name: string, thai: string, rarity: string, element: string?, move: string?,",
        "\tbasePower: number, speed: number, area: number, swordShape: string, guardStyle: string, handleStyle: string,",
        "}",
        "",
        f"local R = {arr(rar)}",
        f"local E = {arr(els)}",
        f"local S = {arr(shp)}",
        f"local G = {arr(grd)}",
        f"local H = {arr(hnd)}",
        "local rows = {",
    ]
    for w in data:
        e = 0 if w["element"] == "–" else els.index(w["element"]) + 1
        mv = "" if w["move"] == "–" else w["move"]
        lines.append(
            f'\t{{{lua_str(w["id"])},{lua_str(w["name"])},{lua_str(w["thai"])},{rar.index(w["rarity"]) + 1},{e},{lua_str(mv)},'
            f'{w["basePower"]},{w["speed"]},{w["area"]},{shp.index(w["swordShape"]) + 1},{grd.index(w["guardStyle"]) + 1},{hnd.index(w["handleStyle"]) + 1}}},'
        )
    lines += [
        "}",
        "",
        "local list: { Sword } = {}",
        "local byId: { [string]: Sword } = {}",
        "for _, r in rows do",
        "\tlocal w: Sword = table.freeze({",
        "\t\tid = r[1], name = r[2], thai = r[3], rarity = R[r[4]], element = r[5] > 0 and E[r[5]] or nil,",
        "\t\tmove = r[6] ~= \"\" and r[6] or nil, basePower = r[7], speed = r[8], area = r[9],",
        "\t\tswordShape = S[r[10]], guardStyle = G[r[11]], handleStyle = H[r[12]],",
        "\t}) :: any",
        "\tassert(byId[w.id] == nil, \"duplicate sword id \" .. w.id)",
        "\tbyId[w.id] = w",
        "\ttable.insert(list, w)",
        "end",
        "",
        "return table.freeze({ List = table.freeze(list), ById = table.freeze(byId) })",
        "",
    ]
    (OUT / "SwordPack.luau").write_text("\n".join(lines), encoding="utf-8")
    return data


def legacy_map(legacy, swords):
    """1:1 legacy weapon -> sword. Same rarity, sword basePower >= legacy basePower,
    prefer the same element within +25% power, else the weakest sword that still satisfies power.
    Strongest legacy first: any sword >= p stays valid for every weaker legacy, so this never dead-ends."""
    used, out = set(), {}
    for rarity in ["Common", "Rare", "Epic", "Legendary", "Mythic"]:
        olds = sorted((w for w in legacy if w["rarity"] == rarity), key=lambda w: (-w["basePower"], w["id"]))
        for w in olds:
            pool = [s for s in swords if s["rarity"] == rarity and s["id"] not in used and s["basePower"] >= w["basePower"]]
            same = [s for s in pool if s["element"] == w["element"] and s["basePower"] <= w["basePower"] * 1.25]
            pick = min(same or pool, key=lambda s: (s["basePower"], s["id"]))
            used.add(pick["id"])
            out[w["id"]] = pick
    assert len(out) == len(legacy) and len(set(s["id"] for s in out.values())) == len(legacy)
    return out


def gen_legacy_map(swords):
    legacy = json.loads((ROOT / "data" / "weapons.json").read_text(encoding="utf-8"))
    m = legacy_map(legacy, swords)
    lines = [
        "-- สร้างอัตโนมัติด้วย tools/gen_config.py — ห้ามแก้ไฟล์นี้ด้วยมือ",
        "-- Legacy weapon id (Config.Weapons, wpn_*) -> Sword Pack id. 1:1, same rarity, basePower never lower.",
        "-- Used by DataService MIGRATIONS[2]. Never remove rows: old saves may still hold these ids.",
        "-- Power before/after per row: docs/sword-pack-migration.md",
        "",
        "return table.freeze({",
    ]
    for w in legacy:
        lines.append(f'\t{w["id"]} = {lua_str(m[w["id"]]["id"])},')
    lines += ["})", ""]
    (OUT / "LegacyWeaponMap.luau").write_text("\n".join(lines), encoding="utf-8")
    rep = ["# Sword Pack legacy migration map", "",
           "สร้างอัตโนมัติด้วย `tools/gen_config.py` (กฎ: rarity เดิม, basePower ไม่ลด, ธาตุเดียวกันถ้ามี, 1:1).", "",
           "| Legacy id | Legacy name | Rarity | Power เดิม | → Sword id | Sword name | Power ใหม่ | ธาตุ |", "|---|---|---|---|---|---|---|---|"]
    for w in legacy:
        s = m[w["id"]]
        el = "=" if s["element"] == w["element"] else f'{w["element"]}→{s["element"]}'
        rep.append(f'| {w["id"]} | {w["name"]} | {w["rarity"]} | {w["basePower"]} | {s["id"]} | {s["name"]} | {s["basePower"]} | {el} |')
    (ROOT / "docs" / "sword-pack-migration.md").write_text("\n".join(rep) + "\n", encoding="utf-8")
    return len(m)


if __name__ == "__main__":
    n = gen_weapons()
    print(f"Weapons.luau: {n} weapons")
    swords = gen_swords()
    print(f"SwordPack.luau: {len(swords)} swords")
    print(f"LegacyWeaponMap.luau: {gen_legacy_map(swords)} legacy ids")
