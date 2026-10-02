return table.freeze({
	Seconds = 1200, -- 20 minutes; visual only. Weather/encounters retain their UTC rules.
	Phases = table.freeze({
		{ id = "morning", clock = 7, ambient = Color3.fromRGB(155, 145, 125), brightness = 2 },
		{ id = "noon", clock = 13, ambient = Color3.fromRGB(170, 170, 170), brightness = 2.5 },
		{ id = "evening", clock = 18, ambient = Color3.fromRGB(145, 115, 140), brightness = 1.5 },
		{ id = "night", clock = 0, ambient = Color3.fromRGB(85, 95, 135), brightness = 1 },
	}),
})
