--!nocheck
-- ตัวสร้างแมพ Chop a Tree (ใช้ตอนแก้ใน Studio เท่านั้น ไม่รันในเกม)
-- วางไว้ที่ ServerStorage.MapTools.MapBuilder แล้วเรียกจาก Command Bar:
--   local B = require(game.ServerStorage.MapTools.MapBuilder:Clone())
--   B.BuildAll()          -- หรือ B.BuildWorld(), B.BuildVillage(), B.BuildZone(1) …
-- สุ่มด้วย seed คงที่ → สร้างซ้ำได้ผลเหมือนเดิม
-- ข้อมูลโซนอ่านจาก ReplicatedStorage.Shared.Config.Zones (ไฟล์เดียวกับที่เกมใช้)

local CollectionService = game:GetService("CollectionService")
local ChangeHistoryService = game:GetService("ChangeHistoryService")
local Lighting = game:GetService("Lighting")
local ServerStorage = game:GetService("ServerStorage")

local Zones = require(game.ReplicatedStorage.Shared.Config.Zones:Clone())

local MapBuilder = {}

-- ========== ตัวช่วย ==========
local function rad(d)
	return math.rad(d)
end

local function flat(v)
	return Vector3.new(v.X, 0, v.Z)
end

local function P(props)
	local p = Instance.new("Part")
	p.Anchored = true
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Material = Enum.Material.SmoothPlastic
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

-- จานกลมแนวนอน (Cylinder ตั้งตรง) — topY = ความสูงผิวบน
local function disk(parent, center, radius, height, topY, color, material, name)
	return P({
		Name = name or "Disk",
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(height, radius * 2, radius * 2),
		CFrame = CFrame.new(center.X, topY - height / 2, center.Z) * CFrame.Angles(0, 0, rad(90)),
		Color = color,
		Material = material or Enum.Material.SmoothPlastic,
		Parent = parent,
	})
end

-- ป้ายมีข้อความ หันหน้าไปที่ lookAt
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

-- เส้นทางจากจุดหลายจุด (ผิวบนอยู่ที่ y ของจุด)
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
				Material = material or Enum.Material.Ground,
				Parent = parent,
			})
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

-- ========== ทวีปตัว S + รากขึ้นเกาะลอย ==========
function MapBuilder.Layout()
	local L = { zones = {}, roads = {} }
	local function center(col, row, y)
		return Vector3.new((col - 1.5) * Zones.GridStep, y, (row - 0.5) * Zones.GridStep)
	end
	local V = Zones.Village
	L.village = { center = center(V.col, V.row, 0), radius = V.radius }
	for i, z in Zones.List do
		L.zones[i] = { def = z, y = z.y, radius = z.halfSize, halfDepth = i == 8 and z.halfSize or Zones.GroundHalfDepth, center = center(z.col, z.row, z.y) }
	end
	local previous = L.village
	for i = 1, 7 do
		local z = L.zones[i]
		local dir = flat(z.center - previous.center).Unit
		local a = previous.center + dir * (math.abs(dir.Z) > 0.5 and previous.halfDepth or previous.radius)
		local b = z.center - dir * (math.abs(dir.Z) > 0.5 and z.halfDepth or z.radius)
		if i == 1 then a = Vector3.new(a.X - 4, 0.9, a.Z) end
		previous.exit, z.entry = a, b
		z.trailStart = b + dir * 36
		local roadStart = i == 1 and a or (a - dir * 34)
		if i > 1 then previous.trailEnd = roadStart end
		table.insert(L.roads, { from = i - 1, to = i, points = { roadStart, b + dir * 34 }, bridge = i == 4 })
		previous = z
	end
	local z7, z8 = L.zones[7], L.zones[8]
	z7.exit = z7.center + Vector3.new(0, 0, z7.halfDepth)
	z8.entry = z8.center + Vector3.new(0, 0, z8.radius - 6)
	-- Spiral stays outside the island's solid rim until the final landing.
	local axis = flat(z7.center) + Vector3.new(0, 0, 362)
	local pts = { z7.exit }
	for k = 0, 384 do
		local t = k / 384
		local a = math.pi + t * math.pi * 8
		table.insert(pts, axis + Vector3.new(math.sin(a) * 96, z7.y + (z8.y - z7.y) * t, math.cos(a) * 96))
	end
	table.insert(pts, z8.entry)
	table.insert(L.roads, { from = 7, to = 8, points = pts, sky = true, axis = axis })
	return L
end

function MapBuilder.RoadPoints(r)
	return r.points
end

local function roundedGround(parent, center, halfSize, bottom, top, color, material, name, entry, halfDepth)
	local corner = 36
	local h = top - bottom
	local inward = flat(center - entry).Unit
	local tangent = Vector3.new(inward.Z, 0, -inward.X)
	local a = entry - center - inward * 5 - tangent * 20
	local b = entry - center + inward * 34 + tangent * 20
	local nx0, nx1 = math.min(a.X, b.X), math.max(a.X, b.X)
	local nz0, nz1 = math.min(a.Z, b.Z), math.max(a.Z, b.Z)
	local function rect(x0, x1, z0, z1)
		if x1 - x0 < 0.01 or z1 - z0 < 0.01 then return end
		P({ Name = name, Size = Vector3.new(x1-x0, h, z1-z0), CFrame = CFrame.new(center.X+(x0+x1)/2, bottom+h/2, center.Z+(z0+z1)/2), Color = color, Material = material, Parent = parent })
	end
	-- Leave an entrance notch in BOTH soil and grass so the approach ramp
	-- reaches the higher floor without striking a hidden vertical step.
	for _, bounds in { {-halfSize+corner, halfSize-corner, -halfDepth, halfDepth}, {-halfSize, halfSize, -halfDepth+corner, halfDepth-corner} } do
		local x0,x1,z0,z1 = table.unpack(bounds)
		local ix0,ix1 = math.max(x0,nx0), math.min(x1,nx1)
		local iz0,iz1 = math.max(z0,nz0), math.min(z1,nz1)
		if ix0 < ix1 and iz0 < iz1 then
			rect(x0,ix0,z0,z1); rect(ix1,x1,z0,z1)
			rect(ix0,ix1,z0,iz0); rect(ix0,ix1,iz1,z1)
		else rect(x0,x1,z0,z1) end
	end
	for _, x in { -1, 1 } do
		for _, z in { -1, 1 } do
			disk(parent, center + Vector3.new(x * (halfSize - corner), 0, z * (halfDepth - corner)), corner, h, top, color, material, name)
		end
	end
end

