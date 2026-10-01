-- Finish before Stop. Isolated OpenTen fixture; snapshots and restores the profile.
assert(game.RunService:IsStudio())
local V=game.ServerScriptService.Server.Services
local D=require(V.DataService);local F=require(V.FeatureService);local M=require(V.MonetizationService);local W=require(V.WeaponService);local R=require(V.RunService)
local p=game.Players:GetPlayers()[1];assert(D.WaitForData(p,30))
local original=D.ExportJSON(p);local root=p.Character.HumanoidRootPart;local pivot=p.Character:GetPivot();local anchor=root.Anchored
local flags={};for _,id in {"Shop","Chests","AutoSave","Leaderboard"} do flags[id]=F.IsEnabled(id);F.Set(id,true) end
F.Set("AutoSave",false);F.Set("Leaderboard",false);R.End(p,false)
D.Set(p,"Meta.AdminTouched",true);D.Set(p,"Inventory.Weapons",{});D.Set(p,"Inventory.Equipped","")
D.Set(p,"Purchases.passes",{OpenTen=true});M.Refresh(p);D.Set(p,"Stats.ChestsOpened",0)
D.Set(p,"Inventory.Chests",{});W.GrantChest(p,"Rare",1,1,12,true)
local altar=workspace.Map.Village.ChestAltar.PrimaryPart.Position+Vector3.new(0,6,0);p.Character:PivotTo(CFrame.new(altar));root.Anchored=true
local pass=Instance.new("BindableFunction");pass.Name="SetPass";pass.Parent=script
pass.OnInvoke=function(enabled,nested)
 assert(type(enabled)=="boolean")
 if nested then D.Set(p,"Purchases.passes.OpenTen",enabled) else D.Set(p,"Purchases.passes",enabled and {OpenTen=true} or {}) end
 M.Refresh(p)
end
local capacity=Instance.new("BindableFunction");capacity.Name="SetFreeSlots";capacity.Parent=script
capacity.OnInvoke=function(slots)
 local max=require(game.ReplicatedStorage.Shared.Config.Chests).MaxWeapons
 assert(type(slots)=="number" and slots%1==0 and slots>=0 and slots<=max)
 local id=require(game.ReplicatedStorage.Shared.Config.Weapons).List[1].id
 local inv={};for _=1,max-slots do
  inv[game.HttpService:GenerateGUID(false)]={id=id,il=1,stars=1,giant=false,rebirthDrop=0,roll=1,admin_spawned=true}
 end
 D.Set(p,"Inventory.Equipped","");D.Set(p,"Inventory.Weapons",inv)
 D.Set(p,"Inventory.Chests",{});W.GrantChest(p,"Rare",1,1,12,true);D.Set(p,"Stats.ChestsOpened",0)
 W.RefreshTool(p)
end
script:SetAttribute("Ready",true)
while not script:GetAttribute("Finish") do
 local n=0;for _,c in D.Get(p,"Inventory.Chests") do n+=c.count end
 local w=0;for _ in D.Get(p,"Inventory.Weapons") do w+=1 end
 script:SetAttribute("State",game.HttpService:JSONEncode({chests=n,weapons=w,opened=D.Get(p,"Stats.ChestsOpened"),passes=D.Get(p,"Purchases.passes")}));task.wait(.1)
end
R.End(p,false);D.ImportJSON(p,original);for id,v in flags do F.Set(id,v) end;M.Refresh(p);root.Anchored=anchor;p.Character:PivotTo(pivot);W.RefreshTool(p)
local before=game.HttpService:JSONDecode(original);local after=D.GetData(p);local changes={}
local function same(a,b,path)
 if type(a)~=type(b) then table.insert(changes,path);return end
 if type(a)=="table" then for k,v in a do same(v,b[k],path.."."..tostring(k)) end;for k in b do if a[k]==nil then table.insert(changes,path.."."..tostring(k)) end end
 elseif a~=b then table.insert(changes,path) end
end
for _,key in {"Currencies","Inventory","Purchases","Boosts","Meta","Garden","Pets","Stats","Season"} do same(before[key],after[key],key) end
D.SaveNow(p);script:SetAttribute("Restored",#changes==0);script:SetAttribute("Changes",table.concat(changes,","));script:SetAttribute("Done",true)
