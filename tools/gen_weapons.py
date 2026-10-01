import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent  # รันจากที่ไหนก็ได้ เขียนไฟล์ลง docs/ และ data/

random.seed(11)

# Fantasy weapon categories: (english, thai)
TYPES = [
    ("Greatsword", "ดาบใหญ่"), ("Warhammer", "ค้อนศึก"), ("Battleaxe", "ขวานศึก"), ("Scythe", "เคียว"),
    ("Lance", "ทวนอัศวิน"), ("Halberd", "ง้าวยุโรป"), ("Staff", "คทาเวท"), ("Wand", "ไม้กายสิทธิ์"),
    ("Grimoire", "คัมภีร์เวท"), ("Gauntlets", "สนับมือ"), ("Chakram", "จักรวงแหวน"), ("Longbow", "ธนูยาว"),
    ("Whip", "แส้"), ("Trident", "สามง่าม"), ("Chainsaw", "เลื่อยยนต์"), ("Drill", "สว่านยักษ์"),
    ("Lantern", "ตะเกียงวิญญาณ"), ("Guitar", "กีตาร์ไฟฟ้า"), ("Umbrella", "ร่มดาบ"), ("War Fan", "พัดศึก"),
    ("Anchor", "สมอเรือ"), ("Mace", "กระบอง"), ("Flail", "ลูกตุ้มโซ่"), ("Boomerang", "บูมเมอแรง"),
    ("Banner", "ธงศึก"), ("Bell", "ระฆัง"), ("Arm Cannon", "ปืนใหญ่แขน"), ("Orb", "ลูกแก้วเวท"),
    ("Pickaxe", "จอบขุด"), ("Lollipop", "อมยิ้มยักษ์"), ("Frying Pan", "กระทะ"), ("Bone Club", "กระบองกระดูก"),
]

NEUTRAL = [("Rusty", "สนิมเขรอะ"), ("Iron", "เหล็ก"), ("Oak", "ไม้โอ๊ค"), ("Stone", "หิน"),
           ("Old", "เก่าแก่"), ("Rookie", "มือใหม่"), ("Copper", "ทองแดง"), ("Bent", "บิดเบี้ยว")]

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
TITLES = {
    "Legendary": [("Titan", "ไททัน"), ("Dragon", "มังกร"), ("King's", "ของราชา"), ("Warlord", "ขุนศึก")],
    "Mythic": [("Sovereign", "จอมราชันย์"), ("Godslayer", "สังหารเทพ"), ("Primordial", "ปฐมกาล"), ("Worldbreaker", "ทลายโลก"), ("Eternal", "นิรันดร์")],
}
MOVES = ["Burst", "Rend", "Crescent", "Nova", "Cleave", "Requiem", "Judgement", "Cataclysm", "Spiral", "Rampage"]

RARITY_BASE = {"Common": 125, "Rare": 375, "Epic": 1_250, "Legendary": 4_000, "Mythic": 12_500}  # Power โซน 1 (ตรงกับ balance_sim.py)
COUNTS = {"Common": 30, "Rare": 25, "Epic": 20, "Legendary": 15, "Mythic": 10}
PREFIX_TIER = {"Rare": slice(0, 2), "Epic": slice(2, 4), "Legendary": slice(3, 5), "Mythic": slice(4, 6)}
AREA = {"Common": 4, "Rare": 6, "Epic": 8, "Legendary": 11, "Mythic": 15}

# Japanese-style blades from the earlier draft (kept)
FIXED = {
    "Common": [("Keiko Bokutō 稽古木刀", "ดาบไม้ฝึกหัด", "–", "–"), ("Kurogane Ono 黒鉄斧", "ขวานเหล็กดำ", "–", "–")],
    "Rare": [("Ginrei 銀嶺", "คาตานะยอดเขาเงิน", "น้ำ", "Hyōga Issen 氷河一閃"),
             ("Hibana-maru 火花丸", "คาตานะประกายไฟ", "ไฟ", "Hibana Renzan 火花連斬"),
             ("Ikazuchi-zume 雷爪", "กรงเล็บสายฟ้า", "สายฟ้า", "Shiden Rengeki 紫電連撃")],
    "Epic": [("Tsukikage Ōgama 月影大鎌", "เคียวยักษ์เงาจันทร์", "เงา", "Gekkō Rinbu 月光輪舞"),
             ("Mizuchi Sōken 蛟双剣", "ดาบคู่มังกรน้ำ", "น้ำ", "Uzushio Ranbu 渦潮乱舞")],
    "Legendary": [("Arashigami 嵐神", "คาตานะเทพวายุ", "ลม", "Shippū Jinrai 疾風迅雷"),
                  ("Raitei no Hoko 雷帝の鉾", "ทวนจักรพรรดิสายฟ้า", "สายฟ้า", "Raitei Kōrin 雷帝降臨")],
    "Mythic": [("Shuryū-tō 朱龍刀", "ดาบมังกรสีชาด", "ไฟ", "Ryūen Tenmetsu 龍炎天滅"),
               ("Shūen no Hoko 終焉の鉾", "หอกแห่งจุดจบ", "เงา", "Mugen Shūen 無限終焉")],
}

