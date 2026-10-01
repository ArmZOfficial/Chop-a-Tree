-- Inject in Studio Play as a temporary Script. Always restores the real profile.
assert(game:GetService("RunService"):IsStudio())
local Http=game:GetService("HttpService");local Collection=game:GetService("CollectionService")
local S=game.ReplicatedStorage.Shared;local Services=game.ServerScriptService.Server.Services
local D=require(Services.DataService);local P=require(Services.PetService);local St=require(Services.StealService)
local N=require(Services.NestService);local R=require(Services.RunService);local T=require(Services.TreeService)
local G=require(Services.GardenService);local W=require(Services.WeatherService);local F=require(Services.FeatureService)
local M=require(S.PetMath);local B=require(S.Balance);local Pets=require(S.Config.Pets);local Eggs=require(S.Config.Eggs);local Config=require(S.Config.Base)
local p=game.Players:GetPlayers()[1];assert(D.WaitForData(p,30))
local original=D.ExportJSON(p);script:SetAttribute("OriginalData",original)
local position=p.Character:GetPivot();local override=W.GetOverride();local cutPower=p:GetAttribute("AdminCutPower");local balanceOverrides=B.Overrides()
local root=p.Character:WaitForChild("HumanoidRootPart");local anchored=root.Anchored
local flags={Eggs=F.IsEnabled("Eggs"),Stealing=F.IsEnabled("Stealing")};local results={};local temporary={}
workspace:SetAttribute("Phase5TestStatus","running")
local function check(name,ok) assert(ok,name);table.insert(results,{name=name,passed=true}) end
local function at(cf) p.Character:PivotTo(cf);task.wait(.15) end
local function count(t) local n=0;for _ in t do n+=1 end;return n end
local function freshPets() D.Set(p,"Pets",{incubator={},bank=0,bankAt=0,beltBought={},upgrades={lock=0,incubator=0,pen=0},equipSlots=3});D.Set(p,"Inventory.Eggs",{});D.Set(p,"Inventory.Pets",{});P.Refresh(p) end
local function eggUid() for uid in D.Get(p,"Inventory.Eggs") do return uid end end
local function petsOf(id) local out={};for uid,pet in D.Get(p,"Inventory.Pets") do if pet.id==id then table.insert(out,uid) end end;table.sort(out);return out end
local base=G.Base(p);local incubator=base.Incubator:GetPivot();local pen=base.PetPen:GetPivot()
local function atIncubator() at(incubator*CFrame.new(5,3,0)) end
local ok,err=xpcall(function()
	R.End(p,false);F.Set("Eggs",true);F.Set("Stealing",true);W.Force("Clear",3600);p:SetAttribute("ShieldOverride","off");St.ResetLock(p)
	freshPets();D.Set(p,"Progress.UnlockedZones",{1});D.Set(p,"Progress.Rebirth",0);D.SetCurrency(p,"Coins",1e9);D.SetCurrency(p,"Wood",1e9)
	local migrated=D.Migrate({DataVersion=1,Inventory={Weapons={keep={id="existing"}},Equipped="keep",Chests={}}})
	check("Reconcile adds egg/pet data and keeps weapons",migrated.Inventory.Weapons.keep.id=="existing" and type(migrated.Inventory.Eggs)=="table" and type(migrated.Inventory.Pets)=="table" and migrated.Pets.equipSlots==3 and type(migrated.Run.Eggs)=="table" and migrated.Settings.FriendSteal==false)
	local valid=true;for _,e in Eggs.List do for _,row in e.pets do if not Pets.ById[row[1]] or row[2]<=0 then valid=false end end end
	for _,def in Pets.List do if not Pets.Income[def.rarity] or not Pets.Bonus[def.rarity] or (def.rideable and not Config.MountSpeed[def.rarity]) then valid=false end end
	check("Every egg drop table and pet rarity resolves",valid)
	check("Base pen income is 2 Coins/s for a zone 1 Common",M.Income({id="pet_fox",zone=1,tier=1})==2)
	check("Tier and mutation scale income",M.Income({id="pet_fox",zone=1,tier=2,mutation="Golden"})==2*1.5*5)
	check("Source zone scales income x100 and buff x1.2",M.Income({id="pet_squirrel",zone=2,tier=1})==200 and math.abs(M.Bonus({id="pet_squirrel",zone=2,tier=1})-.06)<1e-9)
	local many={};for _=1,10 do table.insert(many,{id="pet_drake",zone=1,tier=5}) end
	check("Pet Power buff caps at x4",M.Mult(many,"Power")==4)
	check("Pet Speed buff caps at x1.5",M.Mult({{id="pet_stag",zone=2,tier=5},{id="pet_stag",zone=2,tier=5},{id="pet_stag",zone=2,tier=5}},"Speed")==1.5)
	local window=M.BeltWindow(os.time())
	check("Conveyor belt is deterministic with three visible eggs",#window==3 and M.Belt(window[1].epoch)==M.Belt(window[1].epoch) and window[3].leavesAt>os.time())
	for _=1,Config.MaxEggs do P.GrantEgg(p,{id="egg_meadow"}) end
	check("Egg inventory caps at 60",count(D.Get(p,"Inventory.Eggs"))==60 and not P.GrantEgg(p,{id="egg_meadow"}) and P.EggRoom(p)==0)
	freshPets();P.GrantEgg(p,{id="egg_meadow"});local uid=eggUid()
	at(base.PrimaryPart.CFrame*CFrame.new(200,5,0))
	check("Placing an egg away from the incubator is rejected",not P.Place(p,uid,1))
	atIncubator()
	check("Invalid incubator slots are rejected",not P.Place(p,uid,4) and not P.Place(p,uid,1.5))
	check("Placing consumes the egg into the slot",P.Place(p,uid,1) and count(D.Get(p,"Inventory.Eggs"))==0 and D.Get(p,"Pets.incubator")["1"])
	P.GrantEgg(p,{id="egg_meadow"});check("Occupied slot rejects another egg",not P.Place(p,eggUid(),1) and count(D.Get(p,"Inventory.Eggs"))==1)
	local egg=D.Get(p,"Pets.incubator")["1"];local now=os.time();egg.updatedAt=now-30;P.Advance(p,now,true)
	check("Incubator progresses by real time",egg.progress==30 and not egg.done)
	check("Unfinished eggs cannot hatch",not P.Hatch(p))
	W.Force("Golden",300);egg.updatedAt=now-600;P.Advance(p,now,false)
	check("Offline completion never rolls a weather mutation",egg.done and egg.mutation==nil)
	local mutated=0
	for _=1,30 do D.Get(p,"Pets.incubator")["2"]={id="egg_meadow",zone=1,rebirthDrop=0,progress=59,updatedAt=os.time()-1};P.Advance(p,os.time(),true);if D.Get(p,"Pets.incubator")["2"].mutation=="Golden" then mutated+=1 end end
	D.Get(p,"Pets.incubator")["2"]=nil;W.Force("Clear",3600)
	check("Online completion during Golden can roll Golden",mutated>0 and mutated<30)
	local hatched=D.Get(p,"Stats.EggsHatched")
	check("Hatch turns a finished egg into one penned pet",P.Hatch(p) and count(D.Get(p,"Inventory.Pets"))==1 and not D.Get(p,"Pets.incubator")["1"] and D.Get(p,"Stats.EggsHatched")==hatched+1)
	local first=next(D.Get(p,"Inventory.Pets"));check("Hatched pet goes to the pen automatically",D.Get(p,"Inventory.Pets")[first].place=="pen")
	check("Repeated hatch is rejected",not P.Hatch(p) and count(D.Get(p,"Inventory.Pets"))==1)
	freshPets();P.GrantPet(p,"pet_fox",{});local d=D.Get(p,"Pets");d.bankAt=os.time()-10;P.Advance(p,os.time(),true)
	check("Pen income accrues per second online",math.abs(d.bank-20)<=2)
	d.bank=0;d.bankAt=os.time()-20*3600;P.Advance(p,os.time(),false)
	check("Offline pen income caps at 8 hours",d.bank==2*8*3600)
	check("Collecting away from the pen is rejected",not P.Collect(p))
	at(pen*CFrame.new(0,4,0));local coins=D.GetCurrency(p,"Coins");local bank=math.floor(d.bank)
	check("Collect pays the bank exactly once",P.Collect(p) and D.GetCurrency(p,"Coins")==coins+bank and d.bank<1 and not P.Collect(p))
	freshPets();for _=1,9 do P.GrantPet(p,"pet_bunny",{}) end;local penned=0;for _,pet in D.Get(p,"Inventory.Pets") do if pet.place=="pen" then penned+=1 end end
	check("Pen holds 8 pets before upgrades",penned==8)
	local bunnies=petsOf("pet_bunny");for i=1,3 do P.SetPlace(p,bunnies[i],"equip") end
	check("Only three pets can follow",not P.SetPlace(p,bunnies[4],"equip"))
	check("Following pets replicate for client visuals",p:GetAttribute("PetFollow")=="pet_bunny,pet_bunny,pet_bunny")
	freshPets();local before=R.Power(p);P.GrantPet(p,"pet_fox",{});P.SetPlace(p,petsOf("pet_fox")[1],"equip")
	check("Following Power pet raises Cut Power",math.abs(R.Power(p)/before-1.05)<1e-9)
	P.GrantPet(p,"pet_bee",{});P.SetPlace(p,petsOf("pet_bee")[1],"equip");R.Begin(p);local run=R.Get(p);local reward=B.TreeReward(1,1,0,false);R.Award(p,1,1,false)
	check("Following Wood pet multiplies forest Wood",math.abs(run.Wood-reward.wood*1.1)<1e-6);R.End(p,false)
	freshPets();for _=1,3 do P.GrantPet(p,"pet_fox",{}) end;local foxes=petsOf("pet_fox");D.Get(p,"Inventory.Pets")[foxes[2]].mutation="Golden"
	P.GrantPet(p,"pet_bee",{})
	check("Fusing mismatched pets is rejected",not P.Fuse(p,{foxes[1],foxes[2],petsOf("pet_bee")[1]}) and not P.Fuse(p,{foxes[1],foxes[1],foxes[2]}))
	local fused,_,result=P.Fuse(p,foxes)
	check("Fusing three identical pets gives one higher tier and keeps the best mutation",fused and result.pet.tier==2 and result.pet.mutation=="Golden" and #petsOf("pet_fox")==1)
	check("Release removes the pet",P.Release(p,petsOf("pet_bee")[1]) and #petsOf("pet_bee")==0)
	check("Non-rideable pets cannot be mounted",not P.Mount(p,petsOf("pet_fox")[1]))
	P.GrantPet(p,"pet_wolf",{});check("Mounting a rideable pet multiplies WalkSpeed",P.Mount(p,petsOf("pet_wolf")[1]) and math.abs(p.Character.Humanoid.WalkSpeed-16*2.1)<1e-3 and p:GetAttribute("MountPet")=="pet_wolf")
	P.Dismount(p);check("Dismount restores WalkSpeed",p.Character.Humanoid.WalkSpeed==16 and p:GetAttribute("MountPet")=="")
	at(base.PrimaryPart.CFrame*CFrame.new(0,4,0));local wood=D.GetCurrency(p,"Wood")
	check("Pen upgrade costs Wood and adds four slots",P.Upgrade(p,"pen") and D.GetCurrency(p,"Wood")==wood-1000 and P.PenCap(p)==12)
	check("Incubator upgrade speeds hatching",P.Upgrade(p,"incubator") and M.HatchSpeed(D.Get(p,"Pets.upgrades").incubator)==1.25)
	for _=1,3 do P.Upgrade(p,"lock") end;check("Lock upgrade caps at level 3 (120 seconds)",D.Get(p,"Pets.upgrades").lock==3 and not P.Upgrade(p,"lock") and M.LockSeconds(3)==120)
	check("Unknown upgrade rejected",not P.Upgrade(p,"rocket"))
	freshPets();local belt;for _,m in Collection:GetTagged("Shop") do if m:GetAttribute("ShopType")=="EggConveyor" then belt=m end end
	window=M.BeltWindow(os.time());local row;for _,r in window do if Eggs.ById[r.id].zone==1 then row=r end end
	check("Buying away from the conveyor is rejected",not P.Buy(p,window[1].epoch))
	at(belt.PrimaryPart.CFrame*CFrame.new(0,5,6))
	if row then coins=D.GetCurrency(p,"Coins")
		check("Conveyor purchase charges zone price once",P.Buy(p,row.epoch) and D.GetCurrency(p,"Coins")==coins-M.EggPrice(row.id) and count(D.Get(p,"Inventory.Eggs"))==1 and not P.Buy(p,row.epoch))
	end
	check("Old or future belt epochs are rejected",not P.Buy(p,window[1].epoch-5) and not P.Buy(p,window[3].epoch+1))
	local leafEpoch;local e=math.floor(os.time()/Config.BeltSeconds);for k=e-2,e do if M.Belt(k)=="egg_leaf" then leafEpoch=k end end
	if leafEpoch then check("Zone 2 eggs need zone 2 unlocked",not P.Buy(p,leafEpoch)) end
	freshPets();for _=1,300 do if count(D.Get(p,"Inventory.Eggs"))>0 then break end;P.ChestDrop(p,{zone=2,rebirthDrop=1,admin_spawned=true}) end
	local dropped=D.Get(p,"Inventory.Eggs")[eggUid()]
	check("Chest egg drop keeps zone, Rot and admin provenance",dropped and dropped.id=="egg_leaf" and dropped.rebirthDrop==1 and dropped.admin_spawned)
	-- Wild nests
	freshPets();local spotsList={};for spot,s in N.Spots() do if s.zone==1 and s.ready then table.insert(spotsList,spot) end end;table.sort(spotsList,function(a,b) return a:GetFullName()<b:GetFullName() end)
	check("Zone 1 nests expose six egg spots",#spotsList>=6)
	local spot=spotsList[1];at(spot.CFrame*CFrame.new(3,3,0))
	check("Nest eggs need an active Run",not N.Take(p,spot))
	R.Begin(p);at(spot.CFrame*CFrame.new(3,3,0))
	check("Taking a nest egg starts a slowed carry",N.Take(p,spot) and p:GetAttribute("CarryingEgg") and math.abs(p.Character.Humanoid.WalkSpeed-16*.8)<1e-3)
	check("Only one egg can be carried",not N.Take(p,spotsList[2]))
	check("Carrying blocks mounting",not P.Mount(p,select(2,P.GrantPet(p,"pet_wolf",{}))))
	check("Secure moves the egg into Run.Eggs",N.Secure(p) and #D.Get(p,"Run.Eggs")==1 and not p:GetAttribute("CarryingEgg") and p.Character.Humanoid.WalkSpeed==16)
	check("Taken nest spot waits for refill",not N.Spots()[spot].ready)
	R.End(p,false);check("End Run settles secured nest eggs",count(D.Get(p,"Inventory.Eggs"))==1)
	R.Begin(p);spot=spotsList[2];at(spot.CFrame*CFrame.new(3,3,0));N.Take(p,spot);R.End(p,false)
	check("Dying/leaving (End without button) returns the carried egg",count(D.Get(p,"Inventory.Eggs"))==1 and N.Spots()[spot].ready and not p:GetAttribute("CarryingEgg"))
	R.Begin(p);at(spot.CFrame*CFrame.new(3,3,0));N.Take(p,spot);R.End(p,true)
	check("End Run button secures the carried egg",count(D.Get(p,"Inventory.Eggs"))==2);task.wait(.5)
	R.Begin(p);spot=spotsList[3];at(spot.CFrame*CFrame.new(3,3,0));root.Anchored=true;N.Take(p,spot);local caughtAt=os.clock()
	repeat task.wait(.1) until not p:GetAttribute("CarryingEgg") or os.clock()-caughtAt>6
	root.Anchored=anchored
	check("Guardian catches a carrier who stands still and returns the egg",not p:GetAttribute("CarryingEgg") and N.Spots()[spot].ready and os.clock()-caughtAt<6)
	local stone;for _,w in Collection:GetTagged("WarpStone") do if w:GetAttribute("Zone")==1 then stone=w end end
	at(spot.CFrame*CFrame.new(3,3,0));N.Take(p,spot);at(stone:GetPivot()*CFrame.new(4,4,0));task.wait(.3)
	check("Reaching the zone WarpStone secures the egg",not p:GetAttribute("CarryingEgg") and #D.Get(p,"Run.Eggs")==1);R.End(p,false)
	-- Stealing from a bot base
	freshPets();St.ResetLock(p)
	local okBot,botId=St.CreateBot();local botBase=G.BaseById(botId)
	check("Bot base takes a free base without changing ours",okBot and botId~=G.BaseIndex(p) and botBase:GetAttribute("OwnerUserId")==-1)
	check("Eggs hatched past 75% are not stealable",not M.Stealable(St.Bot().incubator["3"]) and M.Stealable(St.Bot().incubator["1"]))
	check("Stealing far from the incubator is rejected",not St.Try(p,botId))
	at(botBase.Incubator:GetPivot()*CFrame.new(5,3,0))
	R.Begin(p);check("Stealing during a Run is rejected",not St.Try(p,botId));R.End(p,false)
	check("Steal starts a slowed carry with a reclaim prompt",St.Try(p,botId) and St.Bot().incubator["1"].carriedBy==p.UserId and math.abs(p.Character.Humanoid.WalkSpeed-12)<1e-3 and root:FindFirstChild("ReclaimPrompt") and Collection:HasTag(p.Character,"EggThief"))
	check("Thief carries only one egg",not St.Try(p,botId))
	check("Thief cannot start a Run",not R.Begin(p) and not D.Get(p,"Run.Active"))
	coins=D.GetCurrency(p,"Coins");local stolen=D.Get(p,"Stats.EggsStolen")
	at(base.PrimaryPart.CFrame*CFrame.new(0,4,0));task.wait(.4)
	local got=D.Get(p,"Inventory.Eggs")[eggUid()]
	check("Delivering home transfers the egg once",got and got.stolen and not St.Bot().incubator["1"] and count(D.Get(p,"Inventory.Eggs"))==1 and not p:GetAttribute("CarryingEgg"))
	check("Successful steal pays a bonus and counts",D.GetCurrency(p,"Coins")==coins+math.floor(M.EggPrice("egg_meadow")*Config.StealBonus) and D.Get(p,"Stats.EggsStolen")==stolen+1)
	at(botBase.Incubator:GetPivot()*CFrame.new(5,3,0))
	check("Same base is on thief cooldown",not St.Try(p,botId))
	St.ResetLock(p);local bot=St.Bot().incubator["2"];local progress=bot.progress
	check("Cooldown reset allows the next egg",St.Try(p,botId) and bot.carriedBy==p.UserId)
	check("Cancel returns the egg untouched",St.Return(p,"test") and bot.carriedBy==nil and St.Bot().incubator["2"]==bot and bot.progress==progress)
	St.RemoveBot();check("Removing the bot frees its base",botBase:GetAttribute("OwnerUserId")==0 and St.Bot()==nil)
	-- Victim side: shields, lock and the test thief
	p:SetAttribute("ShieldOverride",nil);local play=D.Get(p,"Stats.PlaySeconds");D.Set(p,"Stats.PlaySeconds",0)
	check("New players are shielded for 30 minutes",St.Shield(p)=="new");D.Set(p,"Stats.PlaySeconds",3600)
	St.Presence(p,700);check("AFK over 10 minutes grants a shield",St.Shield(p)=="afk")
	St.MarkActive(p);check("Acting clears the AFK shield",St.Shield(p)==nil);D.Set(p,"Stats.PlaySeconds",play);p:SetAttribute("ShieldOverride","off")
	at(base.PrimaryPart.CFrame*CFrame.new(0,4,0))
	check("Locking the base raises the barrier",St.Lock(p) and St.Locked(G.BaseIndex(p)) and base.LockBarrier.CanCollide and base:GetAttribute("LockUntil")>os.time())
	check("A locked base cannot be locked again",not St.Lock(p))
	St.ResetLock(p);check("Reset lock drops the barrier",not base.LockBarrier.CanCollide and not St.Locked(G.BaseIndex(p)))
	freshPets();P.GrantEgg(p,{id="egg_meadow"});atIncubator();P.Place(p,eggUid(),1);local mine=D.Get(p,"Pets.incubator")["1"]
	check("Test thief takes our egg",St.SpawnBotThief(p) and mine.carriedBy==-1)
	local thief;for _,x in Collection:GetTagged("EggThief") do if x.Name=="EggThiefBot" then thief=x end end
	local frozen=mine.progress;task.wait(2.2);P.Advance(p,os.time(),true)
	check("A carried egg does not progress",mine.progress==frozen)
	at(base.PrimaryPart.CFrame*CFrame.new(200,4,0))
	check("Reclaim needs to be close",not St.Reclaim(p,thief))
	at(thief:GetPivot()*CFrame.new(3,0,0))
	check("Owner reclaim returns the egg",St.Reclaim(p,thief) and mine.carriedBy==nil and not thief.Parent)
	F.Set("Eggs",false);check("Eggs feature off disables actions and buffs",not P.Hatch(p) and P.Mult(p,"Power")==1 and not St.Try(p,1));F.Set("Eggs",true)
	check("Balance self-test still passes",B.SelfTest())
end,debug.traceback)
for _,m in temporary do m:Destroy() end
pcall(St.RemoveBot);for _,x in Collection:GetTagged("EggThief") do if x.Name=="EggThiefBot" then St.Return(x) end end
pcall(St.Return,p);pcall(N.Drop,p);St.ResetLock(p)
F.Set("Eggs",flags.Eggs);F.Set("Stealing",flags.Stealing);p:SetAttribute("ShieldOverride",nil)
if override then W.Force(override.id,math.max(1,override.endsAt-os.time())) else W.Force(nil) end
R.End(p,false);P.Dismount(p);root.Anchored=anchored;D.ImportJSON(p,original);p.Character:PivotTo(position);P.Refresh(p);P.Send(p);R.Send(p)
B.ClearOverrides();for key,value in balanceOverrides do B.SetOverride(key,value) end;p:SetAttribute("AdminCutPower",cutPower)
workspace:SetAttribute("Phase5TestResults",Http:JSONEncode({passed=ok,checks=results,error=not ok and err or nil}))
workspace:SetAttribute("Phase5TestStatus",ok and "passed" or "failed")
print("[Phase5Scenario]",ok and "passed" or err,#results)
