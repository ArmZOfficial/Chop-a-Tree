-- Zone guardians (plan 1, 14.4): giant Rot-bound trees chopped together like the
-- shared forest. Health is normalized so players of any Rebirth contribute fairly.
local Players=game:GetService("Players")
local Collection=game:GetService("CollectionService")
local Shared=game.ReplicatedStorage.Shared
local Net=require(Shared.Net)
local Balance=require(Shared.Balance)
local Zones=require(Shared.Config.Zones)
local Story=require(Shared.Config.Story)
local Forest=require(Shared.Config.Forest)
local Data=require(script.Parent.DataService)
local Features=require(script.Parent.FeatureService)
local Run=require(script.Parent.RunService)
local Weapon=require(script.Parent.WeaponService)
local Weather=require(script.Parent.WeatherService)
local Pet=require(script.Parent.PetService)
local Boss={}
local bosses,cooldowns={},{}
local rng=Random.new()

local function root(p)
	local c=p.Character;local h=c and c:FindFirstChildOfClass("Humanoid")
	return h and h.Health>0 and c:FindFirstChild("HumanoidRootPart")
end
local function flat(a,b) return Vector3.new(a.X-b.X,0,a.Z-b.Z).Magnitude end
local function notify(p,text) Net.Event("Notify"):FireClient(p,{text=text}) end

local function build(arena,zone)
	local def=Zones.List[zone];local floor=arena:GetPivot().Position+Vector3.new(0,.5,0)
	local m=Instance.new("Model");m.Name="Guardian_"..def.key
	local function part(name,size,cf,color,shape,material)
		local x=Instance.new("Part");x.Name=name;x.Size=size;x.CFrame=cf;x.Color=color;x.Anchored=true;x.Material=material or Enum.Material.Wood
		if shape then x.Shape=shape end;x.Parent=m;return x
	end
	local rot=Color3.fromRGB(120,60,170);local bark=Color3.fromRGB(78,52,44)
	local trunk=part("Trunk",Vector3.new(30,8,8),CFrame.new(floor+Vector3.new(0,15,0))*CFrame.Angles(0,0,math.rad(90)),bark,Enum.PartType.Cylinder)
	for i=1,5 do local a=i*math.pi*2/5
		part("Root",Vector3.new(3,3,9),CFrame.new(floor+Vector3.new(math.cos(a)*5,1.2,math.sin(a)*5),floor+Vector3.new(math.cos(a)*12,0,math.sin(a)*12)),bark)
	end
	local leaf=def.colors.leaves[1]
	for i,o in {Vector3.new(0,34,0),Vector3.new(7,30,3),Vector3.new(-6,31,-4),Vector3.new(2,29,-7)} do
		part("Canopy"..i,Vector3.new(16,16,16)-Vector3.new(i,i,i),CFrame.new(floor+o),leaf:Lerp(rot,.45),Enum.PartType.Ball,Enum.Material.Grass).CanCollide=false
	end
	for i=-1,1,2 do part("Eye",Vector3.new(1.4,1.4,1.4),CFrame.new(floor+Vector3.new(i*1.6,20,-4)),Color3.fromRGB(255,80,220),Enum.PartType.Ball,Enum.Material.Neon).CanCollide=false end
	local glow=Instance.new("PointLight");glow.Color=rot;glow.Range=40;glow.Brightness=3;glow.Parent=trunk
	m.PrimaryPart=trunk
	m:SetAttribute("Zone",zone);m:SetAttribute("BossName",def.boss);m:SetAttribute("Alive",true);m:SetAttribute("HealthRatio",1)
	m.Parent=arena;Collection:AddTag(m,"Boss")
	local parts={};for _,x in m:GetDescendants() do if x:IsA("BasePart") then parts[x]={x.Transparency,x.CanCollide} end end
	return {model=m,zone=zone,ratio=1,contributors={},cycle=0,parts=parts,center=floor}
end

function Boss.Get(zone) return bosses[zone] end
function Boss.Reset(b)
	b.ratio=1;b.contributors={};b.cycle+=1
	b.model:SetAttribute("Alive",true);b.model:SetAttribute("HealthRatio",1)
	for part,o in b.parts do part.Transparency=o[1];part.CanCollide=o[2] end
end
local function reward(p,zone,first)
	local defeated=Data.Get(p,"Progress.Bosses");local key=tostring(zone)
	defeated[key]=(defeated[key] or 0)+1;Data.Set(p,"Progress.Bosses",defeated)
	Data.Increment(p,"Stats.BossKills",1)
	Run.Award(p,zone,6,false,Balance.Get("BossRewardMult"))
	Run.CollectChest(p,nil,0,first and "Epic" or "Rare")
	if first then Data.AddCurrency(p,"Gems",Story.BossGems*zone) end
	notify(p,first and ("ล้ม "..Zones.List[zone].boss.." ครั้งแรก! +"..(Story.BossGems*zone).." Gems — ไปจุดศาลเจ้า") or ("ล้ม "..Zones.List[zone].boss.." แล้ว! ได้หีบ Rare"))
