-- Phase 8d3: ambient zone mutations, squirrel merchant, daily rare fruit sell cap.
-- Inject in Studio Play as a temporary Script. Always restores the real profile.
assert(game:GetService("RunService"):IsStudio())
local V=game.ServerScriptService.Server.Services;local S=game.ReplicatedStorage.Shared
local D=require(V.DataService);local F=require(V.FeatureService);local WX=require(V.WeatherService);local R=require(V.RunService)
local G=require(V.GardenService);local M=require(V.MerchantService);local P=require(V.PetService);local B=require(S.Balance)
local GC=require(S.Config.Garden);local GM=require(S.GardenMath);local MC=require(S.Config.Merchant);local MM=require(S.MerchantMath)
local p=game.Players:GetPlayers()[1];assert(D.WaitForData(p,30));local original=D.ExportJSON(p)
local root=p.Character.HumanoidRootPart;local anchor=root.Anchored;local pivot=p.Character:GetPivot()
local weather=WX.GetOverride();local results={}
local flags={};for _,id in {"Garden","Eggs","Chests","Weather","Merchant","AutoSave","Leaderboard"} do flags[id]=F.IsEnabled(id) end
local function check(name,ok) assert(ok,name);table.insert(results,{name=name,passed=true}) end
local function at(pos) pcall(p.RequestStreamAroundAsync,p,pos,5);p.Character:PivotTo(CFrame.new(pos));task.wait(.15) end
local function count(t) local n=0;for _ in t do n+=1 end;return n end
workspace:SetAttribute("Phase8MerchantStatus","running")
local ok,err=xpcall(function()
 R.End(p,false);P.Dismount(p);root.Anchored=true
 for id in flags do F.Set(id,true) end;F.Set("AutoSave",false);F.Set("Leaderboard",false);WX.Force("Clear",600)
 D.Set(p,"Meta.AdminTouched",true);D.Set(p,"Progress.UnlockedZones",{1});D.Set(p,"Progress.Rebirth",0)
 local migrated=D.Migrate({DataVersion=1,Garden={slots=12,plots={},bought={x=1}}})
 check("Schema adds sell cap and merchant ledgers without touching garden data",migrated.Garden.slots==12 and migrated.Garden.bought.x==1 and migrated.Garden.sellDay==-1 and next(migrated.Garden.sold)==nil and next(migrated.Merchant.bought)==nil)
 -- schedule
 local first=20730*86400;local window,noRot,nextOk=true,true,true
 for now=first,first+2*86400,60 do
  local v,nextAt=MM.Visit(now);local minute=now%3600
  window=window and ((v~=nil)==(minute>=1800 and minute<2400))
  noRot=noRot and not (v and now%7200<600)
  if v then nextOk=nextOk and v.endsAt>now and v.endsAt-now<=600 else nextOk=nextOk and nextAt>now and MM.Visit(nextAt)~=nil and MM.Visit(nextAt-1)==nil end
 end
 check("Merchant visits minutes 30-40 of every UTC hour",window)
 check("Merchant never overlaps a RotInvasion window",noRot)
 check("Next arrival points at the true start of the next visit",nextOk)
 local stock=MM.Stock(12345);local unique={};for _,id in stock do unique[id]=MC.ById[id]~=nil end
 check("Stock is deterministic with 4 distinct valid offers",#stock==MC.Slots and count(unique)==MC.Slots and table.concat(stock,",")==table.concat(MM.Stock(12345),","))
 -- sell caps
 local cosmic={id="seed_sunapple",zone=1,rebirthDrop=0,mutations={Cosmic=true,Golden=true},count=7}
 local plain={id="seed_sunapple",zone=1,rebirthDrop=0,mutations={Wet=true},count=4}
 check("Cap key is the highest capped mutation",GM.CapKey({Aurora=true,Cosmic=true,Wet=true})=="Cosmic" and GM.CapKey({Wet=true,Golden=true})==nil)
 local total,sold=GM.SellQuote({cosmic,plain},{})
 check("First 5 Cosmic pay full price, extras pay the over-cap rate",math.abs(total-(GM.Value(cosmic)*(5+2*GC.OverCapMult)+GM.Value(plain)*4))<1e-6 and sold.Cosmic==7)
 local again=GM.SellQuote({cosmic},sold);check("Exhausted cap pays only the over-cap rate",math.abs(again-GM.Value(cosmic)*7*GC.OverCapMult)<1e-6)
 local stored={Cosmic=1};local _,after=GM.SellQuote({cosmic},stored)
 check("Quote does not mutate the stored counter",stored.Cosmic==1 and after.Cosmic==8)
 local shop;for _,m in game.CollectionService:GetTagged("Shop") do if m:GetAttribute("ShopType")=="SeedShop" then shop=m.PrimaryPart end end
 at(shop.Position+Vector3.new(0,4,6))
 local coins=D.GetCurrency(p,"Coins");local g=D.Get(p,"Garden");g.sellDay=-1;g.sold={Cosmic=99};D.Set(p,"Garden",g)
 D.Set(p,"Inventory.Fruits",{a=table.clone(cosmic)})
 check("A new UTC day resets the counter before selling",G.Sell(p) and math.abs(D.GetCurrency(p,"Coins")-coins-GM.Value(cosmic)*(5+2*GC.OverCapMult))<1e-3 and D.Get(p,"Garden.sold").Cosmic==7 and D.Get(p,"Garden.sellDay")==os.time()//86400)
 coins=D.GetCurrency(p,"Coins");D.Set(p,"Inventory.Fruits",{a=table.clone(cosmic)})
 check("Same-day sale stays capped",G.Sell(p) and math.abs(D.GetCurrency(p,"Coins")-coins-GM.Value(cosmic)*7*GC.OverCapMult)<1e-3 and next(D.Get(p,"Inventory.Fruits"))==nil)
 -- ambient
 local now=os.time();g=D.Get(p,"Garden")
 g.plots={["1"]={id="seed_sunapple",zone=3,rebirthDrop=0,progress=300,updatedAt=now,mature=true,watered=false,nextFruitAt=now,mutations={}},
  ["2"]={id="seed_sunapple",zone=1,rebirthDrop=0,progress=300,updatedAt=now,mature=true,watered=false,nextFruitAt=now,mutations={}}}
 D.Set(p,"Garden",g);G.Advance(p,now,false)
 check("Offline growth never rolls ambient mutations",D.Get(p,"Garden.plots")["1"].ambientSeen==nil)
 local hits=0
 for i=1,400 do
  local plots=D.Get(p,"Garden.plots");plots["1"].nextFruitAt=now-i;plots["1"].mutations={};G.Advance(p,now,true)
  if plots["1"].mutations.Misty then hits+=1 end
  G.Advance(p,now,true);if plots["1"].ambientSeen~=now-i then hits=-1e9 end
 end
 local plots=D.Get(p,"Garden.plots")
 check("Zone 3 plots roll Misty about 5% per fruit cycle",hits>=5 and hits<=45)
 check("Zone 1 plots get no ambient mutation",next(plots["2"].mutations)==nil and plots["2"].ambientSeen==nil)
 plots["1"].mutations={};local seen=plots["1"].ambientSeen;for _=1,50 do G.Advance(p,now,true) end
 check("One roll per fruit cycle",plots["1"].ambientSeen==seen and next(plots["1"].mutations)==nil)
 -- merchant
 F.Set("Merchant",false);check("Feature off hides the merchant",M.Visit()==nil and M.State(p)==nil and not M.Buy(p,"m_seed_lumora"));F.Set("Merchant",true)
 M.Summon(MC.SummonSeconds);local state=M.State(p)
 check("Summon opens a visit with 4 priced offers",state and #state.offers==MC.Slots and M.GetModel().Parent==workspace)
 D.SetCurrency(p,"Coins",1e15);D.SetCurrency(p,"Gems",1e6);D.Set(p,"Inventory.Eggs",{});D.Set(p,"Inventory.Chests",{});D.Set(p,"Inventory.Seeds",{})
 local first=state.offers[1].id
 at(shop.Position+Vector3.new(0,4,6));check("Buying needs to stand at the merchant",not M.Buy(p,first))
 at(M.GetModel():GetPivot().Position+Vector3.new(4,1,0))
 check("Offers outside this visit's stock are rejected",(function() for _,o in MC.Offers do if not table.find(MM.Stock(M.Visit().seed),o.id) then return not M.Buy(p,o.id) end end;return true end)())
 check("Unknown ids are rejected",not M.Buy(p,"nope") and not M.Buy(p,""))
 R.Begin(p);at(M.GetModel():GetPivot().Position+Vector3.new(4,1,0));check("Buying is blocked during a Run",not M.Buy(p,first));R.End(p,false)
 at(M.GetModel():GetPivot().Position+Vector3.new(4,1,0))
 local allPaid,allGranted,capped=true,true,true
 for _,o in state.offers do
  local def=MC.ById[o.id];local currency,price=MM.Price(o.id,G.ShopZone(p))
  for _=1,def.limit do
   local before=D.GetCurrency(p,currency);local seeds,eggs,chests=count(D.Get(p,"Inventory.Seeds")),count(D.Get(p,"Inventory.Eggs")),#D.Get(p,"Inventory.Chests")
   local okBuy=M.Buy(p,o.id);allPaid=allPaid and okBuy and D.GetCurrency(p,currency)==before-price and price==o.price
   allGranted=allGranted and (def.kind=="egg" and count(D.Get(p,"Inventory.Eggs"))==eggs+1 or def.kind=="seed" and count(D.Get(p,"Inventory.Seeds"))>=math.max(1,seeds) or def.kind=="chest" and #D.Get(p,"Inventory.Chests")>=1)
  end
  local before=D.GetCurrency(p,currency);capped=capped and not M.Buy(p,o.id) and D.GetCurrency(p,currency)==before
 end
 check("Each stock offer charges the server price",allPaid)
 check("Purchases grant the seed, egg or chest",allGranted)
 check("Per-visit limit blocks extra purchases without charging",capped)
 local adminKept=true;for _,s in D.Get(p,"Inventory.Seeds") do adminKept=adminKept and s.admin_spawned==true end;for _,e in D.Get(p,"Inventory.Eggs") do adminKept=adminKept and e.admin_spawned==true end
 check("Admin provenance carries into merchant items",adminKept)
 check("UI state shows zero remaining after buying out",(function() for _,o in M.State(p).offers do if o.left~=0 then return false end end;return true end)())
 task.wait(1.1) -- admin visit keys are per second; a same-second summon would reuse the bought-out ledger
 M.Summon(MC.SummonSeconds);local fresh=M.State(p)
 D.SetCurrency(p,"Coins",0);D.SetCurrency(p,"Gems",0);local key=M.Visit().key
 check("Insufficient currency is rejected without a marker",not M.Buy(p,fresh.offers[1].id) and D.Get(p,"Merchant.bought")[key]==nil)
 local marks=D.Get(p,"Merchant.bought");marks.old={at=os.time()-MC.KeepSeconds-5,n={x=1}};D.Set(p,"Merchant.bought",marks);D.SetCurrency(p,"Coins",1e15);D.SetCurrency(p,"Gems",1e6)
 local buyId;for _,o in fresh.offers do if MC.ById[o.id].kind~="egg" then buyId=o.id end end;buyId=buyId or fresh.offers[1].id;D.Set(p,"Inventory.Eggs",{})
 check("A purchase prunes ledgers older than 2 days",M.Buy(p,buyId) and D.Get(p,"Merchant.bought").old==nil and D.Get(p,"Merchant.bought")[key]~=nil)
 M.Summon(nil);check("Dismiss returns to the UTC schedule",(M.Visit()~=nil)==(MM.Visit(os.time())~=nil))
 check("Balance SelfTest passes",B.SelfTest())
end,debug.traceback)
M.Summon(nil);for id,v in flags do F.Set(id,v) end
if weather then WX.Force(weather.id,math.max(1,weather.endsAt-os.time())) else WX.Force(nil) end
R.End(p,false);D.ImportJSON(p,original);root.Anchored=anchor;p.Character:PivotTo(pivot);P.Refresh(p);R.Send(p);G.Send(p)
workspace:SetAttribute("Phase8MerchantResults",game.HttpService:JSONEncode({passed=ok,checks=results,error=not ok and err or nil}));workspace:SetAttribute("Phase8MerchantStatus",ok and "passed" or "failed")
print("[Phase8MerchantScenario]",ok and "passed" or err,#results)
