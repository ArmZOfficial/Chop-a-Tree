--!nocheck
-- One-off: vets two staged Creator Store packs into ServerStorage.MapAssets for
-- MapBuilder.BuildDressing. Paste into the Command Bar / MCP in Edit mode.
-- Stage first (insert by asset ID into ServerStorage.AssetReview; scripts never run there):
--   NaturePackStaging = 116403161689840 "Nature Asset Pack Studs Texture Style" by khalil2insta
--   VFXPackStaging    = 7564537285 "VFX Pack" by synmade
-- Only geometry is copied. Unions are skipped: MCP/command-bar threads cannot clone them
-- (Capabilities), and MapBuilder runs on such a thread.
local ServerStorage = game:GetService("ServerStorage")
local review, assets = ServerStorage.AssetReview, ServerStorage.MapAssets

local NATURE = { "Bush1", "Bush2", "Bush3", "Grass1", "Grass2", "Grass3", "FlowerPurple", "FlowerOrange", "Tree1", "Tree2", "Tree3", "Rock1", "Rock2", "Rock3", "SandRock1", "SandRock2", "Dirt1", "Dirt2", "Dirt3" }
local SOLID = { Rock1 = true, Rock2 = true, Rock3 = true, SandRock1 = true, SandRock2 = true } -- everything else is walk-through
-- prototype name = mesh name in the pack (first MeshPart with that name)
local VFX = { Ring = "Ring", Spiral = "Spiral", Star = "3DStar", Spike = "Spike", Wind = "Wind", Orb = "FancySphere", Swirl = "Swirl", Tornado = "Tornado", Thunder = "Thunder" }

local function fresh(name)
	local old = assets:FindFirstChild(name)
	if old then old:Destroy() end
	local f = Instance.new("Folder")
	f.Name = name
	f.Parent = assets
	return f
end

local function plain(part, solid)
	for _, child in part:GetChildren() do child:Destroy() end
	part.Anchored = true
	part.CanCollide = solid
	part.CanQuery = solid
	part.CanTouch = false
	return part
end

local nature = fresh("Nature")
for _, name in NATURE do
	local model = Instance.new("Model")
	model.Name = name
	for _, d in review.NaturePackStaging[name]:GetDescendants() do
		if d:IsA("Part") then
			local copy = plain(d:Clone(), SOLID[name] == true)
			copy.CastShadow = copy.Size.Y > 2 -- flowers, grass and dirt cast none
			copy.Parent = model
		end
	end
	local cf, size = model:GetBoundingBox()
	model.WorldPivot = CFrame.new(cf.Position - Vector3.new(0, size.Y / 2, 0)) -- bottom centre
	model.Parent = nature
end

local vfx = fresh("VFX")
for name, source in VFX do
	for _, d in review.VFXPackStaging:GetChildren() do
		if d.Name == source and d:IsA("MeshPart") then
			local copy = plain(d:Clone(), false)
			copy.Name = name
			copy.Material = Enum.Material.Neon
			copy.CastShadow = false
			copy.CFrame = CFrame.new()
			copy.Parent = vfx
			break
		end
	end
end

return #nature:GetChildren() .. " nature models, " .. #vfx:GetChildren() .. " vfx meshes"
