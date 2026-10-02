-- Feature Flags (plan.md หัวข้อ 15.5) — ค่าเริ่มต้นตอนเปิดเซิร์ฟ
-- แอดมินเปิด/ปิดสดได้จากแท็บ Debug (มีผลเฉพาะเซิร์ฟนั้นจนกว่าจะแก้ไฟล์นี้)

return table.freeze({
	AdminPanel = true,
	AutoSave = true,
	Forest = true, -- Phase 2
	FriendBoost = true,
	AutoCut = true,
	Chests = true, -- Phase 3
	Garden = true, -- Phase 4
	Weather = true, -- Phase 4
	Eggs = true, -- Phase 5
	Stealing = true, -- Phase 5
	Story = true, -- Phase 6
	Rebirth = true, -- Phase 8a core
	Daily = true, -- Phase 8b
	Codes = true,
	Leaderboard = true,
	IndexBonuses = true, -- Phase 8c
	Achievements = true,
	LiveEvents = true, -- Phase 8d core
	WeatherEncounters = true, -- Stardust, rare eggs, world boss
	Merchant = true, -- Phase 8d3
	Festivals = true, -- Phase 8e
	Emotes = true, -- Phase 8f emotes + photo mode
	Shop = true, -- Phase 8g Robux shop
	SeasonPass = true, -- Phase 8g Season Pass
	PvP = false, -- Phase 9
	Decor = true, -- base decoration (plan 9.2)
	SwordPack = true, -- Sword Pack 380 chest pool (off = legacy pool; saves resolve both)
	Sprint = true, -- Shift / touch / gamepad sprint (Config.Movement)
	MapSystems = true, -- zone tracking, map UI, rescue, day cycle and Explorer
})
