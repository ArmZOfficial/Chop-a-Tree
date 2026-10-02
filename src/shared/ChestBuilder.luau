--!strict
-- Retro fantasy chests, 5 levels (Common → Mythic), cosmetic only (master prompt §9.7-F).
-- One builder for the Chest Altar, inventory icons (ChestIconRenderer), the opening stage and
-- admin preview. Plastic + studs, flat colours, Neon for accents only. All parts anchored,
-- CanCollide off. Model layout:
--   Chest_L<n>            WorldPivot = ground centre, front = -Z
--     Body, Feet, Bands… base parts
--     Lid (Model)         PrimaryPart "Hinge" on the back top edge — ChestBuilder.SetLid opens it
--     FX (Model)          floating/glow decoration for idle animation (attribute Float = true)
-- Part budgets (no particles): Common ≤25, Rare ≤35, Epic ≤45, Legendary ≤60, Mythic ≤80.

local ChestBuilder = {}

local function rgb(r: number, g: number, b: number): Color3
	return Color3.fromRGB(r, g, b)
end

ChestBuilder.Levels = table.freeze({
	{ rarity = "Common", name = "Mossy Oak Chest", glow = rgb(170, 220, 110), budget = 25 },
	{ rarity = "Rare", name = "Runed Iron Chest", glow = rgb(80, 220, 255), budget = 35 },
	{ rarity = "Epic", name = "Gilded Gem Chest", glow = rgb(200, 120, 255), budget = 45 },
	{ rarity = "Legendary", name = "Crystal Dragon Chest", glow = rgb(255, 140, 40), budget = 60 },
	{ rarity = "Mythic", name = "Celestial Throne Chest", glow = rgb(255, 80, 230), budget = 80 },
})

local ORDER = { Common = 1, Rare = 2, Epic = 3, Legendary = 4, Mythic = 5 }
function ChestBuilder.LevelOf(rarity: string): number
	return ORDER[rarity] or 1
end

local SCALE = { 1, 1.1, 1.2, 1.35, 1.5 }
local OPEN_ANGLE = math.rad(110)

type Opts = { [string]: any }

local function part(parent: Instance, name: string, size: Vector3, cf: CFrame, color: Color3, opts: Opts?): BasePart
	local p = Instance.new("Part")
	p.Name = name
	p.Anchored = true
	p.CanCollide = false
	p.CanTouch = false
	p.Material = Enum.Material.Plastic
	p.TopSurface = Enum.SurfaceType.Studs
	p.BottomSurface = Enum.SurfaceType.Inlet
	p.Size = size
	p.CFrame = cf
	p.Color = color
	if opts then
		for k, v in opts do
			(p :: any)[k] = v
		end
	end
	p.Parent = parent
	return p
end

local NEON = { Material = Enum.Material.Neon }

-- Palette per level: body, trim (bands/rim), feet, lock, lid.
local PALETTE = {
	{ body = rgb(124, 92, 70), trim = rgb(99, 95, 98), feet = rgb(105, 64, 40), lock = rgb(190, 104, 60), lid = rgb(105, 64, 40) },
	{ body = rgb(70, 50, 40), trim = rgb(99, 95, 98), feet = rgb(60, 60, 66), lock = rgb(13, 105, 172), lid = rgb(70, 50, 40) },
	{ body = rgb(226, 178, 60), trim = rgb(170, 120, 30), feet = rgb(170, 120, 30), lock = rgb(98, 37, 209), lid = rgb(240, 196, 80) },
	{ body = rgb(255, 120, 40), trim = rgb(226, 178, 60), feet = rgb(27, 27, 32), lock = rgb(226, 178, 60), lid = rgb(196, 40, 28) },
	{ body = rgb(150, 220, 255), trim = rgb(226, 178, 60), feet = rgb(17, 17, 17), lock = rgb(255, 255, 255), lid = rgb(255, 120, 230) },
}

