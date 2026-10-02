--!nocheck
-- Retro procedural trees for MapBuilder (Studio edit-time only).
-- Every tree is the blocky studded shape of the Creator Store "Kako9's Tree" (picked by ArmZ),
-- rebuilt from code: 8 leaf blocks, trunk + 2 props, 6 root slabs = 17 parts (+3 rot veins on
-- tier 6 in MapBuilder). 24 kinds = 8 zones × 3 (own palette + Classic/Tall/Wide canopy).
-- The part named "Trunk" is the collider/PrimaryPart that TreeService uses for hit range and
-- health bars; it runs from the ground up so TreeService's trunk-bottom = ground.
-- ponytail: 17 parts × ~1,470 trees ≈ 25k parts; drop the root slabs first if mobile FPS suffers.

local TreeKit = {}

local function rgb(r, g, b)
	return Color3.fromRGB(r, g, b)
end

-- Shape of Kako9's Tree on a 16-stud-tall grid, trunk centred on (0, 0). role picks the colour.
-- { role, position, size }
local LEAVES = {
	{ "L1", Vector3.new(-0.5, 11.5, 0.5), Vector3.new(9, 5, 9) },
	{ "L3", Vector3.new(-1.5, 15, 1), Vector3.new(6, 2, 5) },
	{ "L2", Vector3.new(0, 12, -4.5), Vector3.new(1, 4, 6) },
	{ "L2", Vector3.new(-1, 14.5, -3.5), Vector3.new(3, 1, 4) },
	{ "L1", Vector3.new(-5.5, 11.5, -0.5), Vector3.new(5, 3, 1) },
	{ "L2", Vector3.new(-1.5, 12.5, 4.5), Vector3.new(3, 5, 3) },
	{ "L1", Vector3.new(3.5, 13.5, -0.5), Vector3.new(5, 3, 3) },
	{ "L3", Vector3.new(4.5, 11.5, 2), Vector3.new(4, 3, 0.9) },
}
local WOOD = {
	{ "Bark2", Vector3.new(-0.5, 3.5, -1.5), Vector3.new(1, 5, 1) },
	{ "Bark3", Vector3.new(-1.5, 3, 0.5), Vector3.new(1, 4, 1) },
	{ "Bark", Vector3.new(2.5, 1.5, 0), Vector3.new(2, 1, 3) },
	{ "Bark2", Vector3.new(0.5, 0.5, 0), Vector3.new(2, 1, 9) },
	{ "Bark2", Vector3.new(1, 0.5, -1), Vector3.new(4, 1, 2) },
	{ "Bark3", Vector3.new(0, 0.5, 1.5), Vector3.new(1, 1, 6) },
	{ "Bark2", Vector3.new(-0.5, 0.5, 3), Vector3.new(2, 1, 3) },
	{ "Bark2", Vector3.new(0, 0.5, -2), Vector3.new(2, 1, 4) },
}
local CANOPY_CENTER = Vector3.new(-0.5, 12.5, 0.5)

-- Canopy styles: horizontal/vertical stretch and lift (template studs).
local STYLES = {
	Classic = { xz = 1, y = 1, lift = 0 },
	Tall = { xz = 0.85, y = 1.35, lift = 1.5 },
	Wide = { xz = 1.25, y = 0.8, lift = -0.5 },
}

-- fx = material for the L3 accent blocks (glow/ice/crystal zones).
local NEON, GLASS = Enum.Material.Neon, Enum.Material.Glass
local function palette(key, style, bark, bark2, bark3, l1, l2, l3, fx)
	return { key = key, style = style, Bark = bark, Bark2 = bark2, Bark3 = bark3, L1 = l1, L2 = l2, L3 = l3, fx = fx }
end
local OAK, OAK2, OAK3 = rgb(105, 64, 40), rgb(160, 95, 45), rgb(124, 92, 70)

