-- Studio-only baseline controller. Invoke Prepare before each existing scenario,
-- then Finish after its terminal status, even on failure. Never ship this Script.
assert(game.RunService:IsStudio())
local V=game.ServerScriptService.Server.Services
local D=require(V.DataService);local F=require(V.FeatureService);local R=require(V.RunService)
local P=require(V.PetService);local W=require(V.WeaponService);local WX=require(V.WeatherService)
local B=require(game.ReplicatedStorage.Shared.Balance)
local p=game.Players:GetPlayers()[1];assert(D.WaitForData(p,30))
local original=D.ExportJSON(p);script:SetAttribute("OriginalData",original)
local pivot=p.Character:GetPivot();local root=p.Character.HumanoidRootPart;local anchor=root.Anchored
local flags=game.ReplicatedStorage.FeatureFlags:GetAttributes();local weather=WX.GetOverride();local balance=B.Overrides()
local power=p:GetAttribute("AdminCutPower");local shield=p:GetAttribute("ShieldOverride")
local luck=game.ReplicatedStorage:GetAttribute("ServerLuckUntil")
local function restore()
 R.End(p,false);P.Dismount(p);D.ImportJSON(p,original);task.wait(.2)
 -- Import schedules offline pet advancement; restore clocks after that handler.
 local before=game.HttpService:JSONDecode(original);D.Set(p,"Pets",before.Pets)
 local changes={};local function same(a,b,path)
  if type(a)~=type(b) then table.insert(changes,path);return end
  if type(a)=="table" then for k,v in a do same(v,b[k],path.."."..tostring(k)) end;for k in b do if a[k]==nil then table.insert(changes,path.."."..tostring(k)) end end
  elseif a~=b then table.insert(changes,path) end
 end
 local after=D.GetData(p)
 for _,k in {"Currencies","Inventory","Purchases","Boosts","Pets","Garden","Stats","Season","Progress"} do same(before[k],after[k],k) end
 for id,v in flags do F.Set(id,v) end
 if weather then WX.Force(weather.id,math.max(1,weather.endsAt-os.time())) else WX.Force(nil) end
 B.ClearOverrides();for k,v in balance do B.SetOverride(k,v) end
 game.ReplicatedStorage:SetAttribute("ServerLuckUntil",luck)
 p:SetAttribute("AdminCutPower",power);p:SetAttribute("ShieldOverride",shield)
 root.Anchored=anchor;p.Character:PivotTo(pivot);W.RefreshTool(p);P.Refresh(p);R.Send(p)
 script:SetAttribute("Restored",#changes==0);script:SetAttribute("RestoreChanges",table.concat(changes,","))
 D.SaveNow(p);return #changes==0,table.concat(changes,",")
end
local prepare=Instance.new("BindableFunction");prepare.Name="Prepare";prepare.Parent=script
prepare.OnInvoke=function()
 F.Set("AutoSave",false);F.Set("Leaderboard",false);R.End(p,false);P.Dismount(p)
 for _,id in {"FriendBoost","Rebirth","IndexBonuses","SeasonPass"} do F.Set(id,false) end
 D.Set(p,"Meta.AdminTouched",true);D.Set(p,"Purchases.passes",{});D.Set(p,"Boosts",{Wood=0,Coins=0,Exp=0,Luck=0})
 D.Set(p,"Rebirth.skills",{});D.Set(p,"Index.done",{});D.Set(p,"Inventory.Pets",{});D.Set(p,"Garden.plots",{})
 D.Set(p,"Inventory.Equipped","");W.RefreshTool(p)
 game.ReplicatedStorage:SetAttribute("ServerLuckUntil",0)
 return true
end
local finish=Instance.new("BindableFunction");finish.Name="Finish";finish.Parent=script;finish.OnInvoke=restore
script:SetAttribute("Ready",true)
