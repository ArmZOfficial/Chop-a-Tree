-- Egg stealing between bases, base locks, shields and admin test bots (plan 4.7).
-- A stolen egg stays in the victim's profile (carriedBy) until delivery, so a
-- cancelled or interrupted steal never removes it.
local Players=game:GetService("Players")
local Collection=game:GetService("CollectionService")
local Physics=game:GetService("PhysicsService")
local Shared=game.ReplicatedStorage.Shared
local Net=require(Shared.Net)
local Eggs=require(Shared.Config.Eggs)
local Config=require(Shared.Config.Base)
local Math=require(Shared.PetMath)
local Visual=require(Shared.PetVisual)
local Data=require(script.Parent.DataService)
local Features=require(script.Parent.FeatureService)
local Garden=require(script.Parent.GardenService)
local Pet=require(script.Parent.PetService)
local Steal={}
local carrying,locks,afk,cooldowns,friendCache,lastAction={},{},{},{},{},{}
local bot -- {base=id, incubator={}}

local function root(p)
	local c=p.Character;local h=c and c:FindFirstChildOfClass("Humanoid")
	return h and h.Health>0 and c:FindFirstChild("HumanoidRootPart")
end
local function notify(p,text,warn) if typeof(p)=="Instance" and p:IsA("Player") and p.Parent then Net.Event("Notify"):FireClient(p,{text=text,kind=warn and "warn" or nil}) end end
local function flat(a,b) return Vector3.new(a.X-b.X,0,a.Z-b.Z).Magnitude end
local function incubatorOf(id)
	local v=Garden.OwnerOf(id)
	if v and Data.IsLoaded(v) then return Data.Get(v,"Pets.incubator"),v end
	if bot and bot.base==id then return bot.incubator,"bot" end
end
local function commit(victim) if victim~="bot" and Data.IsLoaded(victim) then Data.Set(victim,"Pets",Data.Get(victim,"Pets")) end end
local function sign(base,text) for _,l in base.OwnerSign:GetDescendants() do if l:IsA("TextLabel") then l.Text=text end end end
local function friends(a,b)
	local key=math.min(a.UserId,b.UserId)..":"..math.max(a.UserId,b.UserId)
	if friendCache[key]==nil then local ok,result=pcall(a.IsFriendsWithAsync,a,b.UserId);friendCache[key]=ok and result==true end
	return friendCache[key]
end

function Steal.Locked(id) local l=locks[id];return l~=nil and os.time()<l.untilAt end
function Steal.MarkActive(p) afk[p]=nil end
function Steal.Presence(p,idle)
	if type(idle)~="number" or idle~=idle then return end
	afk[p]=idle>=60 and os.time()-math.clamp(idle,0,86400) or nil
end
function Steal.Shield(p)
	local o=p:GetAttribute("ShieldOverride")
	if o=="off" then return nil elseif o=="on" then return "admin" end
	if (Data.Get(p,"Stats.PlaySeconds") or 0)<Config.NewPlayerShield then return "new" end
	if afk[p] and os.time()-afk[p]>=Config.AfkShield then return "afk" end
	return nil
end

local function clear(thief)
	local entry=carrying[thief];if not entry then return end
	carrying[thief]=nil
	if entry.bot then thief:Destroy();return end
	local hr=thief.Character and thief.Character:FindFirstChild("HumanoidRootPart")
	local prompt=hr and hr:FindFirstChild("ReclaimPrompt");if prompt then prompt:Destroy() end
	if thief.Character then Collection:RemoveTag(thief.Character,"EggThief") end
	Pet.SetCarry(thief,nil)
end
-- Return the egg to its incubator (owner reclaim, cancel, or test bot).
function Steal.Return(thief,reason)
	local entry=carrying[thief];if not entry then return false end
	local inc=incubatorOf(entry.base)
	if inc and inc[entry.key]==entry.egg then entry.egg.carriedBy=nil;entry.egg.updatedAt=os.time();commit(entry.victim) end
	clear(thief)
	if reason=="reclaim" then notify(entry.victim,"ทวงไข่คืนแล้ว!");notify(thief,"เจ้าของฐานทวงไข่คืนไปแล้ว",true)
	elseif reason then notify(entry.victim,reason);notify(thief,reason,true) end
	return true
