"""Sword Pack 380 — deterministic generator for data/swords.json.

Run: python3 tools/gen_swords.py  then  python3 tools/gen_config.py
IDs swd_001..swd_380 are stable: never renumber or reorder existing rows.
Power: each rarity spans Base x1 .. x4 (Config/Rarities.Base) linearly.
Names are unique (EN) without numeric suffixes; `thai` is the Thai display name.
"""
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent

RARITY_BASE = {"Common": 125, "Rare": 375, "Epic": 1_250, "Legendary": 4_000, "Mythic": 12_500}
COUNTS = {"Common": 110, "Rare": 95, "Epic": 80, "Legendary": 60, "Mythic": 35}
AREA = {"Common": (4, 7), "Rare": (6, 9), "Epic": (8, 11), "Legendary": (11, 14), "Mythic": (15, 18)}
SPEEDS = [0.8, 0.9, 1.0, 1.1, 1.2, 1.3, 1.4, 1.5, 1.6]

# shape -> [(english noun, thai noun)]
SHAPES = {
    "Longsword": [("Longsword", "ดาบยาว"), ("Broadsword", "ดาบกว้าง"), ("Bastard Sword", "ดาบครึ่งมือ")],
    "Shortsword": [("Shortsword", "ดาบสั้น"), ("Gladius", "กลาดิอุส"), ("Dirk", "กริชยาว")],
    "Sabre": [("Sabre", "เซเบอร์"), ("Scimitar", "ดาบโค้ง"), ("Falchion", "ดาบฟัลเชียน")],
    "Katana": [("Katana", "คาตานะ"), ("Tachi", "ทาจิ"), ("Nodachi", "โนดาจิ")],
    "Greatsword": [("Greatsword", "ดาบใหญ่"), ("Claymore", "เคลย์มอร์"), ("Zweihander", "ดาบสองมือ")],
    "Rapier": [("Rapier", "เรเปียร์"), ("Estoc", "ดาบแทง"), ("Epee", "ดาบเอเป้")],
    "Cleaver": [("Cleaver", "มีดโค่น"), ("Machete", "มีดพร้า"), ("Khopesh", "ดาบเคียว")],
    "Crystal Blade": [("Crystal Blade", "ดาบคริสตัล"), ("Shardblade", "ดาบเศษผลึก"), ("Prism Edge", "คมปริซึม")],
}
SHAPE_ORDER = list(SHAPES)
GUARDS = {  # by rarity tier, chunkier/wilder guards for higher rarity
    "Common": ["Crossguard", "Swept Guard", "Disc Guard"],
    "Rare": ["Crossguard", "Swept Guard", "Disc Guard", "Basket Guard"],
    "Epic": ["Swept Guard", "Basket Guard", "Wing Guard", "Disc Guard"],
    "Legendary": ["Wing Guard", "Claw Guard", "Basket Guard"],
    "Mythic": ["Wing Guard", "Claw Guard"],
}
HANDLES = {
    "Common": ["Leather Grip", "Wire Grip", "Bone Grip"],
    "Rare": ["Leather Grip", "Wire Grip", "Bone Grip"],
    "Epic": ["Wire Grip", "Crystal Grip", "Bone Grip"],
    "Legendary": ["Crystal Grip", "Dragon Grip"],
    "Mythic": ["Dragon Grip", "Crystal Grip"],
}
MATERIALS = [("Rusty", "สนิมเขรอะ"), ("Iron", "เหล็ก"), ("Oak", "ไม้โอ๊ค"), ("Stone", "หิน"), ("Copper", "ทองแดง"),
             ("Bronze", "สำริด"), ("Flint", "หินเหล็กไฟ"), ("Driftwood", "ไม้ลอยน้ำ"), ("Tin", "ดีบุก"), ("Rookie", "มือใหม่")]
