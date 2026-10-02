local Players = game:GetService("Players")
local Collection = game:GetService("CollectionService")
local S = game.ReplicatedStorage.Shared
local Config = require(S.Config.Explorer)
local Zones = require(S.Config.Zones)
local Net = require(S.Net)
local ChestBuilder = require(S.ChestBuilder)
local Data = require(script.Parent.DataService)
local Features = require(script.Parent.FeatureService)
local Gate = require(script.Parent.GateService)
local Weapon = require(script.Parent.WeaponService)
local Explorer = {}
local folder, connections, cooldowns, markers = nil, {}, {}, {}
function Explorer.Progress(p, zone)
	local data = Data.Get(p, "Explorer.collected") or {}
	local count, total = 0, 0
	for _, def in Config.List do if def.zone == zone then total += 1; if data[def.id] then count += 1 end end end
	return count, total
end
function Explorer.Collect(p, id)
	if type(id) ~= "string" or #id > 80 then return false end
	local def = Config.ById[id]
	local c = p.Character; local h = c and c:FindFirstChildOfClass("Humanoid")
	local hr = h and h.Health > 0 and c:FindFirstChild("HumanoidRootPart")
	if not def or not hr or not Data.IsLoaded(p) or not Features.IsEnabled("MapSystems") then return false end
	if not Gate.CanEnter(p, def.zone) or Zones.At(hr.Position) ~= def.zone or (hr.Position - def.position).Magnitude > Config.Range then return false end
	local now = os.clock(); if now - (cooldowns[p] or -math.huge) < Config.Cooldown then return false end; cooldowns[p] = now
	local data = Data.Get(p, "Explorer")
	if not data or data.collected[id] then return false end
	-- Single non-yielding transaction; persistence uses the existing session profile.
	data.collected[id] = true
	local count, total = Explorer.Progress(p, def.zone)
	if count == total and not data.completed[tostring(def.zone)] then
		local reward=Config.Reward
		if not Weapon.GrantChest(p,reward.rarity,reward.level,reward.zone,reward.count,Data.Get(p,"Meta.AdminTouched")==true) then
			data.collected[id]=nil;return false
		end
		data.completed[tostring(def.zone)] = true
	end
	Data.Set(p, "Explorer", data)
	Net.Event("Notify"):FireClient(p, { text = "Explored {1}: {2}/{3}", vars = { Zones.List[def.zone].name, count, total } })
	return true
end
function Explorer.Init()
	folder = Instance.new("Folder"); folder.Name = "ExplorerMarkers"; folder.Parent = workspace
	for _, def in Config.List do
		local p = Instance.new("Part"); p.Name = def.id; p.Size = Vector3.new(3, 3, 3); p.Position = def.position
		p.Anchored = true; p.CanCollide = false; p.CanTouch = false; p.CanQuery = false
		p.Material = Enum.Material.Plastic; p.TopSurface = Enum.SurfaceType.Studs
		p.Color = Zones.List[def.zone].colors.accent; p:SetAttribute("ExplorerId", def.id); p:SetAttribute("Zone", def.zone)
		p.Parent = folder; Collection:AddTag(p, "ExplorerCollectible"); markers[def.id] = p
		if def.kind=="Mini-chest" then
			p.Transparency=1
			local chest=ChestBuilder.Build(1,CFrame.new(def.position-Vector3.new(0,2.4,0)));chest.Name="ExplorerChest";chest.Parent=p
		end
		local prompt = Instance.new("ProximityPrompt"); prompt.ActionText = "Discover"; prompt.ObjectText = def.kind
		prompt.MaxActivationDistance = Config.Range - 2; prompt.RequiresLineOfSight = false; prompt.Parent = p
		table.insert(connections, prompt.Triggered:Connect(function(player) Explorer.Collect(player, def.id) end))
	end
	local function visible() folder.Parent = Features.IsEnabled("MapSystems") and workspace or game.ServerStorage end
	table.insert(connections, game.ReplicatedStorage.FeatureFlags:GetAttributeChangedSignal("MapSystems"):Connect(visible)); visible()
	table.insert(connections, Players.PlayerRemoving:Connect(function(p) cooldowns[p] = nil end))
end
function Explorer.Start() end
function Explorer.Destroy()
	for _, c in connections do c:Disconnect() end; table.clear(connections); table.clear(cooldowns); table.clear(markers)
	if folder then folder:Destroy(); folder = nil end
end
return Explorer