end
local function deliver(thief)
	local entry=carrying[thief]
	local inc=incubatorOf(entry.base)
	if not inc or inc[entry.key]~=entry.egg then clear(thief);return end
	local egg=entry.egg
	-- No yields between removing from the victim and crediting the thief.
	inc[entry.key]=nil;commit(entry.victim)
	local ok=Pet.GrantEgg(thief,{id=egg.id,rebirthDrop=egg.rebirthDrop,admin_spawned=egg.admin_spawned,progress=egg.progress,stolen=true})
	if not ok then egg.carriedBy=nil;inc[entry.key]=egg;commit(entry.victim);clear(thief);notify(thief,"ไข่เต็มกระเป๋า — คืนไข่แล้ว",true);return end
	local bonus=math.floor(Math.EggPrice(egg.id)*Config.StealBonus)
	Data.AddCurrency(thief,"Coins",bonus);Data.Increment(thief,"Stats.EggsStolen",1)
	clear(thief)
	notify(thief,"ขโมยสำเร็จ! ได้ "..Eggs.ById[egg.id].name.." +"..bonus.." Coins")
	notify(entry.victim,thief.DisplayName.." ขโมยไข่ของคุณสำเร็จ — ล็อกฐานกันไว้นะ",true)
end

function Steal.Try(thief,id)
	if not Features.IsEnabled("Eggs") or not Features.IsEnabled("Stealing") or not Data.IsLoaded(thief) then return false,"ระบบขโมยไข่ยังไม่เปิด" end
	Steal.MarkActive(thief)
	local owner=Garden.OwnerOf(id)
	if owner==thief then return false,"นี่คือฐานของคุณ" end
	-- The friend lookup can yield; everything below re-reads live state.
	if owner and Data.IsLoaded(owner) and not Data.Get(owner,"Settings.FriendSteal") and friends(thief,owner) then return false,"เพื่อนกันขโมยไข่ไม่ได้" end
	local inc,victim=incubatorOf(id)
	if not inc then return false,"ฐานนี้ไม่มีเจ้าของ" end
	if not Garden.Base(thief) then return false,"ต้องมีฐานของตัวเองก่อน" end
	if carrying[thief] or thief:GetAttribute("CarryingEgg") then return false,"ถือไข่ได้ทีละ 1 ใบ" end
	if Data.Get(thief,"Run.Active") then return false,"จบ Run ก่อนขโมยไข่" end
	if Pet.EggRoom(thief)<=0 then return false,"ไข่เต็มกระเป๋า" end
	local hr=root(thief);local base=Garden.BaseById(id)
	if not hr or (hr.Position-base.Incubator:GetPivot().Position).Magnitude>Config.IncubatorRange+2 then return false,"เข้าใกล้ตู้ฟักก่อน" end
	if Steal.Locked(id) then return false,"ฐานนี้ล็อกอยู่" end
	if victim~="bot" and Steal.Shield(victim) then return false,"ฐานนี้มีโล่ป้องกัน" end
	local cd=cooldowns[thief] and cooldowns[thief][id]
	if cd and os.time()<cd then return false,"รออีก "..(cd-os.time()).." วิ ก่อนขโมยฐานนี้อีกครั้ง" end
	local keys={};for k in inc do table.insert(keys,k) end;table.sort(keys)
	local key;for _,k in keys do if Math.Stealable(inc[k]) then key=k;break end end
	if not key then return false,"ไม่มีไข่ที่ขโมยได้ (ว่าง ฟักเกิน 75% หรือป้องกันไว้)" end
	local egg=inc[key];egg.carriedBy=thief.UserId;commit(victim)
	carrying[thief]={base=id,victim=victim,key=key,egg=egg}
	cooldowns[thief]=cooldowns[thief] or {};cooldowns[thief][id]=os.time()+Config.ThiefCooldown
	Pet.SetCarry(thief,Eggs.ById[egg.id].color,Config.StealSlow,victim=="bot" and -1 or victim.UserId)
	Collection:AddTag(thief.Character,"EggThief")
	local prompt=Instance.new("ProximityPrompt");prompt.Name="ReclaimPrompt";prompt.ActionText="ทวงไข่คืน";prompt.ObjectText="EGG THIEF";prompt.HoldDuration=0;prompt.RequiresLineOfSight=false;prompt.MaxActivationDistance=Config.ReclaimRange;prompt.Parent=hr
	prompt.Triggered:Connect(function(by) Steal.Reclaim(by,thief) end)
	notify(victim,thief.DisplayName.." ขโมยไข่จากตู้ฟักของคุณ! ตามไปกด E เพื่อทวงคืน",true)
	return true,"ขโมยไข่แล้ว! วิ่งกลับฐานตัวเอง (เดินช้าลง 25%)"
