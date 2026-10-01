-- Inject in Studio Play as a temporary Script. Always restores the real profile.
assert(game:GetService("RunService"):IsStudio())
local V=game.ServerScriptService.Server.Services;local S=game.ReplicatedStorage.Shared
local D=require(V.DataService);local F=require(V.FeatureService);local WX=require(V.WeatherService);local R=require(V.RunService)
local E=require(V.WeatherEncounterService);local N=require(V.NestService);local P=require(V.PetService);local W=require(V.WeaponService);local Bo=require(V.BossService)
local B=require(S.Balance);local C=require(S.Config.WeatherEncounters);local M=require(S.EncounterMath);local Schedule=require(S.WeatherSchedule);local WC=require(S.Config.Weather)
local p=game.Players:GetPlayers()[1];assert(D.WaitForData(p,30));local original=D.ExportJSON(p);script:SetAttribute("OriginalData",original)
local root=p.Character.HumanoidRootPart;local anchor=root.Anchored;local pivot=p.Character:GetPivot();local power=p:GetAttribute("AdminCutPower")
local L=require(V.LiveEventService);local preview=L.GetPreview()
local weather=WX.GetOverride();local balance=table.clone(B.Overrides());local results={}
local flags={};for _,id in {"Weather","WeatherEncounters","Eggs","Forest","Story","Chests","AutoSave","Leaderboard","Rebirth"} do flags[id]=F.IsEnabled(id) end
local function check(name,ok) assert(ok,name);table.insert(results,{name=name,passed=true}) end
local function at(pos) pcall(p.RequestStreamAroundAsync,p,pos,5);p.Character:PivotTo(CFrame.new(pos));task.wait(.15) end
local function force(id) WX.Force(id,600);E.Update() end
local function dust() return D.GetCurrency(p,"Stardust") end
workspace:SetAttribute("Phase8EncounterStatus","running")
local ok,err=xpcall(function()
 R.End(p,false);P.Dismount(p);root.Anchored=true;L.Preview(nil)
 for id in flags do F.Set(id,true) end;F.Set("AutoSave",false);F.Set("Leaderboard",false);F.Set("Story",false);B.SetOverride("CritChance",0)
 D.Set(p,"Progress.UnlockedZones",{1});D.Set(p,"Progress.Rebirth",0);D.Set(p,"Inventory.Eggs",{});D.Set(p,"Inventory.Chests",{});D.SetCurrency(p,"Stardust",0);D.SetCurrency(p,"Coins",1e9);D.SetCurrency(p,"Gems",0)
 D.Set(p,"Progress.Bosses",{});D.Set(p,"Pets.weatherBought",{});D.Set(p,"Pets.incubator",{});D.Set(p,"Meta.AdminTouched",true)
 local migrated=D.Migrate({DataVersion=1,Pets={beltBought={["7"]=true}},Currencies={Stardust=17}})
 check("Schema adds weather markers and world stats without deleting existing data",migrated.Pets.weatherBought and migrated.Pets.beltBought["7"] and migrated.Currencies.Stardust==17 and migrated.Stats.WorldBossKills==0)
 local Eggs=require(S.Config.Eggs);local Pets=require(S.Config.Pets);local secret=true
 for _,pair in Eggs.ById[C.BloodEgg].pets do secret=secret and Pets.ById[pair[1]].rarity=="Secret" end
 check("Bloodmoon egg contains only Secret pets",secret and #Pets.List==43)
 check("Special eggs stay out of the ordinary conveyor and nest pools",Eggs.ById[C.AuroraEgg].belt==0 and not Eggs.ById[C.FogEgg].nestType)
 check("Infinite or tiny shares cannot claim rewards",M.Payout(math.huge).gems==0 and M.Payout(.001).gems==1 and M.Payout(.001).dust==0)
 check("Two contribution shares conserve the reward budget",M.Payout(.4).gems+M.Payout(.6).gems==C.WorldGems and M.Payout(.4).dust+M.Payout(.6).dust==C.WorldDust)
 -- UTC schedule overlay
 local first=20730*86400;local rot,bounded,forecasts=true,true,true
 for now=first,first+2*86400,60 do
  local s=Schedule.At(now);local inWindow=now%C.WorldPeriod<C.WorldSeconds
  rot=rot and ((s.id=="RotInvasion")==inWindow)
  local nextRot=(math.floor(now/C.WorldPeriod)+1)*C.WorldPeriod
  bounded=bounded and s.endsAt>now and s.endsAt<=nextRot
  if s.nextId~="???" then forecasts=forecasts and Schedule.At(s.nextAt).id==s.nextId end
 end
 check("RotInvasion fills exactly the first 10 minutes of every UTC 2-hour block",rot)
 check("No natural weather runs into a RotInvasion window",bounded)
 check("Forecasts still name the weather that actually follows",forecasts)
 check("World boss payout scales with share and ignores dust-sized shares",M.Payout(1).gems==C.WorldGems and M.Payout(.5).dust==C.WorldDust/2 and M.Payout(C.MinShare/2).gems==0 and M.Payout(0/0).gems==0 and M.Payout(5).gems==C.WorldGems)
 -- Meteor Stardust pickups
 force("Meteor");local pickup=next(E.GetPickups())
 check("Meteor weather spawns a Stardust pickup in zone 1",pickup~=nil and pickup.Parent~=nil)
 at(pickup.Position+Vector3.new(0,2,0))
 check("Stardust needs an active Run",not E.Collect(p,pickup) and dust()==0)
 R.Begin(p);at(pickup.Position+Vector3.new(30,2,0))
 check("Stardust needs to be close",not E.Collect(p,pickup))
 at(pickup.Position+Vector3.new(0,2,0))
 D.Set(p,"Progress.UnlockedZones",{});check("Stardust checks zone access",not E.Collect(p,pickup));D.Set(p,"Progress.UnlockedZones",{1})
 check("Collecting pays Stardust once",E.Collect(p,pickup) and dust()==C.MeteorDust and not E.Collect(p,pickup) and dust()==C.MeteorDust)
 local stale=E.SpawnMeteor();WX.Force("Clear",600);check("Expired weather rejects a pickup before the update loop",not E.Collect(p,stale));E.Update()
 force("Meteor");local expired=E.SpawnMeteor();E.GetPickups()[expired].expires=os.clock()-1;E.Update();check("Stardust TTL destroys unclaimed pickups",expired.Parent==nil)
 for _=1,30 do E.SpawnMeteor() end;local n=0;for _ in E.GetPickups() do n+=1 end;check("Meteor pickups respect the server-wide cap",n==C.MaxPickups)
 E.SpawnMeteor();force("Clear")
 check("Pickups vanish when the meteor shower ends",next(E.GetPickups())==nil);R.End(p,false)
 check("Banked Stardust survives a failed Run",dust()==C.MeteorDust)
 -- Stardust exchange
 local altar=workspace.Map.Village.ChestAltar.PrimaryPart.Position+Vector3.new(0,6,0)
 D.SetCurrency(p,"Stardust",C.ChestDust);check("Exchange only works at the chest altar",not E.Exchange(p) and dust()==C.ChestDust)
 at(altar);D.SetCurrency(p,"Stardust",C.ChestDust-1);check("Exchange needs enough Stardust",not E.Exchange(p) and #D.Get(p,"Inventory.Chests")==0)
 D.SetCurrency(p,"Stardust",C.ChestDust)
 D.Set(p,"Run.Active",true);check("Exchange rejects active Runs",not E.Exchange(p));D.Set(p,"Run.Active",false)
 check("Exchange turns Stardust into one Rare chest",E.Exchange(p) and dust()==0 and D.Get(p,"Inventory.Chests")[1].rarity=="Rare")
 check("Exchange retains admin provenance and cannot debit below zero",D.Get(p,"Inventory.Chests")[1].admin_spawned and not E.Exchange(p) and dust()==0)
 D.SetCurrency(p,"Stardust",20);F.Set("Chests",false);check("Chest feature gate blocks exchange",not E.Exchange(p));F.Set("Chests",true);D.SetCurrency(p,"Stardust",0)
 -- Fog / Bloodmoon nest eggs
 for _,case in {{"Fog",C.FogEgg},{"Bloodmoon",C.BloodEgg}} do
  force(case[1]);local spot=E.GetSpot()
  check(case[1].." adds one special egg spot to a zone 1 nest",spot~=nil and N.Spots()[spot] and N.Spots()[spot].def.id==case[2])
  R.Begin(p);at(spot.Position+Vector3.new(3,3,0))
  check(case[1].." egg can be carried home through the nest rules",N.Take(p,spot) and N.Secure(p) and D.Get(p,"Run.Eggs")[#D.Get(p,"Run.Eggs")].id==case[2])
  R.End(p,false)
 end
 force("Fog");local old=E.GetSpot();force("Clear")
 check("Weather change retires the special spot",E.GetSpot()==nil and N.Spots()[old]==nil)
 force("Fog");local held=E.GetSpot();R.Begin(p);at(held.Position+Vector3.new(3,3,0));assert(N.Take(p,held));force("Clear")
 check("Weather expiry retains a carried egg until settlement",N.Carrying(p).def.id==C.FogEgg and N.Spots()[held].retired)
 check("Securing an expired egg retains its captured definition",N.Secure(p) and held.Parent==nil and D.Get(p,"Run.Eggs")[#D.Get(p,"Run.Eggs")].id==C.FogEgg);R.End(p,false)
 force("Bloodmoon");held=E.GetSpot();R.Begin(p);at(held.Position+Vector3.new(3,3,0));assert(N.Take(p,held));force("Clear")
 check("Dropping an expired egg clears its retired spot and carry state",N.Drop(p) and held.Parent==nil and not p:GetAttribute("CarryingEgg"));R.End(p,false)
 force("Fog");held=E.GetSpot();R.Begin(p);at(held.Position+Vector3.new(3,3,0));WX.Force("Clear",600)
 check("Stale nest requests reject before the update loop",not N.Take(p,held));E.Update();R.End(p,false)
 -- Aurora shop egg
 check("No Aurora offer outside Aurora",P.WeatherOffer(p)==nil)
 force("Aurora");local offer=P.WeatherOffer(p)
 check("Aurora offers its egg",offer and offer.id==C.AuroraEgg and not offer.bought)
 at(altar);check("Aurora egg is sold only at the conveyor",not P.BuyWeather(p))
 local belt;for _,m in game:GetService("CollectionService"):GetTagged("Shop") do if m:GetAttribute("ShopType")=="EggConveyor" then belt=m end end
 at(belt.PrimaryPart.Position+Vector3.new(0,5,6));local coins=D.GetCurrency(p,"Coins");local eggs=0;for _ in D.Get(p,"Inventory.Eggs") do eggs+=1 end
 D.SetCurrency(p,"Coins",offer.price-1);check("Aurora purchase checks Coins before recording a marker",not P.BuyWeather(p) and not P.WeatherOffer(p).bought);D.SetCurrency(p,"Coins",coins)
 local inv=D.Get(p,"Inventory.Eggs");local full={};for i=1,require(S.Config.Base).MaxEggs do full[tostring(i)]={id="egg_meadow"} end;D.Set(p,"Inventory.Eggs",full)
 check("Full egg inventory prevents Aurora debit",not P.BuyWeather(p) and D.GetCurrency(p,"Coins")==coins);D.Set(p,"Inventory.Eggs",inv)
 D.Set(p,"Run.Active",true);check("Aurora purchase rejects an active Run",not P.BuyWeather(p));D.Set(p,"Run.Active",false)
 check("Aurora egg costs Coins once per Aurora event",P.BuyWeather(p) and D.GetCurrency(p,"Coins")==coins-offer.price and not P.BuyWeather(p) and P.WeatherOffer(p).bought)
 local now=0;for _ in D.Get(p,"Inventory.Eggs") do now+=1 end;check("Aurora purchase grants exactly one egg",now==eggs+1)
 local saved=D.ExportJSON(p);D.ImportJSON(p,saved);task.wait(.1);check("Profile reload preserves the one-purchase marker",P.WeatherOffer(p).bought and not P.BuyWeather(p))
 D.SetCurrency(p,"Stardust",23);check("Rebirth retains Stardust and weather purchase markers",require(V.RebirthService).Perform(p,0,true) and dust()==23 and P.WeatherOffer(p).bought);D.Set(p,"Progress.Rebirth",0);D.SetCurrency(p,"Stardust",0)
 F.Set("WeatherEncounters",false);check("Feature gate removes Aurora offer",P.WeatherOffer(p)==nil and not P.BuyWeather(p));F.Set("WeatherEncounters",true)
 -- World boss
 force("RotInvasion");local world=E.GetWorld()
 check("RotInvasion spawns the world boss and hides the zone 1 guardian",world and world.model:GetAttribute("WorldBoss") and not game:GetService("CollectionService"):HasTag(Bo.Get(1).model,"Boss"))
 check("The hidden guardian cannot be hit",not Bo.Hit(p,1))
 at(world.center+Vector3.new(-14,4,0))
 check("World boss needs an active Run",not E.Hit(p,world.model))
 R.Begin(p);at(world.center+Vector3.new(-14,4,0));p:SetAttribute("AdminCutPower",B.BossHP(1)*C.WorldHP*.4);task.wait(1.05)
 D.Set(p,"Progress.UnlockedZones",{});check("World boss checks zone access",not E.Hit(p,world.model));D.Set(p,"Progress.UnlockedZones",{1})
 check("Suppressed guardian cannot be killed through its admin helper",not Bo.Kill(p,1))
 check("World boss hit takes a health share",E.Hit(p,world.model) and math.abs(world.ratio-.6)<1e-9)
 check("World hit cooldown rejects immediate replay",not E.Hit(p,world.model) and math.abs(world.ratio-.6)<1e-9)
 local kills=D.Get(p,"Stats.WorldBossKills");p:SetAttribute("AdminCutPower",B.BossHP(1)*C.WorldHP);task.wait(1.05);E.Hit(p,world.model)
 check("Defeat pays by share and counts the kill",world.paid and D.GetCurrency(p,"Gems")==C.WorldGems and dust()==C.WorldDust and D.Get(p,"Stats.WorldBossKills")==kills+1)
 check("World kills do not grant story boss progression",next(D.Get(p,"Progress.Bosses"))==nil and world.contributors[p].share==1)
 task.wait(1.05);check("A defeated world boss cannot be hit or paid again",not E.Hit(p,world.model) and D.GetCurrency(p,"Gems")==C.WorldGems)
 E.Update();check("The same RotInvasion never respawns its boss",E.GetWorld()==world)
 force("Clear");R.End(p,false)
 check("Ending RotInvasion removes the world boss and restores the guardian",E.GetWorld()==nil and game:GetService("CollectionService"):HasTag(Bo.Get(1).model,"Boss"))
 F.Set("WeatherEncounters",false);force("Meteor");check("Feature off spawns no encounters",next(E.GetPickups())==nil and E.SpawnMeteor()==nil);F.Set("WeatherEncounters",true)
 check("Balance SelfTest passes",B.SelfTest())
end,debug.traceback)
N.Drop(p);L.Preview(preview);for id,v in flags do F.Set(id,v) end
if weather then WX.Force(weather.id,math.max(1,weather.endsAt-os.time())) else WX.Force(nil) end;pcall(E.Update)
R.End(p,false);D.ImportJSON(p,original);p:SetAttribute("AdminCutPower",power);B.ClearOverrides();for k,v in balance do B.SetOverride(k,v) end
root.Anchored=anchor;p.Character:PivotTo(pivot);P.Refresh(p);R.Send(p)
workspace:SetAttribute("Phase8EncounterResults",game.HttpService:JSONEncode({passed=ok,checks=results,error=not ok and err or nil}));workspace:SetAttribute("Phase8EncounterStatus",ok and "passed" or "failed")
print("[Phase8EncounterScenario]",ok and "passed" or err,#results)
