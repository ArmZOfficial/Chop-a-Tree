--!nocheck
-- Chop a Tree map builder (Studio edit-time only, never runs in game).
-- Lives at ServerStorage.MapTools.MapBuilder (+ TreeKit). From the Command Bar / MCP:
--   local B = loadstring(game.ServerStorage.MapTools.MapBuilder.Source)()
--   B.BuildAll()          -- or B.BuildWorld(), B.BuildVillage(), B.BuildZone(1) …
-- Fixed seeds → rebuilding gives the same map. Zone data: ReplicatedStorage.Shared.Config.Zones.
-- Layout: circular island, 8 concentric rings rising to the Lumora plateau; Rootfall hub on the
-- south edge; every ring is entered on the south axis via stairs + torii ZoneGate.

local CollectionService = game:GetService("CollectionService")
local ChangeHistoryService = game:GetService("ChangeHistoryService")
local Lighting = game:GetService("Lighting")
local ServerStorage = game:GetService("ServerStorage")

-- MCP/command-bar threads cannot require game modules (Capabilities), so fall back to the source.
local function load(module)
	local ok, result = pcall(require, module:Clone())
	if ok then return result end
	return loadstring(module.Source)()
end

local Zones = load(game.ReplicatedStorage.Shared.Config.Zones)
local TreeKit = load(ServerStorage.MapTools.TreeKit)
local ChestBuilder = load(game.ReplicatedStorage.Shared.ChestBuilder)

local MapBuilder = {}

local SOUTH = Vector3.new(0, 0, 1)
local INWARD = -SOUTH
local RUN_PER_RISE = 2.5 -- stair depth per stud of height
local GATE_HALF = 19 -- half-width of every ring opening (torii pillars end at 18.75)
local HUB = Zones.Hub

-- ========== helpers ==========
local function rad(d)
	return math.rad(d)
end

local function flat(v)
	return Vector3.new(v.X, 0, v.Z)
end

-- Retro default: Plastic, studs on top, inlets below.
local function P(props)
	local p = Instance.new("Part")
	p.Anchored = true
	p.TopSurface = Enum.SurfaceType.Studs
	p.BottomSurface = Enum.SurfaceType.Inlet
	p.Material = Enum.Material.Plastic
	for k, v in props do
		if k ~= "Parent" then
			p[k] = v
		end
	end
	p.Parent = props.Parent
	return p
end

local function F(parent, name)
	local f = parent:FindFirstChild(name)
	if not f then
		f = Instance.new("Folder")
		f.Name = name
		f.Parent = parent
	end
	return f
end

local function M(parent, name)
	local m = Instance.new("Model")
	m.Name = name
	m.Parent = parent
	return m
end

local function tag(inst, tagName, attrs)
	CollectionService:AddTag(inst, tagName)
	if attrs then
		for k, v in attrs do
			inst:SetAttribute(k, v)
		end
	end
	return inst
end

-- Horizontal disk (upright cylinder); topY = top surface height. Studs on the top face.
local function disk(parent, center, radius, height, topY, color, material, name)
	local p = P({
		Name = name or "Disk",
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(height, radius * 2, radius * 2),
		CFrame = CFrame.new(center.X, topY - height / 2, center.Z) * CFrame.Angles(0, 0, rad(90)),
		Color = color,
		Material = material or Enum.Material.Plastic,
		Parent = parent,
	})
	p.RightSurface = Enum.SurfaceType.Studs
	return p
end

-- Point on a circle around `center`; a = 0 is south (+Z), a = ±π north.
local function polar(center, r, a, y)
	return Vector3.new(center.X + math.sin(a) * r, y, center.Z + math.cos(a) * r)
end

-- Signed angle of p around center, 0 = south.
local function angleOf(center, p)
	return math.atan2(p.X - center.X, p.Z - center.Z)
end

-- Text sign facing lookAt.
local function sign(parent, pos, lookAt, text, w, h, bg, fg)
	local board = P({
		Name = "Sign",
		Size = Vector3.new(w, h, 0.6),
		CFrame = CFrame.lookAt(pos, Vector3.new(lookAt.X, pos.Y, lookAt.Z)),
		Color = bg or Color3.fromRGB(30, 36, 51),
		CanCollide = false,
		Parent = parent,
	})
	local gui = Instance.new("SurfaceGui")
	gui.Face = Enum.NormalId.Front
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 25
	gui.LightInfluence = 0
	gui.Parent = board
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Text = text
	label.TextScaled = true
	label.TextWrapped = true
	label.FontFace = Font.new("rbxasset://fonts/families/FredokaOne.json")
	label.TextColor3 = fg or Color3.new(1, 1, 1)
	label.Parent = gui
	local pad = Instance.new("UIPadding")
	pad.PaddingLeft = UDim.new(0.05, 0)
	pad.PaddingRight = UDim.new(0.05, 0)
	pad.PaddingTop = UDim.new(0.08, 0)
	pad.PaddingBottom = UDim.new(0.08, 0)
	pad.Parent = label
	return board
end

