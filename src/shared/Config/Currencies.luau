-- สกุลเงินทั้งหมด (plan.md หัวข้อ 4.9) — ลำดับในลิสต์ = ลำดับที่โชว์ใน UI

export type Currency = { id: string, label: string, color: Color3, hud: boolean }

local list: { Currency } = {
	{ id = "Coins", label = "Coins", color = Color3.fromRGB(250, 204, 21), hud = true },
	{ id = "Wood", label = "Wood", color = Color3.fromRGB(161, 98, 7), hud = true },
	{ id = "Gems", label = "Gems", color = Color3.fromRGB(34, 211, 238), hud = true },
	{ id = "ArenaTokens", label = "Arena Tokens", color = Color3.fromRGB(239, 68, 68), hud = false },
	{ id = "Stardust", label = "เศษดาว", color = Color3.fromRGB(192, 132, 252), hud = false },
	{ id = "RebirthTokens", label = "Rebirth Token", color = Color3.fromRGB(74, 222, 128), hud = false },
}

local byId = {}
for _, c in list do
	byId[c.id] = c
end

return table.freeze({ List = list, ById = byId })
