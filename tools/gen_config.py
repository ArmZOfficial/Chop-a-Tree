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


if __name__ == "__main__":
    n = gen_weapons()
    print(f"Weapons.luau: {n} weapons")
