-- Shared normalized health lets different Rebirth players contribute fairly.
local Players=game:GetService("Players")
local Collection=game:GetService("CollectionService")
local Pathfinding=game:GetService("PathfindingService")
local Shared=game.ReplicatedStorage.Shared
local Net=require(Shared.Net)
local Balance=require(Shared.Balance)
local Config=require(Shared.Config.Forest)
local Data=require(script.Parent.DataService)
local Run=require(script.Parent.RunService)
local Features=require(script.Parent.FeatureService)
local Tree={}
local trees, cooldowns, navigating, chestStates, collected={},{},{},{},{}
local rng=Random.new()
local function root(player)
	local c=player.Character
	local h=c and c:FindFirstChildOfClass("Humanoid")
	return h and h.Health>0 and c:FindFirstChild("HumanoidRootPart")
end
local function position(model)
	local p=model.PrimaryPart
	return p and p.Position-Vector3.new(0,p.Size.Y/2,0)
end
local function flatDistance(a,b)
	return Vector3.new(a.X-b.X,0,a.Z-b.Z).Magnitude
end

function Tree.Reset(model)
	local s=trees[model]
	if not s or not model.Parent then return end
	s.ratio=1; s.contributors={}; s.cycle+=1
	model:SetAttribute("HealthRatio",1); model:SetAttribute("Alive",true)
	for part,original in s.parts do if part.Parent then part.Transparency=original[1]; part.CanCollide=original[2] end end
end

local function register(model)
	if trees[model] or not model:IsA("Model") or not model:IsDescendantOf(workspace) or not model.PrimaryPart then return end
	local zone,tier=model:GetAttribute("Zone"),model:GetAttribute("Tier")
	if type(zone)~="number" or type(tier)~="number" or zone<1 or zone>8 or tier<1 or tier>6 then return end
	local s={ratio=1,contributors={},cycle=0,parts={}}
	for _,d in model:GetDescendants() do if d:IsA("BasePart") then s.parts[d]={d.Transparency,d.CanCollide} end end
	trees[model]=s; Tree.Reset(model)
end

local function fell(model,s,now)
	model:SetAttribute("Alive",false); model:SetAttribute("HealthRatio",0)
	for part in s.parts do if part.Parent then part.Transparency=1; part.CanCollide=false end end
	for contributor,entry in s.contributors do
		if now-entry.at<=Config.ContributionWindow and contributor.Parent and Run.Get(contributor)==entry.run then
			Run.Award(contributor,model:GetAttribute("Zone"),model:GetAttribute("Tier"),entry.autoCut)
		end
	end
	local cycle=s.cycle
	local population=0
	for _,other in Players:GetPlayers() do if Run.ZoneAt(other)==model:GetAttribute("Zone") then population+=1 end end
	local delay=Config.RespawnSeconds/math.clamp(population/3,1,2)
	task.delay(delay,function() if trees[model]==s and s.cycle==cycle then Tree.Reset(model) end end)
end

function Tree.ClearZone(player)
	local r=Run.Get(player); local zone=Run.ZoneAt(player); local count=0
	if not r or not r.Active or not zone then return 0 end
	for model,s in trees do
		if model.Parent and s.ratio>0 and model:GetAttribute("Zone")==zone then
			s.ratio=0; s.contributors[player]={at=os.clock(),autoCut=false,run=r}
			fell(model,s,os.clock()); count+=1
		end
	end
	return count
end

