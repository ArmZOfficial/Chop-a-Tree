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
	Eggs = false, -- Phase 5
	Stealing = false, -- Phase 5
	Story = false, -- Phase 6
	Rebirth = false, -- Phase 8
	Shop = false, -- Phase 8
	PvP = false, -- Phase 9
})