function MapBuilder.BuildWorld()
	withHistory("Chop a Tree: Continent", function()
		local L = MapBuilder.Layout()
		local root = mapRoot()
		local obsoleteMountain = root:FindFirstChild("Mountain")
		if obsoleteMountain then obsoleteMountain:Destroy() end
		local old = F(ServerStorage, "OldTemplate")
		for _, name in { "Baseplate", "SpawnLocation" } do
			local inst = workspace:FindFirstChild(name)
			if inst then inst.Parent = old end
		end
		local ground = fresh(root, "Ground")
		local sx, sz = Zones.ContinentSize.X, Zones.ContinentSize.Y
		local riverHalf = Zones.RiverWidth / 2
		-- Two banks leave a real river channel; only the eastern bridge connects them.
		for _, side in { -1, 1 } do
			local depth = sz / 2 - riverHalf
			P({ Name = "ContinentBank", Size = Vector3.new(sx, 16, depth), CFrame = CFrame.new(0, -8, side * (riverHalf + depth / 2)), Color = Color3.fromRGB(100, 155, 80), Material = Enum.Material.Grass, Parent = ground })
			P({ Name = "RiverBank", Size = Vector3.new(sx, 12, 10), CFrame = CFrame.new(0, -6, side * (riverHalf + 5)), Color = Color3.fromRGB(115, 104, 83), Material = Enum.Material.Rock, Parent = ground })
		end
		local water = fresh(root, "Water")
		P({ Name = "Sea", Size = Vector3.new(5000, 2, 3600), CFrame = CFrame.new(0, -7, 0), Color = Color3.fromRGB(55, 155, 195), Material = Enum.Material.Glass, Transparency = 0.25, CanCollide = false, CanQuery = false, Parent = water })
		P({ Name = "RootRiver", Size = Vector3.new(sx, 2, Zones.RiverWidth), CFrame = CFrame.new(0, -4, 0), Color = Color3.fromRGB(65, 185, 205), Material = Enum.Material.Glass, Transparency = 0.2, CanCollide = false, CanQuery = false, Parent = water })
		local roads = fresh(root, "Roads")
		for _, r in L.roads do
			local folder = F(roads, string.format("Road_%d_%d", r.from, r.to))
			pathSegments(folder, r.points, 26, 3, r.sky and Color3.fromRGB(170, 120, 65) or Color3.fromRGB(155, 125, 90), r.sky and Enum.Material.Wood or (r.bridge and Enum.Material.WoodPlanks or Enum.Material.Ground), r.sky and "SkyRoot" or (r.bridge and "Bridge" or "Road"))
			if r.bridge then
				for _, offset in { -15, 15 } do
					local rail = {}
					for _, point in r.points do table.insert(rail, point + Vector3.new(offset, 4, 0)) end
					pathSegments(folder, rail, 2, 2, Color3.fromRGB(110, 75, 45), Enum.Material.Wood, "BridgeRail")
				end
			elseif r.sky then
				local h = L.zones[8].y - L.zones[7].y
				P({ Name = "LightPillar", Shape = Enum.PartType.Cylinder, Size = Vector3.new(h, 12, 12), CFrame = CFrame.new(r.axis.X, L.zones[7].y + h / 2, r.axis.Z) * CFrame.Angles(0, 0, rad(90)), Color = Color3.fromRGB(255, 225, 140), Material = Enum.Material.Neon, Transparency = 0.45, CanCollide = false, Parent = folder })
				for _, offset in { -14, 14 } do
					local rail = {}
					for i, point in r.points do
						local nextPoint = r.points[math.min(i + 1, #r.points)]
						local prevPoint = r.points[math.max(i - 1, 1)]
						local dir = flat(nextPoint - prevPoint).Unit
						table.insert(rail, point + Vector3.new(dir.Z, 0, -dir.X) * offset + Vector3.new(0, 3, 0))
					end
					pathSegments(folder, rail, 1.5, 1.5, Color3.fromRGB(105, 75, 50), Enum.Material.Wood, "RootRail")
				end
			end
		end
		-- Low hills along the coast, clear of playable routes and trees.
		local hills = fresh(root, "Hills")
		for _, side in { -1, 1 } do
			for x = -900, 900, 300 do
				P({ Name = "CoastalHill", Shape = Enum.PartType.Ball, Size = Vector3.new(70, 16, 40), CFrame = CFrame.new(x, -3, side * 530), Color = Color3.fromRGB(104, 164, 80), Material = Enum.Material.Grass, Parent = hills })
			end
		end
		pcall(function() Lighting.Technology = Enum.Technology.Future end)
		Lighting.ClockTime = 14
		Lighting.Brightness = 2.5
		Lighting.OutdoorAmbient = Color3.fromRGB(140, 140, 140)
		Lighting.EnvironmentDiffuseScale = 0.6
		Lighting.EnvironmentSpecularScale = 0.6
		local atmo = Lighting:FindFirstChildOfClass("Atmosphere") or Instance.new("Atmosphere")
		atmo.Density, atmo.Offset, atmo.Haze, atmo.Glare = 0.2, 0.3, 0.3, 0.1
		atmo.Color = Color3.fromRGB(205, 225, 245)
		atmo.Decay = Color3.fromRGB(150, 170, 200)
		atmo.Parent = Lighting
		workspace.StreamingEnabled = true
	end)
end

-- ========== หมู่บ้าน Rootfall ==========
local function stall(parent, cf, label, roofColor)
	local m = M(parent, label)
	P({ Name = "Floor", Size = Vector3.new(16, 1, 12), CFrame = cf * CFrame.new(0, 0.5, 0), Color = Color3.fromRGB(150, 110, 70), Material = Enum.Material.WoodPlanks, Parent = m })
	for _, o in { { -7, -5 }, { 7, -5 }, { -7, 5 }, { 7, 5 } } do
		P({ Name = "Post", Size = Vector3.new(1, 10, 1), CFrame = cf * CFrame.new(o[1], 5.5, o[2]), Color = Color3.fromRGB(110, 75, 45), Material = Enum.Material.Wood, Parent = m })
	end
	P({ Name = "Roof", Size = Vector3.new(18, 1.5, 14), CFrame = cf * CFrame.new(0, 11, 0) * CFrame.Angles(rad(8), 0, 0), Color = roofColor, Parent = m })
	P({ Name = "Counter", Size = Vector3.new(14, 4, 2), CFrame = cf * CFrame.new(0, 3, -4.5), Color = Color3.fromRGB(170, 125, 80), Material = Enum.Material.WoodPlanks, Parent = m })
	local front = (cf * CFrame.new(0, 0, -20)).Position
	sign(m, (cf * CFrame.new(0, 13.5, -6)).Position, front, label, 14, 3.5, Color3.fromRGB(30, 36, 51), Color3.fromRGB(253, 230, 138))
	m.PrimaryPart = m.Floor
	return m
end

local function warpStone(parent, pos, zoneId, accent)
	local m = M(parent, "WarpStone")
	P({ Name = "Base", Size = Vector3.new(7, 1.5, 7), CFrame = CFrame.new(pos + Vector3.new(0, 0.75, 0)), Color = Color3.fromRGB(110, 110, 120), Material = Enum.Material.Slate, Parent = m })
	local pillar = P({ Name = "Pillar", Size = Vector3.new(4, 10, 4), CFrame = CFrame.new(pos + Vector3.new(0, 6.5, 0)) * CFrame.Angles(0, rad(45), 0), Color = Color3.fromRGB(90, 95, 110), Material = Enum.Material.Slate, Parent = m })
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

local function playerBase(parent, index, cf)
	local m = M(parent, "Base" .. index)
	local slab = P({ Name = "Slab", Size = Vector3.new(56, 1.2, 56), CFrame = cf * CFrame.new(0, 0.6, 0), Color = Color3.fromRGB(170, 120, 75), Material = Enum.Material.WoodPlanks, Parent = m })
	m.PrimaryPart = slab
	-- ขอบฐาน
	for _, e in { { 0, -28, 56, 1 }, { 0, 28, 56, 1 }, { -28, 0, 1, 56 }, { 28, 0, 1, 56 } } do
		P({ Name = "Edge", Size = Vector3.new(e[3] + 1, 1.6, e[4] + 1), CFrame = cf * CFrame.new(e[1], 0.8, e[2]), Color = Color3.fromRGB(120, 80, 50), Material = Enum.Material.Wood, Parent = m })
	end
	-- แปลงสวน (หลังฐาน) 6 ช่อง
	local garden = M(m, "GardenPlot")
	for row = 0, 1 do
		for col = 0, 2 do
			local slot = P({
				Name = "Slot" .. (row * 3 + col + 1),
				Size = Vector3.new(8, 0.8, 8),
				CFrame = cf * CFrame.new((col - 1) * 10, 1.6, 10 + row * 10),
				Color = Color3.fromRGB(110, 72, 45),
				Material = Enum.Material.Ground,
				Parent = garden,
			})
			tag(slot, "GardenSlot", { BaseIndex = index, SlotIndex = row * 3 + col + 1 })
		end
	end
	-- ตู้ฟักไข่ (หน้าซ้าย)
	local inc = M(m, "Incubator")
	P({ Name = "Stand", Shape = Enum.PartType.Cylinder, Size = Vector3.new(2, 8, 8), CFrame = cf * CFrame.new(-16, 2.2, -12) * CFrame.Angles(0, 0, rad(90)), Color = Color3.fromRGB(200, 200, 210), Material = Enum.Material.Metal, Parent = inc })
	P({ Name = "Dome", Shape = Enum.PartType.Ball, Size = Vector3.new(7, 7, 7), CFrame = cf * CFrame.new(-16, 5, -12), Color = Color3.fromRGB(180, 230, 255), Material = Enum.Material.Glass, Transparency = 0.5, CanCollide = false, Parent = inc })
	tag(inc, "Incubator", { BaseIndex = index })
	-- คอกสัตว์ (หน้าขวา) รั้ว
	local pen = M(m, "PetPen")
	local pc = cf * CFrame.new(14, 0, -10)
	for i = 0, 11 do
		local a = i / 12 * math.pi * 2
		P({ Name = "Fence", Size = Vector3.new(1, 3, 4.5), CFrame = pc * CFrame.new(math.sin(a) * 8, 2.7, math.cos(a) * 8) * CFrame.Angles(0, a, 0), Color = Color3.fromRGB(220, 200, 160), Material = Enum.Material.Wood, Parent = pen })
	end
	tag(pen, "PetPen", { BaseIndex = index })
	-- ป้ายเจ้าของ (ขอบหน้า หันไปลานกลาง)
	local front = (cf * CFrame.new(0, 0, -60)).Position
	P({ Name = "SignPost", Size = Vector3.new(1, 8, 1), CFrame = cf * CFrame.new(0, 4.6, -26), Color = Color3.fromRGB(110, 75, 45), Material = Enum.Material.Wood, Parent = m })
	local s = sign(m, (cf * CFrame.new(0, 9, -26)).Position, front, "Base " .. index .. " · Empty", 12, 3.2)
	s.Name = "OwnerSign"
	tag(s, "OwnerSign", { BaseIndex = index })
	-- บาเรียร์ล็อกฐาน (ปิดอยู่)
	local barrier = P({ Name = "LockBarrier", Size = Vector3.new(58, 30, 58), CFrame = cf * CFrame.new(0, 15, 0), Color = Color3.fromRGB(96, 165, 250), Material = Enum.Material.ForceField, Transparency = 1, CanCollide = false, CanQuery = false, Parent = m })
	barrier:SetAttribute("Active", false)
	local spawnPoint = P({ Name = "BaseSpawn", Size = Vector3.new(4, 1, 4), CFrame = cf * CFrame.new(0, 1.7, -18), Transparency = 1, CanCollide = false, Parent = m })
	tag(spawnPoint, "BaseSpawn", { BaseIndex = index })
	tag(m, "PlayerBase", { BaseIndex = index, OwnerUserId = 0 })
	return m
end

function MapBuilder.BuildVillage()
	withHistory("Chop a Tree: Village", function()
		local L = MapBuilder.Layout()
		local v = L.village
		local V = v.center
		local village = fresh(mapRoot(), "Village")
		disk(village, V, v.radius, 1.2, 0.9, Color3.fromRGB(120, 182, 82), Enum.Material.Grass, "Plaza")
		disk(village, V, 70, 0.4, 1.1, Color3.fromRGB(200, 190, 170), Enum.Material.Slate, "InnerPlaza")

		local z1 = L.zones[1]
		local gateDir = flat(z1.entry - V).Unit
		local gateAngle = math.atan2(gateDir.X, gateDir.Z)

		-- ฐานผู้เล่น 7 ฐาน (เว้นช่องตรงประตูป่า)
		local bases = F(village, "Bases")
		for i = 1, 7 do
			local a = gateAngle + rad(40 + (i - 1) * (280 / 6))
			local pos = V + Vector3.new(math.sin(a), 0, math.cos(a)) * 128
			playerBase(bases, i, CFrame.lookAt(Vector3.new(pos.X, 0.3, pos.Z), Vector3.new(V.X, 0.3, V.Z)))
		end

		-- แท่นเปิดหีบ (กลางลาน)
		local altar = M(village, "ChestAltar")
		disk(altar, V, 11, 2, 3.1, Color3.fromRGB(235, 235, 240), Enum.Material.Marble, "Step1")
		disk(altar, V, 8, 3, 6.1, Color3.fromRGB(245, 245, 250), Enum.Material.Marble, "Step2")
		local rim = disk(altar, V, 8.4, 0.6, 6.4, Color3.fromRGB(255, 214, 79), Enum.Material.Neon, "Rim")
		rim.CanCollide = false
		altar.PrimaryPart = altar.Step2
		tag(altar, "ChestAltar")

		-- วงในรอบแท่น: ร้าน, NPC, กระดานผู้นำ, พอร์ทัล, หินวาร์ป
		local services = F(village, "Services")
		local ring = {
			{ "SeedShop", "Seed Shop", Color3.fromRGB(76, 175, 80) },
			{ "EggConveyor", "Egg Conveyor", nil },
			{ "UpgradeShop", "Upgrades", Color3.fromRGB(29, 78, 216) },
			{ "Sawmill", "Sawmill (Sell Wood)", Color3.fromRGB(180, 83, 9) },
			{ "NPC_Bram", "Grandpa Bram", nil },
			{ "Leaderboards", "Leaderboards", nil },
			{ "ArenaPortal", "Chop Arena (PvP)", nil },
			{ "WarpHub", "Warp Stone", nil },
		}
		for i, item in ring do
			local a = gateAngle + rad(25) + (i - 1) * (math.pi * 2 / #ring)
			local pos = V + Vector3.new(math.sin(a), 0, math.cos(a)) * 52
			local cf = CFrame.lookAt(Vector3.new(pos.X, 1.1, pos.Z), Vector3.new(V.X, 1.1, V.Z))
			local id = item[1]
			if item[3] then
				local s = stall(services, cf, item[2], item[3])
				s.Name = id
				tag(s, "Shop", { ShopType = id })
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
					P({ Name = "Ring", Size = Vector3.new(2, 3.4, 2), CFrame = pc * CFrame.new(math.cos(a2) * 8, math.sin(a2) * 8, 0) * CFrame.Angles(0, 0, a2), Color = Color3.fromRGB(109, 40, 217), Material = Enum.Material.Slate, Parent = m })
				end
				local inner = P({ Name = "Portal", Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.6, 14, 14), CFrame = pc * CFrame.Angles(0, rad(90), 0), Color = Color3.fromRGB(168, 85, 247), Material = Enum.Material.Neon, Transparency = 0.35, CanCollide = false, Parent = m })
				sign(m, (cf * CFrame.new(0, 20, 0)).Position, V, "Chop Arena · PvP", 14, 3, Color3.fromRGB(30, 36, 51), Color3.fromRGB(216, 180, 254))
				m.PrimaryPart = inner
				tag(m, "ArenaPortal")
			elseif id == "WarpHub" then
				warpStone(services, Vector3.new(pos.X, 1.1, pos.Z), 0, Color3.fromRGB(96, 165, 250))
			end
		end

		-- จุดเกิด
		local spawnPos = V + gateDir * 30
		local spawn = Instance.new("SpawnLocation")
		spawn.Name = "VillageSpawn"
		spawn.Anchored = true
		spawn.Size = Vector3.new(12, 1, 12)
		spawn.CFrame = CFrame.new(spawnPos.X, 1.6, spawnPos.Z)
		spawn.Material = Enum.Material.Slate
		spawn.Color = Color3.fromRGB(200, 190, 170)
		spawn.Neutral = true
		spawn.Duration = 0
		local decal = spawn:FindFirstChildOfClass("Decal")
		if decal then
			decal:Destroy()
		end
		spawn.Parent = village

		-- ประตูสู่ป่า
		local gate = M(village, "ForestGate")
		local gatePos = V + gateDir * (v.radius - 4)
		local gcf = CFrame.lookAt(Vector3.new(gatePos.X, 0, gatePos.Z), Vector3.new(gatePos.X, 0, gatePos.Z) + gateDir)
		for _, x in { -15, 15 } do
			P({ Name = "Pillar", Shape = Enum.PartType.Cylinder, Size = Vector3.new(24, 4, 4), CFrame = gcf * CFrame.new(x, 12, 0) * CFrame.Angles(0, 0, rad(90)), Color = Color3.fromRGB(115, 78, 46), Material = Enum.Material.Wood, Parent = gate })
		end
		P({ Name = "Beam", Size = Vector3.new(38, 3, 3.5), CFrame = gcf * CFrame.new(0, 23, 0), Color = Color3.fromRGB(95, 62, 38), Material = Enum.Material.Wood, Parent = gate })
		sign(gate, (gcf * CFrame.new(0, 27, 0)).Position, V, "Forest Gate → Sunlit Meadow", 30, 4, Color3.fromRGB(30, 36, 51), Color3.fromRGB(190, 242, 100))
		local trigger = P({ Name = "RunTrigger", Size = Vector3.new(30, 20, 4), CFrame = gcf * CFrame.new(0, 10, 0), Transparency = 1, CanCollide = false, Parent = gate })
		tag(trigger, "ForestGate")
		gate.PrimaryPart = trigger

		-- โคมไฟรอบลาน
		local decor = F(village, "Decor")
		for i = 0, 13 do
			local a = gateAngle + rad(14) + i / 14 * math.pi * 2
			local pos = V + Vector3.new(math.sin(a), 0, math.cos(a)) * 182
			if math.abs(math.deg((a - gateAngle + math.pi) % (2 * math.pi) - math.pi)) > 12 then
				P({ Name = "LampPost", Size = Vector3.new(1, 12, 1), CFrame = CFrame.new(pos + Vector3.new(0, 6.9, 0)), Color = Color3.fromRGB(60, 60, 70), Material = Enum.Material.Metal, Parent = decor })
				local lamp = P({ Name = "Lamp", Size = Vector3.new(2, 2, 2), CFrame = CFrame.new(pos + Vector3.new(0, 13.5, 0)), Color = Color3.fromRGB(255, 220, 150), Material = Enum.Material.Neon, CanCollide = false, Parent = decor })
				local light = Instance.new("PointLight")
				light.Color = Color3.fromRGB(255, 210, 150)
				light.Range = 22
				light.Brightness = 1.2
				light.Parent = lamp
			end
		end
	end)
end

-- ========== โซน ==========
-- Vetted Creator Store prototypes (tools/map/AssetPrototypes.luau) live in
-- ServerStorage.MapAssets.Trees.<ZoneKey>; zones without them keep the block trees.
local function assetVariants(zone)
	local root = ServerStorage:FindFirstChild("MapAssets")
	local folder = root and root:FindFirstChild("Trees") and root.Trees:FindFirstChild(zone.key)
	local list = folder and folder:GetChildren() or {}
	return #list > 0 and list or nil
end

local function placeAsset(parent, proto, pos, height, rng)
	local look = proto:Clone()
	look.Name = "Look"
	look:ScaleTo(height * proto:GetAttribute("HeightScale") / proto:GetAttribute("Height"))
	look:PivotTo(CFrame.new(pos) * CFrame.Angles(0, rng:NextNumber(0, math.pi * 2), 0))
	look.Parent = parent
	return look
end

local function rotVeins(m, zone, pos, tw, trunkH, rng, trunk)
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

-- Asset tree: an invisible trunk collider stays the PrimaryPart so TreeService,
-- hit raycasts and health bars work unchanged; the asset clone is visual only.
local function assetTree(parent, zone, tier, pos, rng, tagName, variants)
	local m = Instance.new("Model")
	m.Name = "Tree_T" .. tier
	local h = 10 + tier * 6
	local tw = 1.4 + tier * 0.45
	local trunkH = h * 0.55
	local trunk = P({
		Name = "Trunk",
		Size = Vector3.new(tw, trunkH, tw),
		CFrame = CFrame.new(pos + Vector3.new(0, trunkH / 2, 0)),
		Transparency = 1,
		Parent = m,
	})
	placeAsset(m, variants[rng:NextInteger(1, #variants)], pos, h, rng)
	if tier == 6 then rotVeins(m, zone, pos, tw, trunkH, rng, trunk) end
	m.PrimaryPart = trunk
	m:SetAttribute("Zone", zone.id)
	m:SetAttribute("Tier", tier)
	CollectionService:AddTag(m, tagName or "Tree")
	m.Parent = parent
	return m
end

local function makeTree(parent, zone, tier, pos, rng, tagName)
	local variants = assetVariants(zone)
	if variants then
		return assetTree(parent, zone, tier, pos, rng, tagName, variants)
	end
	local m = Instance.new("Model")
	m.Name = "Tree_T" .. tier
	local h = 10 + tier * 6
	local tw = 1.4 + tier * 0.45
	local trunkH = h * 0.55
	local trunk = P({
		Name = "Trunk",
		Size = Vector3.new(tw, trunkH, tw),
		CFrame = CFrame.new(pos + Vector3.new(0, trunkH / 2, 0)) * CFrame.Angles(0, rng:NextNumber(0, math.pi), 0),
		Color = zone.colors.trunk,
		Material = Enum.Material.Wood,
		Parent = m,
	})
	local leaves = zone.colors.leaves
	local cs = 4 + tier * 2.6
	for i = 1, 3 do
		local s = cs * (1 - (i - 1) * 0.22)
		local off = Vector3.new(rng:NextNumber(-0.25, 0.25) * cs, trunkH + (i - 1) * s * 0.45, rng:NextNumber(-0.25, 0.25) * cs)
		P({
			Name = "Leaves",
			Size = Vector3.new(s, s * 0.8, s),
			CFrame = CFrame.new(pos + off) * CFrame.Angles(rng:NextNumber(-0.3, 0.3), rng:NextNumber(0, math.pi), rng:NextNumber(-0.3, 0.3)),
			Color = leaves[rng:NextInteger(1, #leaves)],
			CanCollide = false,
			Parent = m,
		})
	end
	if tier == 6 then
		-- ต้นราเน่า: เส้นสีม่วงเรืองแสง
		rotVeins(m, zone, pos, tw, trunkH, rng, trunk)
	end
	m.PrimaryPart = trunk
	m:SetAttribute("Zone", zone.id)
	m:SetAttribute("Tier", tier)
	CollectionService:AddTag(m, tagName or "Tree")
	m.Parent = parent
	return m
end

local function distToSegment(p, a, b)
	local ab = flat(b - a)
	local ap = flat(p - a)
	local t = math.clamp(ap:Dot(ab) / math.max(ab:Dot(ab), 1e-6), 0, 1)
	return (ap - ab * t).Magnitude
end

local function gate(parent, pos, dir, fromZone, toZone, accent)
	local m = M(parent, "ZoneGate")
	local cf = CFrame.lookAt(Vector3.new(pos.X, pos.Y, pos.Z), Vector3.new(pos.X, pos.Y, pos.Z) + flat(dir).Unit)
	for _, x in { -18, 18 } do
		P({ Name = "Pillar", Size = Vector3.new(5, 26, 5), CFrame = cf * CFrame.new(x, 13, 0), Color = Color3.fromRGB(70, 60, 80), Material = Enum.Material.Slate, Parent = m })
	end
	P({ Name = "Beam", Size = Vector3.new(40, 4, 5), CFrame = cf * CFrame.new(0, 27, 0), Color = Color3.fromRGB(60, 50, 70), Material = Enum.Material.Slate, Parent = m })
	local barrier = P({ Name = "RotBarrier", Size = Vector3.new(31, 24, 1), CFrame = cf * CFrame.new(0, 12, 0), Color = Zones.RotColor, Material = Enum.Material.Neon, Transparency = 0.45, CanCollide = true, Parent = m })
	sign(m, (cf * CFrame.new(0, 31.5, 0)).Position, (cf * CFrame.new(0, 0, 30)).Position, "Rot Gate • Defeat Boss to Unlock → Zone " .. toZone, 30, 3.5, Color3.fromRGB(30, 20, 40), Color3.fromRGB(216, 180, 254))
	m.PrimaryPart = barrier
	tag(m, "ZoneGate", { FromZone = fromZone, ToZone = toZone, Open = false })
	return m
end

local function shrine(parent, pos, zoneId, accent)
	local m = M(parent, "Shrine")
	disk(m, pos, 9, 1.5, pos.Y + 1.5, Color3.fromRGB(150, 150, 155), Enum.Material.Slate, "Base")
	for _, o in { { -5, -5 }, { 5, -5 }, { -5, 5 }, { 5, 5 } } do
		P({ Name = "Post", Size = Vector3.new(1.4, 10, 1.4), CFrame = CFrame.new(pos + Vector3.new(o[1], 6.5, o[2])), Color = Color3.fromRGB(160, 40, 40), Material = Enum.Material.Wood, Parent = m })
	end
	P({ Name = "Roof", Size = Vector3.new(16, 1.6, 16), CFrame = CFrame.new(pos + Vector3.new(0, 12, 0)), Color = Color3.fromRGB(60, 50, 50), Material = Enum.Material.Slate, Parent = m })
	local crystal = P({ Name = "Crystal", Size = Vector3.new(2.5, 4, 2.5), CFrame = CFrame.new(pos + Vector3.new(0, 4.5, 0)) * CFrame.Angles(0, rad(45), 0), Color = Color3.fromRGB(90, 90, 100), Material = Enum.Material.Glass, Parent = m })
	crystal:SetAttribute("LitColor", accent)
	m.PrimaryPart = crystal
	tag(m, "Shrine", { Zone = zoneId, Lit = false })
	return m
end

local function bossArena(parent, pos, zone, trailStart, trailEnd)
	local m = M(parent, "BossArena")
	local c = zone.colors.ground
	disk(m, pos, 40, 0.6, pos.Y + 0.3, Color3.new(c.R * 0.85, c.G * 0.85, c.B * 0.85), Enum.Material.Slate, "Floor")
	for k = 0, 15 do
		local a = k / 16 * math.pi * 2
		local stonePos = pos + Vector3.new(math.sin(a) * 42, 3, math.cos(a) * 42)
		if distToSegment(stonePos, trailStart, trailEnd) > 18 then
			P({ Name = "Stone", Size = Vector3.new(3, 5 + (k % 3) * 2, 3), CFrame = CFrame.new(stonePos) * CFrame.Angles(0, a, 0.1), Color = Color3.fromRGB(110, 105, 100), Material = Enum.Material.Slate, Parent = m })
		end
	end
	m.PrimaryPart = m.Floor
	-- Keep the guardian's collidable trunk/roots clear of the through trail.
	local direction = flat(trailEnd - trailStart).Unit
	local side = Vector3.new(direction.Z, 0, -direction.X)
	if flat(pos - trailStart):Dot(side) < 0 then side = -side end
	m:SetAttribute("GuardianOffset", zone.id == #Zones.List and Vector3.new(26, 0, 0) or side * 26)
	tag(m, "BossArena", { Zone = zone.id, Boss = zone.boss })
	return m
end

local function nest(parent, pos, zone, index)
	local m = M(parent, "Nest" .. index)
	for k = 0, 9 do
		local a = k / 10 * math.pi * 2
		P({ Name = "Twig", Size = Vector3.new(1, 1, 4), CFrame = CFrame.new(pos + Vector3.new(math.sin(a) * 4, 0.6, math.cos(a) * 4)) * CFrame.Angles(0, a + 1.4, 0.2), Color = Color3.fromRGB(120, 85, 50), Material = Enum.Material.Wood, CanCollide = false, Parent = m })
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

local function decorZone(folder, zone, center, radius, rng, avoid)
	local function spot(minR)
		for _ = 1, 30 do
			local r = math.sqrt(rng:NextNumber()) * (radius - minR)
			local a = rng:NextNumber(0, math.pi * 2)
			local p = center + Vector3.new(math.sin(a) * r, 0, math.cos(a) * r)
			if avoid(p, 6) then
				return p
			end
		end
		return nil
	end
	local rocks = zone.id == 2 and 25 or 15
	for _ = 1, rocks do
		local p = spot(10)
		if p then
			local s = rng:NextNumber(2, 6)
			P({ Name = "Rock", Size = Vector3.new(s * 1.3, s, s), CFrame = CFrame.new(p + Vector3.new(0, s * 0.35, 0)) * CFrame.Angles(rng:NextNumber(-0.4, 0.4), rng:NextNumber(0, 3), rng:NextNumber(-0.4, 0.4)), Color = Color3.fromRGB(130, 125, 118), Material = Enum.Material.Slate, Parent = folder })
		end
	end
	if zone.id == 1 then
		local petals = { Color3.fromRGB(255, 99, 99), Color3.fromRGB(255, 214, 79), Color3.fromRGB(255, 255, 255), Color3.fromRGB(196, 132, 252) }
		for _ = 1, 70 do
			local p = spot(6)
			if p then
				P({ Name = "Flower", Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.3, 1.4, 1.4), CFrame = CFrame.new(p + Vector3.new(0, 0.3, 0)) * CFrame.Angles(0, 0, rad(90)), Color = petals[rng:NextInteger(1, #petals)], CanCollide = false, CanQuery = false, Parent = folder })
			end
		end
		for _ = 1, 14 do
			local p = spot(8)
			if p then
				local s = rng:NextNumber(3, 5)
				P({ Name = "Bush", Shape = Enum.PartType.Ball, Size = Vector3.new(s * 1.4, s, s * 1.4), CFrame = CFrame.new(p + Vector3.new(0, s * 0.35, 0)), Color = zone.colors.leaves[rng:NextInteger(1, #zone.colors.leaves)], CanCollide = false, Parent = folder })
			end
		end
	elseif assetVariants(zone) then
		-- Small themed props from the same vetted prototypes (no collision, not choppable).
		local variants = assetVariants(zone)
		for _ = 1, 28 do
			local p = spot(8)
			if p then placeAsset(folder, variants[rng:NextInteger(1, #variants)], p, rng:NextNumber(3, 7), rng) end
		end
	end
	if zone.id == 2 then
		for _ = 1, 12 do
			local p = spot(10)
			if p then
				local l = rng:NextNumber(8, 14)
				P({ Name = "FallenLog", Shape = Enum.PartType.Cylinder, Size = Vector3.new(l, 2.4, 2.4), CFrame = CFrame.new(p + Vector3.new(0, 1.1, 0)) * CFrame.Angles(0, rng:NextNumber(0, 3), 0), Color = zone.colors.trunk, Material = Enum.Material.Wood, Parent = folder })
			end
		end
		for _ = 1, 40 do
			local p = spot(6)
			if p then
				local s = rng:NextNumber(3, 6)
				P({ Name = "LeafPile", Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.3, s, s * 0.8), CFrame = CFrame.new(p + Vector3.new(0, 0.2, 0)) * CFrame.Angles(0, rng:NextNumber(0, 3), rad(90)), Color = zone.colors.leaves[rng:NextInteger(1, #zone.colors.leaves)], CanCollide = false, CanQuery = false, Parent = folder })
			end
		end
	end
end

function MapBuilder.BuildZone(index)
	withHistory("Chop a Tree: Zone " .. index, function()
		local L = MapBuilder.Layout()
		local Z = L.zones[index]
		local zone = Z.def
		local wilds = F(mapRoot(), "Wilds")
		local zoneName = string.format("Zone%d_%s", index, zone.key)
		for _, old in wilds:GetChildren() do
			if old.Name ~= zoneName and tonumber(old.Name:match("^Zone(%d+)_")) == index then old:Destroy() end
		end
		local root = fresh(wilds, zoneName)
		root:SetAttribute("Zone", index)
		local C = Z.center
		local E = Z.entry
		local X = Z.exit
		local rng = Random.new(1000 + index)
		local folders = {}
		for _, name in { "Ground", "Trees", "ChestSpots", "Nests", "Shrine", "BossArena", "ZoneGate", "WarpStone", "Spawn", "Boundary", "Decor", "Secrets" } do
			folders[name] = F(root, name)
		end

		-- พื้น + หน้าผา
		local groundMat = index == 6 and Enum.Material.Snow or (index == 8 and Enum.Material.Sand or Enum.Material.Grass)
		if index == 8 then
			disk(folders.Ground, C, Z.radius, 10, Z.y, zone.colors.ground, groundMat, "SkyIsland")
			disk(folders.Ground, C, Z.radius * 0.9, 70, Z.y - 10, zone.colors.cliff, Enum.Material.Rock, "FloatingCliff")
		else
			roundedGround(folders.Ground, C, Z.radius, -8, Z.y - 1, zone.colors.cliff, Enum.Material.Rock, "Soil", E, Z.halfDepth)
			roundedGround(folders.Ground, C, Z.radius, Z.y - 1, Z.y, zone.colors.ground, groundMat, "Meadow", E, Z.halfDepth)
		end

		-- ทางเดินจากทางเข้าไปทางออก
		local inward = flat(C - E).Unit
		local trailEnd = Z.trailEnd or X or (C + Vector3.new(inward.Z, 0, -inward.X) * 80)
		local trail = {}
		for s = 0, 8 do
			local p = (Z.trailStart or E):Lerp(trailEnd, s / 8)
			table.insert(trail, Vector3.new(p.X, Z.y + 0.25, p.Z))
		end
		local gc = zone.colors.ground
		pathSegments(folders.Ground, trail, 14, 0.5, Color3.new(gc.R * 0.7, gc.G * 0.6, gc.B * 0.5), Enum.Material.Ground, "Trail")

		-- จุดเกิดโซน + หินวาร์ป + ป้ายต้อนรับ
		local spawnPos = (Z.trailStart or E) + inward * 22
		local sp = P({ Name = "ZoneSpawn", Size = Vector3.new(8, 1, 8), CFrame = CFrame.new(spawnPos.X, Z.y + 0.5, spawnPos.Z), Transparency = 1, CanCollide = false, Parent = folders.Spawn })
		tag(sp, "ZoneSpawn", { Zone = index })
		local side = Vector3.new(inward.Z, 0, -inward.X)
		warpStone(folders.WarpStone, Vector3.new(spawnPos.X, Z.y, spawnPos.Z) + side * 18, index, zone.colors.accent)
		local signPos = (Z.trailStart or E) + inward * 12 - side * 16
		P({ Name = "SignPost", Size = Vector3.new(1, 10, 1), CFrame = CFrame.new(signPos.X, Z.y + 5, signPos.Z), Color = Color3.fromRGB(110, 75, 45), Material = Enum.Material.Wood, Parent = folders.Decor })
		local welcome = zone.built and string.format("Zone %d · %s", index, zone.name)
			or string.format("Zone %d · %s\n(Available in Phase 7)", index, zone.name)
		sign(folders.Decor, Vector3.new(signPos.X, Z.y + 12, signPos.Z), E - inward * 40, welcome, 16, 7)

		-- Visible rot hedges with exact openings aligned to the gate pillars.
		if index < 8 then
			for _, edge in { {1, 0}, {-1, 0}, {0, 1}, {0, -1} } do
				local normal = Vector3.new(edge[1], 0, edge[2])
				local tangent = Vector3.new(normal.Z, 0, -normal.X)
				local edgeDepth = math.abs(normal.Z) > 0.5 and Z.halfDepth or Z.radius
				local edgeLength = math.abs(normal.Z) > 0.5 and Z.radius or Z.halfDepth
				local middle = C + normal * edgeDepth
				local openings = {}
				for _, point in { E, X } do
					if math.abs(flat(point - middle):Dot(normal)) < 2 then
						local t = flat(point - middle):Dot(tangent)
						table.insert(openings, { t - 20, t + 20 })
					end
				end
				table.sort(openings, function(a, b) return a[1] < b[1] end)
				table.insert(openings, { edgeLength, edgeLength })
				local cursor = -edgeLength
				for _, hole in openings do
					local length = hole[1] - cursor
					if length > 0 then
						local pos = middle + tangent * (cursor + length / 2) + Vector3.new(0, 6, 0)
						P({ Name = "RotHedge", Size = Vector3.new(length, 12, 5), CFrame = CFrame.lookAt(pos, pos + normal), Color = Zones.RotColor:Lerp(zone.colors.cliff, 0.65), Material = Enum.Material.Wood, Parent = folders.Boundary })
						for t = cursor + 8, hole[1] - 8, 24 do
							local thorn = middle + tangent * t + Vector3.new(0, 12, 0)
							P({ Name = "RotThorn", Size = Vector3.new(2, 5, 2), CFrame = CFrame.new(thorn) * CFrame.Angles(0.4, t, 0.3), Color = Zones.RotColor, Material = Enum.Material.Wood, CanCollide = false, Parent = folders.Boundary })
						end
					end
					cursor = hole[2]
				end
			end
		end

		-- ลานบอส (ใกล้ทางออก) + ศาลเจ้า + ประตูโซนถัดไป
		local arenaPos
		if index == #Zones.List then
			arenaPos = Vector3.new(C.X, Z.y, C.Z)
		else
			arenaPos = X + flat(C - X).Unit * 58
			arenaPos = Vector3.new(arenaPos.X, Z.y, arenaPos.Z)
		end
		bossArena(folders.BossArena, arenaPos, zone, Z.trailStart or E, trailEnd)
		local perp = Vector3.new(inward.Z, 0, -inward.X)
		local shrinePos = arenaPos + perp * 55
		if flat(shrinePos - C).Magnitude > Z.radius - 14 then
			shrinePos = arenaPos - perp * 55
		end
		shrine(folders.Shrine, Vector3.new(shrinePos.X, Z.y, shrinePos.Z), index, zone.colors.accent)
		if X then
			gate(folders.ZoneGate, Vector3.new(X.X, Z.y, X.Z), flat(X - C), index, index + 1, zone.colors.accent)
		end

		-- โซนบนสุด: ต้น Lumora + ประตูมิติ (ไว้อนาคต)
		if index == #Zones.List then
			local lum = M(folders.Decor, "Lumora")
			P({ Name = "Trunk", Size = Vector3.new(12, 80, 12), CFrame = CFrame.new(C + Vector3.new(0, 40, 0)), Color = zone.colors.trunk, Material = Enum.Material.Wood, Parent = lum })
			for k = 1, 4 do
				P({ Name = "Crown", Size = Vector3.new(70 - k * 10, 18, 70 - k * 10), CFrame = CFrame.new(C + Vector3.new(0, 70 + k * 12, 0)) * CFrame.Angles(0, k * 0.4, 0), Color = zone.colors.leaves[1], Material = Enum.Material.SmoothPlastic, CanCollide = false, Parent = lum })
			end
			tag(lum, "Lumora")
			local far = C + inward * (Z.radius - 20) -- ฝั่งตรงข้ามทางเข้า
			local rg = M(folders.Secrets, "RealmGate")
			local rcf = CFrame.lookAt(Vector3.new(far.X, Z.y + 16, far.Z), Vector3.new(C.X, Z.y + 16, C.Z))
			for k = 0, 19 do
				local a = k / 20 * math.pi * 2
				P({ Name = "Ring", Size = Vector3.new(2.5, 4.5, 2.5), CFrame = rcf * CFrame.new(math.cos(a) * 13, math.sin(a) * 13, 0) * CFrame.Angles(0, 0, a), Color = Color3.fromRGB(255, 215, 100), Material = Enum.Material.Neon, Parent = rg })
			end
			sign(rg, (rcf * CFrame.new(0, 19, 0)).Position, C, "Realm Gate · Realm 2 (Coming Soon)", 22, 3.5, Color3.fromRGB(30, 36, 51), Color3.fromRGB(255, 230, 150))
			tag(rg, "RealmGate", { Realm = 2, Open = false })
		end

		-- พื้นที่ห้ามวาง
		local blocked = {
			{ E, 40 }, { arenaPos, 52 }, { shrinePos, 18 }, { spawnPos + side * 18, 10 }, { signPos, 6 },
		}
		if X then
			table.insert(blocked, { X, 40 })
		end
		local trees = {}
		local function free(p, margin)
			for _, b in blocked do
				if flat(p - b[1]).Magnitude < b[2] + margin then
					return false
				end
			end
			if distToSegment(p, Z.trailStart or E, trailEnd) < 12 + margin then
				return false
			end
			for _, t in trees do
				if flat(p - t.p).Magnitude < t.r + margin then
					return false
				end
			end
			return true
		end

		if zone.built then
			-- ต้นไม้ ~160 ต้น (ArmZ เลือกให้แน่นขึ้น) ระดับสูงขึ้นตามระยะจากทางเข้า
			local target = 160
			local tries = 0
			while #trees < target and tries < 9000 do
				tries += 1
				local r = math.sqrt(rng:NextNumber()) * (Z.radius - 14)
				local a = rng:NextNumber(0, math.pi * 2)
				local p = C + Vector3.new(math.sin(a) * r, 0, math.cos(a) * r)
				local depth = flat(p - E).Magnitude / (Z.radius * 2)
				local tier = math.clamp(math.floor(depth * 6 * 1.15 + rng:NextNumber(-0.8, 0.8)) + 1, 1, 6)
				local size = 4 + tier * 1.6
				if free(p, size) then
					makeTree(folders.Trees, zone, tier, Vector3.new(p.X, Z.y, p.Z), rng)
					table.insert(trees, { p = p, r = size })
				end
			end
			-- จุดหีบ 10 จุด (ลึก = ดีกว่า)
			local chests = {}
			tries = 0
			while #chests < 10 and tries < 3000 do
				tries += 1
				local r = math.sqrt(rng:NextNumber()) * (Z.radius - 20)
				local a = rng:NextNumber(0, math.pi * 2)
				local p = C + Vector3.new(math.sin(a) * r, 0, math.cos(a) * r)
				local okSpacing = true
				for _, c in chests do
					if flat(p - c).Magnitude < 34 then
						okSpacing = false
					end
				end
				if okSpacing and free(p, 3) then
					table.insert(chests, p)
					local mk = disk(folders.ChestSpots, p, 3, 0.3, Z.y + 0.3, Color3.fromRGB(255, 214, 79), Enum.Material.Neon, "ChestSpot" .. #chests)
					mk.Transparency = 0.5
					mk.CanCollide = false
					tag(mk, "ChestSpot", { Zone = index, Depth = math.clamp(flat(p - E).Magnitude / (Z.radius * 2), 0, 1) })
				end
			end
			-- รังไข่ 2 รัง (ลึกครึ่งหลัง)
			local nests = 0
			tries = 0
			while nests < 2 and tries < 3000 do
				tries += 1
				local r = math.sqrt(rng:NextNumber()) * (Z.radius - 24)
				local a = rng:NextNumber(0, math.pi * 2)
				local p = C + Vector3.new(math.sin(a) * r, 0, math.cos(a) * r)
				if flat(p - E).Magnitude > Z.radius and free(p, 8) then
					nests += 1
					nest(folders.Nests, Vector3.new(p.X, Z.y, p.Z), zone, nests)
					table.insert(trees, { p = p, r = 14 })
				end
			end
			decorZone(folders.Decor, zone, Vector3.new(C.X, Z.y, C.Z), Z.radius - 6, rng, free)
		else
			-- โซนโครง: ต้นตัวอย่างโชว์ธีม (ยังฟันไม่ได้)
			local tries = 0
			while #trees < 14 and tries < 2000 do
				tries += 1
				local r = math.sqrt(rng:NextNumber()) * (Z.radius - 14)
				local a = rng:NextNumber(0, math.pi * 2)
				local p = C + Vector3.new(math.sin(a) * r, 0, math.cos(a) * r)
				local tier = rng:NextInteger(1, 6)
				local size = 4 + tier * 1.6
				if free(p, size) then
					makeTree(folders.Decor, zone, tier, Vector3.new(p.X, Z.y, p.Z), rng, "PreviewTree")
					table.insert(trees, { p = p, r = size })
				end
			end
		end
	end)
end

function MapBuilder.BuildAllZones()
	for i = 1, #Zones.List do
		MapBuilder.BuildZone(i)
	end
end

function MapBuilder.BuildAll()
	MapBuilder.BuildWorld()
	MapBuilder.BuildVillage()
	MapBuilder.BuildAllZones()
end

-- สรุปจำนวนของในแมพ
function MapBuilder.Report()
	local out = {}
	for _, t in { "Tree", "PreviewTree", "ChestSpot", "Nest", "ZoneGate", "WarpStone", "ZoneSpawn", "BossArena", "Shrine", "PlayerBase", "GardenSlot", "Shop", "NPC", "ForestGate", "ArenaPortal", "RealmGate", "Lumora", "Leaderboard", "ChestAltar" } do
		local count = 0
		for _, inst in CollectionService:GetTagged(t) do
			if inst:IsDescendantOf(mapRoot()) then count += 1 end
		end
		table.insert(out, t .. "=" .. count)
	end
	local parts = 0
	for _, d in mapRoot():GetDescendants() do
		if d:IsA("BasePart") then
			parts += 1
		end
	end
	table.insert(out, "Parts=" .. parts)
	return table.concat(out, ", ")
end

return MapBuilder
