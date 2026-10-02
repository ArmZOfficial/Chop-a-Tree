--!nocheck
-- Retro procedural trees for MapBuilder (Studio edit-time only).
-- 24 kinds, 3 themed per zone; each ≤ 9 parts (+3 rot veins on tier 6 in MapBuilder).
-- Plastic + studs, BrickColor-style flat colours. The part named "Trunk" is the
-- collider/PrimaryPart that TreeService uses for hit range and health bars.

local TreeKit = {}

local function rgb(r, g, b)
	return Color3.fromRGB(r, g, b)
end

local function part(m, name, size, cf, color, opts)
	local p = Instance.new("Part")
	p.Name = name
	p.Anchored = true
	p.Material = Enum.Material.Plastic
	p.TopSurface = Enum.SurfaceType.Studs
	p.BottomSurface = Enum.SurfaceType.Inlet
	p.Size = size
	p.CFrame = cf
	p.Color = color
	p.CanCollide = false
	if opts then
		for k, v in opts do
			p[k] = v
		end
	end
	p.Parent = m
	return p
end

local function ball(m, name, d, pos, color, opts)
	local p = part(m, name, Vector3.new(d, d, d), CFrame.new(pos), color, opts)
	p.Shape = Enum.PartType.Ball
	return p
end

-- Upright cylinder centred at pos.
local function cyl(m, name, d, h, pos, color, opts)
	local p = part(m, name, Vector3.new(h, d, d), CFrame.new(pos) * CFrame.Angles(0, 0, math.rad(90)), color, opts)
	p.Shape = Enum.PartType.Cylinder
	return p
end

local function trunk(m, s, color)
	return part(m, "Trunk", Vector3.new(s.tw, s.trunkH, s.tw), CFrame.new(s.pos + Vector3.new(0, s.trunkH / 2, 0)) * CFrame.Angles(0, s.rng:NextNumber(0, math.pi), 0), color, { CanCollide = true })
end

