"""Chop a Tree — balance simulator.
รันใหม่ทุกครั้งที่เพิ่มโซน/อาวุธ/สัตว์ หรือแก้ตัวเลข: python3 balance_sim.py
ทุกค่าปรับได้ที่ CONFIG ด้านล่าง (ให้ตรงกับ ReplicatedStorage.Config ในเกม)
"""
import math

CONFIG = dict(
    ZONES=8,
    ZONE_SCALE=100,                         # HP / EXP / Wood / Coins / RequiredPower ×100 ต่อโซน
    TREE_HP=[1e3, 3e3, 7e3, 12e3, 20e3, 30e3],  # โซน 1, ระดับ 1–6
    EXP_RATIO=0.5,                          # EXP = HP × 0.5
    REQ_HITS=8,                             # RequiredPower = HP / 8 (เทียบกับ Cut Power ที่รวมตัวคูณรอบแล้ว)
    RUN_MULT=1.08,                          # ตัวคูณรอบ = 1.08^เลเวล
    EXP_BASE=2.5e3, EXP_GROWTH=1.25,        # EXP ต่อเลเวล = 2,500 × 1.25^เลเวล × ZONE_SCALE^(โซน−1)  ← สเกลตามโซนที่อยู่
    WEAPON_ZONE_SCALE=100,                  # อาวุธดรอปจากโซน N แรงขึ้น ×100^(N−1) (Item Level)
    PET_ZONE_SCALE=1.2,                     # บัฟสัตว์ ×1.2 ต่อโซน (สัตว์จากไข่โซนลึกกว่า)
    RARITY_BASE=dict(Common=125, Rare=375, Epic=1.25e3, Legendary=4e3, Mythic=12.5e3),  # ×1 / ×3 / ×10 / ×32 / ×100 (= 1 โซน)
    ROLL_AVG=2.5,                           # Power ภายในความหายากสุ่ม ×1–×4 (เฉลี่ย 2.5)
    CRIT_AVG=1.9,                           # crit 10% × 10 → เฉลี่ย ×1.9
    SPEED=1.0,                              # ครั้ง/วินาที
    MAX_KILLS_PER_SEC=2.0,
    AUTO_CUT_REWARD=0.55,                   # Auto Cut: EXP / Wood / Coins ×0.55 (−45%)
    AUTO_CUT_PACE=1.0,                      # Auto Cut เดินหาต้นไม้เองได้ไวเท่าคนเล่น (ไม่มีโทษแอบแฝง)
    REBIRTH_ROT=10,                         # Rebirth ครั้งที่ R: HP/รางวัล/Item Level ×10^R ("ราเน่าแรงขึ้น")
    BOSS_HP_MULT=200,                       # บอสโซน HP = ต้นระดับ 6 ของโซน × 200 (plan 14.4)
    BOSS_REWARD_MULT=20,                    # รางวัลบอส = รางวัลต้นระดับ 6 × 20
    REBIRTH_POWER=1.5,                      # Rebirth ครั้งที่ R: Cut Power ถาวร ×1.5^R                  # จำกัดตามความหนาแน่นต้นไม้ + เวลาเดิน
)
C = CONFIG
SUFFIX = ["", "K", "M", "B", "T", "Qa", "Qi", "Sx", "Sp", "Oc", "No", "Dc"]