# element key (Thai, legacy-compatible) -> adjectives low..high tier
ELEMENTS = {
    "ไฟ": [("Ember", "ถ่านคุ"), ("Blaze", "เปลวเพลิง"), ("Magma", "แมกมา"), ("Inferno", "ไฟนรก"), ("Phoenix", "ฟีนิกซ์"), ("Solar", "สุริยะ")],
    "น้ำ": [("Tidal", "กระแสน้ำ"), ("Frost", "น้ำค้างแข็ง"), ("Coral", "ปะการัง"), ("Glacier", "ธารน้ำแข็ง"), ("Abyssal", "ห้วงลึก"), ("Leviathan", "อสูรทะเล")],
    "สายฟ้า": [("Static", "ไฟฟ้าสถิต"), ("Volt", "โวลต์"), ("Thunder", "ฟ้าร้อง"), ("Storm", "พายุฟ้า"), ("Tempest", "พายุคลั่ง"), ("Thunderking", "ราชาสายฟ้า")],
    "ลม": [("Breeze", "สายลม"), ("Gale", "ลมกรรโชก"), ("Zephyr", "ลมตะวันตก"), ("Cyclone", "ไซโคลน"), ("Skyward", "ทะยานฟ้า"), ("Stormwing", "ปีกพายุ")],
    "เงา": [("Dusk", "สนธยา"), ("Shade", "เงามืด"), ("Phantom", "ภูตผี"), ("Umbral", "เงาทมิฬ"), ("Eclipse", "สุริยุปราคา"), ("Void", "ความว่างเปล่า")],
    "แสง": [("Gleam", "ประกาย"), ("Dawn", "รุ่งอรุณ"), ("Radiant", "เจิดจรัส"), ("Holy", "ศักดิ์สิทธิ์"), ("Seraph", "เทวทูต"), ("Celestial", "สรวงสวรรค์")],
    "ธรรมชาติ": [("Sprout", "ต้นกล้า"), ("Thorn", "หนาม"), ("Bloom", "บุปผา"), ("Verdant", "เขียวขจี"), ("Elder", "พฤกษาโบราณ"), ("Worldroot", "รากโลก")],
    "จักรวาล": [("Comet", "ดาวหาง"), ("Lunar", "จันทรา"), ("Astral", "ดวงดาว"), ("Nebula", "เนบิวลา"), ("Starfall", "ดาวตก"), ("Galaxy", "กาแล็กซี")],
}
ELEMENT_ORDER = list(ELEMENTS)
TIER = {"Common": [0], "Rare": [0, 1], "Epic": [2, 3], "Legendary": [3, 4], "Mythic": [4, 5]}
TITLES = {
    "Legendary": [("Titan", "ไททัน"), ("Dragon", "มังกร"), ("Royal", "ราชันย์"), ("Warlord", "ขุนศึก"), ("Ancient", "ดึกดำบรรพ์")],
    "Mythic": [("Sovereign", "จอมราชันย์"), ("Godslayer", "สังหารเทพ"), ("Primordial", "ปฐมกาล"), ("Worldbreaker", "ทลายโลก"), ("Eternal", "นิรันดร์")],
}
MOVES = ["Burst", "Rend", "Crescent", "Nova", "Cleave", "Requiem", "Judgement", "Cataclysm", "Spiral", "Rampage"]
NO_ELEMENT_COMMONS = 27  # ~25% of Commons are plain material swords


def generate():
    rows, names = [], set()
    gid = 0
    for rarity, count in COUNTS.items():
        base = RARITY_BASE[rarity]
        lo, hi = AREA[rarity]
        for i in range(count):
            gid += 1
            shape = SHAPE_ORDER[(gid - 1) % len(SHAPE_ORDER)]
            guard = GUARDS[rarity][(gid - 1) % len(GUARDS[rarity])]
            handle = HANDLES[rarity][(gid // 3) % len(HANDLES[rarity])]
            plain = rarity == "Common" and i < NO_ELEMENT_COMMONS
            element = None if plain else ELEMENT_ORDER[(i + 3 * list(COUNTS).index(rarity)) % len(ELEMENT_ORDER)]
            name = thai = None
            # Walk noun/adjective/title variants until the English name is unique.
            for attempt in range(200):
                noun, noun_th = SHAPES[shape][(gid // len(SHAPE_ORDER) + attempt) % 3]
                if plain:
                    adj, adj_th = MATERIALS[(i + attempt // 3) % len(MATERIALS)]
                else:
                    tiers = TIER[rarity]
                    adj, adj_th = ELEMENTS[element][tiers[(i + attempt // 3) % len(tiers)]]
                title = TITLES.get(rarity)
                if title:
                    t, t_th = title[(i + attempt // 6) % len(title)]
                    cand, cand_th = f"{t} {adj} {noun}", f"{noun_th}{adj_th}{t_th}"
                else:
                    cand, cand_th = f"{adj} {noun}", f"{noun_th}{adj_th}"
                if cand not in names:
                    name, thai, move_adj = cand, cand_th, adj
                    break
                if attempt % 3 == 2 and not plain:  # also rotate element when a tier is exhausted
                    element = ELEMENT_ORDER[(ELEMENT_ORDER.index(element) + 1) % len(ELEMENT_ORDER)]
            assert name, f"no unique name for {gid}"
            names.add(name)
            move = None if plain else f"{move_adj} {MOVES[(gid - 1) % len(MOVES)]}"
            power = int(base + i * (base * 4 - base) / (count - 1))
            rows.append({
                "id": f"swd_{gid:03d}", "name": name, "thai": thai, "rarity": rarity,
                "element": element or "–", "move": move or "–", "basePower": power,
                "speed": SPEEDS[i % len(SPEEDS)], "area": lo + i % (hi - lo + 1),
                "swordShape": shape, "guardStyle": guard, "handleStyle": handle,
            })
    assert len(rows) == 380 and len({r["id"] for r in rows}) == 380 and len(names) == 380
    return rows


if __name__ == "__main__":
    rows = generate()
    out = ROOT / "data" / "swords.json"
    out.write_text(json.dumps(rows, ensure_ascii=False, indent=1) + "\n", encoding="utf-8")
    print(f"{out.relative_to(ROOT)}: {len(rows)} swords")