end
local function fell(b)
	b.model:SetAttribute("Alive",false);b.model:SetAttribute("HealthRatio",0)
	for part in b.parts do part.Transparency=1;part.CanCollide=false end
	local now=os.clock()
	for p,entry in b.contributors do
		if p.Parent and Data.IsLoaded(p) and entry.share>=Story.BossShare and now-entry.at<=Story.BossWindow and Run.Get(p)==entry.run and entry.run.Active then
			reward(p,b.zone,(Data.Get(p,"Progress.Bosses")[tostring(b.zone)] or 0)==0)
		end
	end
	Net.Event("BossEvent"):FireAllClients({kind="defeated",zone=b.zone,name=Zones.List[b.zone].boss})
	local cycle=b.cycle
	task.delay(Story.BossRespawn,function() if b.cycle==cycle then Boss.Reset(b) end end)
end

function Boss.Hit(p,zone)
	local b=bosses[zone];local r=Run.Get(p);local hr=root(p)
	if not Features.IsEnabled("Story") or not b or b.ratio<=0 or not r or not r.Active or not hr then return false,"Inactive" end
	if not Run.CanAccess(p,zone) or Run.ZoneAt(p)~=zone then return false,"Zone locked" end
	if flat(hr.Position,b.center)>Story.BossRange or math.abs(hr.Position.Y-b.center.Y)>20 then return false,"Out of range" end
	local rebirth=Data.Get(p,"Progress.Rebirth");local power=Run.Power(p);local health=Weather.Def().hp
	if power<Balance.BossRequiredPower(zone,rebirth)*health then return false,"Power too low" end
	local now=os.clock();if now<(cooldowns[p] or 0) then return false,"Cooldown" end
	cooldowns[p]=now+Forest.AttackInterval/Weapon.Combat(p).speed
	Pet.Dismount(p)
	local crit=rng:NextNumber()<Balance.Get("CritChance")
	local damage=power*(crit and Balance.Get("CritMult") or 1)
	local fraction=math.min(b.ratio,damage/(Balance.BossHP(zone,rebirth)*health))
	b.ratio=math.max(0,b.ratio-fraction)
	local entry=b.contributors[p]
	if not entry or entry.run~=r then entry={share=0,run=r};b.contributors[p]=entry end
	entry.share+=fraction;entry.at=now
	b.model:SetAttribute("HealthRatio",b.ratio)
	Data.Set(p,"Stats.HighestHit",math.max(Data.Get(p,"Stats.HighestHit"),damage))
	Net.Event("TreeHit"):FireAllClients({tree=b.model,position=b.center+Vector3.new(0,12,0),damage=damage,crit=crit,player=p.UserId,dead=b.ratio==0,tier=6})
	if b.ratio==0 then fell(b) end
	return true,damage
end
-- Admin/test helper: finish the boss with the given player as the only contributor.
function Boss.Kill(p,zone)
	local b=bosses[zone];if not b or b.ratio<=0 then return false end
	b.contributors={};local r=Run.Get(p)
	if p and r then b.contributors[p]={share=1,at=os.clock(),run=r} end
	b.ratio=0;fell(b);return true
end
function Boss.SetRatio(zone,ratio) local b=bosses[zone];if b and b.ratio>0 then b.ratio=ratio;b.model:SetAttribute("HealthRatio",ratio) end end

function Boss.Init()
	for _,arena in Collection:GetTagged("BossArena") do
		local zone=arena:GetAttribute("Zone")
		if arena:IsDescendantOf(workspace) and Zones.List[zone] and Zones.List[zone].built then bosses[zone]=build(arena,zone) end
	end
	Net.Event("ForestAction").OnServerEvent:Connect(function(p,action,model)
		if action=="Hit" and typeof(model)=="Instance" then
			for zone,b in bosses do if b.model==model then Boss.Hit(p,zone) end end
		end
	end)
	Players.PlayerRemoving:Connect(function(p) cooldowns[p]=nil;for _,b in bosses do b.contributors[p]=nil end end)
end
function Boss.Start()
	task.spawn(function() while true do
		if Features.IsEnabled("Story") then
			for _,p in Players:GetPlayers() do
				local modes=Run.GetModes(p);local zone=Run.ZoneAt(p);local b=zone and bosses[zone];local hr=root(p)
				if b and hr and b.ratio>0 and modes.AutoAttack and flat(hr.Position,b.center)<=Story.BossRange then Boss.Hit(p,zone) end
			end
		end
		task.wait(.2)
	end end)
end
return Boss