def fmt(n):
    for s, v in [("Sp", 1e24), ("Sx", 1e21), ("Qi", 1e18), ("Qa", 1e15), ("T", 1e12), ("B", 1e9), ("M", 1e6), ("K", 1e3)]:
        if n >= v:
            return f"{n / v:.2f}".rstrip("0").rstrip(".") + s
    return str(int(n))

used_names, rows, power_raw = set(), [], {}
elems = list(ELEMENTS)
type_pool = TYPES[:]

for rarity in COUNTS:
    items = list(FIXED[rarity])
    used_types = set()
    ei = random.randrange(8)
    while len(items) < COUNTS[rarity]:
        # spread weapon categories: prefer types not yet used in this tier
        choices = [t for t in TYPES if t[0] not in used_types] or TYPES
        tname, tthai = random.choice(choices)
        if rarity == "Common":
            p, pth = random.choice(NEUTRAL)
            name, thai, el, move = f"{p} {tname}", f"{tthai}{pth}", "–", "–"
        else:
            el = elems[ei % 8]; ei += 1
            p, pth = random.choice(ELEMENTS[el][PREFIX_TIER[rarity]])
            if rarity in TITLES:
                ti, tith = random.choice(TITLES[rarity])
                name, thai = f"{p} {ti} {tname}", f"{tthai}{tith}แห่ง{pth}"
            else:
                name, thai = f"{p} {tname}", f"{tthai}{pth}"
            move = f"{p} {random.choice(MOVES)}"
        if name in used_names:
            continue
        used_names.add(name); used_types.add(tname)
        items.append((name, thai, el, move))
    n = len(items)
    random.shuffle(items)
    for i, (name, thai, el, move) in enumerate(items):
        power = RARITY_BASE[rarity] * (1 + 3 * i / (n - 1))
        power_raw[(rarity, name)] = round(power)
        rows.append((rarity, name, thai, el, move, fmt(round(power)),
                     round(random.uniform(0.8, 1.6), 1), AREA[rarity] + random.randint(0, 3)))

out = ["# รายชื่ออาวุธ 100 ชิ้น (ร่าง)", "",
       "> อาวุธแฟนตาซีไม่จำกัดประเภท ฟีลอนิเมะ ชื่อและดีไซน์คิดเองทั้งหมด — เปลี่ยน/ตัด/เพิ่มได้",
       "> Power = ค่าพื้นฐานที่ **Item Level 1 (ดรอปจากโซน 1)** — ดรอปจากโซน N ได้ Power × 100^(N−1) (ดู plan.md หัวข้อ 14)",
       "> Speed = ครั้ง/วินาที | Area = รัศมีฟัน (studs) | ID = รหัสถาวรในระบบเซฟ ห้ามเปลี่ยน",
       "> ทุกชิ้นมีโอกาสออกเป็นร่างยักษ์ (Giant) ตาม plan.md หัวข้อ 4.5", "",
       "## สรุป", "", "| ความหายาก | จำนวน | Power (โซน 1) | Power (ดรอปจากโซน 8) |", "|---|---|---|---|"]
for r in COUNTS:
    out.append(f"| {r} | {COUNTS[r]} | {fmt(RARITY_BASE[r])} – {fmt(4 * RARITY_BASE[r])} | {fmt(RARITY_BASE[r] * 100**7)} – {fmt(4 * RARITY_BASE[r] * 100**7)} |")
out += ["", "ธาตุ: ไฟ, น้ำ, สายฟ้า, ลม, เงา, แสง, ธรรมชาติ, จักรวาล (Common ไม่มีธาตุ)"]
cur, idx, data = None, 0, []
import re, unicodedata
def slug(n):
    n = unicodedata.normalize("NFKD", n.split(" ")[0] if not n.isascii() and False else n)
    n = "".join(ch for ch in n if ch.isascii())
    return "wpn_" + re.sub(r"[^a-z0-9]+", "_", n.lower()).strip("_")
for rarity, name, thai, el, move, pw, sp, ar in rows:
    wid = slug(name)
    if rarity != cur:
        cur = rarity
        out += ["", f"## {rarity}", "", "| # | ID | ชื่อ | ความหมาย / ประเภท | ธาตุ | ชื่อท่า | Power | Speed | Area |",
                "|---|---|---|---|---|---|---|---|---|"]
    idx += 1
    out.append(f"| {idx} | `{wid}` | {name} | {thai} | {el} | {move} | {pw} | {sp} | {ar} |")
    data.append(dict(id=wid, name=name, thai=thai, rarity=rarity, element=el, move=move,
                     basePower=power_raw[(rarity, name)], speed=sp, area=ar))
open(ROOT / "docs" / "weapons.md", "w", encoding="utf-8").write("\n".join(out) + "\n")
import json
json.dump(data, open(ROOT / "data" / "weapons.json", "w", encoding="utf-8"), ensure_ascii=False, indent=1)
print(idx, len({r[1] for r in rows}))