def fmt(n):
    if n < 1000:
        return f"{n:.0f}"
    e = int(math.log10(n) // 3)
    if e >= len(SUFFIX):
        return f"{n:.2e}"
    return f"{n / 10 ** (3 * e):.3g}{SUFFIX[e]}"


def S(z):
    return C["ZONE_SCALE"] ** (z - 1)


def tree(z, t):
    hp = C["TREE_HP"][t] * S(z)
    req = 0 if t == 0 else hp / C["REQ_HITS"]   # ต้นระดับ 1 ฟันได้เสมอทุกโซน
    return hp, hp * C["EXP_RATIO"], req


def weapon(rarity, zone_dropped, stars=1, giant=False):
    p = C["RARITY_BASE"][rarity] * C["ROLL_AVG"] * C["WEAPON_ZONE_SCALE"] ** (zone_dropped - 1)
    p *= 1 + 0.5 * (stars - 1)
    return p * (5 if giant else 1)


def run(z, base_power, area, seconds=600, auto=False, rebirth=0, wood_out=None):
    """จำลอง Run ในโซน z: คืนค่า snapshot ตามเวลา"""
    level, exp, out, wood = 0, 0.0, {}, 0.0
    rot = C["REBIRTH_ROT"] ** rebirth
    base_power = base_power * C["REBIRTH_POWER"] ** rebirth
    reward = C["AUTO_CUT_REWARD"] if auto else 1.0
    pace = C["AUTO_CUT_PACE"] if auto else 1.0
    need = C["EXP_BASE"] * S(z) * rot
    for sec in range(seconds + 1):
        cut = base_power * C["RUN_MULT"] ** level
        tiers = [t for t in range(6) if tree(z, t)[2] * rot <= cut]
        if sec in (0, 60, 300, 600):
            t = tiers[-1] if tiers else None
            hits = math.ceil(tree(z, t)[0] * rot / (cut * C["CRIT_AVG"])) if t is not None else None
            out[sec] = (level, cut, t, hits)
        if not tiers:
            continue
        t = tiers[-1]
        hp, xp, _ = tree(z, t)
        hp, xp = hp * rot, xp * rot
        dmg = cut * C["CRIT_AVG"] * C["SPEED"]
        kills = min(area * min(1.0, dmg / hp), C["MAX_KILLS_PER_SEC"]) * pace
        exp += kills * xp * reward
        wood += kills * hp / 4 * reward
        while exp >= need:
            exp -= need
            level += 1
            need *= C["EXP_GROWTH"]
    if wood_out is not None:
        wood_out.append(wood)
    return out


def main():
    print("=== ค่าต้นไม้ระดับ 1 และ 6 ต่อโซน ===")
    for z in range(1, C["ZONES"] + 1):
        h1, h6 = tree(z, 0)[0], tree(z, 5)[0]
        print(f"โซน {z}: HP {fmt(h1)} – {fmt(h6)}")
    print()
    print("=== จำลอง Run 10 นาที (เลเวลรอบ / Cut Power / ต้นระดับสูงสุดที่ฟันได้ / ฟันกี่ครั้งถึงล้ม) ===")
    profiles = [
        ("เริ่มเกม / เพิ่งเข้าโซน (Legendary จากโซนก่อน)", lambda z: weapon("Legendary", z - 1) if z > 1 else weapon("Common", 1) / C["ROLL_AVG"], 2),
        ("กลางโซน (Rare ★2 ของโซนนี้)", lambda z: weapon("Rare", z, stars=2), 3),
        ("Mythic จากโซนก่อน (เพิ่งเข้าโซน)", lambda z: weapon("Mythic", max(z - 1, 1)), 4),
        ("ใกล้พร้อมไปต่อ (Epic ของโซนนี้)", lambda z: weapon("Epic", z), 3),
        ("แข็งแรง (Legendary ของโซนนี้)", lambda z: weapon("Legendary", z), 4),
    ]
    for name, wfn, area in profiles:
        print(f"\n-- {name} --")
        for z in range(1, C["ZONES"] + 1):
            pets = C["PET_ZONE_SCALE"] ** (z - 1)
            snaps = run(z, wfn(z) * pets, area)
            cells = []
            for sec, (lv, cut, t, hits) in snaps.items():
                tier = f"T{t + 1}" if t is not None else "ฟันไม่ได้"
                cells.append(f"{sec // 60:>2}น. Lv{lv:<3}{fmt(cut):>7} {tier:<9}{'' if hits is None else str(hits) + 'ครั้ง'}")
            print(f"โซน {z}: " + " | ".join(cells))


def compare():
    print()
    print("=== Auto Cut vs เล่นเอง (Run 10 นาที, Rare ★2 ของโซน) ===")
    for z in (1, 4, 8):
        w = weapon("Rare", z, stars=2) * C["PET_ZONE_SCALE"] ** (z - 1)
        wa, wb = [], []
        a = run(z, w, 3, wood_out=wa)[600]
        b = run(z, w, 3, auto=True, wood_out=wb)[600]
        print(f"โซน {z}: เล่นเอง Lv{a[0]} T{a[2] + 1} Wood {fmt(wa[0])} | Auto Cut Lv{b[0]} T{b[2] + 1} Wood {fmt(wb[0])} "
              f"= {wb[0] / wa[0] * 100:.0f}% ของเล่นเอง | หีบ LEVEL ต่างกัน {a[0] - b[0]} เลเวล")
    print()
    print("=== Rebirth (โซน 8, อาวุธ Mythic ★3 Item Level 8) ===")
    pets = C["PET_ZONE_SCALE"] ** 7
    for r in range(0, 5):
        old = run(8, weapon("Mythic", 8, stars=3) * pets, 4, rebirth=r)
        new = run(8, weapon("Mythic", 8, stars=3) * pets * C["REBIRTH_ROT"] ** r, 4, rebirth=r)
        f = lambda s: f"เริ่ม T{'-' if s[0][2] is None else s[0][2] + 1} → 10 นาที T{'-' if s[600][2] is None else s[600][2] + 1}"
        print(f"Rebirth {r}: HP ×{C['REBIRTH_ROT'] ** r:<6} | ของเก่า: {f(old)} | ดรอปใหม่ของวัฏจักรนี้: {f(new)}")


def bosses():
    print()
    print("=== บอสโซน (ตีคนเดียว, อาวุธ Epic ★1 ของโซน, เลเวลรอบ 30) ===")
    for z in range(1, C["ZONES"] + 1):
        hp = tree(z, 5)[0] * C["BOSS_HP_MULT"]
        dps = weapon("Epic", z) * C["RUN_MULT"] ** 30 * C["CRIT_AVG"] * C["SPEED"]
        print(f"โซน {z}: HP {fmt(hp)} | Power ขั้นต่ำ {fmt(tree(z, 5)[2])} | ใช้เวลา ~{hp / dps:.0f} วินาที")


if __name__ == "__main__":
    main()
    compare()
    bosses()
