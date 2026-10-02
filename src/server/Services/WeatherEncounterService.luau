-- Runtime weather encounters. Currency and eggs stay in the player's profile;
-- public requests never choose a price, weather, spawn or reward amount.
local Players=game:GetService("Players")
local Collection=game:GetService("CollectionService")
local S=game.ReplicatedStorage.Shared
local C=require(S.Config.WeatherEncounters)
local Eggs=require(S.Config.Eggs)
local Zones=require(S.Config.Zones)
local Forest=require(S.Config.Forest)
local Story=require(S.Config.Story)
local Balance=require(S.Balance)
local Math=require(S.EncounterMath)
local Net=require(S.Net)
local D=require(script.Parent.DataService)
local F=require(script.Parent.FeatureService)
local WX=require(script.Parent.WeatherService)
local R=require(script.Parent.RunService)
local W=require(script.Parent.WeaponService)
local P=require(script.Parent.PetService)
local N=require(script.Parent.NestService)
local Boss=require(script.Parent.BossService)
local E={}
local pickups,completed,cooldowns,lastAction={},{},{},{}
local folder,world,worldKey,eggSpot,eggKey,meteorKey
local nextMeteor=0
local rng=Random.new()
local function enabled() return F.IsEnabled("WeatherEncounters") and F.IsEnabled("Weather") end
local function root(p)
 local char=p.Character;local hum=char and char:FindFirstChildOfClass("Humanoid")
 return hum and hum.Health>0 and char:FindFirstChild("HumanoidRootPart")
end
local function notify(p,msg) Net.Event("Notify"):FireClient(p,{text=msg}) end
local function destroyPickup(part) pickups[part]=nil;part:Destroy() end
function E.GetPickups() return pickups end
function E.GetWorld() return world end
function E.GetSpot() return eggSpot end
function E.Collect(p,part)
 local v=pickups[part];local state=WX.State();local hr=root(p)
 if not enabled() or not D.IsLoaded(p) or not v or not hr or not R.Get(p).Active then return false end
 if state.id~="Meteor" or state.eventKey~=v.key or os.clock()>=v.expires then return false end
 if not R.CanAccess(p,v.zone) or R.ZoneAt(p)~=v.zone or (hr.Position-part.Position).Magnitude>C.PickupRange then return false end
 destroyPickup(part);D.AddCurrency(p,"Stardust",C.MeteorDust);notify(p,"+"..C.MeteorDust.." Stardust");return true
