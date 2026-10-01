-- Server-owned run ledger. Active rewards are persisted and settled once.
local Players = game:GetService("Players")
local Collection = game:GetService("CollectionService")
local Shared = game.ReplicatedStorage.Shared
local Net = require(Shared.Net)
local Balance = require(Shared.Balance)
local Config = require(Shared.Config.Forest)
local Zones = require(Shared.Config.Zones)
local Data = require(script.Parent.DataService)
local Features = require(script.Parent.FeatureService)
local Run = {}
local modes, boosts = {}, {}

function Run.Get(player)
	return Data.Get(player,"Run")
end

function Run.GetModes(player)
	return modes[player] or {AutoAttack=false,AutoCut=false}
end

function Run.ZoneAt(player)
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	if not root then return nil end
	for _, z in Zones.List do
		local x,zpos = (z.col-1.5)*Zones.GridStep,(z.row-0.5)*Zones.GridStep
		local depth = z.id==8 and z.halfSize or Zones.GroundHalfDepth
		if math.abs(root.Position.X-x)<=z.halfSize and math.abs(root.Position.Z-zpos)<=depth and math.abs(root.Position.Y-z.y)<18 then return z.id end
	end
	return nil
end

function Run.CanAccess(player,zone)
	local d=Data.GetData(player)
	return d and table.find(d.Progress.UnlockedZones,zone)~=nil and Zones.List[zone] and Zones.List[zone].built
end

function Run.Power(player)
	local d=Data.GetData(player)
	if not d then return 0 end
	local override=player:GetAttribute("AdminCutPower")
	if type(override)=="number" then return override end
	-- Phase 3 replaces the starter with the equipped weapon roll.
	return Balance.CutPower(Config.StarterPower,d.Run.Active and d.Run.Level or 1,1,d.Progress.Rebirth)
end

function Run.Send(player,summary)
	local r=Run.Get(player)
	if not r or not player.Parent then return end
	local m=Run.GetModes(player)
	Net.Event("RunState"):FireClient(player,{
		active=r.Active,level=r.Level,exp=r.Exp,nextExp=Balance.ExpToNext(r.Level,r.Zone,Data.Get(player,"Progress.Rebirth")),
		zone=r.Zone,power=Run.Power(player),multiplier=Balance.RunMultiplier(r.Level),wood=r.Wood,coins=r.Coins,trees=r.Trees,
		chests=r.Chests,autoAttack=m.AutoAttack,autoCut=m.AutoCut,friendBoost=Features.IsEnabled("FriendBoost") and (boosts[player] or 1) or 1,summary=summary,
	})
end

function Run.SetMode(player,name,on)
	if name~="AutoAttack" and name~="AutoCut" or type(on)~="boolean" then return false end
	local r=Run.Get(player)
	if not r or not r.Active or (name=="AutoCut" and not Features.IsEnabled("AutoCut")) then return false end
	modes[player]=modes[player] or {AutoAttack=false,AutoCut=false}
	modes[player][name]=on
	if on then modes[player][name=="AutoCut" and "AutoAttack" or "AutoCut"]=false end
	Data.Set(player,"Settings."..name,on)
	if name=="AutoCut" and not on and player.Character then
		local hum=player.Character:FindFirstChildOfClass("Humanoid")
		local root=player.Character:FindFirstChild("HumanoidRootPart")
		if hum and root then hum:MoveTo(root.Position) end
	end
	Run.Send(player)
	return true
end

local function giveAxe(player)
	local char=player.Character
	local bag=player:FindFirstChildOfClass("Backpack")
	if not char or not bag then return end
	local hum=char:FindFirstChildOfClass("Humanoid")
	local tool=char:FindFirstChild("StarterAxe") or bag:FindFirstChild("StarterAxe")
	if not tool then
		tool=Instance.new("Tool"); tool.Name="StarterAxe"; tool.CanBeDropped=false; tool.ToolTip="ฟันต้นไม้ • Power 125"
		local handle=Instance.new("Part"); handle.Name="Handle"; handle.Size=Config.StarterVisual.Size
		handle.CanCollide=false; handle.Massless=true; handle.Parent=tool
		local mesh=Instance.new("SpecialMesh"); mesh.MeshType=Enum.MeshType.FileMesh
		mesh.MeshId=Config.StarterVisual.MeshId; mesh.TextureId=Config.StarterVisual.TextureId; mesh.Scale=Config.StarterVisual.Scale; mesh.Parent=handle
		tool:SetAttribute("ForestAxe",true); tool.Parent=bag
	end
	if hum then hum:EquipTool(tool) end
end

function Run.Begin(player)
	if not Features.IsEnabled("Forest") or not Data.IsLoaded(player) then return false end
	local current=Run.Get(player)
	if current.Active then return true end
	Data.Set(player,"Run",{Active=true,Level=1,Exp=0,Zone=1,Wood=0,Coins=0,Trees=0,Chests={},StartedAt=os.time()})
	modes[player]={AutoAttack=false,AutoCut=false}
	giveAxe(player); Run.Send(player)
	return true
end

