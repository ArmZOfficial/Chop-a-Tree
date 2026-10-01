-- ความหายาก (plan.md หัวข้อ 14.2) — base = Power โซน 1, สุ่ม ×1–×4 ภายในความหายาก

return table.freeze({
	Order = table.freeze({ "Common", "Rare", "Epic", "Legendary", "Mythic" }),
	Base = table.freeze({ Common = 125, Rare = 375, Epic = 1250, Legendary = 4000, Mythic = 12500 }),
	Color = table.freeze({
		Common = Color3.fromRGB(75, 85, 99),
		Rare = Color3.fromRGB(29, 78, 216),
		Epic = Color3.fromRGB(126, 34, 206),
		Legendary = Color3.fromRGB(180, 83, 9),
		Mythic = Color3.fromRGB(185, 28, 28),
	}),
	GiantChance = table.freeze({ Common = 0.005, Rare = 0.01, Epic = 0.02, Legendary = 0.04, Mythic = 0.08 }),
})
