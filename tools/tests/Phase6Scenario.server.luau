-- Inject in Studio Play as a temporary Script. Always restores the real profile.
assert(game:GetService("RunService"):IsStudio())
local Http=game:GetService("HttpService");local Collection=game:GetService("CollectionService")
local S=game.ReplicatedStorage.Shared;local Services=game.ServerScriptService.Server.Services
local D=require(Services.DataService);local Q=require(Services.QuestService);local St=require(Services.StoryService);local Bo=require(Services.BossService)
local R=require(Services.RunService);local W=require(Services.WeaponService);local G=require(Services.GardenService);local P=require(Services.PetService)
local Wx=require(Services.WeatherService);local F=require(Services.FeatureService)
local B=require(S.Balance);local Story=require(S.Config.Story);local Zones=require(S.Config.Zones);local Seeds=require(S.Config.Seeds)
local p=game.Players:GetPlayers()[1];assert(D.WaitForData(p,30))
local original=D.ExportJSON(p);script:SetAttribute("OriginalData",original)
local position=p.Character:GetPivot();local override=Wx.GetOverride();local cutPower=p:GetAttribute("AdminCutPower");local balanceOverrides=B.Overrides()
local flags={Story=F.IsEnabled("Story"),Eggs=F.IsEnabled("Eggs")};local results={}
workspace:SetAttribute("Phase6TestStatus","running")
local function check(name,ok) assert(ok,name);table.insert(results,{name=name,passed=true}) end
local function at(cf) p.Character:PivotTo(cf);task.wait(.15) end
local function tagged(tag,attr,value) for _,x in Collection:GetTagged(tag) do if x:IsDescendantOf(workspace) and x:GetAttribute(attr)==value then return x end end end
local function step() return D.Get(p,"Quests.main.step") end
local function gems() return D.GetCurrency(p,"Gems") end
local ok,err=xpcall(function()
	R.End(p,false);F.Set("Story",true);F.Set("Eggs",true);Wx.Force("Clear",3600);B.SetOverride("CritChance",0);p:SetAttribute("AdminCutPower",nil)
	Q.ResetStory(p);D.Set(p,"Progress.Rebirth",0);D.SetCurrency(p,"Coins",1e9);D.SetCurrency(p,"Wood",1e9);D.SetCurrency(p,"Gems",0)
	D.Set(p,"Inventory.Chests",{});D.Set(p,"Inventory.Eggs",{});D.Set(p,"Inventory.Pets",{});D.Set(p,"Inventory.Seeds",{});D.Set(p,"Garden",{slots=6,plots={},starterGiven=true,shopEpoch=0,bought={}})
	D.Set(p,"Index",{weapons={},pets={},seeds={},mutations={},done={}})
	for _,b in {1,2} do Bo.Reset(Bo.Get(b)) end
	local migrated=D.Migrate({DataVersion=1,Inventory={Weapons={keep={id="existing"}},Equipped="keep",Chests={}}})
	check("Reconcile adds quests, index, bosses and shrines",migrated.Inventory.Weapons.keep.id=="existing" and migrated.Quests.main.step==1 and migrated.Quests.daily.key==-1 and type(migrated.Index.done)=="table" and type(migrated.Progress.Bosses)=="table" and type(migrated.Progress.Shrines)=="table" and migrated.Stats.BossKills==0)
	check("Boss HP is tier 6 x200 and power gate matches tier 6",B.BossHP(1)==6e6 and B.BossHP(2,1)==6e6*100*10 and B.BossRequiredPower(1)==B.TreeRequiredPower(1,6))
	local valid=#Story.Chapters==8
	for i,c in Story.Chapters do if c.zone~=i or #c.steps==0 then valid=false end
		for _,s in c.steps do if not ({talk=true,stat=true,zone=true,boss=true,shrine=true})[s.kind] or (s.zone and not Zones.List[s.zone]) or (s.kind=="talk" and not Story.Npcs[s.npc]) then valid=false end end end
	check("Eight chapters with valid steps",valid)
	local boss1=Bo.Get(1)
	local allBuilt=true;for z=1,8 do if (Zones.List[z].built and not Bo.Get(z)) or (not Zones.List[z].built and Bo.Get(z)) then allBuilt=false end end
	check("Guardians exist exactly for built zones",boss1 and allBuilt and Collection:HasTag(boss1.model,"Boss") and boss1.model:GetAttribute("BossName")=="Old Oakheart")
	-- Chapter 1
	local bram=tagged("NPC","NpcId","Bram")
	at(bram:GetPivot()*CFrame.new(0,0,60))
	check("Talking far from Bram is rejected",not St.Talk(p,"Bram") and step()==1)
	at(bram:GetPivot()*CFrame.new(0,0,-6));local g=gems()
	check("Talking to Bram completes the first step once",St.Talk(p,"Bram") and step()==2 and gems()==g+Story.StepGems)
	D.Increment(p,"Stats.TreesCut",9);Q.Check(p);check("Tree step counts only since it began",step()==2)
	D.Increment(p,"Stats.TreesCut",1);Q.Check(p);check("Tenth tree completes the tree step",step()==3)
	local altar=workspace.Map.Village.ChestAltar;at(altar.PrimaryPart.CFrame+Vector3.new(0,6,0))
	W.GrantChest(p,"Common",1,1,1,false);W.Open(p,W.Chests(p)[1].uid);Q.Check(p)
	check("Opening a chest counts through WeaponService",D.Get(p,"Stats.ChestsOpened")>=1 and step()==4)
	local _,seed=G.GrantSeed(p,"seed_sunapple",1,0,1,false);at(G.Base(p).GardenSlots.Slot1.CFrame+Vector3.new(0,4,0))
	G.Plant(p,1,seed);Q.Check(p);check("Planting counts through GardenService",step()==5)
	P.GrantEgg(p,{id="egg_meadow"});local eggUid=next(D.Get(p,"Inventory.Eggs"));at(G.Base(p).Incubator:GetPivot()*CFrame.new(6,3,0))
	P.Place(p,eggUid,1);local egg=D.Get(p,"Pets.incubator")["1"];egg.progress=60;egg.done=true;P.Hatch(p);Q.Check(p)
	check("Hatching counts through PetService",step()==6)
	-- Boss
	local center=boss1.center
	check("Boss cannot be hit outside a Run",not Bo.Hit(p,1))
	R.Begin(p);at(CFrame.new(center+Vector3.new(-60,4,0)))
	local hit,reason=Bo.Hit(p,1);check("Boss hit out of range is rejected",not hit and reason=="Out of range")
	at(CFrame.new(center+Vector3.new(14,4,0)));p:SetAttribute("AdminCutPower",B.BossRequiredPower(1)*.5)
	hit,reason=Bo.Hit(p,1);check("Boss needs tier 6 power",not hit and reason=="Power too low")
	p:SetAttribute("AdminCutPower",2e6);task.wait(1.05)
	hit=Bo.Hit(p,1);check("Boss hit removes the right health share",hit and math.abs(boss1.model:GetAttribute("HealthRatio")-(1-2e6/6e6))<1e-9)
	check("Boss swing respects weapon cooldown",not Bo.Hit(p,1))
	g=gems();local kills=D.Get(p,"Stats.BossKills");local run=R.Get(p);local chests=#run.Chests
	p:SetAttribute("AdminCutPower",7e6);task.wait(1.05);local killed,why=Bo.Hit(p,1)
	check("Killing the boss marks it defeated ("..tostring(why).."; position="..tostring(p.Character:GetPivot().Position)..")",killed and boss1.model:GetAttribute("Alive")==false and D.Get(p,"Progress.Bosses")["1"]==1 and D.Get(p,"Stats.BossKills")==kills+1)
	check("First defeat grants Gems and an Epic run chest",gems()>=g+Story.BossGems and #run.Chests==chests+1 and run.Chests[#run.Chests].rarity=="Epic")
	check("Dead boss cannot be hit",not Bo.Hit(p,1))
	Q.Check(p);check("Boss step completes",step()==7)
	Bo.Reset(boss1);task.wait(1.05);Bo.Hit(p,1)
	check("Repeat defeat gives a Rare chest without first-kill Gems",D.Get(p,"Progress.Bosses")["1"]==2 and run.Chests[#run.Chests].rarity=="Rare")
	Bo.Reset(boss1);R.End(p,false);p:SetAttribute("AdminCutPower",nil)
	-- Shrine and chapter 2
	local shrine=tagged("Shrine","Zone",1)
	check("Lighting far from the shrine is rejected",not St.LightShrine(p,1))
	at(shrine:GetPivot()*CFrame.new(0,4,8))
	check("Shrine of an undefeated boss is rejected",not St.LightShrine(p,2))
	check("Mount stays locked in chapter 1",not P.Mount(p,select(2,P.GrantPet(p,"pet_wolf",{}))))
	g=gems()
	check("Lighting the shrine unlocks zone 2 and finishes chapter 1",St.LightShrine(p,1) and D.Get(p,"Progress.Shrines")["1"] and table.find(D.Get(p,"Progress.UnlockedZones"),2) and D.Get(p,"Progress.StoryChapter")==2 and step()==1)
	check("Chapter completion pays step and chapter Gems",gems()==g+Story.StepGems+Story.ChapterGems)
	check("A lit shrine cannot be lit twice",not St.LightShrine(p,1))
	local wolf;for uid,pet in D.Get(p,"Inventory.Pets") do if pet.id=="pet_wolf" then wolf=uid end end
	check("Mount unlocks in chapter 2",P.Mount(p,wolf));P.Dismount(p)
	at(bram:GetPivot()*CFrame.new(0,0,-6));St.Talk(p,"Bram");check("Chapter 2 opens with Bram",step()==2)
	local stone=workspace.Map.Village.Services.WarpStone
	check("Warp needs a warp stone",not St.Warp(p,2))
	at(stone:GetPivot()*CFrame.new(0,0,6))
	check("Locked or unbuilt zones cannot be warped to",not St.Warp(p,3) and not St.Warp(p,7))
	p:SetAttribute("CarryingEgg",true);check("Carrying an egg blocks warping",not St.Warp(p,2));p:SetAttribute("CarryingEgg",nil)
	-- TravelService (map systems): fast travel only to visited zones, 2 s cooldown after a warp.
	D.Set(p,"Progress.VisitedZones",{["2"]=true})
	check("Warping to an unlocked zone starts a Run there",St.Warp(p,2) and D.Get(p,"Run.Active") and (p.Character:GetPivot().Position-tagged("ZoneSpawn","Zone",2).Position).Magnitude<10)
	task.wait(.3);Q.Check(p);check("Standing in zone 2 completes the zone step",step()==3)
	local zone2Stone=tagged("WarpStone","Zone",2);at(zone2Stone:GetPivot()*CFrame.new(0,0,6));task.wait(2.1)
	check("Warping home ends the Run",St.Warp(p,0) and not D.Get(p,"Run.Active"))
	D.Set(p,"Progress.StoryChapter",3);D.Set(p,"Quests.main",{step=1,base=0})
	local s3=Q.Step(p);check("Chapter 3 zone step follows the zone build flag",s3.kind=="zone" and Q.Blocked(s3)==not Zones.List[3].built);Q.Check(p);check("Zone step does not advance away from the zone",step()==1)
	-- Daily / weekly
	local d1=Q.Side(p,"daily");local d2=Q.Side(p,"daily")
	local distinct=#d1.ids==3 and d1.ids[1]~=d1.ids[2] and d1.ids[2]~=d1.ids[3] and d1.ids[1]~=d1.ids[3]
	check("Daily quests are three distinct UTC-seeded picks",distinct and d1==d2)
	D.Set(p,"Quests.daily",{key=-1,ids={},base={},claimed={}});local again=Q.Side(p,"daily")
	check("Re-rolling the same day gives the same quests",table.concat(again.ids,",")==table.concat(d1.ids,","))
	local id=again.ids[1];local def;for _,q in Story.Daily do if q.id==id then def=q end end
	check("Unfinished daily cannot be claimed",not Q.Claim(p,"daily",id))
	D.Increment(p,"Stats."..def.stat,def.count);g=gems()
	check("Finished daily pays once",Q.Claim(p,"daily",id) and gems()==g+Story.DailyGems and not Q.Claim(p,"daily",id))
	D.Set(p,"Quests.weekly",{key=-1,ids={},base={},claimed={}});local weekly=Q.Side(p,"weekly");local wid=weekly.ids[1];local wdef;for _,q in Story.Daily do if q.id==wid then wdef=q end end
	D.Increment(p,"Stats."..wdef.stat,wdef.count*Story.WeeklyScale-1)
	check("Weekly needs six times the daily count",not Q.Claim(p,"weekly",wid))
	D.Increment(p,"Stats."..wdef.stat,1);check("Weekly claim pays weekly Gems",Q.Claim(p,"weekly",wid))
	check("Unknown quest kinds are rejected",not Q.Claim(p,"monthly",id) and not Q.Claim(p,"daily","nope"))
	-- Index
	D.Set(p,"Index",{weapons={},pets={},seeds={},mutations={},done={}});D.Set(p,"Inventory.Pets",{});D.Set(p,"Inventory.Weapons",{});D.Set(p,"Inventory.Seeds",{});D.Set(p,"Garden.plots",{})
	P.GrantPet(p,"pet_fox",{mutation="Golden"});P.GrantPet(p,"pet_bee",{admin=true});W.Grant(p,require(S.Config.WeaponCatalog).List[1].id,1,false)
	g=gems();local gained=Q.ScanIndex(p)
	check("Index records non-admin pets and pet mutations only",D.Get(p,"Index").pets.pet_fox and not D.Get(p,"Index").pets.pet_bee and D.Get(p,"Index").mutations.Golden and gained>=2)
	check("Admin-granted weapons do not count",not next(D.Get(p,"Index").weapons))
	check("Each new Index entry pays one Gem",gems()==g+gained*Story.IndexGem)
	check("Rescanning pays nothing",Q.ScanIndex(p)==0)
	for _,s in Seeds.List do G.GrantSeed(p,s.id,1,0,1,false) end;g=gems();Q.ScanIndex(p)
	check("Completing a category pays the completion bonus",D.Get(p,"Index").done.seeds and gems()==g+#Seeds.List*Story.IndexGem+Story.IndexCompleteGems)
	F.Set("Story",false);R.Begin(p);at(CFrame.new(center+Vector3.new(14,4,0)));p:SetAttribute("AdminCutPower",7e6);task.wait(1.05)
	check("Story feature off disables bosses and talking",not Bo.Hit(p,1) and not St.Talk(p,"Bram"));F.Set("Story",true);R.End(p,false)
	check("Balance self-test includes boss HP",B.SelfTest())
end,debug.traceback)
for _,b in {1,2} do pcall(function() Bo.Reset(Bo.Get(b)) end) end
F.Set("Story",flags.Story);F.Set("Eggs",flags.Eggs);P.Dismount(p);p:SetAttribute("CarryingEgg",nil)
if override then Wx.Force(override.id,math.max(1,override.endsAt-os.time())) else Wx.Force(nil) end
R.End(p,false);D.ImportJSON(p,original);p.Character:PivotTo(position);R.Send(p);Q.Send(p,true)
B.ClearOverrides();for key,value in balanceOverrides do B.SetOverride(key,value) end;p:SetAttribute("AdminCutPower",cutPower)
workspace:SetAttribute("Phase6TestResults",Http:JSONEncode({passed=ok,checks=results,error=not ok and err or nil}))
workspace:SetAttribute("Phase6TestStatus",ok and "passed" or "failed")
print("[Phase6Scenario]",ok and "passed" or err,#results)