end
function Steal.Reclaim(by,thief)
	local entry=carrying[thief]
	if not entry or entry.victim~=by then return false,"ทวงคืนได้เฉพาะเจ้าของไข่" end
	local hr=root(by);local target=entry.bot and thief.PrimaryPart or (thief.Character and thief.Character:FindFirstChild("HumanoidRootPart"))
	if not hr or not target or (hr.Position-target.Position).Magnitude>Config.ReclaimRange+2 then return false,"เข้าใกล้คนขโมยก่อน" end
	Steal.MarkActive(by);return Steal.Return(thief,"reclaim")
end
function Steal.Carrying(thief) return carrying[thief] end

local function eject(id,owner)
	local barrier=Garden.BaseById(id).LockBarrier
	for _,p in Players:GetPlayers() do
		local hr=p~=owner and root(p)
		if hr then
			local l=barrier.CFrame:PointToObjectSpace(hr.Position);local half=barrier.Size/2
			if math.abs(l.X)<half.X+3 and math.abs(l.Z)<half.Z+3 and math.abs(l.Y)<half.Y+3 then
				local dir=Vector3.new(l.X,0,l.Z);dir=dir.Magnitude>.1 and dir.Unit or Vector3.xAxis
				p.Character:PivotTo(CFrame.new(barrier.CFrame:PointToWorldSpace(dir*(half.X+8))-Vector3.new(0,half.Y-4,0)))
			end
		end
	end
end
local function barrier(id,on)
	local base=Garden.BaseById(id);local wall=base and base:FindFirstChild("LockBarrier");if not wall then return end
	wall.CanCollide=on;wall.Transparency=on and .65 or 1
	local l=locks[id];base:SetAttribute("LockUntil",l and l.untilAt or 0);base:SetAttribute("LockReadyAt",l and l.ready or 0)
end
function Steal.Lock(p)
	if not Features.IsEnabled("Eggs") or not Data.IsLoaded(p) or not Garden.NearBase(p) then return false,"ล็อกฐานที่ฐานตัวเอง" end
	Steal.MarkActive(p)
	local id=Garden.BaseIndex(p);local l=locks[id];local now=os.time()
	if l and now<l.untilAt then return false,"ฐานล็อกอยู่แล้ว" end
	if l and now<l.ready then return false,"คูลดาวน์อีก "..(l.ready-now).." วิ" end
	local seconds=Math.LockSeconds(Data.Get(p,"Pets.upgrades").lock)
	locks[id]={untilAt=now+seconds,ready=now+seconds+Config.LockCooldown,owner=p}
	barrier(id,true);eject(id,p)
	return true,"ล็อกฐาน "..seconds.." วินาที"
end
function Steal.ResetLock(p) local id=Garden.BaseIndex(p);cooldowns[p]=nil;if id then locks[id]=nil;barrier(id,false) end end

