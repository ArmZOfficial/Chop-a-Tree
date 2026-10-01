-- ตัวเลขสูตรหลัก (plan.md หัวข้อ 14) — ต้องตรงกับ CONFIG ใน tools/balance_sim.py เสมอ
-- แก้ตรงนี้แล้วรัน balance_sim.py ด้วยค่าเดียวกันทุกครั้ง

return table.freeze({
	ZoneScale = 100, -- HP / EXP / รางวัล / Power ขั้นต่ำ ×100 ต่อโซน
	TreeHP = table.freeze({ 1e3, 3e3, 7e3, 12e3, 20e3, 30e3 }), -- โซน 1 ระดับ 1–6
	ExpRatio = 0.5, -- EXP = HP × 0.5
	WoodRatio = 0.25, -- Wood = HP × 0.25
	CoinRatio = 0.1, -- Coins = HP × 0.1
	ReqHits = 8, -- Power ขั้นต่ำ = HP / 8 (ระดับ 1 = 0)
	RunMult = 1.08, -- ตัวคูณรอบ = 1.08^เลเวล
	ExpBase = 2.5e3,
	ExpGrowth = 1.25, -- EXP ต่อเลเวล = 2,500 × 1.25^เลเวล × ZoneScale^(โซน−1) × Rot
	WeaponZoneScale = 100, -- Item Level
	PetZoneScale = 1.2,
	StarBonus = 0.5, -- Power +50% ต่อดาว
	GiantPower = 5,
	CritChance = 0.1,
	CritMult = 10,
	AutoCutReward = 0.55, -- −45%
	RebirthRot = 10, -- HP/รางวัล/Item Level ×10^Rebirth
	RebirthPower = 1.5, -- พลังถาวร ×1.5^Rebirth
	BossHPMult = 200, -- บอสโซน HP = ต้นระดับ 6 × 200 (plan 14.4)
	BossRewardMult = 20, -- รางวัลบอส = รางวัลต้นระดับ 6 × 20
	FriendBoostPer = 0.1,
	FriendBoostMax = 0.5,
})