-- Flat strips through points (top surface at each point's y).
local function pathSegments(parent, points, width, thickness, color, material, name)
	for i = 1, #points - 1 do
		local a = points[i] - Vector3.new(0, thickness / 2, 0)
		local b = points[i + 1] - Vector3.new(0, thickness / 2, 0)
		local len = (b - a).Magnitude
		if len > 0.1 then
			P({
				Name = name or "Road",
				Size = Vector3.new(width, thickness, len + 3),
				CFrame = CFrame.lookAt((a + b) / 2, b),
				Color = color,
				Material = material or Enum.Material.Plastic,
				Parent = parent,
			})
		end
	end
end

-- Wall of straight segments around a circle with exact openings.
-- gaps = { {angle, halfArc}, ... } (angle 0 = south, halfArc in studs along the wall).
local function ringWall(parent, center, r, bottomY, height, thickness, color, name, gaps, segLen)
	local cuts = {}
	for _, g in gaps do
		local half = g[2] / r
		table.insert(cuts, { g[1] - half, g[1] + half })
	end
	table.sort(cuts, function(a, b) return a[1] < b[1] end)
	-- Solid arcs run from the end of one opening to the start of the next (wrapping once).
	local arcs = {}
	for i, c in cuts do
		local nextCut = cuts[i % #cuts + 1]
		local stop = nextCut[1] + (i == #cuts and 2 * math.pi or 0)
		table.insert(arcs, { c[2], stop })
	end
	if #cuts == 0 then arcs = { { -math.pi, math.pi } } end
	for _, arc in arcs do
		local span = arc[2] - arc[1]
		local n = math.max(1, math.ceil(span * r / (segLen or 30)))
		local step = span / n
		for i = 0, n - 1 do
			local a = arc[1] + (i + 0.5) * step
			local pos = polar(center, r, a, bottomY + height / 2)
			local len = 2 * r * math.sin(step / 2) + (i > 0 and i < n - 1 and 0.6 or 0.3)
			P({ Name = name, Size = Vector3.new(len, height, thickness), CFrame = CFrame.lookAt(pos, Vector3.new(center.X, pos.Y, center.Z)), Color = color, Parent = parent })
		end
	end
end

local function withHistory(label, fn)
	local id = ChangeHistoryService:TryBeginRecording(label)
	local ok, err = pcall(fn)
	if id then
		ChangeHistoryService:FinishRecording(id, ok and Enum.FinishRecordingOperation.Commit or Enum.FinishRecordingOperation.Cancel)
	end
	if not ok then
		error(err, 0)
	end
end

local function mapRoot()
	return F(workspace, "Map")
end

local function fresh(parent, name)
	local old = parent:FindFirstChild(name)
	if old then
		old:Destroy()
	end
	local f = Instance.new("Folder")
	f.Name = name
	f.Parent = parent
	return f
end

local function distToSegment(p, a, b)
	local ab = flat(b - a)
	local ap = flat(p - a)
	local t = math.clamp(ap:Dot(ab) / math.max(ab:Dot(ab), 1e-6), 0, 1)
	return (ap - ab * t).Magnitude
end

-- 0 at the south entry axis → 1 on the far (north) side of the ring.
local function depthOf(p)
	return math.abs(angleOf(Vector3.zero, p)) / math.pi
end

-- ========== layout ==========
function MapBuilder.Layout()
	local L = { zones = {}, roads = {} }
	local hubNorth = HUB.center + INWARD * HUB.radius
	L.hub = { center = HUB.center, radius = HUB.radius, gate = hubNorth + SOUTH * 4, plazaY = HUB.center.Y + 0.9 }
	for i, z in Zones.List do
		local Z = { def = z, y = z.y, inner = z.inner, outer = z.outer, center = Vector3.new(0, z.y, 0) }
		Z.entry = i == 1 and Vector3.new(0, z.y, hubNorth.Z) or Vector3.new(0, z.y, z.outer)
		Z.trailStart = Z.entry + INWARD * 8
		local nextZone = Zones.List[i + 1]
		if nextZone then
			Z.rise = nextZone.y - z.y
			Z.run = Z.rise * RUN_PER_RISE
			Z.exit = Vector3.new(0, z.y, z.inner)
			Z.stairFoot = Z.exit + SOUTH * Z.run
			Z.trailEnd = Z.stairFoot + SOUTH * 4
		else
			Z.trailEnd = Vector3.new(0, z.y, 70)
		end
		L.zones[i] = Z
	end
	local z1 = L.zones[1]
	table.insert(L.roads, { from = 0, to = 1, points = {
		Vector3.new(0, L.hub.plazaY, HUB.center.Z - 60), Vector3.new(0, L.hub.plazaY, hubNorth.Z + 8), z1.trailStart,
	} })
	for i = 1, #Zones.List - 1 do
		local Z, N = L.zones[i], L.zones[i + 1]
		table.insert(L.roads, { from = i, to = i + 1, stairs = true, points = {
			Z.trailEnd, Z.stairFoot, Vector3.new(0, N.y, Z.exit.Z), Vector3.new(0, N.y, Z.exit.Z - 8),
		} })
	end
	return L
end

function MapBuilder.RoadPoints(r)
	return r.points
end

-- ========== island, sea, stairs ==========
local STONE = Color3.fromRGB(130, 125, 118)

local function stairs(parent, Z, nextY, color)
	local steps = math.ceil(Z.rise)
	local depth = Z.run / steps
	for k = 1, steps do
		local top = Z.y + Z.rise * k / steps
		local z0 = Z.stairFoot.Z - (k - 1) * depth
		P({ Name = "Step", Size = Vector3.new(26, top - Z.y + 1, depth + 0.05), CFrame = CFrame.new(0, (top + Z.y - 1) / 2, z0 - depth / 2), Color = k % 2 == 0 and color or color:Lerp(Color3.new(1, 1, 1), 0.12), Parent = parent })
	end
	for _, x in { -14, 14 } do
		P({ Name = "StairWall", Size = Vector3.new(2, Z.rise + 3, Z.run), CFrame = CFrame.new(x, Z.y + (Z.rise + 3) / 2, Z.exit.Z + Z.run / 2), Color = color:Lerp(Color3.new(0, 0, 0), 0.2), Parent = parent })
	end
	return nextY
end

function MapBuilder.BuildWorld()
	withHistory("Chop a Tree: Island", function()
		local L = MapBuilder.Layout()
		local root = mapRoot()
		for _, obsolete in { "Mountain", "Hills", "Roads" } do
			local old = root:FindFirstChild(obsolete)
			if old then old:Destroy() end
		end
		local stash = F(ServerStorage, "OldTemplate")
		for _, name in { "Baseplate", "SpawnLocation" } do
			local inst = workspace:FindFirstChild(name)
			if inst then inst.Parent = stash end
		end
		-- Wedding-cake rings: each zone = cliff cylinder + thin coloured top; inner rings sit higher.
		local ground = fresh(root, "Ground")
		for i, z in Zones.List do
			local outer = z.outer
			disk(ground, Vector3.zero, outer, z.y + 19, z.y - 1, z.colors.cliff, Enum.Material.Plastic, "Cliff_Z" .. i)
			disk(ground, Vector3.zero, outer - 0.5, 1, z.y, z.colors.ground, Enum.Material.Plastic, "Top_Z" .. i)
		end
		disk(ground, HUB.center, HUB.radius, HUB.center.Y + 20, HUB.center.Y, Zones.List[1].colors.cliff, Enum.Material.Plastic, "HubCliff")
		-- Rocky cliff coast (collidable, keeps players on the island) except at the hub.
		local coast = fresh(root, "Coast")
		local z1 = Zones.List[1]
		local function inHub(a, r)
			local p = polar(Vector3.zero, r, a, 0)
			return flat(p - HUB.center).Magnitude < HUB.radius + 6
		end
		-- Coast opening = where the island rim enters the hub disk (law of cosines).
		local rimR, d = z1.outer - 3, flat(HUB.center).Magnitude
		local hubHalf = math.acos((rimR ^ 2 + d ^ 2 - (HUB.radius - 4) ^ 2) / (2 * rimR * d)) * rimR
		ringWall(coast, Vector3.zero, rimR, z1.y - 1, 11, 6, Color3.fromRGB(110, 110, 115), "CoastRock", { { 0, hubHalf } }, 26)
		local rng = Random.new(77)
		for i = 0, 89 do
			local a = i / 90 * math.pi * 2
			if not inHub(a, z1.outer + 6) then
				local s = rng:NextNumber(8, 16)
				P({ Name = "Boulder", Size = Vector3.new(s * 1.4, s, s), CFrame = CFrame.new(polar(Vector3.zero, z1.outer + 5, a, z1.y - s * 0.3)) * CFrame.Angles(0, -a, rng:NextNumber(-0.2, 0.2)), Color = rng:NextNumber() < 0.5 and Color3.fromRGB(110, 110, 115) or Color3.fromRGB(140, 138, 132), Parent = coast })
			end
		end
		local water = fresh(root, "Water")
		for _, x in { -2048, 0, 2048 } do
			for _, z in { -1700, 348, 2396 } do
				P({ Name = "Sea", Size = Vector3.new(2048, 2, 2048), CFrame = CFrame.new(x, -7, z), Color = Color3.fromRGB(45, 150, 210), Material = Enum.Material.Glass, Transparency = 0.2, CanCollide = false, CanQuery = false, TopSurface = Enum.SurfaceType.Smooth, Parent = water })
			end
		end
		-- Stairs between rings on the south axis.
		local stairsFolder = fresh(root, "Stairs")
		for i = 1, #Zones.List - 1 do
			local Z = L.zones[i]
			stairs(F(stairsFolder, string.format("Stairs_%d_%d", i, i + 1)), Z, L.zones[i + 1].y, STONE)
		end
		-- Flat retro lighting.
		pcall(function() Lighting.Technology = Enum.Technology.Voxel end)
		Lighting.ClockTime = 14
		Lighting.Brightness = 2
		Lighting.GlobalShadows = true
		Lighting.OutdoorAmbient = Color3.fromRGB(150, 150, 150)
		Lighting.EnvironmentDiffuseScale = 0
		Lighting.EnvironmentSpecularScale = 0
		local atmo = Lighting:FindFirstChildOfClass("Atmosphere") or Instance.new("Atmosphere")
		atmo.Density, atmo.Offset, atmo.Haze, atmo.Glare = 0.15, 0.25, 0.2, 0
		atmo.Color = Color3.fromRGB(205, 225, 245)
		atmo.Decay = Color3.fromRGB(150, 170, 200)
		atmo.Parent = Lighting
		workspace.StreamingEnabled = true
	end)
end

-- ========== Rootfall hub ==========
local function stall(parent, cf, label, roofColor)
	local m = M(parent, label)
	P({ Name = "Floor", Size = Vector3.new(16, 1, 12), CFrame = cf * CFrame.new(0, 0.5, 0), Color = Color3.fromRGB(150, 110, 70), Parent = m })
	for _, o in { { -7, -5 }, { 7, -5 }, { -7, 5 }, { 7, 5 } } do
		P({ Name = "Post", Size = Vector3.new(1, 10, 1), CFrame = cf * CFrame.new(o[1], 5.5, o[2]), Color = Color3.fromRGB(110, 75, 45), Parent = m })
	end
	P({ Name = "Roof", Size = Vector3.new(18, 1.5, 14), CFrame = cf * CFrame.new(0, 11, 0) * CFrame.Angles(rad(8), 0, 0), Color = roofColor, Parent = m })
	P({ Name = "Counter", Size = Vector3.new(14, 4, 2), CFrame = cf * CFrame.new(0, 3, -4.5), Color = Color3.fromRGB(170, 125, 80), Parent = m })
	local front = (cf * CFrame.new(0, 0, -20)).Position
	sign(m, (cf * CFrame.new(0, 13.5, -6)).Position, front, label, 14, 3.5, Color3.fromRGB(30, 36, 51), Color3.fromRGB(253, 230, 138))
	m.PrimaryPart = m.Floor
	return m
end

local function warpStone(parent, pos, zoneId, accent)
	local m = M(parent, "WarpStone")
	P({ Name = "Base", Size = Vector3.new(7, 1.5, 7), CFrame = CFrame.new(pos + Vector3.new(0, 0.75, 0)), Color = Color3.fromRGB(110, 110, 120), Parent = m })
	local pillar = P({ Name = "Pillar", Size = Vector3.new(4, 10, 4), CFrame = CFrame.new(pos + Vector3.new(0, 6.5, 0)) * CFrame.Angles(0, rad(45), 0), Color = Color3.fromRGB(90, 95, 110), Parent = m })
	local rune = P({ Name = "Rune", Size = Vector3.new(4.2, 1.2, 4.2), CFrame = CFrame.new(pos + Vector3.new(0, 9, 0)) * CFrame.Angles(0, rad(45), 0), Color = accent, Material = Enum.Material.Neon, CanCollide = false, Parent = m })
	local light = Instance.new("PointLight")
	light.Color = accent
	light.Range = 14
	light.Brightness = 1.5
	light.Parent = rune
	m.PrimaryPart = pillar
	tag(m, "WarpStone", { Zone = zoneId })
	return m
end

local ROOFS = { Color3.fromRGB(196, 40, 28), Color3.fromRGB(13, 105, 172), Color3.fromRGB(107, 50, 124), Color3.fromRGB(40, 127, 71), Color3.fromRGB(218, 133, 65), Color3.fromRGB(18, 144, 140), Color3.fromRGB(245, 205, 48) }

local function playerBase(parent, index, cf)
	local m = M(parent, "Base" .. index)
	local slab = P({ Name = "Slab", Size = Vector3.new(56, 1.2, 56), CFrame = cf * CFrame.new(0, 0.6, 0), Color = Color3.fromRGB(170, 120, 75), Parent = m })
	m.PrimaryPart = slab
	for _, e in { { 0, -28, 56, 1 }, { 0, 28, 56, 1 }, { -28, 0, 1, 56 }, { 28, 0, 1, 56 } } do
		P({ Name = "Edge", Size = Vector3.new(e[3] + 1, 1.6, e[4] + 1), CFrame = cf * CFrame.new(e[1], 0.8, e[2]), Color = Color3.fromRGB(120, 80, 50), Parent = m })
	end
	-- Garden (back) 6 slots.
	local garden = M(m, "GardenPlot")
	for row = 0, 1 do
		for col = 0, 2 do
			local slot = P({
				Name = "Slot" .. (row * 3 + col + 1),
				Size = Vector3.new(8, 0.8, 8),
				CFrame = cf * CFrame.new((col - 1) * 10, 1.6, 10 + row * 10),
				Color = Color3.fromRGB(110, 72, 45),
				Parent = garden,
			})
			tag(slot, "GardenSlot", { BaseIndex = index, SlotIndex = row * 3 + col + 1 })
		end
	end
	-- Incubator (front left).
	local inc = M(m, "Incubator")
	P({ Name = "Stand", Shape = Enum.PartType.Cylinder, Size = Vector3.new(2, 8, 8), CFrame = cf * CFrame.new(-16, 2.2, -12) * CFrame.Angles(0, 0, rad(90)), Color = Color3.fromRGB(200, 200, 210), Parent = inc })
	P({ Name = "Dome", Shape = Enum.PartType.Ball, Size = Vector3.new(7, 7, 7), CFrame = cf * CFrame.new(-16, 5, -12), Color = Color3.fromRGB(180, 230, 255), Material = Enum.Material.Glass, Transparency = 0.5, CanCollide = false, Parent = inc })
	tag(inc, "Incubator", { BaseIndex = index })
	-- Pet pen (front right).
	local pen = M(m, "PetPen")
	local pc = cf * CFrame.new(14, 0, -10)
	for i = 0, 11 do
		local a = i / 12 * math.pi * 2
		P({ Name = "Fence", Size = Vector3.new(1, 3, 4.5), CFrame = pc * CFrame.new(math.sin(a) * 8, 2.7, math.cos(a) * 8) * CFrame.Angles(0, a, 0), Color = Color3.fromRGB(220, 200, 160), Parent = pen })
	end
	tag(pen, "PetPen", { BaseIndex = index })
	-- Cosy hut (back left corner), roof colour per base.
	local hut = M(m, "Hut")
	local hc = cf * CFrame.new(-20, 1.2, 19)
	P({ Name = "Walls", Size = Vector3.new(9, 7, 8), CFrame = hc * CFrame.new(0, 3.5, 0), Color = Color3.fromRGB(215, 190, 150), Parent = hut })
	for _, s in { -1, 1 } do
		P({ Name = "Roof", Size = Vector3.new(10.5, 1, 6), CFrame = hc * CFrame.new(0, 8.4, s * 2.2) * CFrame.Angles(s * rad(35), 0, 0), Color = ROOFS[index] or ROOFS[1], Parent = hut })
	end
	P({ Name = "Door", Size = Vector3.new(2.6, 4.4, 0.4), CFrame = hc * CFrame.new(0, 2.2, -4.1), Color = Color3.fromRGB(105, 64, 40), CanCollide = false, Parent = hut })
	-- Owner sign (front edge, facing the plaza).
	local front = (cf * CFrame.new(0, 0, -60)).Position
	P({ Name = "SignPost", Size = Vector3.new(1, 8, 1), CFrame = cf * CFrame.new(0, 4.6, -26), Color = Color3.fromRGB(110, 75, 45), Parent = m })
	local s = sign(m, (cf * CFrame.new(0, 9, -26)).Position, front, "Base " .. index .. " · Empty", 12, 3.2)
	s.Name = "OwnerSign"
	tag(s, "OwnerSign", { BaseIndex = index })
	local barrier = P({ Name = "LockBarrier", Size = Vector3.new(58, 30, 58), CFrame = cf * CFrame.new(0, 15, 0), Color = Color3.fromRGB(96, 165, 250), Material = Enum.Material.ForceField, Transparency = 1, CanCollide = false, CanQuery = false, Parent = m })
	barrier:SetAttribute("Active", false)
	local spawnPoint = P({ Name = "BaseSpawn", Size = Vector3.new(4, 1, 4), CFrame = cf * CFrame.new(0, 1.7, -18), Transparency = 1, CanCollide = false, Parent = m })
	tag(spawnPoint, "BaseSpawn", { BaseIndex = index })
	tag(m, "PlayerBase", { BaseIndex = index, OwnerUserId = 0 })
	return m
end

-- Hub angle a: 0 = north (towards the island centre), positive = east.
local function hubPoint(a, r, dy)
	local V = HUB.center
	return Vector3.new(V.X + math.sin(rad(a)) * r, V.Y + (dy or 0), V.Z - math.cos(rad(a)) * r)
end

function MapBuilder.BuildVillage()
	withHistory("Chop a Tree: Village", function()
		local L = MapBuilder.Layout()
		local V = HUB.center
		local Y = V.Y
		local village = fresh(mapRoot(), "Village")
		disk(village, V, HUB.radius - 1, 1.2, Y + 0.9, Color3.fromRGB(120, 182, 82), Enum.Material.Plastic, "Plaza")
		disk(village, V, 34, 0.4, Y + 1.1, Color3.fromRGB(226, 200, 150), Enum.Material.Plastic, "InnerPlaza")
		pathSegments(village, { hubPoint(180, HUB.radius - 2, 1.05), hubPoint(0, HUB.radius - 2, 1.05) }, 22, 0.3, Color3.fromRGB(226, 200, 150), Enum.Material.Plastic, "MainPath")
		local function face(pos)
			return CFrame.lookAt(pos, Vector3.new(V.X, pos.Y, V.Z))
		end

		-- 7 player bases (houses) east ×4 / west ×3, clear of the gate and dock axis.
		local bases = F(village, "Bases")
		for i, a in { 40, 75, 110, 145, -40, -75, -110 } do
			playerBase(bases, i, face(hubPoint(a, 140, 0.3)))
		end

		-- Chest Altar in the plaza centre.
		local altar = M(village, "ChestAltar")
		disk(altar, V, 11, 2, Y + 3.1, Color3.fromRGB(235, 235, 240), Enum.Material.Plastic, "Step1")
		disk(altar, V, 8, 3, Y + 6.1, Color3.fromRGB(245, 245, 250), Enum.Material.Plastic, "Step2")
		local rim = disk(altar, V, 8.4, 0.6, Y + 6.4, Color3.fromRGB(255, 214, 79), Enum.Material.Neon, "Rim")
		rim.CanCollide = false
		altar.PrimaryPart = altar.Step2
		-- Display chest (Epic "Gilded Gem") facing the dock; cosmetic, no collision.
		ChestBuilder.Build(3, CFrame.new(V.X, Y + 6.4, V.Z) * CFrame.Angles(0, math.pi, 0)).Parent = altar
		tag(altar, "ChestAltar")

		-- Services: axe shop left (west), wood shop right (east) of the altar.
		local services = F(village, "Services")
		local ring = {
			{ "UpgradeShop", -55, 62, "Axe Shop", Color3.fromRGB(29, 78, 216) },
			{ "Sawmill", 55, 62, "Wood Shop · Sell", Color3.fromRGB(180, 83, 9) },
			{ "SeedShop", -110, 72, "Seed Shop", Color3.fromRGB(76, 175, 80) },
			{ "EggConveyor", 110, 72 },
			{ "NPC_Bram", -22, 62 },
			{ "WarpHub", 22, 62 },
			{ "Leaderboards", -145, 140 },
			{ "ArenaPortal", -150, 95 },
		}
		for _, item in ring do
			local id = item[1]
			local pos = hubPoint(item[2], item[3], 1.1)
			local cf = face(pos)
			if item[5] then
				local s = stall(services, cf, item[4], item[5])
				s.Name = id
				tag(s, "Shop", { ShopType = id })
				if id == "UpgradeShop" then
					-- Giant axe over the axe shop.
					local axe = cf * CFrame.new(0, 16, 0) * CFrame.Angles(0, 0, rad(-30))
					P({ Name = "AxeHandle", Size = Vector3.new(0.8, 9, 0.8), CFrame = axe, Color = Color3.fromRGB(124, 92, 70), CanCollide = false, Parent = s })
					P({ Name = "AxeHead", Size = Vector3.new(3.4, 2.6, 0.7), CFrame = axe * CFrame.new(1.4, 3.6, 0), Color = Color3.fromRGB(163, 162, 165), CanCollide = false, Parent = s })
				elseif id == "Sawmill" then
					-- Log pile beside the wood shop.
					for _, o in { { 9.7, 1.3 }, { 12.3, 1.3 }, { 11, 3.5 } } do
						P({ Name = "Log", Shape = Enum.PartType.Cylinder, Size = Vector3.new(7, 2.6, 2.6), CFrame = cf * CFrame.new(o[1], o[2], 0) * CFrame.Angles(0, rad(90), 0), Color = Color3.fromRGB(160, 110, 65), Parent = s })
					end
				end
			elseif id == "EggConveyor" then
				local m = M(services, id)
				local belt = P({ Name = "Belt", Size = Vector3.new(26, 1.6, 6), CFrame = cf * CFrame.new(0, 0.8, 0), Color = Color3.fromRGB(40, 44, 52), Material = Enum.Material.DiamondPlate, Parent = m })
				for k = -2, 2 do
					P({ Name = "Stripe", Size = Vector3.new(1, 0.2, 6.2), CFrame = cf * CFrame.new(k * 5, 1.7, 0), Color = Color3.fromRGB(250, 204, 21), Material = Enum.Material.Neon, CanCollide = false, Parent = m })
				end
				sign(m, (cf * CFrame.new(0, 7, 2)).Position, V, "Egg Conveyor", 14, 3.5, Color3.fromRGB(30, 36, 51), Color3.fromRGB(253, 230, 138))
				m.PrimaryPart = belt
				tag(m, "Shop", { ShopType = id })
			elseif id == "NPC_Bram" then
				local m = M(services, id)
				local body = P({ Name = "Body", Size = Vector3.new(4, 5, 2.5), CFrame = cf * CFrame.new(0, 3.6, 0), Color = Color3.fromRGB(120, 90, 60), Parent = m })
				P({ Name = "Head", Shape = Enum.PartType.Ball, Size = Vector3.new(3, 3, 3), CFrame = cf * CFrame.new(0, 7.6, 0), Color = Color3.fromRGB(240, 200, 160), Parent = m })
				P({ Name = "Beard", Size = Vector3.new(2.6, 2.4, 1), CFrame = cf * CFrame.new(0, 6.4, -1.2), Color = Color3.fromRGB(245, 245, 245), Parent = m })
				P({ Name = "Hat", Size = Vector3.new(3.6, 1, 3.6), CFrame = cf * CFrame.new(0, 9.4, 0), Color = Color3.fromRGB(60, 120, 60), Parent = m })
				sign(m, (cf * CFrame.new(0, 12, 0)).Position, V, "Grandpa Bram", 8, 2.4, Color3.fromRGB(30, 36, 51), Color3.fromRGB(253, 230, 138))
				m.PrimaryPart = body
				tag(m, "NPC", { NpcId = "Bram" })
			elseif id == "Leaderboards" then
				local m = M(services, id)
				for k, title in { "Trees Cut", "Highest Damage" } do
					local bpos = (cf * CFrame.new((k - 1.5) * 12, 7, 0)).Position
					local b = sign(m, bpos, V, title, 10, 12, Color3.fromRGB(23, 28, 41), Color3.fromRGB(250, 204, 21))
					b.CanCollide = true
					tag(b, "Leaderboard", { Board = k == 1 and "TreesCut" or "HighestHit" })
				end
				m.PrimaryPart = m:FindFirstChild("Sign")
			elseif id == "ArenaPortal" then
				local m = M(services, id)
				local pc = cf * CFrame.new(0, 9, 0)
				for k = 0, 15 do
					local a2 = k / 16 * math.pi * 2
					P({ Name = "Ring", Size = Vector3.new(2, 3.4, 2), CFrame = pc * CFrame.new(math.cos(a2) * 8, math.sin(a2) * 8, 0) * CFrame.Angles(0, 0, a2), Color = Color3.fromRGB(109, 40, 217), Parent = m })
				end
				local inner = P({ Name = "Portal", Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.6, 14, 14), CFrame = pc * CFrame.Angles(0, rad(90), 0), Color = Color3.fromRGB(168, 85, 247), Material = Enum.Material.Neon, Transparency = 0.35, CanCollide = false, Parent = m })
				sign(m, (cf * CFrame.new(0, 20, 0)).Position, V, "Chop Arena · PvP", 14, 3, Color3.fromRGB(30, 36, 51), Color3.fromRGB(216, 180, 254))
				m.PrimaryPart = inner
				tag(m, "ArenaPortal")
			elseif id == "WarpHub" then
				warpStone(services, pos, 0, Color3.fromRGB(96, 165, 250))
			end
		end

		-- Spawn north of the altar, facing the forest gate.
		local spawnPos = hubPoint(0, 30, 1.6)
		local spawn = Instance.new("SpawnLocation")
		spawn.Name = "VillageSpawn"
		spawn.Anchored = true
		spawn.Size = Vector3.new(12, 1, 12)
		spawn.CFrame = CFrame.new(spawnPos)
		spawn.Material = Enum.Material.Plastic
		spawn.TopSurface = Enum.SurfaceType.Studs
		spawn.Color = Color3.fromRGB(200, 190, 170)
		spawn.Neutral = true
		spawn.Duration = 0
		local decal = spawn:FindFirstChildOfClass("Decal")
		if decal then decal:Destroy() end
		spawn.Parent = village

		-- Forest gate (north edge) → Sunny Meadow.
		local gate = M(village, "ForestGate")
		local gatePos = Vector3.new(L.hub.gate.X, Y, L.hub.gate.Z)
		local gcf = CFrame.lookAt(gatePos, gatePos + INWARD)
		for _, x in { -15, 15 } do
			P({ Name = "Pillar", Shape = Enum.PartType.Cylinder, Size = Vector3.new(24, 4, 4), CFrame = gcf * CFrame.new(x, 12, 0) * CFrame.Angles(0, 0, rad(90)), Color = Color3.fromRGB(115, 78, 46), Parent = gate })
		end
		P({ Name = "Beam", Size = Vector3.new(38, 3, 3.5), CFrame = gcf * CFrame.new(0, 23, 0), Color = Color3.fromRGB(95, 62, 38), Parent = gate })
		sign(gate, (gcf * CFrame.new(0, 27, 0)).Position, V, "Forest Gate → Sunny Meadow", 30, 4, Color3.fromRGB(30, 36, 51), Color3.fromRGB(190, 242, 100))
		local trigger = P({ Name = "RunTrigger", Size = Vector3.new(30, 20, 4), CFrame = gcf * CFrame.new(0, 10, 0), Transparency = 1, CanCollide = false, Parent = gate })
		tag(trigger, "ForestGate")
		gate.PrimaryPart = trigger

		-- Hub wall: openings at the forest gate (north) and the dock (south).
		local decor = F(village, "Decor")
		ringWall(decor, V, HUB.radius - 2.5, Y, 10, 4, Color3.fromRGB(150, 140, 125), "HubWall", { { math.pi, 17 }, { 0, 12 } }, 20)

		-- Dock (south).
		local dock = M(village, "Dock")
		local dz0 = V.Z + HUB.radius - 6
		P({ Name = "Deck", Size = Vector3.new(20, 1, 80), CFrame = CFrame.new(V.X, Y + 0.4, dz0 + 40), Color = Color3.fromRGB(160, 110, 65), Parent = dock })
		for z = 8, 78, 14 do
			for _, x in { -9, 9 } do
				P({ Name = "Post", Size = Vector3.new(1.6, 16, 1.6), CFrame = CFrame.new(V.X + x, Y - 5, dz0 + z), Color = Color3.fromRGB(105, 70, 42), Parent = dock })
			end
		end
		for _, x in { -9, 9 } do
			local lamp = P({ Name = "Lantern", Size = Vector3.new(1.6, 1.6, 1.6), CFrame = CFrame.new(V.X + x, Y + 4.2, dz0 + 78), Color = Color3.fromRGB(255, 200, 90), Material = Enum.Material.Neon, CanCollide = false, Parent = dock })
			local light = Instance.new("PointLight")
			light.Color = lamp.Color
			light.Range = 18
			light.Parent = lamp
		end
		dock.PrimaryPart = dock.Deck

		-- Lamps along the main path.
		for z = -150, 170, 40 do
			if math.abs(z) > 40 then
				for _, x in { -16, 16 } do
					local pos = Vector3.new(V.X + x, Y + 0.9, V.Z + z)
					P({ Name = "LampPost", Size = Vector3.new(1, 12, 1), CFrame = CFrame.new(pos + Vector3.new(0, 6, 0)), Color = Color3.fromRGB(60, 60, 70), Parent = decor })
					local lamp = P({ Name = "Lamp", Size = Vector3.new(2, 2, 2), CFrame = CFrame.new(pos + Vector3.new(0, 12.6, 0)), Color = Color3.fromRGB(255, 220, 150), Material = Enum.Material.Neon, CanCollide = false, Parent = decor })
					local light = Instance.new("PointLight")
					light.Color = Color3.fromRGB(255, 210, 150)
					light.Range = 22
					light.Brightness = 1.2
					light.Parent = lamp
				end
			end
		end
	end)
end

-- ========== zones ==========
local function rotVeins(m, pos, tw, trunkH, rng, trunk)
	for i = 1, 3 do
		local a = i / 3 * math.pi * 2
		P({
			Name = "RotVein",
			Size = Vector3.new(0.4, trunkH * 0.8, 0.4),
			CFrame = CFrame.new(pos + Vector3.new(math.cos(a) * tw * 0.52, trunkH * 0.45, math.sin(a) * tw * 0.52)) * CFrame.Angles(0, 0, rng:NextNumber(-0.25, 0.25)),
			Color = Zones.RotColor,
			Material = Enum.Material.Neon,
			CanCollide = false,
			Parent = m,
		})
	end
	local light = Instance.new("PointLight")
	light.Color = Zones.RotColor
	light.Range = 16
	light.Brightness = 1.5
	light.Parent = trunk
end

local function makeTree(parent, zone, tier, pos, rng, tagName)
	local m = TreeKit.Build(TreeKit.Pick(zone.id, rng), pos, tier, rng)
	if tier == 6 then
		local h = 10 + tier * 6
		rotVeins(m, pos, 1.4 + tier * 0.45, h * 0.55, rng, m.PrimaryPart)
	end
	m:SetAttribute("Zone", zone.id)
	m:SetAttribute("Tier", tier)
	CollectionService:AddTag(m, tagName or "Tree")
	m.Parent = parent
	return m
end

-- Torii ZoneGate at the top of the stairs; RotBarrier blocks until the player unlocks toZone.
local function gate(parent, pos, fromZone, toZone, accent)
	local m = M(parent, "ZoneGate")
	local cf = CFrame.lookAt(pos, pos + SOUTH)
	local red = Color3.fromRGB(196, 40, 28)
	for _, x in { -17, 17 } do
		P({ Name = "Pillar", Shape = Enum.PartType.Cylinder, Size = Vector3.new(26, 3.5, 3.5), CFrame = cf * CFrame.new(x, 13, 0) * CFrame.Angles(0, 0, rad(90)), Color = red, Parent = m })
	end
	P({ Name = "Kasagi", Size = Vector3.new(46, 3, 5), CFrame = cf * CFrame.new(0, 27.5, 0), Color = Color3.fromRGB(27, 42, 53), Parent = m })
	P({ Name = "Nuki", Size = Vector3.new(40, 2, 3), CFrame = cf * CFrame.new(0, 22, 0), Color = red, Parent = m })
	P({ Name = "Gem", Size = Vector3.new(3, 3, 1), CFrame = cf * CFrame.new(0, 24.5, -1.6), Color = accent, Material = Enum.Material.Neon, CanCollide = false, Parent = m })
	local barrier = P({ Name = "RotBarrier", Size = Vector3.new(31, 20, 1), CFrame = cf * CFrame.new(0, 10, 0), Color = Zones.RotColor, Material = Enum.Material.Neon, Transparency = 0.45, CanCollide = true, Parent = m })
	sign(m, (cf * CFrame.new(0, 32, 0)).Position, (cf * CFrame.new(0, 0, -30)).Position, "Rot Gate • Defeat Boss to Unlock → " .. Zones.List[toZone].name, 32, 3.5, Color3.fromRGB(30, 20, 40), Color3.fromRGB(216, 180, 254))
	m.PrimaryPart = barrier
	tag(m, "ZoneGate", { FromZone = fromZone, ToZone = toZone, Open = false })
	return m
end

local function shrine(parent, pos, zoneId, accent)
	local m = M(parent, "Shrine")
	disk(m, pos, 9, 1.5, pos.Y + 1.5, Color3.fromRGB(150, 150, 155), Enum.Material.Plastic, "Base")
	for _, o in { { -5, -5 }, { 5, -5 }, { -5, 5 }, { 5, 5 } } do
		P({ Name = "Post", Size = Vector3.new(1.4, 10, 1.4), CFrame = CFrame.new(pos + Vector3.new(o[1], 6.5, o[2])), Color = Color3.fromRGB(160, 40, 40), Parent = m })
	end
	P({ Name = "Roof", Size = Vector3.new(16, 1.6, 16), CFrame = CFrame.new(pos + Vector3.new(0, 12, 0)), Color = Color3.fromRGB(60, 50, 50), Parent = m })
	local crystal = P({ Name = "Crystal", Size = Vector3.new(2.5, 4, 2.5), CFrame = CFrame.new(pos + Vector3.new(0, 4.5, 0)) * CFrame.Angles(0, rad(45), 0), Color = Color3.fromRGB(90, 90, 100), Material = Enum.Material.Glass, Parent = m })
	crystal:SetAttribute("LitColor", accent)
	m.PrimaryPart = crystal
	tag(m, "Shrine", { Zone = zoneId, Lit = false })
	return m
end

local function bossArena(parent, pos, zone, guardianOffset)
	local m = M(parent, "BossArena")
	local c = zone.colors.ground
	disk(m, pos, 40, 0.6, pos.Y + 0.3, Color3.new(c.R * 0.85, c.G * 0.85, c.B * 0.85), Enum.Material.Plastic, "Floor")
	for k = 0, 15 do
		local a = k / 16 * math.pi * 2
		P({ Name = "Stone", Size = Vector3.new(3, 5 + (k % 3) * 2, 3), CFrame = CFrame.new(pos + Vector3.new(math.sin(a) * 38, 3, math.cos(a) * 38)) * CFrame.Angles(0, a, 0.1), Color = STONE, Parent = m })
	end
	m.PrimaryPart = m.Floor
	m:SetAttribute("GuardianOffset", guardianOffset)
	tag(m, "BossArena", { Zone = zone.id, Boss = zone.boss })
	return m
end

local function nest(parent, pos, zone, index)
	local m = M(parent, "Nest" .. index)
	for k = 0, 9 do
		local a = k / 10 * math.pi * 2
		P({ Name = "Twig", Size = Vector3.new(1, 1, 4), CFrame = CFrame.new(pos + Vector3.new(math.sin(a) * 4, 0.6, math.cos(a) * 4)) * CFrame.Angles(0, a + 1.4, 0.2), Color = Color3.fromRGB(120, 85, 50), CanCollide = false, Parent = m })
	end
	local base = disk(m, pos, 3.6, 0.6, pos.Y + 0.4, Color3.fromRGB(150, 110, 70), Enum.Material.Fabric, "Bed")
	for k = 1, 3 do
		local a = k / 3 * math.pi * 2
		P({ Name = "EggSpot", Shape = Enum.PartType.Ball, Size = Vector3.new(1.6, 2, 1.6), CFrame = CFrame.new(pos + Vector3.new(math.sin(a) * 1.4, 1.3, math.cos(a) * 1.4)), Color = zone.colors.accent, CanCollide = false, Parent = m })
	end
	m.PrimaryPart = base
	tag(m, "Nest", { Zone = zone.id, EggType = zone.egg })
	return m
end

-- Small non-collidable dressing; spot(minR) returns a free ground point or nil.
local function decorZone(folder, zone, rng, spot)
	local y = zone.y
	for _ = 1, 16 do
		local p = spot(10)
		if p then
			local s = rng:NextNumber(2, 6)
			P({ Name = "Rock", Size = Vector3.new(s * 1.3, s, s), CFrame = CFrame.new(p + Vector3.new(0, s * 0.35, 0)) * CFrame.Angles(rng:NextNumber(-0.4, 0.4), rng:NextNumber(0, 3), rng:NextNumber(-0.4, 0.4)), Color = STONE, Parent = folder })
		end
	end
	local function scatter(count, minR, fn)
		for _ = 1, count do
			local p = spot(minR)
			if p then fn(Vector3.new(p.X, y, p.Z)) end
		end
	end
	if zone.id == 1 then
		local petals = { Color3.fromRGB(255, 99, 99), Color3.fromRGB(255, 214, 79), Color3.fromRGB(255, 255, 255), Color3.fromRGB(196, 132, 252) }
		scatter(70, 6, function(p)
			P({ Name = "Flower", Size = Vector3.new(1.2, 0.6, 1.2), CFrame = CFrame.new(p + Vector3.new(0, 0.3, 0)), Color = petals[rng:NextInteger(1, #petals)], CanCollide = false, CanQuery = false, Parent = folder })
		end)
		scatter(20, 8, function(p)
			local s = rng:NextNumber(3, 5)
			P({ Name = "Bush", Size = Vector3.new(s * 1.4, s, s * 1.4), CFrame = CFrame.new(p + Vector3.new(0, s * 0.4, 0)), Color = zone.colors.leaves[rng:NextInteger(1, #zone.colors.leaves)], CanCollide = false, Parent = folder })
		end)
	elseif zone.id == 2 then
		scatter(12, 10, function(p)
			local l = rng:NextNumber(8, 14)
			P({ Name = "FallenLog", Size = Vector3.new(l, 2.4, 2.4), CFrame = CFrame.new(p + Vector3.new(0, 1.2, 0)) * CFrame.Angles(0, rng:NextNumber(0, 3), 0), Color = zone.colors.trunk, Parent = folder })
		end)
		scatter(40, 6, function(p)
			local s = rng:NextNumber(3, 6)
			P({ Name = "LeafPile", Size = Vector3.new(s, 0.4, s * 0.8), CFrame = CFrame.new(p + Vector3.new(0, 0.2, 0)) * CFrame.Angles(0, rng:NextNumber(0, 3), 0), Color = zone.colors.leaves[rng:NextInteger(1, #zone.colors.leaves)], CanCollide = false, CanQuery = false, Parent = folder })
		end)
	elseif zone.id == 3 then
		scatter(30, 6, function(p)
			local s = rng:NextNumber(1, 2.5)
			P({ Name = "GlowShroom", Shape = Enum.PartType.Ball, Size = Vector3.new(s, s * 0.7, s), CFrame = CFrame.new(p + Vector3.new(0, s * 0.3, 0)), Color = zone.colors.leaves[rng:NextInteger(1, #zone.colors.leaves)], Material = Enum.Material.Neon, CanCollide = false, CanQuery = false, Parent = folder })
		end)
	elseif zone.id == 4 then
		scatter(12, 8, function(p)
			P({ Name = "StoneLantern", Size = Vector3.new(2, 5, 2), CFrame = CFrame.new(p + Vector3.new(0, 2.5, 0)), Color = STONE, Parent = folder })
			P({ Name = "LanternLight", Size = Vector3.new(1.4, 1.4, 1.4), CFrame = CFrame.new(p + Vector3.new(0, 5.7, 0)), Color = Color3.fromRGB(255, 200, 120), Material = Enum.Material.Neon, CanCollide = false, Parent = folder })
		end)
	elseif zone.id == 5 then
		scatter(25, 6, function(p)
			local h = rng:NextNumber(4, 9)
			P({ Name = "Shoot", Size = Vector3.new(0.8, h, 0.8), CFrame = CFrame.new(p + Vector3.new(0, h / 2, 0)), Color = zone.colors.trunk, CanCollide = false, Parent = folder })
		end)
	elseif zone.id == 6 then
		scatter(25, 8, function(p)
			local s = rng:NextNumber(4, 8)
			P({ Name = "SnowMound", Size = Vector3.new(s * 1.4, s * 0.5, s), CFrame = CFrame.new(p + Vector3.new(0, s * 0.15, 0)) * CFrame.Angles(0, rng:NextNumber(0, 3), 0), Color = Color3.fromRGB(248, 250, 255), CanCollide = false, Parent = folder })
		end)
	elseif zone.id == 7 then
		scatter(25, 6, function(p)
			local h = rng:NextNumber(3, 8)
			P({ Name = "Shard", Size = Vector3.new(1.5, h, 1.5), CFrame = CFrame.new(p + Vector3.new(0, h / 2 - 0.5, 0)) * CFrame.Angles(rng:NextNumber(-0.3, 0.3), rng:NextNumber(0, 3), rng:NextNumber(-0.3, 0.3)), Color = zone.colors.leaves[rng:NextInteger(1, #zone.colors.leaves)], Material = Enum.Material.Neon, CanCollide = false, Parent = folder })
		end)
	elseif zone.id == 8 then
		scatter(16, 8, function(p)
			P({ Name = "GoldLamp", Size = Vector3.new(1.4, 6, 1.4), CFrame = CFrame.new(p + Vector3.new(0, 3, 0)), Color = Color3.fromRGB(245, 205, 48), Parent = folder })
			P({ Name = "GoldLight", Size = Vector3.new(2, 2, 2), CFrame = CFrame.new(p + Vector3.new(0, 7, 0)), Color = Color3.fromRGB(255, 240, 170), Material = Enum.Material.Neon, CanCollide = false, Parent = folder })
		end)
	end
end

function MapBuilder.BuildZone(index)
	withHistory("Chop a Tree: Zone " .. index, function()
		local L = MapBuilder.Layout()
		local Z = L.zones[index]
		local zone = Z.def
		local y = Z.y
		local wilds = F(mapRoot(), "Wilds")
		local zoneName = string.format("Zone%d_%s", index, zone.key)
		for _, old in wilds:GetChildren() do
			if old.Name ~= zoneName and tonumber(old.Name:match("^Zone(%d+)_")) == index then old:Destroy() end
		end
		local root = fresh(wilds, zoneName)
		root:SetAttribute("Zone", index)
		local rng = Random.new(1000 + index)
		local folders = {}
		for _, name in { "Ground", "Trees", "ChestSpots", "Nests", "Shrine", "BossArena", "ZoneGate", "WarpStone", "Spawn", "Boundary", "Decor", "Secrets" } do
			folders[name] = F(root, name)
		end
		local mid = (Z.inner + Z.outer) / 2

		-- Trail along the south axis.
		local gc = zone.colors.ground
		local trailColor = Color3.new(gc.R * 0.75, gc.G * 0.65, gc.B * 0.55)
		local lift = Vector3.new(0, 0.25, 0)
		pathSegments(folders.Ground, { Z.trailStart + lift, Z.trailEnd + lift }, 14, 0.5, trailColor, Enum.Material.Plastic, "Trail")

		-- Spawn + warp stone + welcome sign.
		local spawnPos = Z.trailStart + INWARD * 14
		local side = Vector3.xAxis
		local sp = P({ Name = "ZoneSpawn", Size = Vector3.new(8, 1, 8), CFrame = CFrame.new(spawnPos + Vector3.new(0, 0.5, 0)), Transparency = 1, CanCollide = false, Parent = folders.Spawn })
		tag(sp, "ZoneSpawn", { Zone = index })
		local warpPos = spawnPos + side * 18
		warpStone(folders.WarpStone, warpPos, index, zone.colors.accent)
		local signPos = Z.trailStart + INWARD * 4 - side * 16
		P({ Name = "SignPost", Size = Vector3.new(1, 10, 1), CFrame = CFrame.new(signPos + Vector3.new(0, 5, 0)), Color = Color3.fromRGB(110, 75, 45), Parent = folders.Decor })
		sign(folders.Decor, signPos + Vector3.new(0, 12, 0), Z.entry + SOUTH * 40, string.format("Zone %d · %s", index, zone.name), 16, 7)

		-- Hedge along the outer rim (meadow: coast wall in BuildWorld), opening at the south gate.
		if index > 1 then
			ringWall(folders.Boundary, Vector3.zero, Z.outer - 2.5, y - 0.5, 8.5, 5, Zones.RotColor:Lerp(zone.colors.ground:Lerp(Color3.new(), 0.3), 0.8), "RotHedge", { { 0, GATE_HALF } }, 30)
		end

		-- Gate to the next ring at the top of the stairs.
		if Z.exit then
			local N = L.zones[index + 1]
			gate(folders.ZoneGate, Vector3.new(0, N.y, Z.exit.Z - 3), index, index + 1, zone.colors.accent)
		end

		-- Boss arena east of the trail (Lumora plateau: centre), shrine beside it.
		local arenaPos, shrinePos, offset
		if index == #Zones.List then
			arenaPos = Vector3.new(0, y, 0)
			shrinePos = polar(Vector3.zero, 70, rad(70), y)
			offset = Vector3.new(26, 0, 0)
		else
			local a = rad(75)
			arenaPos = polar(Vector3.zero, mid, a, y)
			shrinePos = polar(Vector3.zero, mid, a + 58 / mid, y)
			offset = (polar(Vector3.zero, mid, a - 0.1, y) - arenaPos).Unit * 22
		end
		bossArena(folders.BossArena, arenaPos, zone, offset)
		shrine(folders.Shrine, shrinePos, index, zone.colors.accent)

		-- Lumora tree + Realm Gate on the plateau.
		if index == #Zones.List then
			local lum = M(folders.Decor, "Lumora")
			P({ Name = "Trunk", Size = Vector3.new(14, 80, 14), CFrame = CFrame.new(0, y + 40, 0), Color = zone.colors.trunk, Parent = lum })
			for k = 1, 3 do
				P({ Name = "Root", Size = Vector3.new(4, 4, 22), CFrame = CFrame.new(0, y + 2, 0) * CFrame.Angles(0, k * 2.1, 0) * CFrame.new(0, 0, 12), Color = zone.colors.trunk, Parent = lum })
			end
			for k = 1, 4 do
				P({ Name = "Crown", Size = Vector3.new(76 - k * 12, 16, 76 - k * 12), CFrame = CFrame.new(0, y + 72 + k * 11, 0) * CFrame.Angles(0, k * 0.4, 0), Color = k % 2 == 0 and zone.colors.leaves[2] or zone.colors.leaves[1], CanCollide = false, Parent = lum })
			end
			local glow = P({ Name = "Glow", Shape = Enum.PartType.Ball, Size = Vector3.new(10, 10, 10), CFrame = CFrame.new(0, y + 125, 0), Color = Color3.fromRGB(255, 240, 170), Material = Enum.Material.Neon, CanCollide = false, Parent = lum })
			local light = Instance.new("PointLight")
			light.Color = glow.Color
			light.Range = 60
			light.Brightness = 2
			light.Parent = glow
			tag(lum, "Lumora")
			local far = polar(Vector3.zero, Z.outer - 22, math.pi, y + 16)
			local rg = M(folders.Secrets, "RealmGate")
			local rcf = CFrame.lookAt(far, Vector3.new(0, far.Y, 0))
			for k = 0, 19 do
				local a = k / 20 * math.pi * 2
				P({ Name = "Ring", Size = Vector3.new(2.5, 4.5, 2.5), CFrame = rcf * CFrame.new(math.cos(a) * 13, math.sin(a) * 13, 0) * CFrame.Angles(0, 0, a), Color = Color3.fromRGB(255, 215, 100), Material = Enum.Material.Neon, Parent = rg })
			end
			sign(rg, (rcf * CFrame.new(0, 19, 0)).Position, Vector3.zero, "Realm Gate · Realm 2 (Coming Soon)", 22, 3.5, Color3.fromRGB(30, 36, 51), Color3.fromRGB(255, 230, 150))
			tag(rg, "RealmGate", { Realm = 2, Open = false })
		end

		-- Free-space test for trees/chests/nests/decor.
		local blocked = { { Z.entry, 40 }, { arenaPos, 52 }, { shrinePos, 18 }, { warpPos, 10 }, { signPos, 6 } }
		if Z.exit then table.insert(blocked, { Z.stairFoot, 40 }) end
		if index == #Zones.List then table.insert(blocked, { polar(Vector3.zero, Z.outer - 22, math.pi, y), 22 }) end
		local trees = {}
		local function free(p, margin)
			local r = flat(p).Magnitude
			if r < Z.inner + margin + 3 or r > Z.outer - margin - 6 then return false end
			if flat(p - HUB.center).Magnitude < HUB.radius + margin + 8 then return false end
			for _, b in blocked do
				if flat(p - b[1]).Magnitude < b[2] + margin then return false end
			end
			if distToSegment(p, Z.entry, Z.trailEnd) < 12 + margin then return false end
			for _, t in trees do
				if flat(p - t.p).Magnitude < t.r + margin then return false end
			end
			return true
		end
		local function ringPoint()
			local r = math.sqrt(rng:NextNumber() * (Z.outer ^ 2 - Z.inner ^ 2) + Z.inner ^ 2)
			local a = rng:NextNumber(-math.pi, math.pi)
			return polar(Vector3.zero, r, a, y)
		end

		-- Trees: ~1 per 1600 studs² (140–260), tier rises with distance around the ring.
		local area = math.pi * (Z.outer ^ 2 - Z.inner ^ 2)
		local target = math.clamp(math.floor(area / 1600), 140, 260)
		local tries = 0
		while #trees < target and tries < 20000 do
			tries += 1
			local p = ringPoint()
			local tier = math.clamp(math.floor(depthOf(p) * 6 * 1.15 + rng:NextNumber(-0.8, 0.8)) + 1, 1, 6)
			local size = 4 + tier * 1.6
			if free(p, size) then
				makeTree(folders.Trees, zone, tier, p, rng)
				table.insert(trees, { p = p, r = size })
			end
		end
		-- 10 chest spots (deeper = better).
		local chests = {}
		tries = 0
		while #chests < 10 and tries < 5000 do
			tries += 1
			local p = ringPoint()
			local okSpacing = true
			for _, c in chests do
				if flat(p - c).Magnitude < 34 then okSpacing = false end
			end
			if okSpacing and free(p, 3) then
				table.insert(chests, p)
				local mk = disk(folders.ChestSpots, p, 3, 0.3, y + 0.3, Color3.fromRGB(255, 214, 79), Enum.Material.Neon, "ChestSpot" .. #chests)
				mk.Transparency = 0.5
				mk.CanCollide = false
				tag(mk, "ChestSpot", { Zone = index, Depth = depthOf(p) })
			end
		end
		-- 2 nests in the far half.
		local nests = 0
		tries = 0
		while nests < 2 and tries < 5000 do
			tries += 1
			local p = ringPoint()
			if depthOf(p) > 0.4 and free(p, 8) then
				nests += 1
				nest(folders.Nests, p, zone, nests)
				table.insert(trees, { p = p, r = 14 })
			end
		end
		decorZone(folders.Decor, zone, rng, function(minR)
			for _ = 1, 30 do
				local p = ringPoint()
				if free(p, minR * 0.5) then return p end
			end
			return nil
		end)
		root:SetAttribute("TreeTarget", target)
	end)
end

function MapBuilder.BuildAllZones()
	for i = 1, #Zones.List do
		MapBuilder.BuildZone(i)
	end
end

-- Studded-rock mountain range around the island and the hub, plus an invisible wall behind it.
-- Template: ServerStorage.MapAssets.StuddedRock (Creator Store model, scripts removed, pivot at
-- the bottom centre). Gaps: the dock (south of the hub) and the boat ride curve (TravelService).
function MapBuilder.BuildMountains()
	withHistory("Chop a Tree: Mountains", function()
		local template = ServerStorage.MapAssets.StuddedRock
		local root = fresh(mapRoot(), "Mountains")
		local barrier = F(root, "Barrier")
		local islandR = Zones.List[1].outer + 25
		local hubR = HUB.radius + 25
		local d = flat(HUB.center).Magnitude
		-- Boat curve (dock → bend → shore), sampled. Copy of Config.Story
		-- MapBoatBend/MapBoatShore (Story cannot load from the command bar); keep them in sync.
		local Story = { MapBoatBend = Vector3.new(540, 6, 1010), MapBoatShore = Vector3.new(210, 5.5, 866) }
		local dock = Vector3.new(HUB.center.X, 5, HUB.center.Z + HUB.radius + 49)
		local boat = {}
		for i = 0, 40 do
			local t = i / 40
			local p = dock * (1 - t) ^ 2 + Story.MapBoatBend * (2 * (1 - t) * t) + Story.MapBoatShore * t ^ 2
			table.insert(boat, p)
		end
		local function blocked(p)
			for _, b in boat do
				if flat(p - b).Magnitude < 40 then return true end
			end
			return math.abs(p.X - HUB.center.X) < 45 and p.Z > HUB.center.Z + 100 -- dock
		end
		local rng = Random.new(1010)
		local function range(center, r, inside)
			local n = math.ceil(2 * math.pi * r / 60)
			for i = 0, n - 1 do
				local a = (i + rng:NextNumber(-0.3, 0.3)) / n * 2 * math.pi
				for row = 0, 1 do -- front rock + a taller peak behind
					local p = polar(center, r + row * 35 + rng:NextNumber(-8, 8), a, -6)
					if not inside(p) and not blocked(p) then
						local m = template:Clone()
						m:ScaleTo(rng:NextNumber(8, 12) * (row == 1 and 1.6 or 1))
						if rng:NextNumber() < 0.5 then -- alternate two greys so neighbouring rocks read apart
							for _, part in m:GetDescendants() do
								if part:IsA("BasePart") then part.Color = Color3.fromRGB(140, 138, 135) end
							end
						end
						m:PivotTo(CFrame.new(p) * CFrame.Angles(0, rng:NextNumber(0, 2 * math.pi), 0))
						m.Parent = root
					end
				end
			end
		end
		range(Vector3.zero, islandR, function(p) return flat(p - HUB.center).Magnitude < hubR + 20 end)
		range(HUB.center, hubR, function(p) return flat(p).Magnitude < islandR + 20 end)
		-- Walls meet where the two circles cross (law of cosines); the hub wall also opens at the dock.
		local wi, wh = islandR - 15, hubR - 15
		local islandHalf = math.acos((wi ^ 2 + d ^ 2 - wh ^ 2) / (2 * wi * d)) * wi
		local hubHalf = math.acos((wh ^ 2 + d ^ 2 - wi ^ 2) / (2 * wh * d)) * wh
		ringWall(barrier, Vector3.zero, wi, -10, 90, 4, Color3.new(), "MountainWall", { { 0, islandHalf } }, 40)
		ringWall(barrier, HUB.center, wh, -10, 90, 4, Color3.new(), "MountainWall", { { math.pi, hubHalf }, { 0, 15 } }, 40)
		for _, wall in barrier:GetChildren() do
			wall.Transparency = 1
			wall.CanQuery = false
		end
	end)
end

function MapBuilder.BuildAll()
	MapBuilder.BuildWorld()
	MapBuilder.BuildMountains()
	MapBuilder.BuildVillage()
	MapBuilder.BuildAllZones()
end

-- Tag counts + part totals (overall and per zone).
function MapBuilder.Report()
	local out = {}
	for _, t in { "Tree", "PreviewTree", "ChestSpot", "Nest", "ZoneGate", "WarpStone", "ZoneSpawn", "BossArena", "Shrine", "PlayerBase", "GardenSlot", "Shop", "NPC", "ForestGate", "ArenaPortal", "RealmGate", "Lumora", "Leaderboard", "ChestAltar" } do
		local count = 0
		for _, inst in CollectionService:GetTagged(t) do
			if inst:IsDescendantOf(mapRoot()) then count += 1 end
		end
		table.insert(out, t .. "=" .. count)
	end
	local function parts(folder)
		local n = 0
		for _, d in folder:GetDescendants() do
			if d:IsA("BasePart") then n += 1 end
		end
		return n
	end
	table.insert(out, "Parts=" .. parts(mapRoot()))
	for _, child in mapRoot():GetChildren() do
		table.insert(out, child.Name .. "=" .. parts(child))
	end
	local wilds = mapRoot():FindFirstChild("Wilds")
	for _, z in (wilds and wilds:GetChildren() or {}) do
		table.insert(out, z.Name .. "=" .. parts(z))
	end
	return table.concat(out, ", ")
end

return MapBuilder
