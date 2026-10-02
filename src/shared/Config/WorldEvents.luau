-- Weather events use the existing scheduler/encounter owners; local tree events never override weather.
local list = {
	{ id = "GoldenTree", name = "Golden Tree", duration = 120, weight = 1, tree = "GoldenTree" },
	{ id = "TimberRush", name = "Timber Rush", duration = 90, weight = 1, wood = 2 },
	{ id = "Meteor", name = "Meteor Shower", weather = "Meteor", zone = 1 },
	{ id = "BossTree", name = "Boss Tree", weather = "RotInvasion", zone = 1 },
	{ id = "Fog", name = "Night Spirits", weather = "Fog", zone = 1 },
}
local byId = {}; for _, def in list do byId[def.id] = def end
return table.freeze({ List = list, ById = byId, Cooldown = 600, MinPlayers = 1, MaxConcurrent = 1,
	SpecialTrees = table.freeze({
		GoldenTree = { hp = 1, wood = 2, scale = 1, color = Color3.fromRGB(255,210,70) },
		-- Opt-in QA variants: no extra Coins/EXP; Wood bonus is within the existing x4 cap.
		GiantTree = { hp = 4, wood = 2, scale = 1.5, shared = true },
		AncientTree = { hp = 2, wood = 2, scale = 1, color = Color3.fromRGB(80,160,110), shared = true },
		CursedTree = { hp = 2, wood = 2, scale = 1, color = Color3.fromRGB(135,70,170), shared = true },
	}),
})
