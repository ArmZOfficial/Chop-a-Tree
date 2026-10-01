-- Temporary Studio Script, never part of the shipped game.
assert(game:GetService("RunService"):IsStudio())
local Http=game:GetService("HttpService")
local Collection=game:GetService("CollectionService")
local S=game.ReplicatedStorage.Shared
local L=require(S.Loot);local B=require(S.Balance);local Defs=require(S.Config.Weapons)
local D=require(game.ServerScriptService.Server.Services.DataService)
local W=require(game.ServerScriptService.Server.Services.WeaponService)
local R=require(game.ServerScriptService.Server.Services.RunService)
local T=require(game.ServerScriptService.Server.Services.TreeService)
local F=require(game.ServerScriptService.Server.Services.FeatureService)
local p=game.Players:GetPlayers()[1]
workspace:SetAttribute("Phase3TestStatus","running")
assert(D.WaitForData(p,30))
local original=D.ExportJSON(p);script:SetAttribute("OriginalData",original)
local pos=p.Character:GetPivot();local override=p:GetAttribute("AdminCutPower");local oldBalance=B.Overrides()
local results,temporary={},{}
local function check(name,condition) assert(condition,name);table.insert(results,{name=name,passed=true}) end
local function nearAltar() p.Character:PivotTo(workspace.Map.Village.ChestAltar.PrimaryPart.CFrame+Vector3.new(0,6,0));task.wait(.2) end
local function countWeapons() local n=0;for _ in D.Get(p,"Inventory.Weapons") do n+=1 end;return n end
local ok,err=xpcall(function()
	R.End(p,false);D.Set(p,"Inventory.Weapons",{});D.Set(p,"Inventory.Equipped","");D.Set(p,"Inventory.Chests",{})
	D.Set(p,"Progress.Rebirth",0);D.Set(p,"Progress.UnlockedZones",{1});p:SetAttribute("AdminCutPower",nil)
	check("100 weapon definitions with unique IDs",#Defs.List==100)
	local ids={};for _,def in Defs.List do assert(not ids[def.id] and Defs.ById[def.id]==def,"Invalid weapon registry");ids[def.id]=true end
	check("Registry IDs unique and indexed",true)
	local odds,g=L.Odds("Common",1)
	check("Common level 1 odds 70/25/5",math.abs(odds[1]-.7)<1e-9 and odds[2]==.25 and odds[3]==.05 and odds[4]==0 and odds[5]==0)
	check("Level raises rarity and Giant odds",L.Odds("Common",40)[1]<odds[1] and select(2,L.Odds("Common",40))>g)
	local random=Random.new(4217785);local buckets={Common=0,Rare=0,Epic=0};local giants=0
	for _=1,20000 do local item=L.Roll({rarity="Common",level=1,zone=1},random);buckets[Defs.ById[item.id].rarity]+=1;if item.giant then giants+=1 end end
	check("20K seeded rolls fit probabilities",math.abs(buckets.Common/20000-.7)<.02 and math.abs(buckets.Rare/20000-.25)<.02 and math.abs(buckets.Epic/20000-.05)<.01 and giants>40 and giants<170)
	local forced={NextNumber=function() return 0 end,NextInteger=function() return 1 end}
	local giant=L.Roll({rarity="Common",level=1,zone=3,rebirthDrop=2},forced)
	check("Giant, Item Level, Rot power",giant.giant and L.Power(giant)==Defs.List[1].basePower*10000*100*5)
	W.GrantChest(p,"Common",1,1,2,false);local chest=W.Chests(p)[1]
	check("Chest UID assigned",type(chest.uid)=="string")
	check("Open away from altar rejected",not W.Open(p,chest.uid))
	nearAltar();check("Altar access validated",W.AtAltar(p))
	local success,_,reward=W.Open(p,chest.uid)
	check("One chest creates one owned weapon",success and countWeapons()==1 and W.Chests(p)[1].count==1 and reward.item.il==1)
	check("First weapon auto equipped",D.Get(p,"Inventory.Equipped")==reward.uid and p.Character:FindFirstChild("ForestWeapon"))
	check("Unknown owned ID rejected",not W.Equip(p,"not-owned"))
	check("Remaining chest opens",W.Open(p,chest.uid))
	check("Duplicate exhausted chest rejected",#W.Chests(p)==0 and not W.Open(p,chest.uid) and countWeapons()==2)
	W.GrantChest(p,"Rare",30,2,1,true);local tagged=W.Chests(p)[1]
	local _,_,adminReward=W.Open(p,tagged.uid)
	check("Chest zone and admin provenance inherited",adminReward.item.il==2 and adminReward.item.admin_spawned)
	W.GrantChest(p,"Common",1,1,1,false);F.Set("Chests",false)
	check("Feature flag rejects opening without consuming",not W.Open(p,W.Chests(p)[1].uid) and W.Chests(p)[1].count==1)
	F.Set("Chests",true)
	D.Set(p,"Inventory.Weapons",{});D.Set(p,"Inventory.Equipped","");D.SetCurrency(p,"Wood",1000)
	local trio={};for i=1,3 do local _,uid=W.Grant(p,Defs.List[1].id,1,false);trio[i]=uid end
	W.Equip(p,trio[2]);local before=L.Power(W.Equipped(p))
	check("Duplicate Fuse input rejected",not W.Fuse(p,{trio[1],trio[1],trio[3]}) and countWeapons()==3)
	D.SetCurrency(p,"Wood",0);check("Insufficient Wood leaves items intact",not W.Fuse(p,trio) and countWeapons()==3)
	D.SetCurrency(p,"Wood",1000)
	check("Fuse succeeds",W.Fuse(p,trio))
	check("Fuse consumes 3 into 1, charges once, preserves equip",countWeapons()==1 and D.GetCurrency(p,"Wood")==900 and D.Get(p,"Inventory.Equipped")==trio[1] and W.Equipped(p).stars==2 and L.Power(W.Equipped(p))==before*1.5)
	check("Repeated Fuse cannot double consume",not W.Fuse(p,trio) and D.GetCurrency(p,"Wood")==900)
	local max={};for i=1,3 do local _,uid=W.Grant(p,Defs.List[1].id,5,false);max[i]=uid end
	check("Max stars rejected",not W.Fuse(p,max) and countWeapons()==4)
	local mismatch={};for i=1,3 do local _,uid=W.Grant(p,Defs.List[i].id,1,false);mismatch[i]=uid end
	check("Different definitions rejected",not W.Fuse(p,mismatch))
	local _,normalUid=W.Grant(p,Defs.List[1].id,1,false)
	local _,giantUid=W.Grant(p,Defs.List[1].id,1,true)
	W.Equip(p,normalUid);local normalHandle=p.Character.ForestWeapon.Handle.Size
	W.Equip(p,giantUid)
	check("Giant model x3 and combat area x2",p.Character.ForestWeapon.Handle.Size:FuzzyEq(normalHandle*3) and W.Combat(p).area==Defs.List[1].area*2)
	check("Equipped weapon drives Run Power",math.abs(R.Power(p)-L.Power(W.Equipped(p))*B.RunMultiplier(1))<1e-7)
	W.Equip(p,normalUid);R.Begin(p);B.SetOverride("CritChance",0)
	F.Set("Chests",false);task.wait(.1);check("Disabled weapons fall back to starter",p.Character:FindFirstChild("StarterAxe") and W.Combat(p).power==125);F.Set("Chests",true);task.wait(.1)
	local spawn=workspace.Map.Wilds.Zone1_SunnyMeadow.Spawn.ZoneSpawn
	local floor=Vector3.new(spawn.Position.X,4,spawn.Position.Z)
	p.Character:PivotTo(CFrame.new(floor+Vector3.new(0,4,0)))
	local function dummy(name,offset)
		local m=Instance.new("Model");m.Name=name
		local trunk=Instance.new("Part");trunk.Name="Trunk";trunk.Size=Vector3.new(1,5,1);trunk.Anchored=true;trunk.Position=floor+offset+Vector3.new(0,2.5,0);trunk.Parent=m;m.PrimaryPart=trunk
		m:SetAttribute("Zone",1);m:SetAttribute("Tier",1);m.Parent=workspace;Collection:AddTag(m,"Tree");table.insert(temporary,m);return m
	end
	local a=dummy("Phase3Primary",Vector3.new(8,0,0));local b=dummy("Phase3Area",Vector3.new(8,0,4));local c=dummy("Phase3GiantArea",Vector3.new(8,0,-8))
	task.wait(.2)
	check("Weapon hit accepted",T.Hit(p,a))
	check("Area damages adjacent tree, leaves far one",a:GetAttribute("HealthRatio")<1 and b:GetAttribute("HealthRatio")<1 and c:GetAttribute("HealthRatio")==1)
	check("Weapon speed cooldown enforced",not T.Hit(p,a));task.wait(.86)
	check("Weapon speed permits next swing",T.Hit(p,a))
	W.Equip(p,giantUid);task.wait(.86)
	check("Giant swing accepted",T.Hit(p,a))
	check("Giant doubled area reaches extra tree",c:GetAttribute("HealthRatio")<1)
	check("Deleting equipped weapon clears slot and restores starter",W.Delete(p,giantUid) and D.Get(p,"Inventory.Equipped")=="" and p.Character:FindFirstChild("StarterAxe"))
	check("Repeated delete rejected",not W.Delete(p,giantUid))
	R.End(p,false)
	D.Set(p,"Progress.Rebirth",2);R.Begin(p);R.CollectChest(p,nil,0)
	check("Run chest captures Rot at pickup",D.Get(p,"Run.Chests")[1].rebirthDrop==2)
	R.End(p,false);nearAltar()
	check("Balance formulas pass",B.SelfTest())
end,debug.traceback)
for _,m in temporary do m:Destroy() end
F.Set("Chests",true);B.ClearOverrides();for k,v in oldBalance do B.SetOverride(k,v) end
R.SetMode(p,"AutoCut",false);R.SetMode(p,"AutoAttack",false)
D.ImportJSON(p,original);p:SetAttribute("AdminCutPower",override);p.Character:PivotTo(pos);W.RefreshTool(p);R.Send(p)
workspace:SetAttribute("Phase3TestResults",Http:JSONEncode({passed=ok,checks=results,error=not ok and err or nil}))
workspace:SetAttribute("Phase3TestStatus",ok and "passed" or "failed")
print("[Phase3Scenario]",ok and "passed" or err,#results)