end
function E.SpawnMeteor()
 if not enabled() then return nil end
 local state=WX.State();if state.id~="Meteor" then return nil end
 local n=0;for _ in pickups do n+=1 end;if n>=C.MaxPickups then return nil end
 local trees={};for _,tree in Collection:GetTagged("Tree") do
  local zone=tree:GetAttribute("Zone")
  if tree:IsDescendantOf(workspace) and tree.PrimaryPart and zone==1 then table.insert(trees,tree) end
 end
 if #trees==0 then return nil end
 local tree=trees[rng:NextInteger(1,#trees)];local zone=tree:GetAttribute("Zone");local at=tree.PrimaryPart.Position
 local part=Instance.new("Part");part.Name="Stardust";part.Shape=Enum.PartType.Ball;part.Size=Vector3.new(1.8,1.8,1.8)
 part.Material=Enum.Material.Neon;part.Color=Color3.fromRGB(180,130,255);part.Anchored=true;part.CanCollide=false
 part.Position=Vector3.new(at.X+4,Zones.List[zone].y+2,at.Z);part.Parent=folder
 local light=Instance.new("PointLight");light.Color=part.Color;light.Range=10;light.Parent=part
 local prompt=Instance.new("ProximityPrompt");prompt.Name="CollectStardust";prompt.ActionText="Collect +"..C.MeteorDust.." Stardust";prompt.ObjectText="METEOR";prompt.MaxActivationDistance=C.PickupRange;prompt.RequiresLineOfSight=false;prompt.Parent=part
 pickups[part]={zone=zone,key=state.eventKey,expires=os.clock()+C.PickupSeconds}
 prompt.Triggered:Connect(function(p) E.Collect(p,part) end);return part
end
function E.Exchange(p)
 if not enabled() or not F.IsEnabled("Chests") or not D.IsLoaded(p) or not W.AtAltar(p) then return false,"Exchange Stardust at the village chest station" end
 if D.Get(p,"Currencies.Stardust")<C.ChestDust then return false,"Requires "..C.ChestDust.." Stardust" end
 D.AddCurrency(p,"Stardust",-C.ChestDust)
 W.GrantChest(p,"Rare",1,1,1,D.Get(p,"Meta.AdminTouched")==true)
 return true,"Exchanged Stardust for a Rare chest"
end
local function clearWorld()
 if world then world.model:Destroy();world=nil;Boss.Suppress(1,false) end
 worldKey=nil
end
local function fell(b)
 b.paid=true;b.model:SetAttribute("Alive",false);b.model:SetAttribute("HealthRatio",0)
 for part in b.parts do part.Transparency=1;part.CanCollide=false end
 for p,entry in b.contributors do
  if p.Parent and D.IsLoaded(p) and R.Get(p)==entry.run and entry.run.Active then
   local award=Math.Payout(entry.share)
   if award.gems>0 then
    D.AddCurrency(p,"Gems",award.gems);D.AddCurrency(p,"Stardust",award.dust);D.Increment(p,"Stats.WorldBossKills",1)
    notify(p,"World Boss: +"..award.gems.." Gems / +"..award.dust.." Stardust")
   end
  end
 end
 Net.Event("BossEvent"):FireAllClients({kind="defeated",zone=1,name="Rot Master"})
end
function E.Hit(p,model)
 local b=world;local state=WX.State();local hr=root(p)
 if not enabled() or state.id~="RotInvasion" or state.eventKey~=worldKey or not D.IsLoaded(p) or not b or b.model~=model or b.paid or not hr then return false end
 local run=R.Get(p);if not run.Active or not R.CanAccess(p,1) or R.ZoneAt(p)~=1 then return false end
 local delta=hr.Position-b.center
 if Vector3.new(delta.X,0,delta.Z).Magnitude>Story.BossRange or math.abs(delta.Y)>20 then return false end
 local now=os.clock();if now<(cooldowns[p] or 0) then return false end
 local power=R.Power(p);if power<=0 or power~=power or power==math.huge then return false end
 cooldowns[p]=now+Forest.AttackInterval/W.Combat(p).speed;P.Dismount(p)
 local crit=rng:NextNumber()<Balance.Get("CritChance");local damage=power*(crit and Balance.Get("CritMult") or 1)
 local fraction=math.min(b.ratio,damage/(Balance.BossHP(1,D.Get(p,"Progress.Rebirth"))*C.WorldHP))
 b.ratio=math.max(0,b.ratio-fraction);local entry=b.contributors[p]
 if not entry or entry.run~=run then entry={share=0,run=run};b.contributors[p]=entry end
 entry.share+=fraction;b.model:SetAttribute("HealthRatio",b.ratio)
 D.Set(p,"Stats.HighestHit",math.max(D.Get(p,"Stats.HighestHit"),damage))
 Net.Event("TreeHit"):FireAllClients({tree=b.model,position=b.center+Vector3.new(0,12,0),damage=damage,crit=crit,player=p.UserId,dead=b.ratio==0,tier=6})
 if b.ratio==0 then fell(b) end;return true,damage
end
function E.Update()
 local state=WX.State();local active=enabled()
 for part,v in pickups do if not active or state.id~="Meteor" or state.eventKey~=v.key or os.clock()>=v.expires then destroyPickup(part) end end
 if active and state.id=="Meteor" then
  if meteorKey~=state.eventKey then meteorKey=state.eventKey;nextMeteor=0 end
  if os.clock()>=nextMeteor then nextMeteor=os.clock()+C.MeteorSeconds;E.SpawnMeteor() end
 else meteorKey=nil end
 local eggId=active and F.IsEnabled("Eggs") and (state.id=="Fog" and C.FogEgg or state.id=="Bloodmoon" and C.BloodEgg)
 local wantKey=eggId and state.eventKey
 if eggKey~=wantKey then
  if eggSpot then N.RemoveSpot(eggSpot);eggSpot=nil end;eggKey=wantKey
  if eggId then for _,nest in Collection:GetTagged("Nest") do
   if nest:IsDescendantOf(workspace) and nest:GetAttribute("Zone")==1 and N.Guardian(nest) then
    local spot=Instance.new("Part");spot.Name="WeatherEggSpot";spot.Size=Vector3.new(1,1,1);spot.Anchored=true;spot.CanCollide=false;spot.Transparency=1
    spot.CFrame=nest:GetPivot()*CFrame.new(-5,1,0);spot:SetAttribute("WeatherKey",state.eventKey);spot.Parent=nest
    if N.AddSpot(spot,Eggs.ById[eggId]) then eggSpot=spot else spot:Destroy() end;break
   end
  end end
 end
 if not active or state.id~="RotInvasion" or state.eventKey~=worldKey then clearWorld() end
 if active and state.id=="RotInvasion" and not world and not completed[state.eventKey] then
  world=Boss.CreateWorld()
  if world then
   worldKey=state.eventKey;completed[worldKey]=state.endsAt;world.model:SetAttribute("WorldHPFactor",C.WorldHP)
   Net.Event("BossEvent"):FireAllClients({kind="intro",zone=1,name="Rot Master"})
  end
 end
 for key,ends in completed do if ends<os.time()-86400 then completed[key]=nil end end
end
function E.Init()
 folder=Instance.new("Folder");folder.Name="WeatherEncounters";folder.Parent=workspace
 Net.Function("EncounterAction").OnServerInvoke=function(p,action)
  if not D.IsLoaded(p) then return false,"Data still loading" end
  local now=os.clock();if now-(lastAction[p] or -math.huge)<.35 then return false,"Please wait" end;lastAction[p]=now
  if action=="Exchange" then return E.Exchange(p) end;return false,"Invalid command"
 end
 Net.Event("ForestAction").OnServerEvent:Connect(function(p,action,model) if action=="Hit" then E.Hit(p,model) end end)
 Players.PlayerRemoving:Connect(function(p) cooldowns[p]=nil;lastAction[p]=nil;if world then world.contributors[p]=nil end end)
end
function E.Start()
 task.spawn(function() while true do
  E.Update()
  if world and not world.paid then for _,p in Players:GetPlayers() do if R.GetModes(p).AutoAttack then E.Hit(p,world.model) end end end
  task.wait(.2)
 end end)
end
return E
