assert(game.RunService:IsStudio())
local V=game.ServerScriptService.Server.Services;local S=game.ReplicatedStorage.Shared
local D=require(V.DataService);local F=require(V.FeatureService);local WX=require(V.WeatherService);local Live=require(V.LiveEventService)
local R=require(V.RunService);local P=require(V.PetService);local T=require(V.TreeService);local W=require(V.WeaponService)
local B=require(S.Balance);local GM=require(S.GardenMath);local LM=require(S.LiveEventMath);local Schedule=require(S.WeatherSchedule)
local WC=require(S.Config.Weather);local MC=require(S.Config.Mutations);local CM=require(S.CollectionMath);local LC=require(S.Config.LiveEvents)
local p=game.Players:GetPlayers()[1];assert(D.WaitForData(p,30));local original=D.ExportJSON(p);script:SetAttribute("OriginalData",original)
local root=p.Character.HumanoidRootPart;local anchor=root.Anchored;local pivot=p.Character:GetPivot();local power=p:GetAttribute("AdminCutPower")
local flags={};for _,id in {"Weather","LiveEvents","Leaderboard","IndexBonuses","Rebirth","FriendBoost","Forest"} do flags[id]=F.IsEnabled(id) end
local weather=WX.GetOverride();local preview=Live.GetPreview();local balance=table.clone(B.Overrides());local results={};local usedTree;local meteorChance=WC.ById.Meteor.chance
local function check(name,ok) assert(ok,name);table.insert(results,{name=name,passed=true}) end
local function near(a,b) return math.abs(a-b)<1e-8 end
workspace:SetAttribute("Phase8WeatherStatus","running")
local ok,err=xpcall(function()
 R.End(p,false);P.Dismount(p);root.Anchored=true;Live.Preview(nil)
 F.Set("Leaderboard",false);F.Set("Weather",true);F.Set("LiveEvents",true);F.Set("Forest",true);F.Set("FriendBoost",false);F.Set("IndexBonuses",false);F.Set("Rebirth",false);task.wait()
 check("All thirteen weather definitions have server multipliers",#WC.List==13 and WC.ById.Rainbow.weight==0 and WC.ById.RotInvasion.weight==0)
 local n=0;for _ in MC.Values do n+=1 end;check("Fruit catalog contains fifteen mutations",n==15)
 local tags={Celestial=true};GM.Apply(tags,"Aurora");check("Celestial and Aurora combine into Cosmic",tags.Cosmic and not tags.Celestial and not tags.Aurora)
 check("Highest special color multiplies the sum of other mutations",GM.Multiplier({Golden=true,Rainbow=true,Wet=true})==150 and GM.Multiplier({Cosmic=true})==151)
 local bounds,night,hidden,deterministic,rainbow=true,true,true,true,false;local seen={};local first=20720*86400
 for now=first,first+30*86400,60 do
  local s=Schedule.At(now);local def=WC.ById[s.id];seen[s.id]=true
  bounds=bounds and def~=nil and s.endsAt>now and s.nextAt>=s.endsAt
  local hour=(now%86400)/3600;if def.nightOnly then night=night and (hour<6 or hour>=18) end
  if s.nextId~="???" then hidden=hidden and not WC.ById[s.nextId].rare end
  local again=Schedule.At(now);deterministic=deterministic and s.id==again.id and s.eventKey==again.eventKey and s.nextAt==again.nextAt
  if s.id=="Rainbow" then rainbow=true end
 end
 check("Thirty UTC days retain valid boundaries and future forecasts",bounds)
 check("Night-only events never appear in daytime",night)
 check("Rare forecasts stay hidden until the event starts",hidden)
 check("Separate schedule calls agree at every sampled minute",deterministic)
 check("Rainbow follows Rain and enters the schedule",rainbow)
 check("Scheduled catalog reaches all weighted weather types",seen.Clear and seen.Rain and seen.Storm and seen.Snow and seen.Golden and seen.Fog and seen.Wind and seen.Sakura and seen.Meteor and seen.Aurora and seen.Bloodmoon)
 local event=assert(LM.Build({{id="Sakura",seconds=20},{id="Golden",seconds=30}},"test",100,1))
 check("Live sequence uses a shared delayed start",event.startAt==105 and event.endsAt==155 and LM.At(event,104).id=="Clear")
 check("Live sequence switches at exact UTC boundaries",LM.At(event,105).id=="Sakura" and LM.At(event,125).id=="Golden" and LM.At(event,155)==nil)
 check("Late join resolves current step rather than restarting",LM.At(event,140).endsAt==155)
 check("Cancelled Live Event has no weather effects",LM.At({cancelled=true,endsAt=1000},200)==nil)
 check("Malformed unknown oversized and nonfinite sequences are rejected",not LM.Build({},"",100,1) and not LM.Build({{id="bad",seconds=20}},"",100,1) and not LM.Build({{id="Clear",seconds=20}},"",100,1) and not LM.Build({{id="Rain",seconds=0/0}},"",100,1) and not LM.Build({{id="Rain",seconds=601}},"",100,1) and not LM.Build({{id="Rain",seconds=10}},string.rep("a",241),100,1))
 local cell;local fake={UpdateAsync=function(_,_,fn,ttl) assert(ttl==LC.TTL);cell=fn(cell);return cell end,GetAsync=function() return cell end};local notifications=0
 local good,msg,v=Live.Write(event,fake,function() notifications+=1 end)
 check("Global write stores the event atomically before notifying",good and v.revision==1 and notifications==1 and cell.rows[1].id=="Sakura")
 Live.Write(event,fake,function() end);check("Concurrent replacements advance a store-owned revision",cell.revision==2)
 good=Live.Write(event,fake,function() error("dropped message") end);check("Dropped messages leave readable committed state for polling",good and select(1,Live.Read(fake)) and cell.revision==3)
 check("MemoryStore failure does not announce success",not Live.Write(event,{UpdateAsync=function() error("offline") end},function() error("should not publish") end))
 local liveNow=assert(LM.Build({{id="Sakura",seconds=20}},"local-test",os.time()-LC.StartDelay,1));WX.Force("Snow",300);Live.Preview(liveNow)
 check("Active Live Event overrides local forced weather",WX.State().id=="Sakura" and WX.State().live)
 F.Set("LiveEvents",false);check("Live flag off resumes server override",WX.State().id=="Snow");F.Set("LiveEvents",true)
 F.Set("Weather",false);check("Weather flag off suppresses all event effects",WX.State().id=="Clear");F.Set("Weather",true)
 Live.Preview(LM.Build({{id="Golden",seconds=10}},"expired",os.time()-100,1));check("Expired preview cannot retain forced event weather",WX.State().id=="Snow")
 Live.Preview(nil);D.Set(p,"Progress.Rebirth",0);D.Set(p,"Progress.UnlockedZones",{1});D.Set(p,"Progress.StoryChapter",9)
 D.Set(p,"Inventory.Pets",{});D.Set(p,"Garden.plots",{});D.Set(p,"Boosts",{Wood=0,Coins=0});D.Set(p,"Rebirth.skills",{});D.Set(p,"Index.done",{})
 check("Run starts for actual weather award validation",R.Begin(p));local base=B.TreeReward(1,1,0,false)
 WX.Force("Aurora",300);local wood=R.Get(p).Wood;local coins=R.Get(p).Coins;R.Award(p,1,1,false)
 check("Aurora boosts real Wood and Coins rewards by x1.5",near(R.Get(p).Wood-wood,base.wood*1.5) and near(R.Get(p).Coins-coins,base.coins*1.5))
 WX.Force("Bloodmoon",300);wood=R.Get(p).Wood;coins=R.Get(p).Coins;R.Award(p,1,1,false)
 check("Bloodmoon real tree rewards are x4 and health is x2",near(R.Get(p).Wood-wood,base.wood*4) and near(R.Get(p).Coins-coins,base.coins*4) and WX.Def().hp==2)
 D.Set(p,"Boosts",{Wood=os.time()+900,Coins=os.time()+900});wood=R.Get(p).Wood;coins=R.Get(p).Coins;R.Award(p,1,1,false)
 check("Bloodmoon with timed boosts keeps Wood Coins cap x4",near(R.Get(p).Wood-wood,base.wood*4) and near(R.Get(p).Coins-coins,base.coins*4));D.Set(p,"Boosts",{Wood=0,Coins=0})
 for _,model in game.CollectionService:GetTagged("Tree") do if model:GetAttribute("Zone")==1 and model:GetAttribute("Tier")==1 then usedTree=model;break end end
 assert(usedTree);T.Reset(usedTree);local trunk=usedTree.PrimaryPart;local ground=trunk.Position-Vector3.new(0,trunk.Size.Y/2,0);p.Character:PivotTo(CFrame.new(ground+Vector3.new(9,4,0)));p:SetAttribute("AdminCutPower",1000);B.SetOverride("CritChance",1);WX.Force("Sakura",300);task.wait(.3)
 local hit,damage=T.Hit(p,usedTree);check("Actual Sakura critical hit uses x15",hit and near(damage,15000))
 WX.Force("Fog",300);task.wait(2.2);local fog=workspace:FindFirstChild("FogChest");check("Fog creates one ready extra chest spot",fog and fog:GetAttribute("ChestReady")==true)
 WX.Force("Clear",300);task.wait(1.2);check("Fog chest is removed when weather ends",not workspace:FindFirstChild("FogChest"))
 R.End(p,false);D.Set(p,"Pets.incubator",{});local Eggs=require(S.Config.Eggs)
 for _,pair in {{"Sakura","Sakura"},{"Meteor","Celestial"},{"Rainbow","Rainbow"}} do
  WX.Force(pair[1],300);local eggs={};local now=os.time();for i=1,30 do eggs[tostring(i)]={id="egg_meadow",zone=1,progress=0,updatedAt=now-Eggs.ById.egg_meadow.hatch} end
  D.Set(p,"Pets.incubator",eggs);P.Advance(p,now,true);local found=false;for _,e in D.Get(p,"Pets.incubator") do found=found or e.mutation==pair[2] end;check(pair[1].." online hatching can grant its pet mutation",found)
 end
 WX.Force("Meteor",300);D.Set(p,"Pets.incubator",{["1"]={id="egg_meadow",zone=1,progress=0,updatedAt=os.time()-60}});P.Advance(p,os.time(),false)
 check("Offline hatch cannot gain rare weather mutations",D.Get(p,"Pets.incubator.1").mutation==nil)
 WC.ById.Meteor.chance=1;local now=os.time();local plot={id="seed_sunapple",zone=1,rebirthDrop=0,mature=true,nextFruitAt=now-1,updatedAt=now-1,mutations={}};D.Set(p,"Garden.plots",{["1"]=plot})
 require(V.GardenService).Advance(p,now,false);check("Offline garden does not acquire rare weather mutations",not plot.mutations.Celestial)
 require(V.GardenService).Advance(p,now,true);check("Online garden uses the new meteor mutation seam",plot.mutations.Celestial==true);WC.ById.Meteor.chance=meteorChance
 local data=D.GetData(p);D.Set(p,"Index.done.seeds",true);check("Expanding mutation catalog preserves earned Index buffs",CM.Bonus(data,"Wood",true)==.25 and CM.Totals.mutations==16)
 check("Balance SelfTest passes",B.SelfTest())
end,debug.traceback)
R.End(p,false);D.ImportJSON(p,original);p:SetAttribute("AdminCutPower",power);Live.Preview(preview)
for id,v in flags do F.Set(id,v) end;if weather then WX.Force(weather.id,math.max(1,weather.endsAt-os.time())) else WX.Force(nil) end
WC.ById.Meteor.chance=meteorChance;B.ClearOverrides();for k,v in balance do B.SetOverride(k,v) end;if usedTree then T.Reset(usedTree) end
root.Anchored=anchor;p.Character:PivotTo(pivot);P.Refresh(p);require(V.GardenService).Send(p);require(V.QuestService).Send(p,true);W.RefreshTool(p);R.Send(p)
workspace:SetAttribute("Phase8WeatherResults",game.HttpService:JSONEncode({passed=ok,checks=results,error=not ok and err or nil}));workspace:SetAttribute("Phase8WeatherStatus",ok and "passed" or "failed")
if ok then print("[Phase8WeatherScenario] passed "..#results) else warn(err) end