local zones = {
	{ -- 1 Sunny Meadow
		palette("MeadowOak", "Classic", OAK, OAK2, OAK3, rgb(75, 151, 75), rgb(91, 154, 76), rgb(52, 142, 64)),
		palette("MeadowLime", "Wide", OAK, OAK2, OAK3, rgb(104, 190, 72), rgb(140, 210, 90), rgb(76, 175, 80)),
		palette("MeadowPine", "Tall", rgb(80, 55, 40), rgb(110, 75, 50), rgb(95, 70, 55), rgb(40, 115, 55), rgb(56, 142, 60), rgb(30, 95, 45)),
	},
	{ -- 2 Amber Woods
		palette("AmberMaple", "Classic", rgb(94, 62, 40), OAK2, OAK3, rgb(234, 108, 36), rgb(214, 62, 37), rgb(246, 170, 46)),
		palette("AmberBirch", "Tall", rgb(225, 220, 205), rgb(60, 55, 50), rgb(200, 195, 180), rgb(250, 200, 60), rgb(246, 170, 46), rgb(255, 220, 110)),
		palette("AmberEmber", "Wide", rgb(80, 50, 35), rgb(120, 70, 40), OAK3, rgb(190, 50, 40), rgb(214, 62, 37), rgb(150, 40, 35)),
	},
	{ -- 3 Glowcap Bog
		palette("BogViolet", "Wide", rgb(200, 205, 225), rgb(150, 150, 175), rgb(170, 170, 195), rgb(120, 70, 160), rgb(160, 60, 200), rgb(90, 230, 200), NEON),
		palette("BogAzure", "Classic", rgb(200, 205, 225), rgb(150, 150, 175), rgb(170, 170, 195), rgb(60, 120, 220), rgb(80, 160, 255), rgb(150, 230, 255), NEON),
		palette("BogTeal", "Tall", rgb(80, 70, 90), rgb(110, 95, 120), rgb(95, 85, 105), rgb(40, 140, 130), rgb(70, 170, 150), rgb(90, 230, 200), NEON),
	},
	{ -- 4 Sakura Highlands
		palette("SakuraPink", "Wide", rgb(90, 60, 60), rgb(120, 80, 75), rgb(105, 70, 68), rgb(255, 183, 213), rgb(255, 210, 230), rgb(255, 160, 200)),
		palette("SakuraBlush", "Classic", rgb(90, 60, 60), rgb(120, 80, 75), rgb(105, 70, 68), rgb(255, 230, 240), rgb(255, 200, 220), rgb(250, 250, 250)),
		palette("SakuraRose", "Tall", rgb(70, 50, 50), rgb(100, 70, 65), rgb(85, 60, 58), rgb(230, 120, 170), rgb(255, 160, 200), rgb(200, 90, 140)),
	},
	{ -- 5 Thunder Bamboo
		palette("BambooGreen", "Tall", rgb(150, 180, 90), rgb(110, 140, 60), rgb(130, 160, 75), rgb(120, 190, 80), rgb(100, 170, 70), rgb(150, 200, 90)),
		palette("BambooSpark", "Classic", rgb(150, 180, 90), rgb(110, 140, 60), rgb(130, 160, 75), rgb(90, 160, 60), rgb(130, 170, 70), rgb(255, 235, 80), NEON),
		palette("BambooOlive", "Wide", rgb(120, 110, 70), rgb(140, 125, 80), rgb(100, 95, 60), rgb(110, 140, 60), rgb(130, 170, 70), rgb(160, 190, 90)),
	},
	{ -- 6 Frostvale
		palette("FrostPine", "Tall", rgb(90, 80, 75), rgb(120, 110, 105), rgb(105, 95, 90), rgb(60, 110, 90), rgb(245, 250, 255), rgb(120, 160, 140)),
		palette("FrostIce", "Classic", rgb(150, 160, 175), rgb(180, 190, 205), rgb(165, 175, 190), rgb(170, 220, 255), rgb(245, 250, 255), rgb(200, 235, 255), GLASS),
		palette("FrostSnow", "Wide", rgb(90, 80, 75), rgb(120, 110, 105), rgb(105, 95, 90), rgb(245, 250, 255), rgb(220, 230, 240), rgb(120, 160, 140)),
	},
	{ -- 7 Crystal Ridge
		palette("CrystalPrism", "Classic", rgb(120, 110, 150), rgb(150, 140, 180), rgb(135, 125, 165), rgb(150, 230, 255), rgb(220, 160, 255), rgb(255, 255, 255), GLASS),
		palette("CrystalAmethyst", "Tall", rgb(110, 100, 140), rgb(140, 130, 170), rgb(125, 115, 155), rgb(160, 100, 220), rgb(190, 140, 240), rgb(230, 190, 255), NEON),
		palette("CrystalTide", "Wide", rgb(120, 110, 150), rgb(150, 140, 180), rgb(135, 125, 165), rgb(110, 200, 230), rgb(150, 230, 255), rgb(220, 160, 255), NEON),
	},
	{ -- 8 Lumora Plateau
		palette("LumoraGold", "Classic", rgb(230, 200, 150), rgb(210, 175, 120), rgb(245, 220, 175), rgb(255, 215, 90), rgb(255, 240, 170), rgb(255, 225, 120), NEON),
		palette("LumoraPearl", "Wide", rgb(245, 235, 210), rgb(225, 210, 180), rgb(250, 245, 230), rgb(255, 255, 245), rgb(255, 240, 170), rgb(255, 215, 90)),
		palette("LumoraSun", "Tall", rgb(230, 200, 150), rgb(210, 175, 120), rgb(245, 220, 175), rgb(255, 200, 70), rgb(255, 230, 140), rgb(255, 245, 200), NEON),
	},
}

