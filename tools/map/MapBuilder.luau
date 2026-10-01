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

local Zones = require(game.ReplicatedStorage.Shared.Config.Zones)

local MapBuilder = {}

-- ========== ตัวช่วย ==========
local function rad(d)
	return math.rad(d)
end

local function mountainR(y)
	return Zones.MountainBase - Zones.MountainSlope * y
end

local function polar(angle, R, y)
	return Vector3.new(R * math.sin(angle), y, R * math.cos(angle))
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

-- ========== ผังเกลียวขึ้นเขา ==========
function MapBuilder.Layout()
	local L = { zones = {}, roads = {} }
	local V = Zones.Village
	L.village = { center = polar(rad(V.angleDeg), V.distance, 0), radius = V.radius }
	local slope = math.tan(rad(Zones.RoadMaxSlopeDeg))
	local count = #Zones.List
	local angle = rad(40)
	for i, z in Zones.List do
		local isTop = i == count
		local R = isTop and 0 or (mountainR(z.y) + z.radius * 0.35)
		if i > 1 then
			local prev = L.zones[i - 1]
			local Rto = isTop and (mountainR(z.y) + 20) or R
			local a0 = prev.angle + (prev.radius / prev.R) * 0.9
			local arc = (z.y - prev.y) / slope
			local a1 = a0 + arc / ((prev.R + Rto) / 2)
			angle = isTop and a1 or (a1 + (z.radius / R) * 0.9)
			table.insert(L.roads, { from = i - 1, to = i, a0 = a0, a1 = a1, y0 = prev.y, y1 = z.y, R0 = prev.R, R1 = Rto })
		end
		L.zones[i] = {
			def = z,
			angle = angle,
			R = R,
			y = z.y,
			radius = z.radius,
			center = isTop and Vector3.new(0, z.y, 0) or polar(angle, R, z.y),
		}
	end
	-- จุดเข้า (E) / ออก (X) ของแต่ละโซน
	for _, r in L.roads do
		L.zones[r.from].exit = polar(r.a0, r.R0, r.y0)
		local toZone = L.zones[r.to]
		if r.to == count then
			local edge = polar(r.a1, toZone.radius - 6, r.y1)
			toZone.entry = edge
		else
			toZone.entry = polar(r.a1, r.R1, r.y1)
		end
	end
	local z1 = L.zones[1]
	local dir = flat(L.village.center - z1.center).Unit
	z1.entry = z1.center + dir * (z1.radius - 6)
	return L
end

function MapBuilder.RoadPoints(r)
	local pts = {}
	local arcLen = math.abs(r.a1 - r.a0) * (r.R0 + r.R1) / 2
	local n = math.max(2, math.ceil(arcLen / 28))
	for s = 0, n do
		local t = s / n
		local y = r.y0 + (r.y1 - r.y0) * t
		local R = r.R0 + (r.R1 - r.R0) * t
		R = math.max(R, mountainR(y) + 16)
		table.insert(pts, polar(r.a0 + (r.a1 - r.a0) * t, R, y))
	end
	return pts
end

