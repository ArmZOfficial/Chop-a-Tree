local tests=0
local function check(ok,label) assert(ok,label);tests+=1 end
local Zones=require(node("ReplicatedStorage.Shared.Config.Zones"))
local Util=require(node("ReplicatedStorage.Shared.ZoneUtil"))
for _,z in Zones.List do
	check(Zones.At(vec((z.inner+z.outer)/2,z.y,0))==z.id,"ring "..z.id)
	check(Util.SurfaceAt(vec((z.inner+z.outer)/2,500,0))==z.id,"vertical footprint "..z.id)
end
check(Util.At(Zones.Hub.center)=="hub" and Zones.At(Zones.Hub.center)==nil,"Hub compatibility")
check(Util.At(vec(1500,4,0))==nil,"sea")
check(Util.Project(vec(10,0,20),vec(0,0,0),100).X==.6,"projection")
local migration=require(node("ServerScriptService.Server.AdminCommands.MapMigrationCheck"))
local ok,summary,errors=migration(Data);check(ok,summary..errors)
local p=fixture(makePlayer(810,7,0))
local second=fixture(makePlayer(810,7,0))
local Zone=require(node("ServerScriptService.Server.Services.ZoneService"))
local transitions=0;Zone.PlayerEntered:Connect(function() transitions+=1 end)
Zone.Update(100);Zone.Update(100.8);check(Zone.GetZone(p)==1,"zone settle")
check(p:GetAttribute("Zone")==1 and p.Character.attributes.Zone==1,"zone attributes")
check(Data.Get(p,"Progress.VisitedZones")["1"]==true,"visited")
p.root.Position=vec(695,15,0);Zone.Update(101);p.root.Position=vec(810,7,0);Zone.Update(101.1)
check(Zone.GetZone(p)==1,"border hysteresis")
p.root.Position=vec(695,15,0);Zone.Update(102);Zone.Update(103)
check(Zone.GetZone(p)==2 and not Data.Get(p,"Progress.VisitedZones")["2"],"locked visit rejected")
local Gate=require(node("ServerScriptService.Server.Services.GateService"))
Gate.Update();check(p.root.Position.Z==1014 or p.root.Position.Z==1010,"locked entry rescued")
p.root.Position=vec(810,7,0);Gate.Update();p.root.Position=vec(695,500,0);Gate.Update()
check(p.root.Position.X==810,"sky bypass blocked")
p.root.Position=vec(810,-20,0);Gate.Update();check(p.root.Position.Y==7,"underground rescue")
p._arena={mode="Duel"};p.root.Position=vec(695,15,0);Gate.Update();check(p.root.Position.X==695,"Arena untouched");p._arena={}
p.root.Position=vec(810,-100,0);Gate.Update();check(p.root.Position.Y==7,"kill floor")
enabled.MapSystems=false;Zone.Update(104);check(p:GetAttribute("Zone")==nil,"flag clears zone");enabled.MapSystems=true
local Config=require(node("ReplicatedStorage.Shared.Config.Explorer"))
local Explorer=require(node("ServerScriptService.Server.Services.ExplorerService"))
local ids={};for _,def in Config.List do check(not ids[def.id],"stable unique ID");ids[def.id]=true end
check(#Config.List==24,"collectible count")
for _,def in Config.List do if def.zone==1 then
	p.root.Position=def.position;now+=1;check(Explorer.Collect(p,def.id),"collect")
	now+=1;check(not Explorer.Collect(p,def.id),"duplicate collect")
end end
check(grants==1 and Data.Get(p,"Explorer.completed")["1"],"completion pays once")
local def=Config.List[4];p.root.Position=def.position;now+=1;check(not Explorer.Collect(p,def.id),"locked collection")
now+=1;check(not Explorer.Collect(p,{}),"invalid payload")
local Travel=require(node("ServerScriptService.Server.Services.TravelService"))
p.data.Purchases.passes.Teleport=true;p.root.Position=vec(810,7,0)
tags.ZoneSpawn={{GetAttribute=function(_,key) return key=="Zone" and 1 end,IsDescendantOf=function() return true end,GetPivot=function() return CFrame.new(vec(810,4,0)) end}}
check(not Travel.Warp(p,0/0),"NaN destination")
check(not Travel.Warp(p,1,{}),"forged dock rejected")
p.data.Progress.VisitedZones={};check(not Travel.Warp(p,1),"unvisited travel")
p.data.Progress.VisitedZones["1"]=true;p:SetAttribute("CarryingEgg",true);check(not Travel.Warp(p,1),"egg travel blocked");p:SetAttribute("CarryingEgg",nil)
p._arena={mode="Duel"};check(not Travel.Warp(p,1),"Arena travel blocked");p._arena={}
p:SetAttribute("CombatUntil",now+3);check(not Travel.Warp(p,1),"combat travel blocked");p:SetAttribute("CombatUntil",nil)
workspace.blocked=true;check(not Travel.Warp(p,1),"blocked destination");workspace.blocked=false
p.onStream=function() p:SetAttribute("CarryingEgg",true) end;check(not Travel.Warp(p,1),"recheck after yield");p.onStream=nil;p:SetAttribute("CarryingEgg",nil)
p.data.Run.Active=true;check(Travel.Warp(p,1),"valid travel");check(not Travel.Warp(p,1),"travel cooldown");now+=3
p.data.Purchases.passes.Teleport=nil;check(not Travel.Warp(p,1),"stone or owned pass only")
local Run=require(node("ServerScriptService.Server.Services.RunService"))
local Balance=require(node("ReplicatedStorage.Shared.Balance"))
local function award(treeMult,eventMult,petMult)
	p.data.Run.Wood=0;p.data.Run.Coins=0;p.data.Run.Exp=0;p.data.Run.Level=1
	mult=petMult;Run.SetMapMultiplierProvider(function() return eventMult end)
	Run.Award(p,1,1,false,nil,treeMult)
	return p.data.Run.Wood,p.data.Run.Coins
end
local normal,coins=award(1,1,1);local boosted,newCoins=award(2,1,1)
check(boosted==normal*2 and newCoins==coins,"Golden Wood only")
check(award(2,2,4)==normal*4,"combined x4 cap")
enabled.MapSystems=false;check(award(2,2,1)==normal,"flag removes bonus");enabled.MapSystems=true
local tree=makeTree(1);tags.Tree={tree}
local Tree=require(node("ServerScriptService.Server.Services.TreeService"));Tree.Init()
check(Tree.SetSpecial(tree,"GoldenTree"),"pooled Golden tree");check(tree:GetAttribute("MapWoodMult")==2,"Golden attr")
check(not Tree.SetSpecial(tree,"Invalid"),"invalid special rejected");check(tree:GetAttribute("SpecialKind")=="GoldenTree","invalid special preserves tree")
check(Tree.SetSpecial(tree,nil) and tree:GetScale()==1,"special restored")
check(Tree.SetSpecial(tree,"GiantTree") and tree:GetScale()==1.5,"Giant scale")
check(not Tree.Strike(tree),"no lightning shared-reward bypass")
Tree.SetSpecial(tree,nil)
local Event=require(node("ServerScriptService.Server.Services.WorldEventService"));Event.Init()
check(Event.StartEvent("GoldenTree",1),"Golden event")
check(not Event.StartEvent("TimberRush",1),"concurrency cap")
Event.Stop();check(tree:GetAttribute("SpecialKind")==nil,"event cleanup")
check(Event.StartEvent("TimberRush",1),"Timber event")
check(Event.WoodMultiplier(p,1)==2 and Event.WoodMultiplier(p,2)==1,"zone bonus only")
now+=100;Event.Update();check(Event.Get()==nil,"event timeout")
check(not Event.StartEvent("Meteor",2),"existing encounter zone safety")
Event.StartEvent("TimberRush",1);enabled.MapSystems=false;Event.Update();check(Event.Get()==nil,"flag stops event");enabled.MapSystems=true
check(not Event.StartEvent({},1),"event payload")
Event.Destroy();mult=1
p.root.Position=vec(810,7,0);p.data.Run.Level=1;p.data.Run.Exp=0;p.data.Run.Wood=0;p.data.Run.Coins=0
Tree.Reset(tree);check(Tree.SetSpecial(tree,"GoldenTree"),"prepare Golden cut")
local cuts=0
repeat now+=2;local accepted=Tree.Hit(p,tree);check(accepted,"real Golden hit");cuts+=1 until tree:GetAttribute("Alive")==false or cuts>20
check(tree:GetAttribute("Alive")==false and p.data.Run.Wood==normal*2,"Golden cut reward")
local after=p.data.Run.Wood;now+=2;check(not Tree.Hit(p,tree) and p.data.Run.Wood==after,"dead tree cannot repay")
Tree.SetSpecial(tree,nil);for _,callback in delayed do callback() end;table.clear(delayed)
check(tree:GetAttribute("Alive") and tree.PrimaryPart.Transparency==0,"same pooled tree respawns")
p.data.Run.Level=1;p.data.Run.Exp=0;p.data.Run.Wood=0;p.data.Run.Coins=0
second.data.Run.Active=true;second.data.Run.Level=1;second.data.Run.Exp=0;second.data.Run.Wood=0;second.data.Run.Coins=0
check(Tree.SetSpecial(tree,"GiantTree"),"prepare Giant cut")
cuts=0
repeat now+=1.1;local player=cuts%2==0 and p or second;check(Tree.Hit(player,tree),"real Giant hit");cuts+=1 until tree:GetAttribute("Alive")==false or cuts>80
check(tree:GetAttribute("Alive")==false,"Giant fell")
check(math.abs(p.data.Run.Wood+second.data.Run.Wood-normal*2)<.0001,"Giant payout is shared, not duplicated")
check(math.abs(p.data.Run.Coins+second.data.Run.Coins-coins)<.0001,"Giant Coins retain total budget")
Tree.SetSpecial(tree,nil)
local Encounters=require(node("ServerScriptService.Server.Services.WeatherEncounterService"))
local function pickup(kind,key)
	local part=Instance.new("Part");part.Position=vec(810,7,0)
	Encounters.GetPickups()[part]={weather=kind,key=key or "mock",zone=1,expires=now+30}
	return part
end
p.root.Position=vec(810,7,0);weather.id="Meteor"
local part=pickup("Meteor");local dust=Data.Get(p,"Currencies.Stardust")
check(Encounters.Collect(p,part),"Meteor existing collector")
check(Data.Get(p,"Currencies.Stardust")==dust+5 and not Encounters.Collect(p,part),"Meteor pays once")
weather.id="Fog";runtimeFolders.DayCycleState={GetAttribute=function() return "night" end}
part=pickup("Fog");check(Encounters.Collect(p,part),"Night Spirit reuses collector")
check(not Encounters.Collect(p,part),"Spirit pays once")
runtimeFolders.DayCycleState={GetAttribute=function() return "noon" end};check(not Encounters.Collect(p,pickup("Fog")),"daytime spirit rejected")
weather.id="Meteor";check(not Encounters.Collect(p,pickup("Meteor","stale")),"stale event pickup rejected")
check(Balance.SelfTest(),"Balance self-test")
print("Map systems: "..tests.." checks passed (synthetic boundaries; no live profile)")
