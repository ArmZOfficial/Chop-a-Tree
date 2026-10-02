-- StoryService remains the unlock owner. This catches bypasses independently of client collision.
local Players = game:GetService("Players")
local RS = game:GetService("RunService")
local Collection = game:GetService("CollectionService")
local Net = require(game.ReplicatedStorage.Shared.Net)
local Zones = require(game.ReplicatedStorage.Shared.Config.Zones)
local Util = require(game.ReplicatedStorage.Shared.ZoneUtil)
local Data = require(script.Parent.DataService)
local Features = require(script.Parent.FeatureService)
local Arena = require(script.Parent.ArenaService)
local Gate = {}
local safe, connections = {}, {}
local prompts, notices = {}, {}
local elapsed = 0
function Gate.CanEnter(p, id)
	if id == "hub" then return true end
	return Zones.List[id] ~= nil and table.find(Data.Get(p, "Progress.UnlockedZones") or {}, id) ~= nil
end
local function fallback()
	local map = workspace:FindFirstChild("Map"); local v = map and map:FindFirstChild("Village")
	return v and v:FindFirstChild("VillageSpawn")
end
function Gate.Update()
	for _, p in Players:GetPlayers() do
		if not Data.IsLoaded(p) or not Features.IsEnabled("MapSystems") then safe[p] = nil; continue end
		local arena = Arena.State(p)
		if arena.mode or arena.transferring then continue end
		local c = p.Character; local h = c and c:FindFirstChildOfClass("Humanoid")
		local hr = h and h.Health > 0 and c:FindFirstChild("HumanoidRootPart")
		if not hr then safe[p] = nil; continue end
		local entry = safe[p]
		if entry and entry.character ~= c then entry = nil; safe[p] = nil end
		local id = Util.At(hr.Position)
		local surface = Util.SurfaceAt(hr.Position)
		local locked = type(surface) == "number" and not Gate.CanEnter(p, surface)
		local groundY = surface == "hub" and Zones.Hub.center.Y or type(surface)=="number" and Zones.List[surface].y
		if locked or hr.Position.Y < Zones.Tracking.killFloor or groundY and hr.Position.Y < groundY - 12 then
			local destination = entry and Gate.CanEnter(p, entry.zone) and entry.pivot
			if not destination then local spawn = fallback(); destination = spawn and spawn:GetPivot() + Vector3.new(0, 4, 0) end
			if destination then c:PivotTo(destination); hr.AssemblyLinearVelocity = Vector3.zero; hr.AssemblyAngularVelocity = Vector3.zero end
		elseif id and Gate.CanEnter(p, id) then
			-- Save only positions with nearby ground. Sea/air jumps never replace rescue points.
			local params = RaycastParams.new(); params.FilterType = Enum.RaycastFilterType.Exclude; params.FilterDescendantsInstances = { c }
			if workspace:Raycast(hr.Position, Vector3.new(0, -9, 0), params) then safe[p] = { character = c, pivot = c:GetPivot(), zone = id } end
		end
	end
end
function Gate.Init()
	local function attach(model)
		if prompts[model] or not model:IsDescendantOf(workspace) then return end
		local wall=model:FindFirstChild("RotBarrier");local id=model:GetAttribute("ToZone")
		if not wall or not Zones.List[id] then return end
		local prompt=Instance.new("ProximityPrompt");prompt.Name="ZoneUnlockPrompt";prompt.ActionText="Unlock Zone"
		prompt.ObjectText=Zones.List[id].name;prompt.MaxActivationDistance=18;prompt.RequiresLineOfSight=false;prompt.Parent=wall;prompts[model]=prompt
		table.insert(connections,prompt.Triggered:Connect(function(p)
			local root=p.Character and p.Character:FindFirstChild("HumanoidRootPart")
			if not Features.IsEnabled("MapSystems") or not Data.IsLoaded(p) or not root or (root.Position-wall.Position).Magnitude>20 or Gate.CanEnter(p,id) then return end
			if os.clock()-(notices[p] or -math.huge)<1 then return end;notices[p]=os.clock()
			Net.Event("Notify"):FireClient(p,{text="Light shrine in Zone {1} to unlock this gate",vars={id-1}})
		end))
	end
	for _,model in Collection:GetTagged("ZoneGate") do attach(model) end
	table.insert(connections,Collection:GetInstanceAddedSignal("ZoneGate"):Connect(attach))
	table.insert(connections,Collection:GetInstanceRemovedSignal("ZoneGate"):Connect(function(model) if prompts[model] then prompts[model]:Destroy();prompts[model]=nil end end))
	table.insert(connections, Players.PlayerRemoving:Connect(function(p) safe[p] = nil; notices[p] = nil end))
end
function Gate.Start()
	table.insert(connections, RS.Heartbeat:Connect(function(dt) elapsed += dt; if elapsed >= .2 then elapsed = 0; Gate.Update() end end))
end
function Gate.Destroy()
	for _,c in connections do c:Disconnect() end;table.clear(connections);table.clear(safe);table.clear(notices)
	for _,prompt in prompts do prompt:Destroy() end;table.clear(prompts)
end
return Gate