function Steal.CreateBot()
	if bot then return true,bot.base end
	for id=1,7 do local b=Garden.BaseById(id)
		if b and b:GetAttribute("OwnerUserId")==0 then
			b:SetAttribute("OwnerUserId",-1);bot={base=id,incubator={}}
			for i=1,3 do bot.incubator[tostring(i)]={id="egg_meadow",zone=1,rebirthDrop=0,admin_spawned=true,progress=i==3 and 50 or 0,updatedAt=os.time()} end
			sign(b,"ฐานบอททดสอบ");return true,id
		end
	end
	return false
end
function Steal.RemoveBot()
	if not bot then return false end
	for thief,entry in carrying do if entry.base==bot.base then clear(thief) end end
	local b=Garden.BaseById(bot.base);b:SetAttribute("OwnerUserId",0);sign(b,"ฐาน "..bot.base.." · ว่าง");locks[bot.base]=nil;barrier(bot.base,false);bot=nil;return true
end
function Steal.Bot() return bot end
-- Admin test: an NPC carries one of the owner's eggs toward the village; reclaim it with E.
function Steal.SpawnBotThief(owner)
	local id=Garden.BaseIndex(owner);if not id or not Data.IsLoaded(owner) then return false,"ต้องมีฐานก่อน" end
	local inc=Data.Get(owner,"Pets.incubator");local keys={};for k in inc do table.insert(keys,k) end;table.sort(keys)
	local key;for _,k in keys do if Math.Stealable(inc[k]) then key=k;break end end
	if not key then return false,"ไม่มีไข่ที่ขโมยได้ในตู้ฟัก" end
	local base=Garden.BaseById(id);local start=base.Incubator:GetPivot().Position
	local m=Instance.new("Model");m.Name="EggThiefBot"
	local body=Instance.new("Part");body.Name="Body";body.Size=Vector3.new(2,3,1.2);body.Color=Color3.fromRGB(60,40,90);body.Anchored=true;body.CanCollide=false;body.Parent=m
	local head=Instance.new("Part");head.Name="Head";head.Shape=Enum.PartType.Ball;head.Size=Vector3.new(1.6,1.6,1.6);head.Color=Color3.fromRGB(240,200,160);head.Anchored=true;head.CanCollide=false;head.CFrame=CFrame.new(0,2.3,0);head.Parent=m
	m.PrimaryPart=body
	local egg=Visual.Egg(Eggs.ById[inc[key].id].color,1);egg:PivotTo(CFrame.new(0,4.4,0));egg.Parent=m
	m:PivotTo(CFrame.new(start+Vector3.new(4,1.5,0)));m:SetAttribute("StealingFrom",owner.UserId);m.Parent=workspace
	Collection:AddTag(m,"EggThief")
	inc[key].carriedBy=-1;commit(owner)
	local spawn=workspace.Map.Village:FindFirstChild("VillageSpawn")
	carrying[m]={base=id,victim=owner,key=key,egg=inc[key],bot=true,target=spawn and spawn.Position or start+Vector3.new(80,0,0),deadline=os.clock()+30}
	local prompt=Instance.new("ProximityPrompt");prompt.Name="ReclaimPrompt";prompt.ActionText="ทวงไข่คืน";prompt.ObjectText="TEST THIEF";prompt.HoldDuration=0;prompt.RequiresLineOfSight=false;prompt.MaxActivationDistance=Config.ReclaimRange;prompt.Parent=body
	prompt.Triggered:Connect(function(by) Steal.Reclaim(by,m) end)
	notify(owner,"บอทขโมยไข่ทดสอบกำลังหนี! ตามไปกด E",true)
	return true,"ปล่อยบอทขโมยไข่แล้ว"
end

