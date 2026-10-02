-- Existing stone/Teleport pass contract, with one validated path for Story UI and map UI.
local Players = game:GetService("Players")
local Collection = game:GetService("CollectionService")
local S = game.ReplicatedStorage.Shared
local Zones = require(S.Config.Zones)
local Story = require(S.Config.Story)
local Data = require(script.Parent.DataService)
local Features = require(script.Parent.FeatureService)
local Run = require(script.Parent.RunService)
local Garden = require(script.Parent.GardenService)
local Arena = require(script.Parent.ArenaService)
local Net = require(S.Net)
local Travel = {}
local busy, cooldowns, connections = {}, {}, {}
local docks, dockModels, dockEndpoints = {}, {}, {}
local rides, rideId = {}, 0
function Travel.SkipBoat(p, token)
	local ride=rides[p]
	if not ride or type(token)~="number" or token~=ride.token or p.Character~=ride.character then return false,"Travel unavailable" end
	ride.skip=true;return true,"Ready"
end
local function root(p)
	local c = p.Character; local h = c and c:FindFirstChildOfClass("Humanoid")
	return h and h.Health > 0 and c:FindFirstChild("HumanoidRootPart")
end
local function nearStone(p)
	local hr = root(p); if not hr then return false end
	for _, stone in Collection:GetTagged("WarpStone") do
		if stone:IsDescendantOf(workspace) and (stone:GetPivot().Position - hr.Position).Magnitude <= Story.WarpRange then return true end
	end
	return false
