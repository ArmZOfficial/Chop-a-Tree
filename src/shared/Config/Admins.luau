-- ใครเป็นแอดมิน (plan.md หัวข้อ 18.1)
-- ระดับ: Owner > Admin > Moderator > Tester > Player
-- ตรวจ 4 ทาง (ใช้ระดับสูงสุดที่เจอ):
--   1) ใน Roblox Studio ทุกคนเป็น Owner
--   2) เจ้าของเกม (game.CreatorId ถ้าเกมเป็นของผู้ใช้) เป็น Owner
--   3) UserId ในรายชื่อด้านล่าง
--   4) ยศในกลุ่ม Roblox (ใส่ GroupId แล้วตั้งยศขั้นต่ำของแต่ละระดับ)

return table.freeze({
	Levels = table.freeze({ Player = 0, Tester = 1, Moderator = 2, Admin = 3, Owner = 4 }),

	-- ใส่ UserId (ตัวเลข) ของทีมงาน
	Users = table.freeze({
		-- [7488194538] = "Owner",
	}),

	-- 0 = ยังไม่ใช้กลุ่ม
	GroupId = 0,
	GroupRanks = table.freeze({ Owner = 255, Admin = 200, Moderator = 150, Tester = 100 }),

	StudioIsOwner = true,

	-- กันกดรัว: จำนวนคำสั่งสูงสุดต่อวินาทีต่อแอดมิน
	RateLimitPerSecond = 8,
})
