-- Finish before Stop. All profile changes happen inside the game's VM.
assert(game.RunService:IsStudio())
local V=game.ServerScriptService.Server.Services;local S=game.ReplicatedStorage.Shared
local D=require(V.DataService);local F=require(V.FeatureService);local WX=require(V.WeatherService);local L=require(V.LiveEventService)
local E=require(V.WeatherEncounterService);local R=require(V.RunService);local P=require(V.PetService);local N=require(V.NestService);local Net=require(S.Net)
local p=game.Players:GetPlayers()[1];assert(D.WaitForData(p,30))
local original=D.ExportJSON(p);script:SetAttribute("OriginalData",original)
local root=p.Character.HumanoidRootPart;local pivot=p.Character:GetPivot();local anchor=root.Anchored;local power=p:GetAttribute("AdminCutPower")
local weather=WX.GetOverride();local preview=L.GetPreview();local flags={}
for _,id in {"Weather","WeatherEncounters","Eggs","Chests","Forest","Story","AutoSave","Leaderboard"} do flags[id]=F.IsEnabled(id);F.Set(id,true) end
F.Set("AutoSave",false);F.Set("Leaderboard",false);F.Set("Story",false);L.Preview(nil);R.End(p,false);root.Anchored=true
D.Set(p,"Meta.AdminTouched",true);D.Set(p,"Progress.UnlockedZones",{1});D.Set(p,"Pets.weatherBought",{});D.Set(p,"Inventory.Eggs",{});D.Set(p,"Inventory.Chests",{})
local function move(pos) pcall(p.RequestStreamAroundAsync,p,pos,5);p.Character:PivotTo(CFrame.new(pos));root.Anchored=true end
local function state()
 local eggs={};for _,egg in D.Get(p,"Inventory.Eggs") do table.insert(eggs,egg.id) end
 local w=E.GetWorld()
 script:SetAttribute("State",game.HttpService:JSONEncode({dust=D.GetCurrency(p,"Stardust"),coins=D.GetCurrency(p,"Coins"),eggs=eggs,chests=D.Get(p,"Inventory.Chests"),worldRatio=w and w.ratio,carrying=p:GetAttribute("CarryingEgg")}))
end
local stage=""
script:SetAttribute("Ready",true)
while not script:GetAttribute("Finish") do
 local want=script:GetAttribute("Stage")
 if want~=stage then stage=want
  if stage=="Exchange" then
   R.End(p,false);WX.Force("Clear",600);E.Update();D.SetCurrency(p,"Stardust",20)
   move(workspace.Map.Village.ChestAltar.PrimaryPart.Position+Vector3.new(0,6,0));Net.Event("InventoryShow"):FireClient(p)
  elseif stage=="Aurora" then
   R.End(p,false);WX.Force("Aurora",600);E.Update();D.SetCurrency(p,"Coins",100000)
   for _,belt in game.CollectionService:GetTagged("Shop") do if belt:GetAttribute("ShopType")=="EggConveyor" then move(belt:GetPivot().Position+Vector3.new(0,5,6)) end end
   Net.Event("PetShow"):FireClient(p,"Belt");P.Send(p)
  elseif stage=="Meteor" then
   WX.Force("Meteor",600);E.Update();local pickup=E.SpawnMeteor();assert(pickup)
   move(pickup.Position+Vector3.new(0,2,4));R.Begin(p);move(pickup.Position+Vector3.new(0,2,4));script:SetAttribute("Pickup",pickup:GetFullName())
  elseif stage=="World" then
   WX.Force("RotInvasion",600);E.Update();local w=E.GetWorld();assert(w)
   move(w.center+Vector3.new(-14,4,0));R.Begin(p);move(w.center+Vector3.new(-14,4,0));p:SetAttribute("AdminCutPower",1000)
  end
  script:SetAttribute("StageReady",stage)
 end
 state();task.wait(.1)
end
N.Drop(p);R.End(p,false);WX.Force("Clear",600);E.Update();D.ImportJSON(p,original);L.Preview(preview)
for id,v in flags do F.Set(id,v) end;if weather then WX.Force(weather.id,math.max(1,weather.endsAt-os.time())) else WX.Force(nil) end;E.Update()
p:SetAttribute("AdminCutPower",power);root.Anchored=anchor;p.Character:PivotTo(pivot);P.Refresh(p);require(V.WeaponService).RefreshTool(p);require(V.GardenService).Send(p);require(V.QuestService).Send(p,true);R.Send(p)
local before=game.HttpService:JSONDecode(original);local after=D.GetData(p);local changes={}
local function same(a,b,path)
 if type(a)~=type(b) then table.insert(changes,path);return end
 if type(a)=="table" then for k,v in a do same(v,b[k],path.."."..tostring(k)) end;for k in b do if a[k]==nil then table.insert(changes,path.."."..tostring(k)) end end
 elseif a~=b then table.insert(changes,path) end
end
for _,key in {"Currencies","Inventory","Pets","Progress","Index","Achievements","Rebirth","Garden","Quests","Meta"} do same(before[key],after[key],key) end
workspace:SetAttribute("EncounterGUIRestoration",game.HttpService:JSONEncode({passed=#changes==0,mismatches=changes}));script:SetAttribute("Restored",true)
