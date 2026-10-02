-- IDs are permanent: never rename the prefix, zone IDs or suffixes without migration.
-- Approved completion reward: one Common chest Level 1, source zone 1 per zone; at most eight total.
local Zones = require(script.Parent.Zones)
local list, byId = {}, {}
for _, z in Zones.List do
	local radius = (z.inner + z.outer) / 2
	for index, kind in { "Landmark", "Secret", "Mini-chest" } do
		local angle = math.rad(60 + index * 90)
		local def = { id = "explorer_z" .. z.id .. "_" .. index .. "_v1", zone = z.id, kind = kind,
			position = Vector3.new(math.sin(angle) * radius, z.y + 3, math.cos(angle) * radius) }
		table.insert(list, def); byId[def.id] = def
	end
end
return table.freeze({ List = list, ById = byId, Range = 12, Cooldown = .35,
	Reward = table.freeze({ rarity = "Common", level = 1, zone = 1, count = 1 }) })
