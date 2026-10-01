-- Inject as a temporary Script in Play SERVER. Runs in the real game VM.
-- MCP execute_luau has a separate require cache; do not require DataService
-- directly there to infer live player data. Results are workspace attributes.
assert(game:GetService("RunService"):IsStudio(),"Studio test only")
local Http=game:GetService("HttpService")
local D=require(game.ServerScriptService.Server.Services.DataService)
local R=require(game.ServerScriptService.Server.Services.RunService)
local T=require(game.ServerScriptService.Server.Services.TreeService)
local B=require(game.ReplicatedStorage.Shared.Balance)
local p=game.Players:GetPlayers()[1]
workspace:SetAttribute("Phase2TestStatus","running")
assert(D.WaitForData(p,30),"Player data not ready")
local original=D.ExportJSON(p)
local Weather=require(game.ServerScriptService.Server.Services.WeatherService)
local oldWeather=Weather.GetOverride();Weather.Force("Clear",3600)
script:SetAttribute("OriginalData",original) -- server-only recovery if a test is interrupted
local savedPosition=p.Character:GetPivot()
local oldOverride=p:GetAttribute("AdminCutPower")
local results={}
local originals={get=R.Get,can=R.CanAccess,power=R.Power,award=R.Award,dataGet=D.Get,dataSet=D.Set}
local fakeChar
local function check(name,condition)
	assert(condition,name); table.insert(results,{name=name,passed=true})
end
local function near(model)
	local part=model.PrimaryPart
	local ground=part.Position-Vector3.new(0,part.Size.Y/2,0)
	p.Character:PivotTo(CFrame.new(ground+Vector3.new(9,4,0)))
	task.wait(0.2)
