"""Sword Pack data + legacy map checks. Run: python3 -m unittest tools/tests/test_sword_pack.py"""
import json, re, sys, unittest
from collections import Counter
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "tools"))
import gen_config  # noqa: E402

BASE = {"Common": 125, "Rare": 375, "Epic": 1250, "Legendary": 4000, "Mythic": 12500}


class SwordPack(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.swords = json.loads((ROOT / "data/swords.json").read_text(encoding="utf-8"))
        cls.legacy = json.loads((ROOT / "data/weapons.json").read_text(encoding="utf-8"))
        cls.map = gen_config.legacy_map(cls.legacy, cls.swords)

    def test_ids_counts_names(self):
        ids = [s["id"] for s in self.swords]
        self.assertEqual(ids, [f"swd_{i:03d}" for i in range(1, 381)])
        self.assertEqual(Counter(s["rarity"] for s in self.swords), Counter(Common=110, Rare=95, Epic=80, Legendary=60, Mythic=35))
        self.assertEqual(len({s["name"] for s in self.swords}), 380)
        for s in self.swords:
            self.assertFalse(re.search(r"\d", s["name"]), s["name"])
            self.assertTrue(s["thai"])
            self.assertTrue(BASE[s["rarity"]] <= s["basePower"] <= BASE[s["rarity"]] * 4, s["id"])

    def test_no_clash_with_legacy(self):
        self.assertFalse({s["id"] for s in self.swords} & {w["id"] for w in self.legacy})
        self.assertFalse({s["name"] for s in self.swords} & {w["name"] for w in self.legacy})

    def test_map_is_lossless(self):
        self.assertEqual(set(self.map), {w["id"] for w in self.legacy})
        self.assertEqual(len({s["id"] for s in self.map.values()}), len(self.legacy), "must be 1:1")
        for w in self.legacy:
            s = self.map[w["id"]]
            self.assertEqual(s["rarity"], w["rarity"], w["id"])
            self.assertGreaterEqual(s["basePower"], w["basePower"], w["id"])

    def test_generated_luau_matches(self):
        lua = (ROOT / "src/shared/Config/LegacyWeaponMap.luau").read_text(encoding="utf-8")
        pairs = dict(re.findall(r'^\t(wpn_[a-z0-9_]+) = "(swd_\d{3})",$', lua, re.M))
        self.assertEqual(pairs, {k: v["id"] for k, v in self.map.items()})
        pack = (ROOT / "src/shared/Config/SwordPack.luau").read_text(encoding="utf-8")
        self.assertEqual(len(re.findall(r'^\t\{"swd_\d{3}"', pack, re.M)), 380)


if __name__ == "__main__":
    unittest.main()
