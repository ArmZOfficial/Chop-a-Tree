-- แท็บของ Admin Panel (plan.md หัวข้อ 18.3) — phase = Phase ที่ระบบนั้นจะมา
-- แท็บที่ยังไม่มีคำสั่งลงทะเบียน จะโชว์ "มาใน Phase X"

return table.freeze({
	{ id = "quick", label = "Shortcuts", color = Color3.fromRGB(250, 204, 21), phase = 0 },
	{ id = "player", label = "Player", color = Color3.fromRGB(56, 189, 248), phase = 0 },
	{ id = "money", label = "Currency & Stats", color = Color3.fromRGB(250, 204, 21), phase = 0 },
	{ id = "weapons", label = "Weapons", color = Color3.fromRGB(248, 113, 113), phase = 3 },
	{ id = "chests", label = "Chests", color = Color3.fromRGB(251, 146, 60), phase = 3 },
	{ id = "pets", label = "Eggs & Pets", color = Color3.fromRGB(244, 114, 182), phase = 5 },
	{ id = "garden", label = "Garden", color = Color3.fromRGB(74, 222, 128), phase = 4 },
	{ id = "forest", label = "Forest & Run", color = Color3.fromRGB(34, 197, 94), phase = 2 },
	{ id = "story", label = "Zones & Story", color = Color3.fromRGB(167, 139, 250), phase = 6 },
	{ id = "weather", label = "Weather & Events", color = Color3.fromRGB(96, 165, 250), phase = 4 },
	{ id = "rebirth", label = "Rebirth", color = Color3.fromRGB(192, 132, 252), phase = 8 },
	{ id = "shop", label = "Shop (Testing)", color = Color3.fromRGB(253, 224, 71), phase = 8 },
	{ id = "pvp", label = "PvP", color = Color3.fromRGB(239, 68, 68), phase = 9 },
	{ id = "balance", label = "Balance Live", color = Color3.fromRGB(45, 212, 191), phase = 2 },
	{ id = "data", label = "Save Data", color = Color3.fromRGB(148, 163, 184), phase = 0 },
	{ id = "mod", label = "Manage Players", color = Color3.fromRGB(249, 115, 22), phase = 0 },
	{ id = "debug", label = "Debug", color = Color3.fromRGB(163, 163, 163), phase = 0 },
})