end
local ok,err=xpcall(function()
	D.Set(p,"Progress.Rebirth",0); D.Set(p,"Progress.UnlockedZones",{1,2})
	D.SetCurrency(p,"Wood",0); D.SetCurrency(p,"Coins",0); D.Set(p,"Inventory.Chests",{})
	R.End(p,false); R.Begin(p)
	local r=R.Get(p); R.Begin(p)
	check("Run begins once at level 1",R.Get(p)==r and r.Level==1)
	local tree
	for _,m in game:GetService("CollectionService"):GetTagged("Tree") do
		if m:GetAttribute("Zone")==1 and m:GetAttribute("Tier")==1 then tree=m; break end
	end
	assert(tree,"Need zone1 tier1 tree")
	T.Reset(tree); near(tree); p:SetAttribute("AdminCutPower",1000)
	B.SetOverride("CritChance",0)
	check("Manual hit kills tier1",T.Hit(p,tree))
	check("Manual full rewards",r.Wood==250 and r.Coins==100 and r.Exp==500)
	T.Reset(tree)
	local before=tree:GetAttribute("HealthRatio")
	check("Cooldown rejects repeated hits",not T.Hit(p,tree) and tree:GetAttribute("HealthRatio")==before)
	p.Character:PivotTo(savedPosition)
	check("Out-of-range hit rejected",not T.Hit(p,tree))
	check("Fake target rejected",not T.Hit(p,workspace.Map.Village))
	near(tree); task.wait(1.05)
	R.SetMode(p,"AutoCut",true)
	check("AutoCut hit",T.Hit(p,tree))
	R.SetMode(p,"AutoCut",false)
	check("AutoCut reward is 55 percent",r.Wood==387.5 and r.Coins==155 and r.Exp==775)
	T.Reset(tree); task.wait(1.05)
	p:SetAttribute("AdminCutPower",250); R.SetMode(p,"AutoCut",true)
	check("AutoCut partial hit",T.Hit(p,tree)); R.SetMode(p,"AutoCut",false)
	p:SetAttribute("AdminCutPower",1000); task.wait(1.05)
	check("Manual finishing hit after AutoCut",T.Hit(p,tree))
	check("Mode switching keeps AutoCut reduction",r.Wood==525 and r.Coins==210 and r.Exp==1050)
	for _=1,51 do R.CollectChest(p,nil,0) end
	local count=0; for _,c in r.Chests do count+=c.count end
	check("Chest cap 50 and stacked",count==50 and #r.Chests==1)
	R.End(p,false)
	local coins=D.GetCurrency(p,"Coins")
	check("End transfers rewards and chests",coins==210 and D.GetCurrency(p,"Wood")==525 and D.Get(p,"Inventory.Chests")[1].count==50)
	check("Duplicate End does not pay twice",not R.End(p,false) and D.GetCurrency(p,"Coins")==coins)
	-- Exercise both contributors against the actual TreeService lifecycle.
	fakeChar=Instance.new("Model"); fakeChar.Name="Phase2Contributor"
	local hr=Instance.new("Part"); hr.Name="HumanoidRootPart"; hr.Anchored=true; hr.CanCollide=false; hr.Size=Vector3.one; hr.Parent=fakeChar
	local hum=Instance.new("Humanoid"); hum.Parent=fakeChar; fakeChar.Parent=workspace
	local fake={Character=fakeChar,Parent=true,UserId=-999999}
	local fakeRun={Active=true}; local fakeAwards=0
	R.Get=function(who) if who==fake then return fakeRun end return originals.get(who) end
	R.CanAccess=function(who,z) if who==fake then return z==1 end return originals.can(who,z) end
	R.Power=function(who) if who==fake then return 250 end return originals.power(who) end
	D.Get=function(who,path) if who==fake then return 0 end return originals.dataGet(who,path) end
	D.Set=function(who,path,value) if who==fake then return end return originals.dataSet(who,path,value) end
	R.Award=function(who,z,t,a) if who==fake then fakeAwards+=1; return end return originals.award(who,z,t,a) end
	R.Begin(p); r=R.Get(p); T.Reset(tree); near(tree)
	hr.CFrame=p.Character.HumanoidRootPart.CFrame
	check("Contributor first hit",T.Hit(fake,tree))
	task.wait(1.05)
	check("Cooperative finishing hit",T.Hit(p,tree))
	check("Both contributors receive full reward",fakeAwards==1 and r.Wood==250 and r.Coins==100)
	T.Reset(tree); fakeAwards=0
	task.wait(1.05); check("Old contributor hit",T.Hit(fake,tree)); task.wait(10.2)
	check("Recent player finishes",T.Hit(p,tree))
	check("Contribution older than 10s expires",fakeAwards==0 and r.Trees==2)
	R.Get=originals.get; R.CanAccess=originals.can; R.Power=originals.power; R.Award=originals.award; D.Get=originals.dataGet; D.Set=originals.dataSet
	fakeChar:Destroy(); fakeChar=nil
	task.wait(15.3)
	check("Tree respawns after 15 seconds",tree:GetAttribute("Alive")==true and tree:GetAttribute("HealthRatio")==1 and tree.PrimaryPart.CanCollide)
	R.End(p,false); R.Begin(p); r=R.Get(p)
	local spawn=workspace.Map.Wilds.Zone1_SunnyMeadow.Spawn.ZoneSpawn
	p.Character:PivotTo(spawn.CFrame+Vector3.new(0,4,0)); task.wait(0.3)
	local start=p.Character.HumanoidRootPart.Position
	R.SetMode(p,"AutoCut",true)
	local deadline=os.clock()+45
	repeat task.wait(0.2) until r.Trees>0 or os.clock()>deadline
	R.SetMode(p,"AutoCut",false)
	local moved=(p.Character.HumanoidRootPart.Position-start).Magnitude
	check("AutoCut pathfinding finds and cuts a tree (trees="..r.Trees..", moved="..math.floor(moved)..")",r.Trees>0 and moved>3)
	check("Balance formulas still pass",B.SelfTest())
end,debug.traceback)
R.Get=originals.get; R.CanAccess=originals.can; R.Power=originals.power; R.Award=originals.award; D.Get=originals.dataGet; D.Set=originals.dataSet
if fakeChar then fakeChar:Destroy() end
R.SetMode(p,"AutoCut",false); R.SetMode(p,"AutoAttack",false)
B.ClearOverrides()
D.ImportJSON(p,original)
p:SetAttribute("AdminCutPower",oldOverride)
p.Character:PivotTo(savedPosition)
R.Send(p)
if oldWeather then Weather.Force(oldWeather.id,math.max(1,oldWeather.endsAt-os.time())) else Weather.Force(nil) end
workspace:SetAttribute("Phase2TestResults",Http:JSONEncode({passed=ok,checks=results,error=not ok and err or nil}))
workspace:SetAttribute("Phase2TestStatus",ok and "passed" or "failed")
print("[Phase2Scenario]",ok and "passed" or err,#results)
