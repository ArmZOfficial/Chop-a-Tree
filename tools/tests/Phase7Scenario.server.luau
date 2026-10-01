-- Inject in Studio Play as a temporary Script. Always restores the real profile.
assert(game:GetService("RunService"):IsStudio())
local Http=game:GetService("HttpService");local Collection=game:GetService("CollectionService")
local S=game.ReplicatedStorage.Shared;local Services=game.ServerScriptService.Server.Services
local D=require(Services.DataService);local R=require(Services.RunService);local T=require(Services.TreeService)
local Bo=require(Services.BossService);local St=require(Services.StoryService);local Q=require(Services.QuestService)
local N=require(Services.NestService);local Wx=require(Services.WeatherService);local F=require(Services.FeatureService)
local B=require(S.Balance);local Zones=require(S.Config.Zones);local Eggs=require(S.Config.Eggs);local Pets=require(S.Config.Pets)
local Ambience=require(game.StarterPlayer.StarterPlayerScripts.Client.ZoneAmbience)
local p=game.Players:GetPlayers()[1];assert(D.WaitForData(p,30))
local original=D.ExportJSON(p);script:SetAttribute("OriginalData",original)
local position=p.Character:GetPivot();local override=Wx.GetOverride();local cutPower=p:GetAttribute("AdminCutPower");local balanceOverrides=B.Overrides()
local results={}
workspace:SetAttribute("Phase7TestStatus","running")
local function check(name,ok) assert(ok,name);table.insert(results,{name=name,passed=true}) end
local function at(cf) pcall(p.RequestStreamAroundAsync,p,cf.Position,5);p.Character:PivotTo(cf);task.wait(.2) end
local function tagged(tag,attr,value) for _,x in Collection:GetTagged(tag) do if x:IsDescendantOf(workspace) and x:GetAttribute(attr)==value then return x end end end
local ok,err=xpcall(function()
	R.End(p,false);F.Set("Story",true);F.Set("Eggs",true);Wx.Force("Clear",3600);B.SetOverride("CritChance",0)
	D.Set(p,"Progress.Rebirth",0);D.Set(p,"Inventory.Pets",{});D.Set(p,"Inventory.Eggs",{});D.Set(p,"Inventory.Equipped","")
	local allBuilt=true;for _,z in Zones.List do if not z.built then allBuilt=false end end
	check("All eight zones are marked built",allBuilt)
	local perZone,assetTrees,badTrunk={}, 0,0
	for _,m in Collection:GetTagged("Tree") do if m:IsDescendantOf(workspace) then
		local z=m:GetAttribute("Zone");perZone[z]=(perZone[z] or 0)+1
		if z>=3 then
			if m:FindFirstChild("Look") then assetTrees+=1 end
			if not m.PrimaryPart or m.PrimaryPart.Name~="Trunk" or m.PrimaryPart.Transparency~=1 or not m.PrimaryPart.CanCollide then badTrunk+=1 end
		end
	end end
	local counts=true;for z=1,8 do if perZone[z]~=160 then counts=false end end
	check("Every zone has 160 choppable trees",counts)
	check("Zone 3-8 trees use asset visuals over an invisible collider trunk",assetTrees==960 and badTrunk==0)
	local scripts=0;for _,d in workspace.Map:GetDescendants() do if d:IsA("LuaSourceContainer") then scripts+=1 end end
	check("The built map contains no scripts from Creator Store assets",scripts==0)
	local protoOk=true;local protoCount=0
	for _,folder in game.ServerStorage.MapAssets.Trees:GetChildren() do for _,m in folder:GetChildren() do protoCount+=1
		if not m:GetAttribute("AssetId") or not m:GetAttribute("Height") then protoOk=false end
		for _,d in m:GetDescendants() do if d:IsA("LuaSourceContainer") then protoOk=false end end
	end end
	check("Vetted prototypes are script-free and record their asset IDs",protoOk and protoCount==8)
	local nestsOk,nestCount=true,0
	for _,nest in Collection:GetTagged("Nest") do if nest:IsDescendantOf(workspace) then nestCount+=1
		local def=Eggs.ByNest[nest:GetAttribute("EggType")];if not def or def.zone~=nest:GetAttribute("Zone") then nestsOk=false end
	end end
	check("All 16 nests map to their zone egg",nestsOk and nestCount==16)
	local spots=0;for _ in N.Spots() do spots+=1 end;check("Every nest exposes three egg spots",spots==48)
	local petsOk=true;for _,e in Eggs.List do for _,row in e.pets do local pet=Pets.ById[row[1]];if not pet or (e.nestType and pet.zone~=e.zone) then petsOk=false end end end
	check("Zone eggs hatch only that zone's pets",petsOk and #Pets.List==43)
	local bossesOk=true;for z=1,8 do if not Bo.Get(z) then bossesOk=false end end
	local lumora=Collection:GetTagged("Lumora")[1]
	check("Guardians exist for all eight zones",bossesOk)
	check("Sky Isles guardian stands beside the Lumora trunk",(Bo.Get(8).center-Vector3.new(lumora:GetPivot().Position.X,Bo.Get(8).center.Y,lumora:GetPivot().Position.Z)).Magnitude>=20)
	local same=true;for z=1,8 do local sp=tagged("ZoneSpawn","Zone",z);if Ambience.ZoneAt(sp.Position+Vector3.new(0,3,0))~=z then same=false end end
	check("Client ambience detects the same zone as the server at every spawn",same)
	-- Zone 3 gameplay
	D.Set(p,"Progress.UnlockedZones",{1,2});local tree
	for _,m in Collection:GetTagged("Tree") do if m:GetAttribute("Zone")==3 and m:GetAttribute("Tier")==1 then tree=m;break end end
	local function near(model) local part=model.PrimaryPart;at(CFrame.new(part.Position-Vector3.new(0,part.Size.Y/2,0)+Vector3.new(6,4,0))) end
	R.Begin(p);near(tree);T.Reset(tree);p:SetAttribute("AdminCutPower",1e12)
	local hit,reason=T.Hit(p,tree);check("Locked zone 3 trees cannot be chopped",not hit and reason=="Zone locked")
	R.End(p,false);D.Set(p,"Progress.UnlockedZones",{1,2,3});R.Begin(p);near(tree);T.Reset(tree);task.wait(1.05)
	local run=R.Get(p);hit=T.Hit(p,tree)
	check("Unlocked zone 3 tree falls and pays zone 3 rewards",hit and tree:GetAttribute("Alive")==false and math.abs(run.Wood-B.TreeReward(3,1,0,false).wood)<1e-6)
	check("Asset tree hides fully when felled",(function() for _,d in tree:GetDescendants() do if d:IsA("BasePart") and d.Transparency<1 then return false end end return true end)())
	T.Reset(tree);check("Asset tree reappears on respawn",tree.PrimaryPart.Transparency==1 and tree.Look:FindFirstChildWhichIsA("BasePart").Transparency<1)
	-- Zone 3 boss and shrine unlock zone 4
	local b3=Bo.Get(3);at(CFrame.new(b3.center+Vector3.new(-14,4,0)));p:SetAttribute("AdminCutPower",B.BossRequiredPower(3)*.5);task.wait(1.05)
	hit,reason=Bo.Hit(p,3);check("Zone 3 guardian needs zone 3 tier 6 power",not hit and reason=="Power too low")
	p:SetAttribute("AdminCutPower",B.BossHP(3)*2);task.wait(1.05);local killed,why=Bo.Hit(p,3)
	check("Zone 3 guardian can be defeated ("..tostring(why)..")",killed and D.Get(p,"Progress.Bosses")["3"]==1);Bo.Reset(b3);R.End(p,false)
	at(tagged("Shrine","Zone",3):GetPivot()*CFrame.new(0,4,8))
	check("Zone 3 shrine unlocks zone 4",St.LightShrine(p,3) and table.find(D.Get(p,"Progress.UnlockedZones"),4)~=nil)
	-- Chapter 3 zone step and warping to zone 4
	D.Set(p,"Progress.StoryChapter",3);D.Set(p,"Quests.main",{step=1,base=0})
	check("Chapter 3 steps are no longer blocked",not Q.Blocked(Q.Step(p)))
	at(workspace.Map.Village.Services.WarpStone:GetPivot()*CFrame.new(0,0,6))
	check("Warp to zone 4 starts a Run there",St.Warp(p,4) and D.Get(p,"Run.Active") and R.ZoneAt(p)==4)
	at(tagged("WarpStone","Zone",4):GetPivot()*CFrame.new(0,0,6));St.Warp(p,3);task.wait(.3);Q.Check(p)
	check("Standing in zone 3 completes the chapter 3 zone step",D.Get(p,"Quests.main.step")==2)
	-- Zone 6 nest egg
	D.Set(p,"Progress.UnlockedZones",{1,2,3,4,5,6});R.End(p,false);R.Begin(p)
	local spot;for sp,s in N.Spots() do if s.zone==6 and s.ready then spot=sp;break end end
	at(spot.CFrame*CFrame.new(3,3,0))
	check("Zone 6 nest gives a Frost Egg once secured",N.Take(p,spot) and N.Secure(p) and D.Get(p,"Run.Eggs")[1].id=="egg_frost")
	R.End(p,false)
	check("Balance self-test still passes",B.SelfTest())
end,debug.traceback)
for z=1,8 do pcall(function() Bo.Reset(Bo.Get(z)) end) end
if override then Wx.Force(override.id,math.max(1,override.endsAt-os.time())) else Wx.Force(nil) end
R.End(p,false);D.ImportJSON(p,original);p.Character:PivotTo(position);R.Send(p);Q.Send(p,true)
B.ClearOverrides();for key,value in balanceOverrides do B.SetOverride(key,value) end;p:SetAttribute("AdminCutPower",cutPower)
workspace:SetAttribute("Phase7TestResults",Http:JSONEncode({passed=ok,checks=results,error=not ok and err or nil}))
workspace:SetAttribute("Phase7TestStatus",ok and "passed" or "failed")
print("[Phase7Scenario]",ok and "passed" or err,#results)