end
local function valid(p, id, source)
	if not Features.IsEnabled("Story") or not Data.IsLoaded(p) or not root(p) then return false, "Warp unavailable" end
	if id ~= "Home" and (type(id) ~= "number" or id % 1 ~= 0 or id < 0 or id > #Zones.List) then return false, "Invalid destination" end
	local state = Arena.State(p)
	if state.mode or state.transferring then return false, "Leave the Arena queue before travelling" end
	if p:GetAttribute("CarryingEgg") then return false, "Cannot warp while carrying an egg" end
	if (p:GetAttribute("CombatUntil") or 0) > workspace:GetServerTimeNow() then return false, "Cannot travel during combat" end
	local atDock=source and docks[source]==id and source:IsDescendantOf(workspace) and (root(p).Position-source.Position).Magnitude<=16 and Features.IsEnabled("MapSystems")
	if source and not atDock then return false,"Move closer to the dock" end
	if not atDock and not nearStone(p) and not (Data.Get(p, "Purchases.passes") or {}).Teleport then return false, "Use at a warp stone only" end
	if type(id) == "number" and id > 0 then
		if not Run.CanAccess(p, id) then return false, "Cannot enter this zone yet" end
		local visits = Data.Get(p, "Progress.VisitedZones") or {}
		if Features.IsEnabled("MapSystems") and not atDock and not visits[tostring(id)] then return false, "Visit this zone before fast travel" end
	end
	return true
end
Travel.Check = valid -- Admin dry run; does not stream, move, settle or charge.
local function spawnFor(p, id)
	if id == "Home" then local base = Garden.Base(p); return base and base:FindFirstChild("BaseSpawn") end
	if id == 0 then
		local map = workspace:FindFirstChild("Map"); local village = map and map:FindFirstChild("Village")
		return village and village:FindFirstChild("VillageSpawn")
	end
	for _, spawn in Collection:GetTagged("ZoneSpawn") do if spawn:IsDescendantOf(workspace) and spawn:GetAttribute("Zone") == id then return spawn end end
end
local function destination(p, spawn)
	local params = OverlapParams.new(); params.FilterType = Enum.RaycastFilterType.Exclude; params.FilterDescendantsInstances = { p.Character, spawn }
	for _, offset in { Vector3.new(0,4,0), Vector3.new(6,4,0), Vector3.new(-6,4,0), Vector3.new(0,4,6), Vector3.new(0,4,-6) } do
		local cf = spawn:GetPivot() + offset
		local clear = true
		for _, part in workspace:GetPartBoundsInBox(cf, Vector3.new(3,5,3), params) do if part.CanCollide then clear = false; break end end
		local ray = RaycastParams.new(); ray.FilterType = Enum.RaycastFilterType.Exclude; ray.FilterDescendantsInstances = { p.Character, spawn }
		if clear and workspace:Raycast(cf.Position, Vector3.new(0,-12,0), ray) then return cf end
	end
end
function Travel.Warp(p, id, source)
	if busy[p] or os.clock() < (cooldowns[p] or 0) then return false, "Please wait" end
	local ok, message = valid(p, id, source); if not ok then return false, message end
	local spawn = spawnFor(p, id); if not spawn then return false, "Destination unavailable" end
	local character = p.Character; busy[p] = true
	local succeeded, result, text = pcall(function()
		if source then
			rideId+=1
			local ride={token=rideId,character=character};rides[p]=ride
			local duration=Story.MapBoatDuration
			Net.Event("StoryShow"):FireClient(p,{kind="boat",token=ride.token,boat=source.Parent,from=source.CFrame,to=dockEndpoints[id] and dockEndpoints[id].CFrame or spawn:GetPivot(),bend=Story.MapBoatBend,duration=duration})
			local untilAt=os.clock()+duration
			while not ride.skip and os.clock()<untilAt do
				if p.Parent~=Players or p.Character~=character or not root(p) then return false,"Character not ready" end
				if not valid(p,id,source) then return false,"Travel unavailable" end
				task.wait(.05)
			end
		end
		pcall(p.RequestStreamAroundAsync, p, spawn:GetPivot().Position, 3)
		if source and not rides[p] then return false,"Travel unavailable" end
		if p.Parent ~= Players or p.Character ~= character or not spawn:IsDescendantOf(workspace) then return false, "Character not ready" end
		local allowed, reason = valid(p, id, source); if not allowed then return false, reason end
		local cf = destination(p, spawn); if not cf then return false, "Destination obstructed" end
		if id == 0 or id == "Home" then
			-- Settle synchronously: a delayed Run.End teleport must not overwrite the Home destination.
			if Data.Get(p, "Run.Active") then Run.End(p, false) end
		elseif not Data.Get(p, "Run.Active") and not Run.Begin(p) then return false, "Cannot start run" end
		character:PivotTo(cf); local hr = root(p); if hr then hr.AssemblyLinearVelocity = Vector3.zero end
		cooldowns[p] = os.clock() + 2 -- Same cooldown for every player; pass grants remote access only.
		return true, "Travel complete"
	end)
	local ride=rides[p];rides[p]=nil
	if ride and p.Parent==Players then Net.Event("StoryShow"):FireClient(p,{kind="boatEnd",token=ride.token}) end
	busy[p] = nil
	if not succeeded then warn("[Travel] " .. tostring(result)); return false, "Travel unavailable" end
	return result, text
end
function Travel.Init()
	table.insert(connections, Players.PlayerRemoving:Connect(function(p) busy[p] = nil; cooldowns[p] = nil; rides[p]=nil end))
	local map=workspace:FindFirstChild("Map");local village=map and map:FindFirstChild("Village");local dock=village and village:FindFirstChild("Dock")
	local shore=spawnFor(nil,1)
	local function boat(at,id)
		local model=Instance.new("Model");model.Name="MapTravelBoat"
		local floor=Instance.new("Part");floor.Name="Hull";floor.Size=Vector3.new(9,1.5,15);floor.CFrame=at;floor.Anchored=true;floor.CanCollide=false;floor.CanTouch=false;floor.CanQuery=false
		floor.Material=Enum.Material.Plastic;floor.TopSurface=Enum.SurfaceType.Studs;floor.Color=Color3.fromRGB(151,92,45);floor.Parent=model
		for _,x in {-4,4} do local rail=floor:Clone();rail.Name="Rail";rail.Size=Vector3.new(1,2,15);rail.CFrame=at*CFrame.new(x,1,0);rail.Parent=model end
		model.PrimaryPart=floor;model.Parent=workspace;table.insert(dockModels,model);docks[floor]=id;dockEndpoints[id==1 and 0 or 1]=floor
		local prompt=Instance.new("ProximityPrompt");prompt.ActionText="Travel";prompt.ObjectText=id==1 and "Sunny Meadow" or "Rootfall";prompt.MaxActivationDistance=14;prompt.RequiresLineOfSight=false;prompt.Parent=floor
		table.insert(connections,prompt.Triggered:Connect(function(p)
			local ok,msg=Travel.Warp(p,id,floor)
			if not ok then require(S.Net).Event("Notify"):FireClient(p,{text=msg,kind="warn"}) end
		end))
		local function enabled() prompt.Enabled=Features.IsEnabled("MapSystems") end
		table.insert(connections,game.ReplicatedStorage.FeatureFlags:GetAttributeChangedSignal("MapSystems"):Connect(enabled));enabled()
	end
	if dock and shore then
		boat(dock:GetPivot()+Vector3.new(0,1,15),1)
		boat(CFrame.new(Story.MapBoatShore),0)
	end
end
function Travel.Start() end
function Travel.Destroy()
	for _,ride in rides do ride.skip=true end;table.clear(rides)
	for _,c in connections do c:Disconnect() end;table.clear(connections);table.clear(busy);table.clear(cooldowns);table.clear(docks);table.clear(dockEndpoints)
	for _,model in dockModels do model:Destroy() end;table.clear(dockModels)
end
return Travel
