assert(game:GetService('RunService'):IsStudio(), 'Map QA is Studio-only')
assert(script.Parent.Services.DataService:GetAttribute('MapUseMockProfiles') == true, 'Map QA requires mock profiles')
local S=script.Parent.Services
local names={"FeatureService","DataService","WeatherService","GardenService","WeaponService","RunService","TreeService","QuestService","StoryService","DayCycleService","ZoneService","GateService","ExplorerService","TravelService","WorldEventService"}
local loaded,failures={},{}
for _,name in names do local ok,m=pcall(require,S[name]);if ok then loaded[name]=m else table.insert(failures,"require "..name..": "..tostring(m)) end end
for _,name in names do if loaded[name] then local ok,e=pcall(loaded[name].Init);if not ok then table.insert(failures,"Init "..name..": "..tostring(e)) end end end
for _,name in {"DataService","WeatherService","QuestService","DayCycleService","ZoneService","GateService","WorldEventService"} do if loaded[name] then local ok,e=pcall(loaded[name].Start);if not ok then table.insert(failures,"Start "..name..": "..tostring(e)) end end end
local call=Instance.new("BindableFunction");call.Name="MapQACall";call.Parent=game.ReplicatedStorage
local function dispatch(action)
 local p=game.Players:GetPlayers()[1];local D=loaded.DataService
 if action=="migration" then local ok,summary,detail=require(game.ServerScriptService.Server.AdminCommands.MapMigrationCheck)(D);return {ok=ok,summary=summary,detail=detail} end
 if action=="report" then local valid,errs=require(game.ReplicatedStorage.Shared.ZoneUtil).Validate();return {failures=failures,valid=valid,validationErrors=errs,zone=loaded.ZoneService.Report(),player=p and p.Name,profile=p and D.GetData(p),counts={trees=#game:GetService("CollectionService"):GetTagged("Tree"),explorer=#game:GetService("CollectionService"):GetTagged("ExplorerCollectible")}} end
 if action=="event" then loaded.WeatherService.Force("Clear",300);local ok,msg=loaded.WorldEventService.StartEvent("GoldenTree",1);return {ok=ok,msg=msg} end
 if action=="variants" then
  loaded.WeatherService.Force("Clear",300);local out={}
  for _,kind in {"GiantTree","AncientTree","CursedTree"} do
   loaded.WorldEventService.Stop();local ok,msg=loaded.WorldEventService.StartEvent(kind,1);local e=loaded.WorldEventService.Get()
   table.insert(out,{kind=kind,ok=ok,msg=msg,actual=e and e.tree:GetAttribute("SpecialKind"),scale=e and e.tree:GetScale()})
  end
  loaded.WorldEventService.Stop();return out
 end
 if action=="unlock2" then loaded.StoryService.UnlockZone(p,2);return true end
 if action=="boat" or action=="boatCancel" or action=="boatBack" then
  local id=action=="boatBack" and 0 or 1
	 local hull
  for _,model in workspace:GetChildren() do if model.Name=="MapTravelBoat" and model.Hull:FindFirstChildWhichIsA("ProximityPrompt").ObjectText==(id==1 and "Sunny Meadow" or "Rootfall") then hull=model.Hull;break end end
  assert(hull,"Missing dock boat");p.Character:PivotTo(hull.CFrame+Vector3.new(0,3,0));task.wait(.5)
  local started=os.clock();local ok,msg=loaded.TravelService.Warp(p,id,hull)
  local pos=p.Character:GetPivot().Position
  return {ok=ok,msg=msg,seconds=os.clock()-started,zone=loaded.RunService.ZoneAt(p),position={pos.X,pos.Y,pos.Z}}
 end
 if action=="spawnTree" then
  for _,spawn in game:GetService("CollectionService"):GetTagged("ZoneSpawn") do if spawn:GetAttribute("Zone")==1 then p.Character:PivotTo(spawn:GetPivot()+Vector3.new(0,4,0));break end end;task.wait(.2)
  local ok,msg,model=loaded.TreeService.SpawnQA(p,"Oak",1)
  local invalid=loaded.TreeService.SpawnQA(p,"missing",1)
  return {ok=ok,msg=msg,invalid=invalid,zone=model and model:GetAttribute("Zone"),tier=model and model:GetAttribute("Tier"),kind=model and model:GetAttribute("Kind"),alive=model and model:GetAttribute("Alive"),tag=model and game:GetService("CollectionService"):HasTag(model,"Tree")}
 end
 if action=="perf" then
  local total,peak=0,0
  for _=1,200 do local started=os.clock();loaded.ZoneService.Update(started);loaded.GateService.Update();loaded.DayCycleService.Update();loaded.WorldEventService.Update();local ms=(os.clock()-started)*1000;total+=ms;peak=math.max(peak,ms);task.wait(.02) end
  return {samples=200,players=#game.Players:GetPlayers(),meanMs=total/200,peakMs=peak,scope="Zone/Gate/DayCycle/WorldEvent synchronous updates; excludes rendering/network callbacks"}
 end
 if action=="basesCycle" then
  local G=loaded.GardenService;local first=G.BaseIndex(p)
  for _=1,25 do G.Release(p);assert(not G.Base(p));G.Assign(p);assert(G.BaseIndex(p)==first);assert(G.Base(p):GetAttribute("OwnerUserId")==p.UserId) end
  return {cycles=25,index=first,ok=true}
 end
 if action=="mockRoundTrip" then
  local Http=game:GetService("HttpService")
  local snapshot=Http:JSONDecode(Http:JSONEncode({Progress=D.Get(p,"Progress"),Explorer=D.Get(p,"Explorer"),Chests=D.Get(p,"Inventory.Chests")}))
  local function same(a,b)
   if type(a)~=type(b) then return false end;if type(a)~="table" then return a==b end
   for k,v in a do if not same(v,b[k]) then return false end end
   for k in b do if a[k]==nil then return false end end;return true
  end
  local function matches(data) return same(snapshot.Progress,data.Progress) and same(snapshot.Explorer,data.Explorer) and same(snapshot.Chests,data.Inventory.Chests) end
  assert(D.SaveAndWait(p,matches,15),"Mock save timed out")
  local key="Player_"..p.UserId;local base=loaded.GardenService.Base(p)
  p:Kick("Map mock profile round-trip test complete")
  local deadline=os.clock()+15
  while D.IsLoaded(p) and os.clock()<deadline do task.wait(.1) end
  assert(not D.IsLoaded(p),"Old mock session not released")
  local mock=require(script.Parent.Packages.ProfileStore).New(D.STORE_NAME,D.Template).Mock
  local reopened=mock:StartSessionAsync(key);assert(reopened,"Mock profile failed to reopen")
  local preserved=matches(reopened.Data);local version=reopened.Data.DataVersion
  reopened:EndSession()
  return {saved=true,reopened=true,preserved=preserved,version=version,baseReleased=base and base:GetAttribute("OwnerUserId")==0,backend="ProfileStore.Mock; existing store/player key"}
 end
 if action=="collect" then
  local results={};local Config=require(game.ReplicatedStorage.Shared.Config.Explorer);local gate=loaded.FeatureService;gate.Set("MapSystems",true)
  for _,def in Config.List do if def.zone==1 then p.Character:PivotTo(CFrame.new(def.position));task.wait(.4);table.insert(results,{id=def.id,ok=loaded.ExplorerService.Collect(p,def.id),duplicate=loaded.ExplorerService.Collect(p,def.id)}) end end
  return {results=results,completed=D.Get(p,"Explorer.completed"),chests=D.Get(p,"Inventory.Chests")}
 end
 if action=="allExplorer" then
 D.Set(p,"Progress.UnlockedZones",{1,2,3,4,5,6,7,8})
 local results={};for _,def in require(game.ReplicatedStorage.Shared.Config.Explorer).List do
 p.Character:PivotTo(CFrame.new(def.position));task.wait(.4);results[def.id]=loaded.ExplorerService.Collect(p,def.id)
 end
 local count=0;for _ in D.Get(p,"Explorer.completed") do count+=1 end
 return {completed=count,chests=D.Get(p,"Inventory.Chests"),results=results}
 end
 if action=="travel" then
 local Travel=loaded.TravelService
 local invalid=Travel.Warp(p,math.huge)
 D.Set(p,"Purchases.passes",{Teleport=true});D.Set(p,"Progress.VisitedZones",{["1"]=true});D.Set(p,"Run.Active",false)
 local ok,msg=Travel.Warp(p,1);return {invalid=invalid,ok=ok,message=msg}
 end
 if action=="zone2" then p.Character:PivotTo(CFrame.new(0,22,700));task.wait(1.5);return {pos=p.Character:GetPivot().Position,zone=p:GetAttribute("Zone"),visits=D.Get(p,"Progress.VisitedZones")} end
 if action=="hub" then p.Character:PivotTo(workspace.Map.Village.VillageSpawn.CFrame+Vector3.new(0,4,0));return true end
 if action=="language" then D.Set(p,"Settings.Language","th");return true end
 return false
end
print("[MapRuntimeQA] mock data only; failures="..#failures)
for _,e in failures do warn("[MapRuntimeQA] "..e) end

local requests=Instance.new("Folder");requests.Name="MapQARequests";requests.Parent=game.ReplicatedStorage
requests:GetAttributeChangedSignal("action"):Connect(function()
 local action=requests:GetAttribute("action");if not action or action=="" then return end
 local ok,result=pcall(dispatch,action)
 if ok then local encodeOK,json=pcall(game:GetService("HttpService").JSONEncode,game:GetService("HttpService"),result);requests:SetAttribute("result",encodeOK and json or tostring(result)) else requests:SetAttribute("result",tostring(result)) end
 requests:SetAttribute("completed",action)
end)