-- ========== โลก: พื้น, ภูเขา, ถนน, แสง ==========
function MapBuilder.BuildWorld()
	withHistory("Chop a Tree: World", function()
		local L = MapBuilder.Layout()
		local root = mapRoot()

		-- ย้ายของเทมเพลตเดิมออก (ไม่ลบ เก็บไว้ที่ ServerStorage.OldTemplate)
		local old = F(ServerStorage, "OldTemplate")
		for _, name in { "Baseplate", "SpawnLocation" } do
			local inst = workspace:FindFirstChild(name)
			if inst then
				inst.Parent = old
			end
		end

		local ground = fresh(root, "Ground")
		for gx = -1, 0 do
			for gz = -1, 0 do
				P({
					Name = "Grass",
					Size = Vector3.new(1700, 8, 1700),
					CFrame = CFrame.new(gx * 1700 + 850, -4, gz * 1700 + 850),
					Color = Color3.fromRGB(98, 170, 70),
					Material = Enum.Material.Grass,
					Parent = ground,
				})
			end
		end

		-- ภูเขาขั้นบันได (low-poly) สีตามโซนของความสูงนั้น
		local mountain = fresh(root, "Mountain")
		local top = Zones.List[#Zones.List].y - 12
		local y0 = 0
		local idx = 0
		while y0 < top do
			idx += 1
			local h = math.min(40, top - y0)
			local band = Zones.List[1]
			for _, z in Zones.List do
				if y0 + h / 2 >= z.y - 60 then
					band = z
				end
			end
			local shade = (idx % 2 == 0) and 1 or 0.92
			local c = band.colors.cliff
			disk(mountain, Vector3.zero, mountainR(y0 + h / 2), h, y0 + h, Color3.new(c.R * shade, c.G * shade, c.B * shade), Enum.Material.Rock, "Tier" .. idx)
			y0 += h
		end

		-- ถนนเกลียว
		local roads = fresh(root, "Roads")
		for _, r in L.roads do
			local folder = F(roads, string.format("Road_%d_%d", r.from, r.to))
			local pts = MapBuilder.RoadPoints(r)
			pathSegments(folder, pts, 26, 4, Color3.fromRGB(150, 120, 85), Enum.Material.Ground, "Road")
			-- หินขอบทางเป็นระยะ
			for i = 2, #pts - 1, 3 do
				local p = pts[i]
				local out = flat(p).Unit
				P({
					Name = "EdgeRock",
					Size = Vector3.new(4, 3, 4),
					CFrame = CFrame.new(p + out * 14 + Vector3.new(0, 1, 0)) * CFrame.Angles(0.3, i, 0.2),
					Color = Color3.fromRGB(120, 115, 105),
					Material = Enum.Material.Slate,
					Parent = folder,
				})
			end
		end
		-- ทางจากหมู่บ้านไปโซน 1
		local v = L.village
		local z1 = L.zones[1]
		local gateDir = flat(z1.entry - v.center).Unit
		local gatePos = v.center + gateDir * (v.radius - 4)
		local villageRoad = {}
		local n = 14
		for s = 0, n do
			local t = s / n
			local p = gatePos:Lerp(z1.entry, t)
			table.insert(villageRoad, Vector3.new(p.X, 0.9 + (z1.y - 0.9) * t * t, p.Z))
		end
		pathSegments(F(roads, "Road_Village_1"), villageRoad, 26, 4, Color3.fromRGB(150, 120, 85), Enum.Material.Ground, "Road")

		-- แสง/บรรยากาศ: low-poly + สมจริง
		pcall(function()
			Lighting.Technology = Enum.Technology.Future
		end)
		Lighting.ClockTime = 14
		Lighting.Brightness = 2.5
		Lighting.OutdoorAmbient = Color3.fromRGB(150, 150, 160)
		Lighting.EnvironmentDiffuseScale = 0.6
		Lighting.EnvironmentSpecularScale = 0.6
		local atmo = Lighting:FindFirstChildOfClass("Atmosphere") or Instance.new("Atmosphere")
		atmo.Density = 0.28
		atmo.Offset = 0.12
		atmo.Color = Color3.fromRGB(200, 220, 255)
		atmo.Decay = Color3.fromRGB(110, 140, 190)
		atmo.Glare = 0.2
		atmo.Haze = 1.2
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
	local s = sign(m, (cf * CFrame.new(0, 9, -26)).Position, front, "ฐาน " .. index .. " · ว่าง", 12, 3.2)
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
		disk(village, V, v.radius, 1.2, 0.9, Color3.fromRGB(176, 168, 150), Enum.Material.Cobblestone, "Plaza")
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
			{ "SeedShop", "ร้านเมล็ด", Color3.fromRGB(76, 175, 80) },
			{ "EggConveyor", "สายพานไข่", nil },
			{ "UpgradeShop", "ร้านอัปเกรด", Color3.fromRGB(29, 78, 216) },
			{ "Sawmill", "โรงเลื่อย (ขาย Wood)", Color3.fromRGB(180, 83, 9) },
			{ "NPC_Bram", "ปู่ Bram", nil },
			{ "Leaderboards", "กระดานผู้นำ", nil },
			{ "ArenaPortal", "Chop Arena (PvP)", nil },
			{ "WarpHub", "หินวาร์ป", nil },
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
				sign(m, (cf * CFrame.new(0, 7, 2)).Position, V, "สายพานไข่", 14, 3.5, Color3.fromRGB(30, 36, 51), Color3.fromRGB(253, 230, 138))
				m.PrimaryPart = belt
				tag(m, "Shop", { ShopType = id })
			elseif id == "NPC_Bram" then
				local m = M(services, id)
				local body = P({ Name = "Body", Size = Vector3.new(4, 5, 2.5), CFrame = cf * CFrame.new(0, 3.6, 0), Color = Color3.fromRGB(120, 90, 60), Parent = m })
				P({ Name = "Head", Shape = Enum.PartType.Ball, Size = Vector3.new(3, 3, 3), CFrame = cf * CFrame.new(0, 7.6, 0), Color = Color3.fromRGB(240, 200, 160), Parent = m })
				P({ Name = "Beard", Size = Vector3.new(2.6, 2.4, 1), CFrame = cf * CFrame.new(0, 6.4, -1.2), Color = Color3.fromRGB(245, 245, 245), Parent = m })
				P({ Name = "Hat", Size = Vector3.new(3.6, 1, 3.6), CFrame = cf * CFrame.new(0, 9.4, 0), Color = Color3.fromRGB(60, 120, 60), Parent = m })
				sign(m, (cf * CFrame.new(0, 12, 0)).Position, V, "ปู่ Bram", 8, 2.4, Color3.fromRGB(30, 36, 51), Color3.fromRGB(253, 230, 138))
				m.PrimaryPart = body
				tag(m, "NPC", { NpcId = "Bram" })
			elseif id == "Leaderboards" then
				local m = M(services, id)
				for k, title in { "ต้นไม้ที่ฟัน", "ดาเมจสูงสุด" } do
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
		sign(gate, (gcf * CFrame.new(0, 27, 0)).Position, V, "ประตูสู่ป่า → ทุ่งหญ้าแสงแดด", 30, 4, Color3.fromRGB(30, 36, 51), Color3.fromRGB(190, 242, 100))
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
local function makeTree(parent, zone, tier, pos, rng, tagName)
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
	for _, x in { -15, 15 } do
		P({ Name = "Pillar", Size = Vector3.new(5, 26, 5), CFrame = cf * CFrame.new(x, 13, 0), Color = Color3.fromRGB(70, 60, 80), Material = Enum.Material.Slate, Parent = m })
	end
	P({ Name = "Beam", Size = Vector3.new(40, 4, 5), CFrame = cf * CFrame.new(0, 27, 0), Color = Color3.fromRGB(60, 50, 70), Material = Enum.Material.Slate, Parent = m })
	local barrier = P({ Name = "RotBarrier", Size = Vector3.new(25, 24, 1), CFrame = cf * CFrame.new(0, 12, 0), Color = Zones.RotColor, Material = Enum.Material.Neon, Transparency = 0.45, CanCollide = true, Parent = m })
	sign(m, (cf * CFrame.new(0, 31.5, 0)).Position, (cf * CFrame.new(0, 0, 30)).Position, "ประตูราเน่า · ล้มบอสเพื่อเปิด → โซน " .. toZone, 30, 3.5, Color3.fromRGB(30, 20, 40), Color3.fromRGB(216, 180, 254))
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

local function bossArena(parent, pos, zone)
	local m = M(parent, "BossArena")
	local c = zone.colors.ground
	disk(m, pos, 40, 0.6, pos.Y + 0.3, Color3.new(c.R * 0.85, c.G * 0.85, c.B * 0.85), Enum.Material.Slate, "Floor")
	for k = 0, 15 do
		local a = k / 16 * math.pi * 2
		P({ Name = "Stone", Size = Vector3.new(3, 5 + (k % 3) * 2, 3), CFrame = CFrame.new(pos + Vector3.new(math.sin(a) * 42, 3, math.cos(a) * 42)) * CFrame.Angles(0, a, 0.1), Color = Color3.fromRGB(110, 105, 100), Material = Enum.Material.Slate, Parent = m })
	end
	m.PrimaryPart = m.Floor
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
	elseif zone.id == 2 then
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
		local root = fresh(wilds, string.format("Zone%d_%s", index, zone.key))
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
		disk(folders.Ground, C, Z.radius, 10, Z.y, zone.colors.ground, groundMat, "Plateau")
		disk(folders.Ground, C, Z.radius * 0.9, 70, Z.y - 10, zone.colors.cliff, Enum.Material.Rock, "Cliff")

		-- ทางเดินจากทางเข้าไปทางออก
		local inward = flat(C - E).Unit
		local trailEnd = X or (C + inward * Z.radius * 0.6)
		local trail = {}
		for s = 0, 8 do
			local p = E:Lerp(trailEnd, s / 8)
			table.insert(trail, Vector3.new(p.X, Z.y + 0.25, p.Z))
		end
		local gc = zone.colors.ground
		pathSegments(folders.Ground, trail, 14, 0.5, Color3.new(gc.R * 0.7, gc.G * 0.6, gc.B * 0.5), Enum.Material.Ground, "Trail")

		-- จุดเกิดโซน + หินวาร์ป + ป้ายต้อนรับ
		local spawnPos = E + inward * 22
		local sp = P({ Name = "ZoneSpawn", Size = Vector3.new(8, 1, 8), CFrame = CFrame.new(spawnPos.X, Z.y + 0.5, spawnPos.Z), Transparency = 1, CanCollide = false, Parent = folders.Spawn })
		tag(sp, "ZoneSpawn", { Zone = index })
		local side = Vector3.new(inward.Z, 0, -inward.X)
		warpStone(folders.WarpStone, Vector3.new(spawnPos.X, Z.y, spawnPos.Z) + side * 18, index, zone.colors.accent)
		local signPos = E + inward * 12 - side * 16 + Vector3.new(0, 0, 0)
		P({ Name = "SignPost", Size = Vector3.new(1, 10, 1), CFrame = CFrame.new(signPos.X, Z.y + 5, signPos.Z), Color = Color3.fromRGB(110, 75, 45), Material = Enum.Material.Wood, Parent = folders.Decor })
		local welcome = zone.built and string.format("โซน %d · %s\n%s", index, zone.thai, zone.name)
			or string.format("โซน %d · %s\n(สร้างเต็มใน Phase 7)", index, zone.thai)
		sign(folders.Decor, Vector3.new(signPos.X, Z.y + 12, signPos.Z), E - inward * 40, welcome, 16, 7)

		-- ขอบเขต (กำแพงล่องหน เว้นทางเข้า/ออก)
		local segs = 28
		for k = 0, segs - 1 do
			local a = k / segs * math.pi * 2
			local p = C + Vector3.new(math.sin(a), 0, math.cos(a)) * (Z.radius - 1)
			local near = (flat(p - E).Magnitude < 26) or (X and flat(p - X).Magnitude < 26)
			if not near then
				P({ Name = "Wall", Size = Vector3.new(2 * math.pi * Z.radius / segs + 2, 40, 2), CFrame = CFrame.lookAt(Vector3.new(p.X, Z.y + 20, p.Z), Vector3.new(C.X, Z.y + 20, C.Z)), Transparency = 1, CanQuery = false, Parent = folders.Boundary })
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
		bossArena(folders.BossArena, arenaPos, zone)
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
			local far = C - inward * (Z.radius - 20)
			local rg = M(folders.Secrets, "RealmGate")
			local rcf = CFrame.lookAt(Vector3.new(far.X, Z.y + 16, far.Z), Vector3.new(C.X, Z.y + 16, C.Z))
			for k = 0, 19 do
				local a = k / 20 * math.pi * 2
				P({ Name = "Ring", Size = Vector3.new(2.5, 4.5, 2.5), CFrame = rcf * CFrame.new(math.cos(a) * 13, math.sin(a) * 13, 0) * CFrame.Angles(0, 0, a), Color = Color3.fromRGB(255, 215, 100), Material = Enum.Material.Neon, Parent = rg })
			end
			sign(rg, (rcf * CFrame.new(0, 19, 0)).Position, C, "ประตูมิติ · Realm 2 (เร็วๆ นี้)", 22, 3.5, Color3.fromRGB(30, 36, 51), Color3.fromRGB(255, 230, 150))
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
			if distToSegment(p, E, trailEnd) < 12 + margin then
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
			-- ต้นไม้ ~120 ต้น ระดับสูงขึ้นตามระยะจากทางเข้า
			local target = 120
			local tries = 0
			while #trees < target and tries < 6000 do
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
		table.insert(out, t .. "=" .. #CollectionService:GetTagged(t))
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