function Run.End(player,teleport)
	local r=Run.Get(player)
	if not r or not r.Active then return false end
	local summary={wood=r.Wood,coins=r.Coins,trees=r.Trees,level=r.Level,chests=r.Chests,seconds=math.max(0,os.time()-r.StartedAt)}
	-- No yields between transferring and marking settled; duplicate requests are harmless.
	r.Active=false
	Data.AddCurrency(player,"Wood",r.Wood); Data.AddCurrency(player,"Coins",r.Coins)
	local inventory=Data.Get(player,"Inventory.Chests")
	for _, chest in r.Chests do table.insert(inventory,table.clone(chest)) end
	Data.Set(player,"Inventory.Chests",inventory)
	Data.Set(player,"Run",{Active=false,Level=1,Exp=0,Zone=1,Wood=0,Coins=0,Trees=0,Chests={},StartedAt=0})
	modes[player]={AutoAttack=false,AutoCut=false}
	Data.Set(player,"Settings.AutoAttack",false); Data.Set(player,"Settings.AutoCut",false)
	local char=player.Character
	local hum=char and char:FindFirstChildOfClass("Humanoid")
	local root=char and char:FindFirstChild("HumanoidRootPart")
	if hum and root then hum:MoveTo(root.Position) end
	Run.Send(player,summary)
	if teleport and player.Character then
		local spawn=workspace.Map.Village:FindFirstChild("VillageSpawn")
		if spawn then
			task.spawn(function()
				pcall(player.RequestStreamAroundAsync,player,spawn.Position,5)
				if player.Character then player.Character:PivotTo(spawn.CFrame+Vector3.new(0,4,0)) end
			end)
		end
	end
	return true
end

function Run.Award(player,zone,tier,autoCut)
	local r=Run.Get(player)
	if not r or not r.Active then return end
	local reward=Balance.TreeReward(zone,tier,Data.Get(player,"Progress.Rebirth"),autoCut)
	local boost=Features.IsEnabled("FriendBoost") and (boosts[player] or 1) or 1
	r.Wood+=reward.wood*boost; r.Coins+=reward.coins*boost; r.Exp+=reward.exp*boost; r.Trees+=1; r.Zone=zone
	while r.Exp>=Balance.ExpToNext(r.Level,zone,Data.Get(player,"Progress.Rebirth")) do
		r.Exp-=Balance.ExpToNext(r.Level,zone,Data.Get(player,"Progress.Rebirth")); r.Level+=1
	end
	Data.Increment(player,"Stats.TreesCut",1)
	Run.Send(player)
end

function Run.CollectChest(player,spot,generation)
	local r=Run.Get(player)
	if not r or not r.Active then return false end
	local count=0
	for _,c in r.Chests do count+=c.count end
	if count>=Config.MaxRunChests then return false end
	for _,c in r.Chests do
		if c.level==r.Level and c.zone==r.Zone and c.rarity=="Common" then c.count+=1; Run.Send(player); return true end
	end
	table.insert(r.Chests,{level=r.Level,zone=r.Zone,rarity="Common",count=1,admin_spawned=Data.Get(player,"Meta.AdminTouched")})
	Run.Send(player)
	return true
end

function Run.Init()
	-- Init runs before DataService.Start, so settlement executes before session release.
	Players.PlayerRemoving:Connect(function(player) Run.End(player,false); modes[player]=nil; boosts[player]=nil end)
	Data.PlayerLoaded:Connect(function(player)
		if Run.Get(player).Active then Run.End(player,false) end -- recover an interrupted/crashed run once
		modes[player]={AutoAttack=false,AutoCut=false}
		Run.Send(player)
		player.CharacterAdded:Connect(function(char)
			local hum=char:WaitForChild("Humanoid")
			hum.Died:Connect(function() Run.End(player,false) end)
		end)
		if player.Character then
			local hum=player.Character:FindFirstChildOfClass("Humanoid")
			if hum then hum.Died:Connect(function() Run.End(player,false) end) end
		end
	end)
	Net.Function("RunRequest").OnServerInvoke=function(player) Run.Send(player); return true end
	local lastAction={}
	Net.Event("ForestAction").OnServerEvent:Connect(function(player,action,value)
		if type(action)~="string" then return end
		local now=os.clock()
		if now-(lastAction[player] or 0)<0.1 then return end
		lastAction[player]=now
		if action=="End" then Run.End(player,true)
		elseif action=="AutoAttack" or action=="AutoCut" then Run.SetMode(player,action,value) end
	end)
	Players.PlayerRemoving:Connect(function(player) lastAction[player]=nil end)
	for _,gate in Collection:GetTagged("ForestGate") do
		if gate:IsA("BasePart") and gate:IsDescendantOf(workspace) then
			gate.Touched:Connect(function(part)
				local char=part:FindFirstAncestorOfClass("Model")
				local player=char and Players:GetPlayerFromCharacter(char)
				if player then Run.Begin(player) end
			end)
		end
	end
end

function Run.Start()
	task.spawn(function()
		while true do
			for _, player in Players:GetPlayers() do
				local friends=0
				if Features.IsEnabled("FriendBoost") then
					for _,other in Players:GetPlayers() do
						if player~=other then local ok,result=pcall(player.IsFriendsWithAsync,player,other.UserId); if ok and result then friends+=1 end end
					end
				end
				boosts[player]=Balance.FriendBoost(friends)
				local r=Run.Get(player)
				local zone=Run.ZoneAt(player)
				if r and r.Active then if zone and Run.CanAccess(player,zone) then r.Zone=zone end; Run.Send(player) end
			end
			task.wait(5)
		end
	end)
end

return Run
