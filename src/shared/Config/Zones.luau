-- Circular island: 8 concentric rings rising to the centre (1 Meadow outermost → 8 Lumora plateau).
-- Ring centre is the origin; south = +Z. inner/outer = ring radii, y = ground level.
-- The Rootfall hub (Hub) sits on the south edge and is not part of any zone.

local function rgb(r, g, b)
	return Color3.fromRGB(r, g, b)
end

export type Zone = {
	id: number,
	key: string,
	name: string,
	thai: string,
	y: number,
	inner: number,
	outer: number,
	built: boolean,
	egg: string,
	boss: string,
	colors: {
		ground: Color3,
		cliff: Color3,
		trunk: Color3,
		leaves: { Color3 },
		accent: Color3,
	},
}

local list: { Zone } = {
	{
		id = 1, key = "SunnyMeadow", name = "Sunny Meadow", thai = "ทุ่งหญ้าแสงแดด",
		y = 4, inner = 740, outer = 900, built = true, egg = "MeadowEgg", boss = "Old Oakheart",
		colors = { ground = rgb(108, 194, 74), cliff = rgb(122, 104, 82), trunk = rgb(115, 78, 46),
			leaves = { rgb(76, 175, 80), rgb(104, 190, 72), rgb(56, 142, 60) }, accent = rgb(255, 214, 79) },
	},
	{
		id = 2, key = "AmberWoods", name = "Amber Woods", thai = "ป่าอำพัน",
		y = 12, inner = 650, outer = 740, built = true, egg = "LeafEgg", boss = "Maple Colossus",
		colors = { ground = rgb(196, 140, 62), cliff = rgb(120, 90, 60), trunk = rgb(94, 62, 40),
			leaves = { rgb(234, 108, 36), rgb(214, 62, 37), rgb(246, 170, 46) }, accent = rgb(255, 120, 40) },
	},
	{
		id = 3, key = "GlowcapBog", name = "Glowcap Bog", thai = "บึงเห็ดเรืองแสง",
		y = 20, inner = 560, outer = 650, built = true, egg = "SporeEgg", boss = "Sporemother",
		colors = { ground = rgb(70, 92, 72), cliff = rgb(70, 66, 60), trunk = rgb(80, 70, 90),
			leaves = { rgb(120, 70, 160), rgb(90, 230, 200) }, accent = rgb(90, 230, 200) },
	},
	{
		id = 4, key = "SakuraHighlands", name = "Sakura Highlands", thai = "ที่ราบสูงซากุระ",
		y = 30, inner = 470, outer = 560, built = true, egg = "PetalEgg", boss = "Blossom Ronin",
		colors = { ground = rgb(150, 200, 120), cliff = rgb(130, 120, 110), trunk = rgb(90, 60, 60),
			leaves = { rgb(255, 183, 213), rgb(255, 210, 230) }, accent = rgb(200, 40, 50) },
	},
	{
		id = 5, key = "ThunderBamboo", name = "Thunder Bamboo", thai = "ป่าไผ่สายฟ้า",
		y = 40, inner = 380, outer = 470, built = true, egg = "ThunderEgg", boss = "Stormstalk",
		colors = { ground = rgb(90, 140, 80), cliff = rgb(100, 105, 100), trunk = rgb(150, 180, 90),
			leaves = { rgb(120, 190, 80) }, accent = rgb(255, 235, 80) },
	},
	{
		id = 6, key = "Frostvale", name = "Frostvale", thai = "หุบเขาน้ำแข็ง",
		y = 52, inner = 290, outer = 380, built = true, egg = "FrostEgg", boss = "Frost Warden",
		colors = { ground = rgb(232, 240, 250), cliff = rgb(150, 160, 175), trunk = rgb(90, 80, 75),
			leaves = { rgb(200, 225, 240), rgb(120, 160, 140) }, accent = rgb(140, 220, 255) },
	},
	{
		id = 7, key = "CrystalRidge", name = "Crystal Ridge", thai = "สันเขาคริสตัล",
		y = 64, inner = 200, outer = 290, built = true, egg = "CrystalEgg", boss = "Prism Titan",
		colors = { ground = rgb(160, 150, 200), cliff = rgb(110, 100, 140), trunk = rgb(120, 110, 150),
			leaves = { rgb(150, 230, 255), rgb(220, 160, 255) }, accent = rgb(255, 255, 255) },
	},
	{
		id = 8, key = "SkyIsles", name = "Lumora Plateau", thai = "ที่ราบสูงลูมอรา",
		y = 78, inner = 0, outer = 200, built = true, egg = "CelestialEgg", boss = "Rotbound Lumora",
		colors = { ground = rgb(240, 230, 190), cliff = rgb(200, 190, 160), trunk = rgb(230, 200, 150),
			leaves = { rgb(255, 215, 90), rgb(255, 240, 170) }, accent = rgb(255, 215, 100) },
	},
}

