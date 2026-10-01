-- ทวีปตัว S: แถวใต้ไปตะวันออก แถวเหนือกลับตะวันตก + เกาะลอยเหนือโซน 7
-- col/row = grid, halfSize = ครึ่งความกว้างโซน, y = ระดับพื้น

local function rgb(r, g, b)
	return Color3.fromRGB(r, g, b)
end

export type Zone = {
	id: number,
	key: string,
	name: string,
	thai: string,
	y: number,
	halfSize: number,
	col: number,
	row: number,
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
		y = 4, halfSize = 250, col = 1, row = 1, built = true, egg = "MeadowEgg", boss = "Old Oakheart",
		colors = { ground = rgb(108, 194, 74), cliff = rgb(122, 104, 82), trunk = rgb(115, 78, 46),
			leaves = { rgb(76, 175, 80), rgb(104, 190, 72), rgb(56, 142, 60) }, accent = rgb(255, 214, 79) },
	},
	{
		id = 2, key = "AmberWoods", name = "Amber Woods", thai = "ป่าเมเปิล",
		y = 12, halfSize = 250, col = 2, row = 1, built = true, egg = "LeafEgg", boss = "Maple Colossus",
		colors = { ground = rgb(196, 140, 62), cliff = rgb(120, 90, 60), trunk = rgb(94, 62, 40),
			leaves = { rgb(234, 108, 36), rgb(214, 62, 37), rgb(246, 170, 46) }, accent = rgb(255, 120, 40) },
	},
	{
		id = 3, key = "GlowcapBog", name = "Glowcap Bog", thai = "บึงเห็ดเรืองแสง",
		y = 20, halfSize = 250, col = 3, row = 1, built = false, egg = "SporeEgg", boss = "Sporemother",
		colors = { ground = rgb(70, 92, 72), cliff = rgb(70, 66, 60), trunk = rgb(80, 70, 90),
			leaves = { rgb(120, 70, 160), rgb(90, 230, 200) }, accent = rgb(90, 230, 200) },
	},
	{
		id = 4, key = "SakuraHighlands", name = "Sakura Highlands", thai = "ที่ราบซากุระ",
		y = 30, halfSize = 250, col = 3, row = 0, built = false, egg = "PetalEgg", boss = "Blossom Ronin",
		colors = { ground = rgb(150, 200, 120), cliff = rgb(130, 120, 110), trunk = rgb(90, 60, 60),
			leaves = { rgb(255, 183, 213), rgb(255, 210, 230) }, accent = rgb(200, 40, 50) },
	},
	{
		id = 5, key = "ThunderBamboo", name = "Thunder Bamboo", thai = "ป่าไผ่สายฟ้า",
		y = 40, halfSize = 250, col = 2, row = 0, built = false, egg = "ThunderEgg", boss = "Stormstalk",
		colors = { ground = rgb(90, 140, 80), cliff = rgb(100, 105, 100), trunk = rgb(150, 180, 90),
			leaves = { rgb(120, 190, 80) }, accent = rgb(255, 235, 80) },
	},
	{
		id = 6, key = "Frostvale", name = "Frostvale", thai = "ทุ่งน้ำแข็ง",
		y = 52, halfSize = 250, col = 1, row = 0, built = false, egg = "FrostEgg", boss = "Frost Warden",
		colors = { ground = rgb(232, 240, 250), cliff = rgb(150, 160, 175), trunk = rgb(90, 80, 75),
			leaves = { rgb(200, 225, 240), rgb(120, 160, 140) }, accent = rgb(140, 220, 255) },
	},
	{
		id = 7, key = "CrystalRidge", name = "Crystal Ridge", thai = "ทุ่งคริสตัล",
		y = 64, halfSize = 250, col = 0, row = 0, built = false, egg = "CrystalEgg", boss = "Prism Titan",
		colors = { ground = rgb(160, 150, 200), cliff = rgb(110, 100, 140), trunk = rgb(120, 110, 150),
			leaves = { rgb(150, 230, 255), rgb(220, 160, 255) }, accent = rgb(255, 255, 255) },
	},
	{
		id = 8, key = "SkyIsles", name = "Sky Isles", thai = "เกาะลอยฟ้า",
		y = 364, halfSize = 250, col = 0, row = 0, built = false, egg = "CelestialEgg", boss = "Rotbound Lumora",
		colors = { ground = rgb(240, 245, 255), cliff = rgb(200, 210, 230), trunk = rgb(230, 200, 150),
			leaves = { rgb(255, 240, 170), rgb(255, 255, 255) }, accent = rgb(255, 215, 100) },
	},
}

local byKey = {}
for _, z in list do
	byKey[z.key] = z
end

return table.freeze({
	List = list,
	ByKey = byKey,
	RotColor = rgb(128, 60, 200),
	GridStep = 500,
	GroundHalfDepth = 240,
	ContinentSize = Vector2.new(2100, 1100),
	RiverWidth = 20,
	Village = { col = 0, row = 1, radius = 190 },
})
