--!nocheck
-- Builds vetted tree prototypes for MapBuilder from Creator Store models staged in
-- ServerStorage.AssetStaging (insert them by asset ID first; scripts never run there).
-- Only geometry and appearance are copied: every script, GUI, constraint and camera is
-- dropped, because several free models carried hidden loader/virus scripts.
--   local A = require(game.ServerStorage.MapTools.AssetPrototypes:Clone())
--   A.Build() ; return A.Report()
local ServerStorage = game:GetService("ServerStorage")

local Prototypes = {}

-- zone key -> staged variants. heightScale shrinks wide canopies so trees do not swallow
-- the forest; recolor maps a part to a new colour (Sky Isles turns pink into gold/white).
Prototypes.Sources = {
	GlowcapBog = {
		{ staged = "Z3_GlowShroom", assetId = 9084160874, creator = "jiveyjim", heightScale = 0.8 },
		{ staged = "Z3_Mushroom_A", assetId = 76687824222281, creator = "LucyP_ixel2793", heightScale = 0.7 },
	},
	SakuraHighlands = {
		{ staged = "Z4_Sakura_B", assetId = 107353504764126, creator = "Cryptl3Prismf152881", heightScale = 0.7, meshOnly = true },
	},
	ThunderBamboo = {
		{ staged = "Z5_Bamboo_C", assetId = 2296254310, creator = "Dev_Fume", heightScale = 1.4 },
	},
	Frostvale = {
		{ staged = "Z6_Snow_B", assetId = 72034473981049, creator = "SparkCrystal1419", heightScale = 1 },
		{ staged = "Z6_Snow_A", assetId = 72443045261774, creator = "L3g3nd_Circuit53", heightScale = 1 },
	},
	CrystalRidge = {
		{ staged = "Z7_CrystalCluster", assetId = 7159849815, creator = "gabs", heightScale = 0.8 },
	},
	SkyIsles = {
		{ staged = "Z8_MysticalTree", assetId = 5614785496, creator = "MoneyOrNot_Rain730", heightScale = 0.9,
			recolor = function(part)
				local c = part.Color
				if c.R > 0.75 and c.B > 0.6 then -- pink canopy
					return (part.Position.Y * 7) % 2 < 1 and Color3.fromRGB(255, 236, 170) or Color3.fromRGB(255, 255, 245)
				end
				return Color3.fromRGB(214, 180, 120) -- trunk and roots
			end },
	},
}

local KEEP = { SurfaceAppearance = true, SpecialMesh = true, Decal = true, Texture = true }

local function clean(source, spec)
	local model = Instance.new("Model")
	for _, d in source:GetDescendants() do
		if d:IsA("BasePart") and (not spec.meshOnly or d:IsA("MeshPart")) then
			local copy = d:Clone()
			for _, child in copy:GetDescendants() do
				if not KEEP[child.ClassName] then child:Destroy() end
			end
			copy.Anchored = true
			copy.CanCollide = false
			copy.CanQuery = false
			copy.CanTouch = false
			if spec.recolor then copy.Color = spec.recolor(copy) end
			copy.Parent = model
		end
	end
	local cf, size = model:GetBoundingBox()
	model.WorldPivot = CFrame.new(cf.Position - Vector3.new(0, size.Y / 2, 0)) -- bottom centre
	model:PivotTo(CFrame.new())
	model:SetAttribute("Height", size.Y)
	model:SetAttribute("HeightScale", spec.heightScale or 1)
	model:SetAttribute("AssetId", tostring(spec.assetId))
	model:SetAttribute("Creator", spec.creator)
	return model
end

function Prototypes.Build()
	local staging = ServerStorage:FindFirstChild("AssetStaging")
	assert(staging, "Insert the source assets into ServerStorage.AssetStaging first")
	local root = ServerStorage:FindFirstChild("MapAssets") or Instance.new("Folder")
	root.Name = "MapAssets"
	root.Parent = ServerStorage
	local trees = root:FindFirstChild("Trees") or Instance.new("Folder")
	trees.Name = "Trees"
	trees.Parent = root
	for key, specs in Prototypes.Sources do
		local old = trees:FindFirstChild(key)
		if old then old:Destroy() end
		local folder = Instance.new("Folder")
		folder.Name = key
		for i, spec in specs do
			local source = staging:FindFirstChild(spec.staged)
			assert(source, "Missing staged asset " .. spec.staged)
			local model = clean(source, spec)
			model.Name = "Variant" .. i
			model.Parent = folder
		end
		folder.Parent = trees
	end
end

function Prototypes.Report()
	local out = {}
	local trees = ServerStorage.MapAssets.Trees
	for _, folder in trees:GetChildren() do
		for _, m in folder:GetChildren() do
			local scripts, parts = 0, 0
			for _, d in m:GetDescendants() do
				if d:IsA("LuaSourceContainer") then scripts += 1 end
				if d:IsA("BasePart") then parts += 1 end
			end
			table.insert(out, string.format("%s.%s asset=%s parts=%d scripts=%d height=%.1f", folder.Name, m.Name, m:GetAttribute("AssetId"), parts, scripts, m:GetAttribute("Height")))
		end
	end
	table.sort(out)
	return table.concat(out, "\n")
end

return Prototypes