-- Builds chest `level` (1–5). Optional cframe places the ground centre.
function ChestBuilder.Build(level: number, cframe: CFrame?): Model
	level = math.clamp(math.floor(level), 1, 5)
	local k = SCALE[level]
	local pal = PALETTE[level]
	local model = Instance.new("Model")
	model.Name = "Chest_L" .. level
	model:SetAttribute("Level", level)
	model:SetAttribute("Rarity", ChestBuilder.Levels[level].rarity)
	local lid = Instance.new("Model")
	lid.Name = "Lid"
	lid.Parent = model
	local fx = Instance.new("Model")
	fx.Name = "FX"
	fx.Parent = model

	-- Pedestal height: Rare stands on a stone disk, Mythic floats above its dais.
	local lift = level == 2 and 1 or (level == 5 and 3.5 or 0)
	-- Local builder: positions/sizes in chest units, scaled by k and lifted.
	local function at(x: number, y: number, z: number): CFrame
		return CFrame.new(x * k, (y + lift) * k, z * k)
	end
	local function S(x: number, y: number, z: number): Vector3
		return Vector3.new(x * k, y * k, z * k)
	end
	local function add(parent: Instance, name: string, size: Vector3, cf: CFrame, color: Color3, opts: Opts?): BasePart
		return part(parent, name, size, cf, color, opts)
	end

	-- Base (10 parts): feet ×4, body, rim, bands ×2, lock plate + keyhole.
	for _, o in { { -2.5, -1.7 }, { 2.5, -1.7 }, { -2.5, 1.7 }, { 2.5, 1.7 } } do
		add(model, "Foot", S(0.9, 0.8, 0.9), at(o[1], 0.4, o[2]), pal.feet)
	end
	local bodyOpts: Opts? = nil
	if level == 4 or level == 5 then
		bodyOpts = { Material = Enum.Material.Glass, Transparency = 0.15 }
	end
	local body = add(model, "Body", S(6, 3.2, 4.4), at(0, 2.4, 0), pal.body, bodyOpts)
	if level == 5 then
		body:SetAttribute("Hue", true) -- idle animator cycles the hue
	end
	add(model, "Rim", S(6.3, 0.4, 4.7), at(0, 3.9, 0), pal.trim)
	for _, x in { -1.8, 1.8 } do
		add(model, "Band", S(0.5, 3.4, 4.6), at(x, 2.4, 0), pal.trim)
	end
	add(model, "Lock", S(1.2, 1.4, 0.3), at(0, 3.2, -2.3), pal.lock, level >= 2 and NEON or nil)
	add(model, "Keyhole", S(0.3, 0.6, 0.1), at(0, 3.1, -2.47), rgb(17, 17, 17))

	-- Lid (6 parts): hinge on the back top edge + stepped arch + bands.
	local hinge = add(lid, "Hinge", S(6, 0.2, 0.2), at(0, 4.1, 2.2), pal.trim, { Transparency = 1 })
	add(lid, "LidBase", S(6, 1, 4.4), at(0, 4.6, 0), pal.lid)
	add(lid, "LidMid", S(5.6, 0.8, 3.6), at(0, 5.5, 0), pal.lid)
	add(lid, "LidCap", S(5.2, 0.5, 2.4), at(0, 6.1, 0), pal.lid)
	for _, x in { -1.8, 1.8 } do
		add(lid, "LidBand", S(0.55, 2.2, 4.6), at(x, 5.1, 0), pal.trim)
	end
	lid.PrimaryPart = hinge

	if level == 1 then
		-- Mossy Oak: moss, vines, two fireflies (7).
		local moss = rgb(124, 156, 107)
		add(lid, "Moss", S(2.4, 0.3, 1.8), at(-1.2, 6.4, 0.3), moss)
		add(lid, "Moss", S(1.6, 0.3, 1.2), at(1.6, 5.95, -0.9), moss)
		add(model, "Moss", S(1.4, 0.8, 0.3), at(2.4, 1.6, -2.25), moss)
		for _, x in { -2.7, 2.2 } do
			add(model, "Vine", S(0.25, 2.6, 0.25), at(x, 2.3, -2.3), rgb(75, 151, 75))
		end
		for _, o in { { -4, 4.5, -1 }, { 4, 5.5, 1 } } do
			local fly = add(fx, "Firefly", S(0.35, 0.35, 0.35), at(o[1], o[2], o[3]), rgb(255, 240, 120), NEON)
			fly.Shape = Enum.PartType.Ball
			fly:SetAttribute("Float", true)
		end
	elseif level == 2 then
		-- Runed Iron: nail heads, runes, stone pedestal + rune ring, four floating chains (12).
		for _, o in { { -2.6, 3.5 }, { 2.6, 3.5 }, { -2.6, 1.2 }, { 2.6, 1.2 } } do
			local nail = add(model, "Nail", S(0.6, 0.6, 0.6), at(o[1], o[2], -2.25), rgb(163, 162, 165))
			nail.Shape = Enum.PartType.Ball
		end
		add(lid, "Rune", S(3.2, 0.15, 0.5), at(0, 6.4, 0), rgb(0, 255, 255), NEON)
		add(model, "Rune", S(2.6, 0.4, 0.1), at(0, 1.4, -2.25), rgb(0, 255, 255), NEON)
		local stone = add(model, "Pedestal", S(1, 9, 9), CFrame.new(0, 0.5 * k, 0) * CFrame.Angles(0, 0, math.rad(90)), rgb(99, 95, 98))
		stone.Shape = Enum.PartType.Cylinder
		local ring = add(fx, "RuneRing", S(0.15, 9.8, 9.8), CFrame.new(0, 1.05 * k, 0) * CFrame.Angles(0, 0, math.rad(90)), rgb(0, 200, 255), { Material = Enum.Material.Neon, Transparency = 0.55 })
		ring.Shape = Enum.PartType.Cylinder
		ring:SetAttribute("Spin", 0.3)
		for i = 1, 4 do
			local a = (i - 0.5) * math.pi / 2
			local chain = add(fx, "Chain", S(0.35, 3.2, 0.35), at(math.cos(a) * 4.4, 4.2, math.sin(a) * 3.6) * CFrame.Angles(0.5, a, 0.4), rgb(91, 93, 105))
			chain:SetAttribute("Float", true)
		end
	elseif level == 3 then
		-- Gilded Gem: five gems, wings, crown spikes, velvet, two counter-rotating rings (14).
		local purple = rgb(98, 37, 209)
		add(lid, "Gem", S(1, 1, 1), at(0, 6.55, 0) * CFrame.Angles(0, math.rad(45), 0), purple, NEON)
		for _, o in { { 0, -2.3, 0 }, { 0, 2.3, 0 }, { -3.05, 0, 90 }, { 3.05, 0, 90 } } do
			add(model, "Gem", S(0.8, 0.8, 0.3), at(o[1], 2.1, o[2]) * CFrame.Angles(0, math.rad(o[3]), math.rad(45)), purple, NEON)
		end
		for _, s in { -1, 1 } do
			add(model, "Wing", S(0.3, 2.4, 3.6), at(s * 3.6, 3.4, 0.4) * CFrame.Angles(0, 0, s * math.rad(-25)), pal.trim)
		end
		for _, o in { { -2.8, -2 }, { 2.8, -2 }, { -2.8, 2 }, { 2.8, 2 } } do
			add(lid, "Spike", S(0.4, 0.9, 0.4), at(o[1], 5.4, o[2]) * CFrame.Angles(0, math.rad(45), 0), pal.trim)
		end
		add(model, "Velvet", S(5.4, 0.2, 3.8), at(0, 3.95, 0), rgb(196, 40, 28))
		for i, d in { 10, 12 } do
			local ring = add(fx, "GoldRing", S(0.2, d, d), at(0, 2.6 + i, 0) * CFrame.Angles(0, 0, math.rad(90)) * CFrame.Angles(i * 0.3, 0, 0), rgb(245, 205, 48), { Material = Enum.Material.Neon, Transparency = 0.6 })
			ring.Shape = Enum.PartType.Cylinder
			ring:SetAttribute("Spin", i == 1 and 0.6 or -0.6)
		end
	elseif level == 4 then
		-- Crystal Dragon: crystal panels, dragon head with horns, tail, layered wings, flames, orbiting shards (21).
		local crimson = rgb(196, 40, 28)
		for _, x in { -3.05, 3.05 } do
			add(model, "Crystal", S(0.2, 2.4, 3.4), at(x, 2.4, 0), rgb(255, 150, 60), NEON)
		end
		add(model, "DragonHead", S(2.2, 1.8, 1.6), at(0, 3.3, -3), pal.trim)
		add(model, "Snout", S(1.4, 0.9, 1.2), at(0, 2.9, -4.1), pal.trim)
		for _, s in { -1, 1 } do
			add(model, "Horn", S(0.3, 1.3, 0.3), at(s * 0.8, 4.5, -2.9) * CFrame.Angles(0.5, 0, s * 0.4), rgb(27, 27, 32))
			add(model, "Tail", S(0.7, 0.7, 4.8), at(s * 3.3, 0.5, 0.3) * CFrame.Angles(0, s * 0.15, 0), pal.trim)
			add(model, "Wing", S(0.3, 3, 4), at(s * 3.9, 4.6, 1) * CFrame.Angles(0.3, 0, s * math.rad(-30)), crimson)
			add(model, "WingTip", S(0.3, 2, 3), at(s * 5, 6.4, 1.6) * CFrame.Angles(0.3, 0, s * math.rad(-45)), pal.trim)
			local flame = add(fx, "Flame", S(0.8, 1.6, 0.8), at(s * 5.5, 3, -1.5) * CFrame.Angles(0, math.rad(45), 0), rgb(255, 120, 0), NEON)
			flame:SetAttribute("Float", true)
		end
		for i = 1, 7 do
			local a = i / 7 * math.pi * 2
			local shard = add(fx, "Shard", S(0.5, 1.2, 0.5), at(math.cos(a) * 5.5, 5 + (i % 2) * 1.2, math.sin(a) * 5.5) * CFrame.Angles(0.4, a, 0.3), rgb(255, 150, 60), NEON)
			shard:SetAttribute("Orbit", true)
		end
	else
		-- Celestial Throne: floating dais, 4 pillars, triple halo, cosmic eye, constellation, lightning, light stairs (45).
		local dais = add(model, "Dais", S(1.2, 11, 11), CFrame.new(0, 0.6 * k, 0) * CFrame.Angles(0, 0, math.rad(90)), rgb(17, 17, 17))
		dais.Shape = Enum.PartType.Cylinder
		local daisRim = add(model, "DaisRim", S(0.3, 11.6, 11.6), CFrame.new(0, 1.1 * k, 0) * CFrame.Angles(0, 0, math.rad(90)), pal.trim, NEON)
		daisRim.Shape = Enum.PartType.Cylinder
		for _, o in { { -4.3, -4.3 }, { 4.3, -4.3 }, { -4.3, 4.3 }, { 4.3, 4.3 } } do
			add(model, "Pillar", S(0.9, 7, 0.9), CFrame.new(o[1] * k, 4.7 * k, o[2] * k), rgb(248, 248, 248))
			add(model, "PillarCap", S(1.3, 0.6, 1.3), CFrame.new(o[1] * k, 8.5 * k, o[2] * k), pal.trim, NEON)
		end
		local haloColors = { rgb(255, 0, 191), rgb(0, 140, 255), rgb(255, 255, 255) }
		for ring = 1, 3 do
			local r = 3.4 + ring * 0.9
			for i = 1, 6 do
				local a = i / 6 * math.pi * 2 + ring * 0.4
				local seg = add(fx, "Halo" .. ring, S(1.6, 0.3, 0.4), at(math.cos(a) * r, 8 + ring * 0.8, math.sin(a) * r) * CFrame.Angles(0, -a + math.pi / 2, 0), haloColors[ring], NEON)
				seg:SetAttribute("Spin", ring % 2 == 0 and -0.4 or 0.4)
			end
		end
		local eye = add(lid, "Eye", S(1.3, 1.3, 1.3), at(0, 6.3, -0.6), rgb(255, 255, 255), NEON)
		eye.Shape = Enum.PartType.Ball
		local pupil = add(lid, "Pupil", S(0.6, 0.6, 0.6), at(0, 6.35, -1.2), rgb(17, 17, 17))
		pupil.Shape = Enum.PartType.Ball
		local stars = {}
		for i = 1, 6 do
			local a = i / 6 * math.pi * 2
			local p = Vector3.new(math.cos(a) * 6.5, 6 + math.sin(a * 2) * 1.5, math.sin(a) * 6.5)
			stars[i] = p
			local star = add(fx, "Star", S(0.5, 0.5, 0.5), at(p.X, p.Y, p.Z) * CFrame.Angles(0, 0, math.rad(45)), rgb(255, 255, 255), NEON)
			star:SetAttribute("Float", true)
		end
		for i = 1, 3 do
			local a, b = stars[i * 2 - 1], stars[i * 2]
			local mid = (a + b) / 2
			add(fx, "StarLine", S(0.1, 0.1, (b - a).Magnitude), CFrame.lookAt((mid + Vector3.new(0, lift, 0)) * k, (b + Vector3.new(0, lift, 0)) * k), rgb(170, 200, 255), { Material = Enum.Material.Neon, Transparency = 0.4 })
		end
		for _, s in { -1, 1 } do
			local bolt = add(fx, "Bolt", S(0.3, 3, 0.3), at(s * 6, 9, -1) * CFrame.Angles(0, 0, s * 0.5), rgb(200, 150, 255), NEON)
			bolt:SetAttribute("Flicker", true)
		end
		for i = 1, 4 do
			local step = add(fx, "LightStair", S(3, 0.2, 1.4), at(0, 7 + i * 1.6, 3 + i * 1.4), rgb(255, 255, 255), { Material = Enum.Material.Neon, Transparency = 0.6 })
			step:SetAttribute("Stair", i)
		end
	end

	local light = Instance.new("PointLight")
	light.Color = ChestBuilder.Levels[level].glow
	light.Range = 10 + level * 3
	light.Brightness = 0.8 + level * 0.3
	light.Parent = body

	model.PrimaryPart = body
	body.PivotOffset = body.CFrame:Inverse() -- model pivot = ground centre (WorldPivot is ignored with a PrimaryPart)
	lid:SetAttribute("Closed", hinge.CFrame)
	if cframe then
		model:PivotTo(cframe)
	end
	return model
end

-- Opens the lid on its hinge: t = 0 closed … 1 fully open (110°).
function ChestBuilder.SetLid(model: Model, t: number)
	local lid = model:FindFirstChild("Lid") :: Model?
	if not lid then return end
	local closed = model:GetPivot() * (lid:GetAttribute("Closed") :: CFrame)
	lid:PivotTo(closed * CFrame.Angles(OPEN_ANGLE * math.clamp(t, 0, 1), 0, 0))
end

return ChestBuilder
