-- Wild nests (plan 4.7): grab an egg during a Run, outrun the guardian, then
-- reach the zone WarpStone or press End Run to secure it in Run.Eggs.
local Players=game:GetService("Players")
local Collection=game:GetService("CollectionService")
local Shared=game.ReplicatedStorage.Shared
local Net=require(Shared.Net)
local Eggs=require(Shared.Config.Eggs)
local Config=require(Shared.Config.Base)
local Visual=require(Shared.PetVisual)
local Data=require(script.Parent.DataService)
local Features=require(script.Parent.FeatureService)
local Pet=require(script.Parent.PetService)
local Nest={}
local spots,guardians,carriers={},{},{}
local rng=Random.new()

local function root(p)
	local c=p.Character;local h=c and c:FindFirstChildOfClass("Humanoid")
	return h and h.Health>0 and c:FindFirstChild("HumanoidRootPart")
end
local function flat(a,b) return Vector3.new(a.X-b.X,0,a.Z-b.Z).Magnitude end
local function notify(p,text,warn) Net.Event("Notify"):FireClient(p,{text=text,kind=warn and "warn" or nil}) end
local function show(s,on)
	s.ready=on;s.prompt.Enabled=on and Features.IsEnabled("Eggs")
	for _,part in s.visual:GetDescendants() do if part:IsA("BasePart") then part.Transparency=on and 0 or 1 end end
end
local function refill(s)
	s.generation+=1;local gen=s.generation
	task.delay(rng:NextInteger(Config.NestRefillMin,Config.NestRefillMax),function() if s.generation==gen and not s.retired and spots[s.spot]==s then show(s,true) end end)
end
local function release(p)
	local c=carriers[p];carriers[p]=nil
	if c then Pet.SetCarry(p,nil) end
	return c
end

function Nest.Take(p,spot)
	if not Features.IsEnabled("Eggs") or not Data.IsLoaded(p) then return false,"ระบบไข่ยังไม่เปิด" end
	local s=spots[spot]
	if not s or not s.ready then return false,"รังนี้ยังไม่มีไข่" end
	local weatherKey=spot:GetAttribute("WeatherKey")
	if weatherKey and (not Features.IsEnabled("WeatherEncounters") or require(script.Parent.WeatherService).State().eventKey~=weatherKey) then return false,"รอบอากาศนี้จบแล้ว" end
	if not Data.Get(p,"Run.Active") then return false,"หยิบไข่ในป่าได้ระหว่าง Run" end
	if not table.find(Data.Get(p,"Progress.UnlockedZones"),s.zone) then return false,"ยังไม่ปลดล็อกโซนนี้" end
	if carriers[p] or p:GetAttribute("CarryingEgg") then return false,"ถือไข่ได้ทีละ 1 ใบ" end
	if Pet.EggRoom(p)<=0 then return false,"ไข่เต็มกระเป๋า" end
	local hr=root(p);if not hr or (hr.Position-spot.Position).Magnitude>12 then return false,"เข้าใกล้รังก่อน" end
	show(s,false);s.generation+=1
	carriers[p]={spot=spot,def=s.def,zone=s.zone}
	local g=guardians[s.nest];if g then g.alarmUntil=os.clock()+Config.BurstSeconds end
	Pet.SetCarry(p,s.def.color,Config.NestSlow,nil)
	return true,"ได้ไข่! วิ่งไปหินวาร์ปหรือกด End Run — ผู้พิทักษ์ไล่ตามอยู่!"
end
-- Egg returns to its nest (caught, death, leaving, cancelled run).
function Nest.Drop(p,reason)
	local c=release(p);if not c then return false end
	local s=spots[c.spot];if s.retired then spots[c.spot]=nil;c.spot:Destroy() else show(s,true) end
	if reason and p.Parent then notify(p,reason,true) end
	return true
end
function Nest.Secure(p)
	local c=carriers[p];if not c or not Data.Get(p,"Run.Active") then return Nest.Drop(p) end
	release(p)
	local s=spots[c.spot];local eggs=Data.Get(p,"Run.Eggs") or {}
	table.insert(eggs,{id=c.def.id,rebirthDrop=Data.Get(p,"Progress.Rebirth"),admin_spawned=Data.Get(p,"Meta.AdminTouched")==true})
	Data.Set(p,"Run.Eggs",eggs);if s.retired then spots[c.spot]=nil;c.spot:Destroy() else refill(s) end
	notify(p,"ไข่ปลอดภัยแล้ว! ("..c.def.name..") ได้รับเมื่อจบ Run")
	return true
end
function Nest.Carrying(p) return carriers[p] end
function Nest.Spots() return spots end
function Nest.Guardian(nest) return guardians[nest] end
function Nest.AddSpot(spot,def)
	local nest=spot.Parent;if not guardians[nest] or spots[spot] then return false end
	local v=Visual.Egg(def.color,.85);v:PivotTo(spot.CFrame);v.Parent=spot
	local prompt=Instance.new("ProximityPrompt");prompt.Name="TakeEggPrompt";prompt.ActionText="หยิบไข่";prompt.ObjectText=def.thai;prompt.HoldDuration=.3;prompt.RequiresLineOfSight=false;prompt.MaxActivationDistance=10;prompt.Parent=spot
	local s={spot=spot,nest=nest,def=def,zone=nest:GetAttribute("Zone"),ready=true,visual=v,prompt=prompt,generation=0};spots[spot]=s;show(s,true)
	prompt.Triggered:Connect(function(p) local ok,msg=Nest.Take(p,spot);notify(p,msg,not ok) end);return true
