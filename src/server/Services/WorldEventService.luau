-- Local tree events; existing Weather/WeatherEncounter services still own Meteor/Fog/world-boss rewards.
local Players = game:GetService("Players")
local Collection = game:GetService("CollectionService")
local RS = game:GetService("RunService")
local S = game.ReplicatedStorage.Shared
local C = require(S.Config.WorldEvents)
local Zones = require(S.Config.Zones)
local Features = require(script.Parent.FeatureService)
local Run = require(script.Parent.RunService)
local Tree = require(script.Parent.TreeService)
local Weather = require(script.Parent.WeatherService)
local Event = {}
local trees, connections = {}, {}
local active, folder, nextAt = nil, nil, 0
local rng = Random.new(40261002)
local function publish(id, zone, endsAt, position)
	folder:SetAttribute("id",id);folder:SetAttribute("zone",zone);folder:SetAttribute("endsAt",endsAt);folder:SetAttribute("position",position)
end
function Event.Stop()
	if active and active.tree then Tree.SetSpecial(active.tree,nil) end
	active=nil;nextAt=os.clock()+C.Cooldown
	if folder then publish(nil,nil,nil,nil) end
end
function Event.Get() return active end
function Event.WoodMultiplier(_,zone) return active and active.id=="TimberRush" and active.zone==zone and os.clock()<active.untilAt and 2 or 1 end
function Event.StartEvent(id,zone)
	local def=type(id)=="string" and C.ById[id]
	if not def or not Features.IsEnabled("MapSystems") then return false,"Unknown/disabled event" end
	if zone~=nil and (type(zone)~="number" or zone%1~=0 or not Zones.List[zone]) then return false,"Invalid zone" end
	if active then return false,"An event is already active" end
	if def.weather then
		if zone and zone~=def.zone then return false,"This existing encounter runs in Zone 1" end
		Weather.Force(def.weather,def.weather=="RotInvasion" and 600 or 240);return true,"Existing weather encounter started"
	end
	if Weather.State().id~="Clear" then return false,"Wait for clear weather" end
	zone=zone or 1
	local tree
	if def.tree then
		local pool={}
		for model in trees do if model:IsDescendantOf(workspace) and model:GetAttribute("Zone")==zone and model:GetAttribute("HealthRatio")==1 and model:GetAttribute("Alive")~=false and not model:GetAttribute("SpecialKind") then table.insert(pool,model) end end
		if #pool==0 then return false,"No healthy pooled tree" end
		tree=pool[rng:NextInteger(1,#pool)];if not Tree.SetSpecial(tree,def.tree) then return false,"Tree unavailable" end
	end
	active={id=id,zone=zone,tree=tree,untilAt=os.clock()+def.duration}
	publish(id,zone,workspace:GetServerTimeNow()+def.duration,tree and tree:GetPivot().Position)
	return true,"Event started"
end
function Event.Update()
	if not Features.IsEnabled("MapSystems") then if active then Event.Stop() end;publish(nil,nil,nil,nil);return end
	local weather=Weather.State()
	if active then
		if os.clock()>=active.untilAt or weather.id~="Clear" or active.tree and (not active.tree.Parent or active.tree:GetAttribute("Alive")==false) then Event.Stop() end
		return
	end
	for _,def in C.List do if def.weather==weather.id then
		publish(def.id,def.zone,weather.endsAt,nil);return
	end end
	if folder:GetAttribute("id") then publish(nil,nil,nil,nil) end
	if weather.id~="Clear" or os.clock()<nextAt or #Players:GetPlayers()<C.MinPlayers then return end
	local candidates={}
	for _,p in Players:GetPlayers() do local id=Run.ZoneAt(p);if id and Run.CanAccess(p,id) and not table.find(candidates,id) then table.insert(candidates,id) end end
	if #candidates==0 then nextAt=os.clock()+10;return end
	local total=0
	for _,def in C.List do if not def.weather and (def.weight or 0)>0 then total+=def.weight end end
	if total<=0 then nextAt=os.clock()+C.Cooldown;return end
	local roll=rng:NextNumber()*total;local chosen
	for _,def in C.List do if not def.weather and (def.weight or 0)>0 then
		roll-=def.weight;if roll<=0 then chosen=def.id;break end
	end end
	local ok=chosen and Event.StartEvent(chosen,candidates[rng:NextInteger(1,#candidates)])
	if not ok then nextAt=os.clock()+30 end
end
function Event.Init()
	folder=Instance.new("Folder");folder.Name="WorldEventState";folder.Parent=game.ReplicatedStorage
	for _,model in Collection:GetTagged("Tree") do trees[model]=true end
	table.insert(connections,Collection:GetInstanceAddedSignal("Tree"):Connect(function(model) trees[model]=true end))
	table.insert(connections,Collection:GetInstanceRemovedSignal("Tree"):Connect(function(model) trees[model]=nil end))
	Run.SetMapMultiplierProvider(Event.WoodMultiplier);nextAt=os.clock()+C.Cooldown
end
function Event.Start()
	local elapsed=0;table.insert(connections,RS.Heartbeat:Connect(function(dt) elapsed+=dt;if elapsed>=.5 then elapsed=0;Event.Update() end end))
end
function Event.Destroy()
	Event.Stop();Run.SetMapMultiplierProvider(nil)
	for _,c in connections do c:Disconnect() end;table.clear(connections);table.clear(trees)
	if folder then folder:Destroy();folder=nil end
end
return Event