function Tree.Hit(player,model)
	local s=trees[model]
	local r=Run.Get(player)
	local hr=root(player)
	if not Features.IsEnabled("Forest") or not s or s.ratio<=0 or not r or not r.Active or not hr then return false,"Inactive" end
	local zone,tier=model:GetAttribute("Zone"),model:GetAttribute("Tier")
	if not Run.CanAccess(player,zone) or Run.ZoneAt(player)~=zone then return false,"Zone locked" end
	local p=position(model)
	if flatDistance(hr.Position,p)>Config.AttackRange or math.abs(hr.Position.Y-p.Y)>12 then return false,"Out of range" end
	local rebirth=Data.Get(player,"Progress.Rebirth")
	local power=Run.Power(player)
	if power<Balance.TreeRequiredPower(zone,tier,rebirth) then return false,"Power too low" end
	local now=os.clock()
	if now-(cooldowns[player] or -math.huge)<Config.AttackInterval then return false,"Cooldown" end
	local params=RaycastParams.new(); params.FilterType=Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances={player.Character}; params.RespectCanCollide=true
	local aim=p+Vector3.new(0,3,0)
	local obstacle=workspace:Raycast(hr.Position,aim-hr.Position,params)
	if obstacle and not obstacle.Instance:IsDescendantOf(model) then return false,"Blocked" end
	cooldowns[player]=now
	local crit=rng:NextNumber()<Balance.Get("CritChance")
	local damage=power*(crit and Balance.Get("CritMult") or 1)
	local fraction=math.min(s.ratio,damage/Balance.TreeHP(zone,tier,rebirth))
	s.ratio=math.max(0,s.ratio-fraction)
	local previous=s.contributors[player]
	-- A manual finishing hit cannot erase AutoCut's reward reduction.
	local usedAuto=Run.GetModes(player).AutoCut or (previous and previous.run==r and now-previous.at<=Config.ContributionWindow and previous.autoCut) or false
	s.contributors[player]={at=now,autoCut=usedAuto,run=r}
	model:SetAttribute("HealthRatio",s.ratio)
	Data.Set(player,"Stats.HighestHit",math.max(Data.Get(player,"Stats.HighestHit"),damage))
	Net.Event("TreeHit"):FireAllClients({tree=model,position=aim,damage=damage,crit=crit,player=player.UserId,dead=s.ratio==0,tier=tier})
	if s.ratio==0 then
		fell(model,s,now)
	end
	return true,damage
end

local function avoidDanger(p,zone)
	for _,tag in {"Nest","BossArena"} do
		for _,m in Collection:GetTagged(tag) do
			if m:IsDescendantOf(workspace) and m:GetAttribute("Zone")==zone and m:IsA("Model") and m.PrimaryPart then
				if flatDistance(p,m.PrimaryPart.Position)<(tag=="Nest" and 18 or 50) then return true end
			end
		end
	end
	return false
end

function Tree.Nearest(player,maxDistance,autoCut)
	local hr=root(player)
	local zone=Run.ZoneAt(player)
	if not hr or not zone or not Run.CanAccess(player,zone) then return nil end
	local best,dist=nil,maxDistance or math.huge
	for model,s in trees do
		if model.Parent and s.ratio>0 and model:GetAttribute("Zone")==zone then
			local p=position(model)
			local d=flatDistance(hr.Position,p)
			if d<dist and Run.Power(player)>=Balance.TreeRequiredPower(zone,model:GetAttribute("Tier"),Data.Get(player,"Progress.Rebirth")) and (not autoCut or not avoidDanger(p,zone)) then best,dist=model,d end
		end
	end
	return best
end

