-- Finish before Stop. Stages: Merchant (stand at the summoned squirrel), Sell (Cosmic fruits at the seed shop).
assert(game.RunService:IsStudio())
local V=game.ServerScriptService.Server.Services
local D=require(V.DataService);local F=require(V.FeatureService);local R=require(V.RunService);local M=require(V.MerchantService);local G=require(V.GardenService)
local p=game.Players:GetPlayers()[1];assert(D.WaitForData(p,30))
local original=D.ExportJSON(p);local root=p.Character.HumanoidRootPart;local pivot=p.Character:GetPivot();local anchor=root.Anchored;local flags={}
for _,id in {"Garden","Eggs","Chests","Merchant","AutoSave","Leaderboard"} do flags[id]=F.IsEnabled(id);F.Set(id,true) end
F.Set("AutoSave",false);F.Set("Leaderboard",false);R.End(p,false);root.Anchored=true
D.Set(p,"Meta.AdminTouched",true);D.Set(p,"Inventory.Eggs",{});D.Set(p,"Inventory.Chests",{});D.Set(p,"Inventory.Seeds",{})
local function move(pos) pcall(p.RequestStreamAroundAsync,p,pos,5);p.Character:PivotTo(CFrame.new(pos));root.Anchored=true end
local function state()
 local eggs,seeds=0,0;for _,e in D.Get(p,"Inventory.Eggs") do eggs+=1 end;for _,s in D.Get(p,"Inventory.Seeds") do seeds+=s.count end
 script:SetAttribute("State",game.HttpService:JSONEncode({coins=D.GetCurrency(p,"Coins"),gems=D.GetCurrency(p,"Gems"),eggs=eggs,seeds=seeds,chests=#D.Get(p,"Inventory.Chests"),fruits=next(D.Get(p,"Inventory.Fruits"))~=nil,sold=D.Get(p,"Garden.sold"),visit=M.Visit() and M.Visit().key,merchant=M.State(p)}))
end
local stage=""
script:SetAttribute("Ready",true)
while not script:GetAttribute("Finish") do
 local want=script:GetAttribute("Stage")
 if want~=stage then stage=want
  if stage=="Merchant" then
   D.SetCurrency(p,"Coins",1e15);D.SetCurrency(p,"Gems",1e6);move(M.GetModel():GetPivot().Position+Vector3.new(5,2,0))
  elseif stage=="Sell" then
   local g=D.Get(p,"Garden");g.sellDay=-1;g.sold={};D.Set(p,"Garden",g);D.SetCurrency(p,"Coins",0)
   D.Set(p,"Inventory.Fruits",{a={id="seed_sunapple",zone=1,rebirthDrop=0,mutations={Cosmic=true},count=7,admin_spawned=true}})
   for _,m in game.CollectionService:GetTagged("Shop") do if m:GetAttribute("ShopType")=="SeedShop" then move(m.PrimaryPart.Position+Vector3.new(0,4,6)) end end
   G.Send(p)
  end
  script:SetAttribute("StageReady",stage)
 end
 state();task.wait(.1)
end
M.Summon(nil);R.End(p,false);D.ImportJSON(p,original);for id,v in flags do F.Set(id,v) end
root.Anchored=anchor;p.Character:PivotTo(pivot);G.Send(p)
local before=game.HttpService:JSONDecode(original);local after=D.GetData(p);local changes={}
local function same(a,b,path)
 if type(a)~=type(b) then table.insert(changes,path);return end
 if type(a)=="table" then for k,v in a do same(v,b[k],path.."."..tostring(k)) end;for k in b do if a[k]==nil then table.insert(changes,path.."."..tostring(k)) end end
 elseif a~=b then table.insert(changes,path) end
end
for _,key in {"Currencies","Inventory","Garden","Merchant","Pets","Progress","Meta"} do same(before[key],after[key],key) end
script:SetAttribute("Restored",#changes==0);script:SetAttribute("Changes",table.concat(changes,","));script:SetAttribute("Done",true)