local byKey = {}
local treePools = {
	{"MeadowOak","MeadowLime","MeadowPine"}, {"AmberMaple","AmberBirch","AmberEmber"}, {"BogViolet","BogAzure","BogTeal"},
	{"SakuraPink","SakuraBlush","SakuraRose"}, {"BambooGreen","BambooSpark","BambooOlive"}, {"FrostPine","FrostIce","FrostSnow"},
	{"CrystalPrism","CrystalAmethyst","CrystalTide"}, {"LumoraGold","LumoraPearl","LumoraSun"},
}
local particles = { "", "", "Fireflies", "Petals", "Drizzle", "LightSnow", "Sparkles", "GoldMotes" }
local lighting = {
	[3] = { Ambient = rgb(105,115,135), FogColor = rgb(130,155,170), FogEnd = 650 },
	[6] = { OutdoorAmbient = rgb(192,218,245), FogColor = rgb(222,236,250), FogEnd = 750 },
}
for _, z in list do
	byKey[z.key] = z
	z.region = "Workspace.Map.Wilds.Zone" .. z.id .. "_" .. z.key
	z.order = z.id
	z.nameKey = z.name -- Locale uses English text as its stable key.
	z.unlock = { shrine = z.id > 1 and z.id - 1 or nil, coins = 0 }
	z.trees = { pool = treePools[z.id], hpMult = 1, dropMult = 1 } -- TreeKit retains its 55/30/15 mix; Balance/Forest own stats.
	z.events = { "GoldenTree", "TimberRush", "Meteor", "BossTree", "Fog" }
	z.rarityBonus = 0
	z.ambient = { music = "", sfx = "", particles = particles[z.id], lighting = lighting[z.id] } -- Silent until licensed assets exist.
	z.fastTravel = { zone = z.id, cost = 0 }
	z.explorer = { landmarks = 1, secrets = 1, chests = 1 }
end

local hub = { center = Vector3.new(0, 4, 1010), radius = 190 }

-- Zone id at a world position (nil in the hub, the sea or between levels).
-- Single footprint used by RunService (server) and ZoneAmbience (client).
local function at(pos: Vector3): number?
	local dx, dz = pos.X - hub.center.X, pos.Z - hub.center.Z
	if dx * dx + dz * dz <= hub.radius * hub.radius then
		return nil
	end
	local r = math.sqrt(pos.X * pos.X + pos.Z * pos.Z)
	for _, z in list do
		if r >= z.inner and r < z.outer and math.abs(pos.Y - z.y) < 18 then
			return z.id
		end
	end
	return nil
end

return table.freeze({
	List = list,
	ByKey = byKey,
	RotColor = rgb(128, 60, 200),
	Hub = table.freeze(hub),
	At = at,
	Tracking = table.freeze({ interval = .35, settleSeconds = .7, killFloor = -60 }),
})
