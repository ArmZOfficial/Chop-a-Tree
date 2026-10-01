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
	Shop = false, -- Phase 8
	PvP = false, -- Phase 9
})