function Steal.Init()
	Pet.OnForeignIncubator=Steal.Try
	for id=1,7 do
		local wall=Garden.BaseById(id) and Garden.BaseById(id):FindFirstChild("LockBarrier")
		if wall then
			for _,g in {"BaseBarrier"..id,"BaseOwner"..id} do if not Physics:IsCollisionGroupRegistered(g) then Physics:RegisterCollisionGroup(g) end end
			Physics:CollisionGroupSetCollidable("BaseBarrier"..id,"BaseOwner"..id,false)
			wall.CollisionGroup="BaseBarrier"..id;barrier(id,false)
		end
	end
	Players.PlayerRemoving:Connect(function(p)
		-- Runs before the profile is released: unmark eggs this player was carrying or owned.
		if carrying[p] then Steal.Return(p) end
		for thief,entry in carrying do if entry.victim==p then clear(thief);notify(thief,"เจ้าของฐานออกจากเกม — ไข่กลับตู้ฟักแล้ว",true) end end
		if Data.IsLoaded(p) then for _,egg in Data.Get(p,"Pets.incubator") do egg.carriedBy=nil end end
		local id=Garden.BaseIndex(p);if id then locks[id]=nil;barrier(id,false) end
		afk[p]=nil;cooldowns[p]=nil;lastAction[p]=nil
	end)
	Net.Function("BaseAction").OnServerInvoke=function(p,action,arg)
		if not Data.IsLoaded(p) then return false,"กำลังโหลดข้อมูล" end
		if action=="Presence" then Steal.Presence(p,arg);return true end
		local now=os.clock();if now-(lastAction[p] or -math.huge)<.3 then return false,"รอสักครู่" end;lastAction[p]=now
		if action=="Lock" then return Steal.Lock(p)
		elseif action=="FriendSteal" and type(arg)=="boolean" then Data.Set(p,"Settings.FriendSteal",arg);Pet.Send(p);return true,arg and "เพื่อนขโมยไข่ได้" or "เพื่อนขโมยไข่ไม่ได้"
		elseif action=="Reclaim" and typeof(arg)=="Instance" then
			for thief in carrying do if thief==arg or (typeof(thief)=="Instance" and thief:IsA("Player") and thief.Character==arg) then return Steal.Reclaim(p,thief) end end
			return false,"ไม่พบคนขโมย"
		end
		return false,"คำสั่งไม่ถูกต้อง"
	end
end
function Steal.Start()
	task.spawn(function() while true do
		local dt=.1
		for thief,entry in carrying do
			if entry.bot then
				local pos=thief:GetPivot().Position;local to=Vector3.new(entry.target.X,pos.Y,entry.target.Z)-pos
				if to.Magnitude<3 or os.clock()>entry.deadline or not Data.IsLoaded(entry.victim) then Steal.Return(thief,"บอททดสอบหนีได้ — คืนไข่ให้แล้ว (โหมดทดสอบ)")
				else thief:PivotTo(CFrame.lookAt(pos+to.Unit*math.min(to.Magnitude,10*dt),pos+to)) end
			elseif not thief.Parent or not Data.IsLoaded(thief) or not root(thief) or Data.Get(thief,"Run.Active") then Steal.Return(thief,"การขโมยถูกยกเลิก — ไข่กลับตู้ฟัก")
			elseif entry.victim~="bot" and not Data.IsLoaded(entry.victim) then clear(thief)
			elseif entry.victim=="bot" and (not bot or bot.base~=entry.base) then clear(thief)
			else
				local home=Garden.Base(thief);local hr=root(thief)
				if home and flat(hr.Position,home.PrimaryPart.Position)<=Config.BaseRadius and math.abs(hr.Position.Y-home.PrimaryPart.Position.Y)<15 then deliver(thief) end
			end
		end
		task.wait(dt)
	end end)
	task.spawn(function() while true do
		local now=os.time()
		for id,l in locks do if now>=l.untilAt and Garden.BaseById(id).LockBarrier.CanCollide then barrier(id,false) end end
		for _,p in Players:GetPlayers() do
			if Data.IsLoaded(p) then p:SetAttribute("Shield",Steal.Shield(p) or "") end
			local id=Garden.BaseIndex(p);local group=id and "BaseOwner"..id or "Default"
			local hr=p.Character and p.Character:FindFirstChild("HumanoidRootPart")
			if hr and hr.CollisionGroup~=group then for _,part in p.Character:GetDescendants() do if part:IsA("BasePart") then part.CollisionGroup=group end end end
		end
		task.wait(1)
	end end)
end
return Steal
