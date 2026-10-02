assert(game:GetService('RunService'):IsStudio(), 'Map QA is Studio-only')
assert(script.Parent.Services.DataService:GetAttribute('MapUseMockProfiles') == true, 'Map QA requires mock profiles')
local S=script.Parent.Services
local names={"FeatureService","DataService","WeatherService","GardenService","WeaponService","RunService","TreeService","StoryService","DayCycleService","ZoneService","GateService","ExplorerService","TravelService","WorldEventService"}
local loaded,failures={},{}
for _,name in names do local ok,m=pcall(require,S[name]);if ok then loaded[name]=m else table.insert(failures,"require "..name..": "..tostring(m)) end end
for _,name in names do if loaded[name] then local ok,e=pcall(loaded[name].Init);if not ok then table.insert(failures,"Init "..name..": "..tostring(e)) end end end
for _,name in {"DataService","WeatherService","DayCycleService","ZoneService","GateService","WorldEventService"} do if loaded[name] then local ok,e=pcall(loaded[name].Start);if not ok then table.insert(failures,"Start "..name..": "..tostring(e)) end end end
local call=Instance.new("BindableFunction");call.Name="MapQACall";call.Parent=game.ReplicatedStorage
local function dispatch(action)
 local p=game.Players:GetPlayers()[1];local D=loaded.DataService
 if action=="migration" then local ok,summary,detail=require(game.ServerScriptService.Server.AdminCommands.MapMigrationCheck)(D);return {ok=ok,summary=summary,detail=detail} end
 if action=="report" then local valid,errs=require(game.ReplicatedStorage.Shared.ZoneUtil).Validate();return {failures=failures,valid=valid,validationErrors=errs,zone=loaded.ZoneService.Report(),player=p and p.Name,profile=p and D.GetData(p),counts={trees=#game:GetService("CollectionService"):GetTagged("Tree"),explorer=#game:GetService("CollectionService"):GetTagged("ExplorerCollectible")}} end
 if action=="event" then loaded.WeatherService.Force("Clear",300);local ok,msg=loaded.WorldEventService.StartEvent("GoldenTree",1);return {ok=ok,msg=msg} end
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
