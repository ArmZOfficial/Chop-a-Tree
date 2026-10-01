-- Phase 8g Robux shop. Inject in Studio Play as a temporary Script. Always restores the real profile.
assert(game:GetService("RunService"):IsStudio())
local V=game.ServerScriptService.Server.Services;local S=game.ReplicatedStorage.Shared
local D=require(V.DataService);local F=require(V.FeatureService);local M=require(V.MonetizationService);local R=require(V.RunService)
local P=require(V.PetService);local G=require(V.GardenService);local St=require(V.StealService);local Story=require(V.StoryService);local Daily=require(V.DailyService)
local WX=require(V.WeatherService);local B=require(S.Balance)
local C=require(S.Config.Products);local CM=require(S.CollectionMath);local Loot=require(S.Loot);local Prog=require(S.Config.Progression)
local p=game.Players:GetPlayers()[1];assert(D.WaitForData(p,30));local original=D.ExportJSON(p)
local root=p.Character.HumanoidRootPart;local anchor=root.Anchored;local pivot=p.Character:GetPivot();local weather=WX.GetOverride()
local flags={};for _,id in {"Shop","Garden","Eggs","Chests","Story","Daily","Rebirth","IndexBonuses","AutoSave","Leaderboard","FriendBoost"} do flags[id]=F.IsEnabled(id) end
local results={}
local function check(name,ok) assert(ok,name);table.insert(results,{name=name,passed=true}) end
local function passes(t) D.Set(p,"Purchases.passes",t);M.Refresh(p) end
local Enum_=Enum.ProductPurchaseDecision
workspace:SetAttribute("Phase8ShopStatus","running")
local ok,err=xpcall(function()
 R.End(p,false);P.Dismount(p);root.Anchored=true;WX.Force("Clear",600)
 for id in flags do F.Set(id,true) end;F.Set("AutoSave",false);F.Set("Leaderboard",false);F.Set("FriendBoost",false);F.Set("Rebirth",false);F.Set("IndexBonuses",false)
 D.Set(p,"Meta.AdminTouched",true);D.Set(p,"Index.done",{});D.Set(p,"Rebirth.skills",{});D.Set(p,"Boosts",{Wood=0,Coins=0,Exp=0,Luck=0});passes({});D.Set(p,"Inventory.Pets",{});D.Set(p,"Garden.plots",{})
 game.ReplicatedStorage:SetAttribute("ServerLuckUntil",0)
 local migrated=D.Migrate({DataVersion=1,Boosts={Wood=5}})
 check("Schema adds pass/receipt ledgers and EXP/Luck boosts",migrated.Boosts.Wood==5 and migrated.Boosts.Exp==0 and migrated.Boosts.Luck==0 and next(migrated.Purchases.passes)==nil and next(migrated.Purchases.receipts)==nil)
 local ids={};local dup=false;for _,v in C.Passes do dup=dup or ids[v.id];ids[v.id]=true end;for _,v in C.Products do dup=dup or ids[v.id];ids[v.id]=true end
 check("10 passes and 17 products with unique IDs",#C.Passes==10 and #C.Products==17 and not dup)
 -- pass math
 local d=D.GetData(p)
 check("Without passes permanent Wood/Coins and luck stay free values",CM.Permanent(d,"Wood",false,false)==1 and CM.Luck(d,false,false)==0)
 passes({Wood2x=true,Coins2x=true,Lucky=true});d=D.GetData(p)
 check("x2 Wood/Coins passes reach the free ceiling x2",CM.Permanent(d,"Wood",false,false)==2 and CM.Permanent(d,"Coins",false,false)==2)
 D.Set(p,"Index.done",{seeds=true});d=D.GetData(p)
 check("Pass does not stack on free permanent bonuses",CM.Permanent(d,"Wood",false,true)==Prog.PermanentCap)
 check("Lucky pass gives +25% permanent luck",CM.Luck(d,false,false)==Prog.LuckCap)
 local now=os.time();d.Boosts.Luck=now+60
 check("Luck potion adds a temporary +25% up to +50%",CM.Luck(d,false,false,now)==Prog.LuckMax)
 d.Boosts.Luck=0;check("Server luck adds the same temporary +25%",CM.Luck(d,false,false,now,now+60)==Prog.LuckMax and CM.Luck(d,false,false,now,now-1)==Prog.LuckCap)
 local w25=Loot.Odds("Common",1,.25);local w50=Loot.Odds("Common",1,.5);local hi=function(w) return w[3]+w[4]+w[5] end
 check("Loot honours luck up to +50%",hi(w50)>hi(w25) and math.abs(hi(w50)/hi(Loot.Odds("Common",1,0))-1.5)<1e-9 and hi(Loot.Odds("Common",1,9))==hi(w50))
 D.Set(p,"Pets.equipSlots",3);local cap0=P.EquipCap(p);passes({PetSlots=true})
 check("Pet slot pass adds 2 within the max of 6",P.EquipCap(p)==math.min(6,cap0+2))
 D.Set(p,"Pets.upgrades",{lock=0,incubator=0,pen=0});passes({HatchSpeed=true})
 check("Hatch pass gives x2 and never stacks with the max incubator",P.HatchSpeed(p)==2 and (function() D.Set(p,"Pets.upgrades",{lock=0,incubator=4,pen=0});return P.HatchSpeed(p)==2 end)())
 D.Set(p,"Garden.slots",6);passes({GardenPlots=true});check("Garden pass adds 10 plots",G.Slots(p)==16)
 D.Set(p,"Garden.slots",24);check("Garden plots never exceed 30",G.Slots(p)==30);D.Set(p,"Garden.slots",6)
 -- receipts
 passes({});D.SetCurrency(p,"Gems",0);local gems=C.ProductByKey.gems100
 local info={PlayerId=p.UserId,ProductId=gems.id,PurchaseId="phase8-shop-test-1",CurrencySpent=19}
 check("Receipt grants Gems once saved",M.ProcessReceipt(info)==Enum_.PurchaseGranted and D.GetCurrency(p,"Gems")==100 and D.Get(p,"Purchases.receipts")["phase8-shop-test-1"]~=nil)
 check("Replayed receipt is granted without paying again",M.ProcessReceipt(info)==Enum_.PurchaseGranted and D.GetCurrency(p,"Gems")==100)
 check("Unknown product or player is not processed",M.ProcessReceipt({PlayerId=p.UserId,ProductId=1,PurchaseId="x"})==Enum_.NotProcessedYet and M.ProcessReceipt({PlayerId=1,ProductId=gems.id,PurchaseId="y"})==Enum_.NotProcessedYet and D.GetCurrency(p,"Gems")==100)
 local t=D.Get(p,"Purchases.receipts");t.old=os.time()-C.ReceiptKeepSeconds-5;D.Set(p,"Purchases.receipts",t)
 M.ProcessReceipt({PlayerId=p.UserId,ProductId=gems.id,PurchaseId="phase8-shop-test-2"})
 check("Receipts older than 90 days are pruned",D.Get(p,"Purchases.receipts").old==nil and D.GetCurrency(p,"Gems")==200)
 -- product effects
 now=os.time();for _,k in {"wood15","coins30","exp15","luck30"} do M.Grant(p,k) end;local b=D.Get(p,"Boosts")
 check("Boost potions set 15/30 minute expiries",b.Wood>=now+899 and b.Coins>=now+1799 and b.Exp>=now+899 and b.Luck>=now+1799)
 R.Begin(p);local base=B.TreeReward(1,1,0,false);local r=R.Get(p);local exp=r.Exp;R.Award(p,1,1,false)
 check("EXP potion doubles tree EXP",math.abs((r.Exp-exp)-base.exp*2*G.ExpBuff())<1e-6);R.End(p,false)
 M.Grant(p,"serverLuck");check("Server luck sets a 15 minute shared window",(game.ReplicatedStorage:GetAttribute("ServerLuckUntil") or 0)>=os.time()+899)
 D.Set(p,"Pets.incubator",{["1"]={id="egg_meadow",zone=1,progress=0,updatedAt=os.time()}})
 M.Grant(p,"instantHatch");check("Instant hatch finishes incubator eggs",D.Get(p,"Pets.incubator")["1"].done==true)
 D.Set(p,"Pets.incubator",{});local okP,msg=M.Prompt(p,"instantHatch");check("Instant hatch prompt is refused with an empty incubator",not okP and msg~=nil)
 D.Set(p,"Garden.plots",{["1"]={id="seed_sunapple",zone=1,rebirthDrop=0,progress=0,updatedAt=os.time(),mature=false,watered=false,nextFruitAt=0,mutations={}}})
 M.Grant(p,"instantGrow");check("Instant grow matures garden plots",D.Get(p,"Garden.plots")["1"].mature==true)
 D.Set(p,"Inventory.Chests",{});M.Grant(p,"chestKey");local ch=D.Get(p,"Inventory.Chests")[1]
 check("Chest key grants a Legendary LEVEL 10 chest",ch and ch.rarity=="Legendary" and ch.level==10 and ch.count==1)
 St.ResetLock(p);M.Grant(p,"baseLock");check("Base lock product locks the base immediately",St.Locked(G.BaseIndex(p)))
 local okL=M.Prompt(p,"baseLock");check("Base lock prompt is refused while locked",not okL);St.ResetLock(p)
 -- pass perks
 passes({VIP=true});check("VIP shows a title and attribute",p:GetAttribute("VIP")==true and string.sub(p:GetAttribute("AchievementTitle"),1,3)=="VIP")
 D.Set(p,"Daily",{lastDay=-1,streak=0,claimedDay=-1});D.SetCurrency(p,"Gems",0);Daily.Claim(p)
 check("VIP daily claim adds bonus Gems",D.GetCurrency(p,"Gems")==20+require(S.Config.Daily).VipGems)
 check("Owned pass cannot be prompted again",not M.Prompt(p,"VIP"))
 passes({});local village=workspace.Map.Village.ChestAltar.PrimaryPart.Position+Vector3.new(0,5,12);p.Character:PivotTo(CFrame.new(village));task.wait(.2)
 check("Warp away from a stone needs the Teleport pass",not Story.Warp(p,0))
 passes({Teleport=true});check("Teleport pass warps from anywhere",Story.Warp(p,0))
 passes({AutoSell=true});local coins=D.GetCurrency(p,"Coins");D.Set(p,"Inventory.Fruits",{});local plot=D.Get(p,"Garden.plots")["1"];plot.nextFruitAt=os.time()-1
 local slot=G.Base(p).GardenSlots.Slot1;p.Character:PivotTo(slot.CFrame+Vector3.new(0,4,0));task.wait(.2)
 check("Auto Sell sells the harvest immediately",G.Harvest(p,1) and next(D.Get(p,"Inventory.Fruits"))==nil and D.GetCurrency(p,"Coins")>coins)
 F.Set("Shop",false);check("Shop flag off refuses prompts",not M.Prompt(p,"gems100"));F.Set("Shop",true)
 check("Balance SelfTest passes",B.SelfTest())
end,debug.traceback)
for id,v in flags do F.Set(id,v) end;game.ReplicatedStorage:SetAttribute("ServerLuckUntil",0);pcall(St.ResetLock,p)
if weather then WX.Force(weather.id,math.max(1,weather.endsAt-os.time())) else WX.Force(nil) end
R.End(p,false);D.ImportJSON(p,original);root.Anchored=anchor;p.Character:PivotTo(pivot);M.Refresh(p);R.Send(p);D.SaveNow(p)
workspace:SetAttribute("Phase8ShopResults",game.HttpService:JSONEncode({passed=ok,checks=results,error=not ok and err or nil}));workspace:SetAttribute("Phase8ShopStatus",ok and "passed" or "failed")
print("[Phase8ShopScenario]",ok and "passed" or err,#results)