end
function Nest.RemoveSpot(spot)
	local s=spots[spot];if not s then return end;s.retired=true;s.generation+=1;show(s,false)
	for _,c in carriers do if c.spot==spot then return end end
	spots[spot]=nil;spot:Destroy()
end

local function guardian(nest)
	local home=nest:GetPivot()*CFrame.new(9,0,0)
	local m=Visual.Pet("pet_boar",2.4);m.Name="NestGuardian"
	for _,part in m:GetDescendants() do if part:IsA("BasePart") and part.Name~="Eye" then part.Color=part.Name=="Tusk" and Color3.fromRGB(240,235,215) or Color3.fromRGB(86,112,62) end end
	local b=Instance.new("BillboardGui");b.Size=UDim2.fromOffset(140,26);b.StudsOffset=Vector3.new(0,5,0);b.MaxDistance=80;b.Parent=m.PrimaryPart
	local l=Instance.new("TextLabel");l.Size=UDim2.fromScale(1,1);l.BackgroundTransparency=1;l.TextColor3=Color3.fromRGB(255,220,120);l.TextStrokeTransparency=0;l.TextSize=14;l.Text="ผู้พิทักษ์รัง";l.Parent=b
	local lift=2.9
	local g={model=m,home=home.Position,pos=home.Position,lift=lift,alarmUntil=0,ground=nest.Parent.Parent:FindFirstChild("Ground")}
	m:PivotTo(CFrame.new(home.Position+Vector3.new(0,lift,0)));m.Parent=nest
	return g
end
local function groundY(g,at)
	if not g.ground then return g.home.Y end
	local params=RaycastParams.new();params.FilterType=Enum.RaycastFilterType.Include;params.FilterDescendantsInstances={g.ground}
	local hit=workspace:Raycast(at+Vector3.new(0,40,0),Vector3.new(0,-120,0),params)
	return hit and hit.Position.Y or g.pos.Y
end

function Nest.Init()
	for _,nest in Collection:GetTagged("Nest") do
		local def=nest:IsA("Model") and nest:IsDescendantOf(workspace) and Eggs.ByNest[nest:GetAttribute("EggType")]
		if def then
			for _,spot in nest:GetChildren() do if spot.Name=="EggSpot" and spot:IsA("BasePart") then
				spot.Transparency=1
				local v=Visual.Egg(def.color,.85);v:PivotTo(spot.CFrame);v.Parent=spot
				local prompt=Instance.new("ProximityPrompt");prompt.Name="TakeEggPrompt";prompt.ActionText="หยิบไข่";prompt.ObjectText=def.thai;prompt.HoldDuration=.3;prompt.RequiresLineOfSight=false;prompt.MaxActivationDistance=10;prompt.Parent=spot
				local s={spot=spot,nest=nest,def=def,zone=nest:GetAttribute("Zone"),ready=true,visual=v,prompt=prompt,generation=0}
				spots[spot]=s;show(s,true)
				prompt.Triggered:Connect(function(p) local ok,msg=Nest.Take(p,spot);notify(p,msg,not ok) end)
			end end
			guardians[nest]=guardian(nest)
		end
	end
	game.ReplicatedStorage.FeatureFlags:GetAttributeChangedSignal("Eggs"):Connect(function()
		for _,s in spots do s.prompt.Enabled=s.ready and Features.IsEnabled("Eggs") end
		if not Features.IsEnabled("Eggs") then for p in carriers do Nest.Drop(p) end end
	end)
	Players.PlayerRemoving:Connect(function(p) Nest.Drop(p) end)
end
function Nest.Start()
	local stones={};for _,w in Collection:GetTagged("WarpStone") do if w:IsDescendantOf(workspace) then table.insert(stones,w) end end
	task.spawn(function() while true do
		local dt=.1
		for p,c in carriers do
			local hr=root(p);local s=spots[c.spot]
			if not p.Parent or not hr or not Data.IsLoaded(p) or not Data.Get(p,"Run.Active") then Nest.Drop(p)
			else
				for _,w in stones do if w:GetAttribute("Zone")==s.zone and (hr.Position-w:GetPivot().Position).Magnitude<=Config.WarpSecureRange then Nest.Secure(p);break end end
			end
		end
		for nest,g in guardians do
			local target,chased=g.home,nil
			for p,c in carriers do local hr=root(p)
				if hr and spots[c.spot].nest==nest and flat(hr.Position,g.home)<=Config.GuardianLeash then target,chased=hr.Position,p end
			end
			local to=Vector3.new(target.X-g.pos.X,0,target.Z-g.pos.Z)
			if to.Magnitude>.5 then
				local speed=os.clock()<g.alarmUntil and Config.GuardianBurst or Config.GuardianSpeed
				local step=g.pos+to.Unit*math.min(to.Magnitude,speed*dt)
				g.pos=Vector3.new(step.X,groundY(g,step),step.Z)
				g.model:PivotTo(CFrame.lookAt(g.pos+Vector3.new(0,g.lift,0),g.pos+Vector3.new(0,g.lift,0)+to.Unit))
			end
			if chased then local hr=root(chased)
				if hr and flat(hr.Position,g.pos)<=Config.CatchRadius and math.abs(hr.Position.Y-g.pos.Y)<8 then Nest.Drop(chased,"ผู้พิทักษ์จับได้! ไข่กลับรังแล้ว") end
			end
		end
		task.wait(dt)
	end end)
end
return Nest