local kinds = {}
for zone, list in zones do
	for _, p in list do
		p.zone = zone
		table.insert(kinds, p)
	end
end
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

local function part(m, name, size, cf, color, material, collide)
	local p = Instance.new("Part")
	p.Name = name
	p.Anchored = true
	p.Material = material or Enum.Material.Plastic
	for _, face in { "Top", "Bottom", "Front", "Back", "Left", "Right" } do -- studs on every face, like the reference
		p[face .. "Surface"] = Enum.SurfaceType.Studs
	end
	p.Size = size
	p.CFrame = cf
	p.Color = color
	p.CanCollide = collide == true
	p.Parent = m
	return p
end

-- Builds tree kind `index` at ground pos; returns the Model (PrimaryPart = Trunk, untagged).
function TreeKit.Build(index, pos, tier, rng)
	local kind = kinds[index]
	local style = STYLES[kind.style]
	local m = Instance.new("Model")
	m.Name = "Tree_T" .. tier
	local k = (10 + tier * 6) / 16 -- template is 16 studs tall
	local tw = 1.4 + tier * 0.45 -- trunk width per tier (hit range / rot veins rely on it)
	local base = CFrame.new(pos) * CFrame.Angles(0, rng:NextNumber(0, math.pi * 2), 0)
	-- Small per-tree shade shift so neighbours of the same kind do not look stamped.
	local shade = rng:NextNumber(-0.08, 0.08)
	local function tint(c)
		return shade > 0 and c:Lerp(Color3.new(1, 1, 1), shade) or c:Lerp(Color3.new(0, 0, 0), -shade)
	end
	local trunk = part(m, "Trunk", Vector3.new(tw, 9 * k, tw), base * CFrame.new(0, 4.5 * k, 0), tint(kind.Bark), nil, true)
	for _, w in WOOD do
		part(m, "Root", w[3] * k, base * CFrame.new(w[2] * k), tint(kind[w[1]]))
	end
	local c = CANOPY_CENTER
	for _, l in LEAVES do
		local off = l[2] - c
		local p = c + Vector3.new(off.X * style.xz, off.Y * style.y + style.lift, off.Z * style.xz)
		local size = Vector3.new(l[3].X * style.xz, l[3].Y * style.y, l[3].Z * style.xz)
		part(m, "Leaves", size * k, base * CFrame.new(p * k), tint(kind[l[1]]), l[1] == "L3" and kind.fx or nil)
	end
	m.PrimaryPart = trunk
	m:SetAttribute("Kind", kind.key)
	return m
end

return TreeKit