local function autoWalk(player,model)
	if navigating[player] then return end
	navigating[player]=true
	task.spawn(function()
		local ok,err=pcall(function()
			local hr=root(player); if not hr then return end
			local zone=Run.ZoneAt(player)
			local p=position(model)
			local away=Vector3.new(hr.Position.X-p.X,0,hr.Position.Z-p.Z)
			local target=p+(away.Magnitude>0 and away.Unit or Vector3.xAxis)*9
			local path=Pathfinding:CreatePath({AgentRadius=2,AgentHeight=5,AgentCanJump=true,WaypointSpacing=12})
			path:ComputeAsync(hr.Position,target)
			if path.Status~=Enum.PathStatus.Success then return end
			for _,waypoint in path:GetWaypoints() do
				if not Features.IsEnabled("Forest") or not Features.IsEnabled("AutoCut") or not Run.GetModes(player).AutoCut or Run.ZoneAt(player)~=zone or not root(player) or model:GetAttribute("Alive")==false then break end
				if avoidDanger(waypoint.Position,zone) then break end
				local hum=player.Character:FindFirstChildOfClass("Humanoid")
				if waypoint.Action==Enum.PathWaypointAction.Jump then hum.Jump=true end
				hum:MoveTo(waypoint.Position)
				local deadline=os.clock()+3
				repeat task.wait(0.1) until not root(player) or flatDistance(root(player).Position,waypoint.Position)<3 or os.clock()>deadline or not Run.GetModes(player).AutoCut
				if not root(player) or os.clock()>deadline then break end
			end
		end)
		navigating[player]=nil
		if not ok then warn("[TreeService] AutoCut: "..tostring(err)) end
	end)
end

function Tree.CollectNearby(player)
	local r=Run.Get(player); local hr=root(player)
	if not r or not r.Active or not hr then return end
	if not collected[player] or collected[player].run~=r then collected[player]={run=r,spots={}} end
	local seen=collected[player].spots
	for spot,s in chestStates do
		if s.ready and spot:GetAttribute("Zone")==Run.ZoneAt(player) and Run.CanAccess(player,spot:GetAttribute("Zone")) and flatDistance(hr.Position,spot.Position)<=Config.ChestCollectRange and seen[spot]~=s.generation then
			if Run.CollectChest(player,spot,s.generation) then seen[spot]=s.generation end
		end
	end
end

function Tree.Init()
	for _,m in Collection:GetTagged("Tree") do register(m) end
	Collection:GetInstanceAddedSignal("Tree"):Connect(register)
	Collection:GetInstanceRemovedSignal("Tree"):Connect(function(m) trees[m]=nil end)
	for _,spot in Collection:GetTagged("ChestSpot") do if spot:IsA("BasePart") and spot:IsDescendantOf(workspace) then chestStates[spot]={ready=false,generation=0} end end
	Net.Event("ForestAction").OnServerEvent:Connect(function(player,action,model)
		if action=="Hit" and typeof(model)=="Instance" and trees[model] then Tree.Hit(player,model) end
	end)
	Players.PlayerRemoving:Connect(function(player) cooldowns[player]=nil; collected[player]=nil end)
end

function Tree.Start()
	task.spawn(function()
		while true do
			if Features.IsEnabled("Forest") then
				for _,player in Players:GetPlayers() do
					local r=Run.Get(player); local mode=Run.GetModes(player)
					if r and r.Active then
						if mode.AutoCut and not Features.IsEnabled("AutoCut") then Run.SetMode(player,"AutoCut",false) end
						if mode.AutoAttack or mode.AutoCut then
							local tree=Tree.Nearest(player,mode.AutoCut and 700 or Config.AttackRange,mode.AutoCut)
							if tree then local ok,reason=Tree.Hit(player,tree); if not ok and mode.AutoCut and (reason=="Out of range" or reason=="Blocked") then autoWalk(player,tree) end end
						end
						Tree.CollectNearby(player)
					end
				end
			end
			task.wait(0.2)
		end
	end)
	task.spawn(function()
		while true do
			for spot,s in chestStates do
				local nearby,alive=0,false
				for model,state in trees do if model.Parent and model:GetAttribute("Zone")==spot:GetAttribute("Zone") and flatDistance(position(model),spot.Position)<=Config.ChestClearRadius then nearby+=1; if state.ratio>0 then alive=true end end end
				local ready=nearby>0 and not alive
				if ready and not s.ready then s.generation+=1 end
				s.ready=ready; spot:SetAttribute("ChestReady",ready)
			end
			task.wait(1)
		end
	end)
end

return Tree