local function pick(rng, list)
	return list[rng:NextInteger(1, #list)]
end

local function jitter(s, k)
	return Vector3.new(s.rng:NextNumber(-k, k), 0, s.rng:NextNumber(-k, k))
end

local function spin(s)
	return CFrame.Angles(0, s.rng:NextNumber(0, math.pi * 2), 0)
end

local OAK, DARK_WOOD, PALE_WOOD = rgb(115, 78, 46), rgb(80, 55, 40), rgb(225, 220, 205)
local NEON = { Material = Enum.Material.Neon }
local GLASS = { Material = Enum.Material.Glass, Transparency = 0.15 }

-- s = { pos, h, tw, trunkH, cs (crown size), rng }
local kinds = {
	-- 1 Sunny Meadow
	{ zone = 1, key = "Oak", build = function(m, s)
		trunk(m, s, OAK)
		local greens = { rgb(76, 175, 80), rgb(104, 190, 72), rgb(56, 142, 60) }
		for i = 1, 3 do
			local c = s.cs * (1 - (i - 1) * 0.22)
			part(m, "Leaves", Vector3.new(c, c * 0.8, c), CFrame.new(s.pos + jitter(s, c * 0.25) + Vector3.new(0, s.trunkH + (i - 1) * c * 0.45, 0)) * spin(s), pick(s.rng, greens))
		end
	end },
	{ zone = 1, key = "RoundTree", build = function(m, s)
		trunk(m, s, OAK)
		ball(m, "Leaves", s.cs * 1.15, s.pos + Vector3.new(0, s.trunkH + s.cs * 0.35, 0), rgb(104, 190, 72))
		ball(m, "Leaves", s.cs * 0.6, s.pos + jitter(s, s.cs * 0.35) + Vector3.new(0, s.trunkH + s.cs * 0.85, 0), rgb(140, 210, 90))
	end },
	{ zone = 1, key = "Pine", build = function(m, s)
		trunk(m, s, DARK_WOOD)
		for i = 1, 3 do
			local c = s.cs * (1.1 - (i - 1) * 0.3)
			part(m, "Leaves", Vector3.new(c, c * 0.45, c), CFrame.new(s.pos + Vector3.new(0, s.trunkH * 0.7 + (i - 1) * c * 0.5, 0)) * CFrame.Angles(0, math.rad(45 * i), 0), rgb(40, 115, 55))
		end
	end },
	-- 2 Amber Woods
	{ zone = 2, key = "Maple", build = function(m, s)
		trunk(m, s, rgb(94, 62, 40))
		local reds = { rgb(234, 108, 36), rgb(214, 62, 37), rgb(246, 170, 46) }
		part(m, "Leaves", Vector3.new(s.cs * 1.3, s.cs * 0.45, s.cs * 1.3), CFrame.new(s.pos + Vector3.new(0, s.trunkH, 0)) * spin(s), pick(s.rng, reds))
		part(m, "Leaves", Vector3.new(s.cs, s.cs * 0.45, s.cs), CFrame.new(s.pos + jitter(s, s.cs * 0.15) + Vector3.new(0, s.trunkH + s.cs * 0.42, 0)) * spin(s), pick(s.rng, reds))
		part(m, "Leaves", Vector3.new(s.cs * 0.55, s.cs * 0.4, s.cs * 0.55), CFrame.new(s.pos + Vector3.new(0, s.trunkH + s.cs * 0.8, 0)) * spin(s), pick(s.rng, reds))
	end },
	{ zone = 2, key = "Birch", build = function(m, s)
		local t = trunk(m, s, PALE_WOOD)
		for i = 1, 2 do
			part(m, "Bark", Vector3.new(s.tw + 0.1, 0.4, s.tw + 0.1), t.CFrame * CFrame.new(0, (i - 1.5) * s.trunkH * 0.4, 0), rgb(40, 40, 40))
		end
		part(m, "Leaves", Vector3.new(s.cs * 0.8, s.cs * 1.4, s.cs * 0.8), CFrame.new(s.pos + Vector3.new(0, s.trunkH + s.cs * 0.5, 0)) * spin(s), rgb(250, 200, 60))
	end },
	{ zone = 2, key = "AutumnBall", build = function(m, s)
		trunk(m, s, rgb(94, 62, 40))
		for i, color in { rgb(246, 170, 46), rgb(234, 108, 36), rgb(255, 200, 70) } do
			local a = i / 3 * math.pi * 2
			ball(m, "Leaves", s.cs * 0.8, s.pos + Vector3.new(math.cos(a) * s.cs * 0.3, s.trunkH + s.cs * 0.25 + (i % 2) * s.cs * 0.3, math.sin(a) * s.cs * 0.3), color)
		end
	end },
	-- 3 Glowcap Bog
	{ zone = 3, key = "Mushroom", build = function(m, s)
		local t = trunk(m, s, rgb(235, 230, 215))
		t.Shape = Enum.PartType.Cylinder
		t.Size = Vector3.new(s.trunkH, s.tw * 1.3, s.tw * 1.3)
		t.CFrame = CFrame.new(s.pos + Vector3.new(0, s.trunkH / 2, 0)) * CFrame.Angles(0, 0, math.rad(90))
		local capY = s.trunkH + s.cs * 0.15
		cyl(m, "Leaves", s.cs * 1.3, s.cs * 0.35, s.pos + Vector3.new(0, capY, 0), pick(s.rng, { rgb(120, 70, 160), rgb(160, 60, 200) }))
		for i = 1, 3 do
			local a = i / 3 * math.pi * 2 + s.rng:NextNumber()
			ball(m, "Spot", s.cs * 0.18, s.pos + Vector3.new(math.cos(a) * s.cs * 0.4, capY + s.cs * 0.17, math.sin(a) * s.cs * 0.4), rgb(90, 230, 200), NEON)
		end
	end },
	{ zone = 3, key = "TwinShroom", build = function(m, s)
		trunk(m, s, rgb(200, 205, 225))
		cyl(m, "Leaves", s.cs * 1.1, s.cs * 0.3, s.pos + Vector3.new(0, s.trunkH * 0.75, 0), rgb(60, 120, 220))
		cyl(m, "Leaves", s.cs * 0.7, s.cs * 0.28, s.pos + Vector3.new(0, s.trunkH + s.cs * 0.25, 0), rgb(80, 160, 255))
		ball(m, "Glow", s.cs * 0.25, s.pos + Vector3.new(0, s.trunkH + s.cs * 0.45, 0), rgb(150, 230, 255), NEON)
	end },
	{ zone = 3, key = "GlowBulb", build = function(m, s)
		trunk(m, s, rgb(80, 70, 90))
		ball(m, "Glow", s.cs * 0.9, s.pos + Vector3.new(0, s.trunkH + s.cs * 0.3, 0), rgb(90, 230, 200), NEON)
		for i = 1, 2 do
			ball(m, "Leaves", s.cs * 0.5, s.pos + Vector3.new((i - 1.5) * s.cs * 0.9, s.trunkH * 0.85, 0), rgb(120, 70, 160))
		end
	end },
	-- 4 Sakura Highlands
	{ zone = 4, key = "Sakura", build = function(m, s)
		trunk(m, s, rgb(90, 60, 60))
		for i = 1, 2 do
			part(m, "Branch", Vector3.new(s.tw * 0.6, s.trunkH * 0.5, s.tw * 0.6), CFrame.new(s.pos + Vector3.new(0, s.trunkH * 0.85, 0)) * CFrame.Angles(0, i * math.pi, math.rad(35)) * CFrame.new(0, s.trunkH * 0.2, 0), rgb(90, 60, 60))
		end
		for i, color in { rgb(255, 183, 213), rgb(255, 210, 230), rgb(255, 160, 200) } do
			local a = i / 3 * math.pi * 2
			ball(m, "Leaves", s.cs * 0.75, s.pos + Vector3.new(math.cos(a) * s.cs * 0.35, s.trunkH + s.cs * 0.3, math.sin(a) * s.cs * 0.35), color)
		end
	end },
	{ zone = 4, key = "Weeping", build = function(m, s)
		trunk(m, s, rgb(90, 60, 60))
		local top = s.pos + Vector3.new(0, s.trunkH + s.cs * 0.2, 0)
		part(m, "Leaves", Vector3.new(s.cs * 1.2, s.cs * 0.5, s.cs * 1.2), CFrame.new(top), rgb(255, 183, 213))
		for i = 1, 4 do
			local a = i / 4 * math.pi * 2 + math.pi / 4
			part(m, "Strand", Vector3.new(s.cs * 0.2, s.cs * 0.7, s.cs * 0.2), CFrame.new(top + Vector3.new(math.cos(a) * s.cs * 0.5, -s.cs * 0.45, math.sin(a) * s.cs * 0.5)), rgb(255, 210, 230))
		end
	end },
	{ zone = 4, key = "Layered", build = function(m, s)
		trunk(m, s, rgb(70, 50, 50))
		for i = 1, 3 do
			local c = s.cs * (1.25 - (i - 1) * 0.3)
			part(m, "Leaves", Vector3.new(c, s.cs * 0.22, c), CFrame.new(s.pos + jitter(s, s.cs * 0.12) + Vector3.new(0, s.trunkH * 0.75 + (i - 1) * s.cs * 0.35, 0)) * spin(s), i == 2 and rgb(255, 210, 230) or rgb(255, 160, 200))
		end
	end },
	-- 5 Thunder Bamboo
	{ zone = 5, key = "BambooClump", build = function(m, s)
		local t = trunk(m, s, rgb(150, 180, 90))
		t.Size = Vector3.new(s.tw * 0.7, s.h, s.tw * 0.7)
		t.CFrame = CFrame.new(s.pos + Vector3.new(0, s.h / 2, 0))
		for i = 1, 3 do
			local a = i / 3 * math.pi * 2
			local hh = s.h * s.rng:NextNumber(0.6, 0.9)
			cyl(m, "Stalk", s.tw * 0.55, hh, s.pos + Vector3.new(math.cos(a) * s.tw, hh / 2, math.sin(a) * s.tw), rgb(130, 170, 70))
		end
		for i = 1, 2 do
			part(m, "Leaves", Vector3.new(s.cs * 0.7, s.cs * 0.15, s.cs * 0.25), CFrame.new(s.pos + Vector3.new(0, s.h * (0.75 + i * 0.1), 0)) * CFrame.Angles(0, i * 1.3, 0.3), rgb(120, 190, 80))
		end
	end },
	{ zone = 5, key = "BambooTall", build = function(m, s)
		local t = trunk(m, s, rgb(150, 180, 90))
		t.Size = Vector3.new(s.tw, s.h, s.tw)
		t.CFrame = CFrame.new(s.pos + Vector3.new(0, s.h / 2, 0))
		for i = 1, 3 do
			part(m, "Node", Vector3.new(s.tw + 0.4, 0.5, s.tw + 0.4), CFrame.new(s.pos + Vector3.new(0, s.h * i / 4, 0)), rgb(110, 140, 60))
		end
		for i = 1, 3 do
			part(m, "Leaves", Vector3.new(s.cs * 0.8, s.cs * 0.12, s.cs * 0.3), CFrame.new(s.pos + Vector3.new(0, s.h - i * 0.8, 0)) * CFrame.Angles(0, i * 2.1, -0.35) * CFrame.new(s.cs * 0.3, 0, 0), rgb(120, 190, 80))
		end
	end },
	{ zone = 5, key = "ThunderPalm", build = function(m, s)
		trunk(m, s, rgb(120, 110, 70))
		local top = s.pos + Vector3.new(0, s.trunkH, 0)
		for i = 1, 4 do
			part(m, "Leaves", Vector3.new(s.cs * 0.9, s.cs * 0.12, s.cs * 0.3), CFrame.new(top) * CFrame.Angles(0, i * math.pi / 2, -0.4) * CFrame.new(s.cs * 0.4, 0, 0), rgb(100, 170, 70))
		end
		part(m, "Spark", Vector3.new(s.cs * 0.25, s.cs * 0.5, s.cs * 0.25), CFrame.new(top + Vector3.new(0, s.cs * 0.35, 0)) * CFrame.Angles(0, 0, 0.5), rgb(255, 235, 80), NEON)
	end },
	-- 6 Frostvale
	{ zone = 6, key = "SnowPine", build = function(m, s)
		trunk(m, s, rgb(90, 80, 75))
		for i = 1, 3 do
			local c = s.cs * (1.1 - (i - 1) * 0.3)
			local y = s.trunkH * 0.6 + (i - 1) * c * 0.55
			part(m, "Leaves", Vector3.new(c, c * 0.4, c), CFrame.new(s.pos + Vector3.new(0, y, 0)) * CFrame.Angles(0, math.rad(45 * i), 0), rgb(60, 110, 90))
			part(m, "Snow", Vector3.new(c * 0.8, c * 0.12, c * 0.8), CFrame.new(s.pos + Vector3.new(0, y + c * 0.24, 0)) * CFrame.Angles(0, math.rad(45 * i), 0), rgb(245, 250, 255))
		end
	end },
	{ zone = 6, key = "IceSpire", build = function(m, s)
		trunk(m, s, rgb(150, 160, 175))
		for i = 1, 3 do
			local hh = s.cs * (1.4 - i * 0.25)
			part(m, "Ice", Vector3.new(s.cs * 0.35, hh, s.cs * 0.35), CFrame.new(s.pos + Vector3.new(0, s.trunkH + hh * 0.3, 0)) * CFrame.Angles(0, i * 2.1, 0.25 * (i - 2)) * CFrame.new(0, 0, (i - 2) * s.cs * 0.2), rgb(170, 220, 255), GLASS)
		end
	end },
	{ zone = 6, key = "SnowRound", build = function(m, s)
		trunk(m, s, rgb(90, 80, 75))
		ball(m, "Leaves", s.cs * 1.1, s.pos + Vector3.new(0, s.trunkH + s.cs * 0.3, 0), rgb(120, 160, 140))
		part(m, "Snow", Vector3.new(s.cs * 0.8, s.cs * 0.2, s.cs * 0.8), CFrame.new(s.pos + Vector3.new(0, s.trunkH + s.cs * 0.8, 0)) * spin(s), rgb(245, 250, 255))
	end },
	-- 7 Crystal Ridge
	{ zone = 7, key = "CrystalTree", build = function(m, s)
		trunk(m, s, rgb(120, 110, 150))
		local colors = { rgb(150, 230, 255), rgb(220, 160, 255) }
		for i = 1, 4 do
			part(m, "Crystal", Vector3.new(s.cs * 0.3, s.cs * 0.9, s.cs * 0.3), CFrame.new(s.pos + Vector3.new(0, s.trunkH + s.cs * 0.2, 0)) * CFrame.Angles(0, i * math.pi / 2, 0.45) * CFrame.new(0, s.cs * 0.35, 0), colors[i % 2 + 1], NEON)
		end
	end },
	{ zone = 7, key = "Prism", build = function(m, s)
		trunk(m, s, rgb(110, 100, 140))
		for i, color in { rgb(150, 230, 255), rgb(220, 160, 255), rgb(255, 255, 255) } do
			local hh = s.cs * (1.5 - i * 0.3)
			part(m, "Crystal", Vector3.new(s.cs * 0.45, hh, s.cs * 0.45), CFrame.new(s.pos + Vector3.new((i - 2) * s.cs * 0.35, s.trunkH + hh * 0.3, 0)) * CFrame.Angles(0, math.rad(45), 0), color, GLASS)
		end
	end },
	{ zone = 7, key = "Amethyst", build = function(m, s)
		trunk(m, s, rgb(120, 110, 150))
		local top = s.pos + Vector3.new(0, s.trunkH + s.cs * 0.35, 0)
		ball(m, "Leaves", s.cs, top, rgb(160, 100, 220))
		for i = 1, 3 do
			part(m, "Spike", Vector3.new(s.cs * 0.2, s.cs * 0.7, s.cs * 0.2), CFrame.new(top) * CFrame.Angles(0, i * 2.1, 0.7) * CFrame.new(0, s.cs * 0.55, 0), rgb(230, 190, 255), NEON)
		end
	end },
	-- 8 Lumora Plateau
	{ zone = 8, key = "GoldenTree", build = function(m, s)
		trunk(m, s, rgb(230, 200, 150))
		for i = 1, 3 do
			local c = s.cs * (1.1 - (i - 1) * 0.25)
			part(m, "Leaves", Vector3.new(c, c * 0.6, c), CFrame.new(s.pos + jitter(s, c * 0.2) + Vector3.new(0, s.trunkH + (i - 1) * c * 0.45, 0)) * spin(s), i == 2 and rgb(255, 240, 170) or rgb(255, 215, 90))
		end
	end },
	{ zone = 8, key = "LightOrb", build = function(m, s)
		trunk(m, s, rgb(230, 200, 150))
		ball(m, "Leaves", s.cs * 1.1, s.pos + Vector3.new(0, s.trunkH + s.cs * 0.3, 0), rgb(255, 240, 170))
		ball(m, "Glow", s.cs * 0.4, s.pos + Vector3.new(0, s.trunkH + s.cs * 0.95, 0), rgb(255, 225, 120), NEON)
	end },
	{ zone = 8, key = "SpiritWillow", build = function(m, s)
		trunk(m, s, rgb(245, 235, 210))
		local top = s.pos + Vector3.new(0, s.trunkH + s.cs * 0.2, 0)
		part(m, "Leaves", Vector3.new(s.cs * 1.2, s.cs * 0.45, s.cs * 1.2), CFrame.new(top) * spin(s), rgb(255, 215, 90))
		for i = 1, 4 do
			local a = i / 4 * math.pi * 2
			part(m, "Strand", Vector3.new(s.cs * 0.12, s.cs * 0.8, s.cs * 0.12), CFrame.new(top + Vector3.new(math.cos(a) * s.cs * 0.5, -s.cs * 0.5, math.sin(a) * s.cs * 0.5)), rgb(255, 245, 200), NEON)
		end
	end },
}

TreeKit.Kinds = kinds

-- Mix per plan: own zone ~55%, neighbouring zones ~30%, anywhere ~15%.
function TreeKit.Pick(zoneId, rng)
	local roll = rng:NextNumber()
	local zone = zoneId
	if roll >= 0.85 then
		zone = rng:NextInteger(1, 8)
	elseif roll >= 0.55 then
		zone = math.clamp(zoneId + (rng:NextNumber() < 0.5 and -1 or 1), 1, 8)
	end
	return (zone - 1) * 3 + rng:NextInteger(1, 3)
end

-- Builds tree kind `index` at ground pos; returns the Model (PrimaryPart = Trunk, untagged).
function TreeKit.Build(index, pos, tier, rng)
	local m = Instance.new("Model")
	m.Name = "Tree_T" .. tier
	local h = 10 + tier * 6
	local s = { pos = pos, h = h, tw = 1.4 + tier * 0.45, trunkH = h * 0.55, cs = 4 + tier * 2.6, rng = rng }
	kinds[index].build(m, s)
	m.PrimaryPart = m:FindFirstChild("Trunk")
	m:SetAttribute("Kind", kinds[index].key)
	return m
end

return TreeKit
