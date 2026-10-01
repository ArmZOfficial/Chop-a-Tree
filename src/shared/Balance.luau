--!strict
-- สูตรตัวเลขทั้งเกม (plan.md หัวข้อ 14) — สูตรเดียวกับ tools/balance_sim.py
-- ทุกระบบต้องคำนวณผ่านโมดูลนี้ ห้ามเขียนสูตรซ้ำที่อื่น
-- แอดมินแก้ค่าสดได้ผ่าน Balance.SetOverride (มีผลเฉพาะเซิร์ฟนั้น)

local Config = require(script.Parent.Config.BalanceConfig)

local Balance = {}

local overrides: { [string]: number } = {}

function Balance.Get(key: string): any
	local v = overrides[key]
	if v ~= nil then
		return v
	end
	return (Config :: any)[key]
end

function Balance.SetOverride(key: string, value: number?)
	assert((Config :: any)[key] ~= nil, "unknown balance key " .. key)
	overrides[key] = value
end

function Balance.ClearOverrides()
	table.clear(overrides)
end

function Balance.Overrides(): { [string]: number }
	return table.clone(overrides)
end

local function G(key: string): number
	return Balance.Get(key) :: number
end

-- ตัวคูณของโซน: 100^(โซน−1)
function Balance.ZoneScale(zone: number): number
	return G("ZoneScale") ^ (zone - 1)
end

-- ราเน่า (Rot Tier) จาก Rebirth: 10^R
function Balance.Rot(rebirth: number): number
	return G("RebirthRot") ^ rebirth
end

function Balance.TreeHP(zone: number, tier: number, rebirth: number?): number
	return Config.TreeHP[tier] * Balance.ZoneScale(zone) * Balance.Rot(rebirth or 0)
end

function Balance.TreeRequiredPower(zone: number, tier: number, rebirth: number?): number
	if tier <= 1 then
		return 0
	end
	return Balance.TreeHP(zone, tier, rebirth) / G("ReqHits")
end

export type Reward = { exp: number, wood: number, coins: number }

function Balance.TreeReward(zone: number, tier: number, rebirth: number?, autoCut: boolean?): Reward
	local hp = Balance.TreeHP(zone, tier, rebirth)
	local mult = if autoCut then G("AutoCutReward") else 1
	return {
		exp = hp * G("ExpRatio") * mult,
		wood = hp * G("WoodRatio") * mult,
		coins = hp * G("CoinRatio") * mult,
	}
end

function Balance.RunMultiplier(level: number): number
	return G("RunMult") ^ level
end

-- EXP ที่ต้องใช้จากเลเวล level → level+1 (สเกลตามโซนที่อยู่)
function Balance.ExpToNext(level: number, zone: number, rebirth: number?): number
	return G("ExpBase") * G("ExpGrowth") ^ level * Balance.ZoneScale(zone) * Balance.Rot(rebirth or 0)
end

export type WeaponRoll = { basePower: number, itemLevel: number, stars: number?, giant: boolean?, rebirthDrop: number? }

-- Power ของอาวุธ 1 ชิ้น (ยังไม่รวมตัวคูณรอบ/สัตว์/Rebirth ของผู้เล่น)
function Balance.WeaponPower(w: WeaponRoll): number
	local p = w.basePower * G("WeaponZoneScale") ^ (w.itemLevel - 1)
	p *= 1 + G("StarBonus") * ((w.stars or 1) - 1)
	if w.giant then
		p *= G("GiantPower")
	end
	return p * Balance.Rot(w.rebirthDrop or 0)
end

-- Cut Power ที่โชว์บน HUD
function Balance.CutPower(weaponPower: number, runLevel: number, petMult: number?, rebirth: number?, other: number?): number
	return weaponPower * Balance.RunMultiplier(runLevel) * (petMult or 1) * G("RebirthPower") ^ (rebirth or 0) * (other or 1)
end

function Balance.FriendBoost(friendsInServer: number): number
	return 1 + math.min(friendsInServer * G("FriendBoostPer"), G("FriendBoostMax"))
end

-- ตรวจว่าสูตรในเกมตรงกับ balance_sim.py (ค่าคาดหวังมาจาก docs/balance_report.txt)
function Balance.SelfTest(): (boolean, string)
	local checks = {
		{ "TreeHP z1 t1", Balance.TreeHP(1, 1), 1e3 },
		{ "TreeHP z8 t6", Balance.TreeHP(8, 6), 3e18 },
		{ "TreeHP z4 t1", Balance.TreeHP(4, 1), 1e9 },
		{ "ReqPower z1 t6", Balance.TreeRequiredPower(1, 6), 3750 },
		{ "ReqPower z3 t1", Balance.TreeRequiredPower(3, 1), 0 },
		{ "WeaponPower Mythic base IL8", Balance.WeaponPower({ basePower = 12500, itemLevel = 8 }), 12500 * 1e14 },
		{ "WeaponPower Rare★2", Balance.WeaponPower({ basePower = 375, itemLevel = 1, stars = 2 }), 562.5 },
		{ "Rot R3", Balance.Rot(3), 1000 },
	}
	local bad = {}
	for _, c in checks do
		local got, want = c[2], c[3]
		if math.abs(got - want) > math.abs(want) * 1e-9 then
			table.insert(bad, string.format("%s: got %g want %g", c[1], got, want))
		end
	end
	if #bad == 0 then
		return true, string.format("Balance OK (%d checks)", #checks)
	end
	return false, table.concat(bad, "; ")
end

return Balance
