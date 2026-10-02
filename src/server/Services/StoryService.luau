-- NPC dialogue, shrines, zone unlocks and warp stones (plan 1, 3.1).
-- Zone gates open per player on the client from Progress.UnlockedZones.
local Players=game:GetService("Players")
local Collection=game:GetService("CollectionService")
local Shared=game.ReplicatedStorage.Shared
local Net=require(Shared.Net)
local Story=require(Shared.Config.Story)
local Zones=require(Shared.Config.Zones)
local Data=require(script.Parent.DataService)
local Features=require(script.Parent.FeatureService)
local Run=require(script.Parent.RunService)
local Quest=require(script.Parent.QuestService)
local StoryService={}
local lastAction={}
local rng=Random.new()

local function root(p)
	local c=p.Character;local h=c and c:FindFirstChildOfClass("Humanoid")
	return h and h.Health>0 and c:FindFirstChild("HumanoidRootPart")
end
local function near(p,inst,range) local hr=root(p);return hr~=nil and inst~=nil and (hr.Position-inst:GetPivot().Position).Magnitude<=range end
local function tagged(tag,attr,value)
	for _,x in Collection:GetTagged(tag) do if x:IsDescendantOf(workspace) and x:GetAttribute(attr)==value then return x end end
end

function StoryService.Talk(p,npc)
	if not Features.IsEnabled("Story") or not Data.IsLoaded(p) then return false,"Story unavailable" end
	local def=type(npc)=="string" and Story.Npcs[npc];local model=def and tagged("NPC","NpcId",npc)
	if not def or not near(p,model,Story.TalkRange) then return false,"Move closer to the NPC first" end
	local step=Quest.Step(p);local chapter=Data.Get(p,"Progress.StoryChapter")
	local lines=step and step.kind=="talk" and step.npc==npc and def.chapter[chapter] or def.zone==chapter and def.intro or {def.idle[rng:NextInteger(1,#def.idle)]}
	if Data.Get(p,"Progress.Rebirth")>0 then
		lines=table.clone(lines);table.insert(lines,1,"Cycle "..Data.Get(p,"Progress.Rebirth").." cycles already... The Rot grows stronger, but so do you!")
	end
	Net.Event("StoryShow"):FireClient(p,{kind="dialog",speaker=def.name,lines=lines})
	Quest.OnTalk(p,npc)
	return true,"Talk to "..def.name
end
function StoryService.UnlockZone(p,zone)
	local unlocked=Data.Get(p,"Progress.UnlockedZones")
	if zone<=#Zones.List and not table.find(unlocked,zone) then table.insert(unlocked,zone);table.sort(unlocked);Data.Set(p,"Progress.UnlockedZones",unlocked) end
end
function StoryService.LightShrine(p,zone)
	if not Features.IsEnabled("Story") or not Data.IsLoaded(p) then return false,"Story unavailable" end
	if type(zone)~="number" or not near(p,tagged("Shrine","Zone",zone),Story.ShrineRange) then return false,"Go to the shrine first" end
	local shrines=Data.Get(p,"Progress.Shrines");local key=tostring(zone)
	if shrines[key] then return false,"Shrine already lit" end
	if (Data.Get(p,"Progress.Bosses")[key] or 0)<1 then return false,"Defeat "..Zones.List[zone].boss.." before lighting the shrine" end
	shrines[key]=true;Data.Set(p,"Progress.Shrines",shrines)
	if zone<#Zones.List then StoryService.UnlockZone(p,zone+1) end
	Net.Event("StoryShow"):FireClient(p,{kind="shrine",zone=zone,title=Zones.List[zone].name.." Shrine Lit!",lines=Story.ShrineLines})
	Quest.Check(p)
	return true,"Shrine lit"..(zone<#Zones.List and " — Unlock Zone "..(zone+1) or "")
end
-- Warp from any WarpStone to the village (ends the Run) or an unlocked, built zone (starts one).
function StoryService.Warp(p,zone)
	if not Features.IsEnabled("Story") or not Data.IsLoaded(p) then return false,"Warp unavailable" end
	if type(zone)~="number" or zone%1~=0 then return false,"Invalid destination" end
	local atStone=false;for _,w in Collection:GetTagged("WarpStone") do if w:IsDescendantOf(workspace) and near(p,w,Story.WarpRange) then atStone=true end end
	if not atStone and not (Data.Get(p,"Purchases.passes") or {}).Teleport then return false,"Use at a warp stone only" end
	if p:GetAttribute("CarryingEgg") then return false,"Cannot warp while carrying an egg" end
	if zone==0 then
		if Data.Get(p,"Run.Active") then Run.End(p,true);return true,"End Run & Return Home" end
		local spawn=workspace.Map.Village:FindFirstChild("VillageSpawn")
		pcall(p.RequestStreamAroundAsync,p,spawn.Position,5);if p.Character then p.Character:PivotTo(spawn.CFrame+Vector3.new(0,4,0)) end
		return true,"Warp to Village"
	end
	if not Zones.List[zone] or not Run.CanAccess(p,zone) then return false,"Cannot enter this zone yet" end
	if not Data.Get(p,"Run.Active") and not Run.Begin(p) then return false,"Cannot start run" end
	local spawn=tagged("ZoneSpawn","Zone",zone)
	pcall(p.RequestStreamAroundAsync,p,spawn.Position,5)
	if p.Character then p.Character:PivotTo(spawn.CFrame+Vector3.new(0,4,0)) end
	return true,"Warped to "..Zones.List[zone].name
end

local function prompt(parent,name,action,object,range,callback)
	local x=Instance.new("ProximityPrompt");x.Name=name;x.ActionText=action;x.ObjectText=object;x.RequiresLineOfSight=false;x.MaxActivationDistance=range;x.HoldDuration=.2;x.Parent=parent
	x.Triggered:Connect(callback);return x
end
function StoryService.Init()
	for _,m in Collection:GetTagged("NPC") do if m:IsDescendantOf(workspace) and Story.Npcs[m:GetAttribute("NpcId")] then
		local npc=m:GetAttribute("NpcId")
		prompt(m:FindFirstChild("Head") or m.PrimaryPart,"TalkPrompt","Talk",Story.Npcs[npc].name,Story.TalkRange-2,function(p) local ok,msg=StoryService.Talk(p,npc);if not ok then Net.Event("Notify"):FireClient(p,{text=msg,kind="warn"}) end end)
	end end
	for _,s in Collection:GetTagged("Shrine") do if s:IsDescendantOf(workspace) then
		local zone=s:GetAttribute("Zone");local crystal=s:FindFirstChild("Crystal") or s.PrimaryPart
		if crystal and Zones.List[zone] then prompt(crystal,"ShrinePrompt","Light Shrine","SHRINE",Story.ShrineRange-2,function(p) local ok,msg=StoryService.LightShrine(p,zone);Net.Event("Notify"):FireClient(p,{text=msg,kind=not ok and "warn" or nil}) end) end
	end end
	for _,w in Collection:GetTagged("WarpStone") do if w:IsDescendantOf(workspace) then
		local pillar=w:FindFirstChild("Pillar") or w.PrimaryPart or w:FindFirstChildWhichIsA("BasePart")
		if pillar then prompt(pillar,"WarpPrompt","Warp","WARP STONE",Story.WarpRange-2,function(p) if Features.IsEnabled("Story") then Net.Event("StoryShow"):FireClient(p,{kind="warp"}) end end) end
	end end
	Net.Function("StoryAction").OnServerInvoke=function(p,action,arg)
		if not Data.IsLoaded(p) then return false,"Loading data" end
		local now=os.clock();if now-(lastAction[p] or -math.huge)<.3 then return false,"Please wait" end;lastAction[p]=now
		local ok,msg=false,"Invalid command"
		if action=="Sync" then ok,msg=true,"Ready"
		elseif action=="Talk" then ok,msg=StoryService.Talk(p,arg)
		elseif action=="Warp" then ok,msg=StoryService.Warp(p,arg)
		elseif action=="Shrine" then ok,msg=StoryService.LightShrine(p,arg)
		elseif action=="Claim" and type(arg)=="table" then ok,msg=Quest.Claim(p,arg.kind,arg.id) end
		Quest.Send(p,true);return ok,msg
	end
	Players.PlayerRemoving:Connect(function(p) lastAction[p]=nil end)
end
function StoryService.Start() end
return StoryService
