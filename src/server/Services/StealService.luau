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
local Math=require(Shared.PetMath);local rng=Random.new()
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
	if reason=="reclaim" then notify(entry.victim,"Egg reclaimed!");notify(thief,"The owner reclaimed the egg",true)
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
	if not ok then egg.carriedBy=nil;inc[entry.key]=egg;commit(entry.victim);clear(thief);notify(thief,"Egg bag full. Egg returned",true);return end
	local bonus=math.floor(Math.EggPrice(egg.id)*Config.StealBonus)
	Data.AddCurrency(thief,"Coins",bonus);Data.Increment(thief,"Stats.EggsStolen",1)
	clear(thief)
	notify(thief,"Theft successful! Received "..Eggs.ById[egg.id].name.." +"..bonus.." Coins")
	notify(entry.victim,thief.DisplayName.." stole your egg! Lock your base to protect it",true)
end

function Steal.Try(thief,id)
	if not Features.IsEnabled("Eggs") or not Features.IsEnabled("Stealing") or not Data.IsLoaded(thief) then return false,"Egg theft unavailable" end
	Steal.MarkActive(thief)
	local owner=Garden.OwnerOf(id)
	if owner==thief then return false,"This is your base" end
	-- The friend lookup can yield; everything below re-reads live state.
	if owner and Data.IsLoaded(owner) and not Data.Get(owner,"Settings.FriendSteal") and friends(thief,owner) then return false,"Friends cannot steal your eggs" end
	local inc,victim=incubatorOf(id)
	if not inc then return false,"This base has no owner" end
	if not Garden.Base(thief) then return false,"You need your own base first" end
	if carrying[thief] or thief:GetAttribute("CarryingEgg") then return false,"You can carry only one egg at a time" end
	if Data.Get(thief,"Run.Active") then return false,"End your run before stealing eggs" end
	if Pet.EggRoom(thief)<=0 then return false,"Egg bag full" end
	local hr=root(thief);local base=Garden.BaseById(id)
	if not hr or (hr.Position-base.Incubator:GetPivot().Position).Magnitude>Config.IncubatorRange+2 then return false,"Move closer to the incubator first" end
	if Steal.Locked(id) then return false,"This base is locked" end
	if victim~="bot" and Steal.Shield(victim) then return false,"This base has a shield" end
	local cd=cooldowns[thief] and cooldowns[thief][id]
	if cd and os.time()<cd then return false,"Wait "..(cd-os.time()).." sec before stealing from this base again" end
	local keys={};for k in inc do table.insert(keys,k) end;table.sort(keys)
	local key;for _,k in keys do if Math.Stealable(inc[k]) then key=k;break end end
	if not key then return false,"No stealable egg (empty, over 75% hatched or protected)" end
	local defence=victim=="bot" and bot.defence or Data.Get(victim,"Pets.upgrades")
	if rng:NextNumber()<Math.GuardChance(defence.guard) then
		cooldowns[thief]=cooldowns[thief] or {};cooldowns[thief][id]=os.time()+Config.ThiefCooldown
		notify(victim,"Guard chased "..thief.DisplayName.." away!",true)
		return false,"Guard chased you away! Wait "..Config.ThiefCooldown.." sec before trying this base again"
	end
	local egg=inc[key];egg.carriedBy=thief.UserId;commit(victim)
	carrying[thief]={base=id,victim=victim,key=key,egg=egg}
	cooldowns[thief]=cooldowns[thief] or {};cooldowns[thief][id]=os.time()+Config.ThiefCooldown
	local slow=Math.TrapSlow(defence.trap)
	Pet.SetCarry(thief,Eggs.ById[egg.id].color,slow,victim=="bot" and -1 or victim.UserId)
	Collection:AddTag(thief.Character,"EggThief")
	local prompt=Instance.new("ProximityPrompt");prompt.Name="ReclaimPrompt";prompt.ActionText="Reclaim Egg";prompt.ObjectText="EGG THIEF";prompt.HoldDuration=0;prompt.RequiresLineOfSight=false;prompt.MaxActivationDistance=Config.ReclaimRange;prompt.Parent=hr
	prompt.Triggered:Connect(function(by) Steal.Reclaim(by,thief) end)
	notify(victim,thief.DisplayName.." stole an egg from your incubator! Chase them and press E to reclaim it",true)
	return true,"Egg stolen! Run back to your base (speed reduced by "..math.round((1-slow)*100).."%)"
end
function Steal.Reclaim(by,thief)
	local entry=carrying[thief]
	if not entry or entry.victim~=by then return false,"Only the egg owner can reclaim it" end
	local hr=root(by);local target=entry.bot and thief.PrimaryPart or (thief.Character and thief.Character:FindFirstChild("HumanoidRootPart"))
	if not hr or not target or (hr.Position-target.Position).Magnitude>Config.ReclaimRange+2 then return false,"Move closer to the thief first" end
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
	if not Features.IsEnabled("Eggs") or not Data.IsLoaded(p) or not Garden.NearBase(p) then return false,"Lock your base from your own base" end
	Steal.MarkActive(p)
	local id=Garden.BaseIndex(p);local l=locks[id];local now=os.time()
	if l and now<l.untilAt then return false,"Base already locked" end
	if l and now<l.ready then return false,"Cooldown remaining "..(l.ready-now).." sec" end
	local seconds=Math.LockSeconds(Data.Get(p,"Pets.upgrades").lock)
	locks[id]={untilAt=now+seconds,ready=now+seconds+Config.LockCooldown,owner=p}
	barrier(id,true);eject(id,p)
	return true,"Lock Base "..seconds.." sec"
end
-- Robux "lock now": skips the cooldown but keeps the normal lock length.
function Steal.ForceLock(p)
	local id=Garden.BaseIndex(p);if not id or not Data.IsLoaded(p) then return false end
	local now=os.time();local seconds=Math.LockSeconds(Data.Get(p,"Pets.upgrades").lock)
	locks[id]={untilAt=now+seconds,ready=now+seconds+Config.LockCooldown,owner=p};barrier(id,true);eject(id,p);return true
end
function Steal.ResetLock(p) local id=Garden.BaseIndex(p);cooldowns[p]=nil;if id then locks[id]=nil;barrier(id,false) end end

function Steal.CreateBot()
	if bot then return true,bot.base end
	for id=1,7 do local b=Garden.BaseById(id)
		if b and b:GetAttribute("OwnerUserId")==0 then
			b:SetAttribute("OwnerUserId",-1);bot={base=id,incubator={},defence={}}
			for i=1,3 do bot.incubator[tostring(i)]={id="egg_meadow",zone=1,rebirthDrop=0,admin_spawned=true,progress=i==3 and 50 or 0,updatedAt=os.time()} end
			sign(b,"Test Bot Base");return true,id
		end
	end
	return false
end
-- Admin test seam: the bot base has no profile, so its trap/guard levels live here.
function Steal.SetBotDefence(trap,guard) if not bot then return false end;bot.defence={trap=trap,guard=guard};return true end
function Steal.RemoveBot()
	if not bot then return false end
	for thief,entry in carrying do if entry.base==bot.base then clear(thief) end end
	local b=Garden.BaseById(bot.base);b:SetAttribute("OwnerUserId",0);sign(b,"Base "..bot.base.." · Empty");locks[bot.base]=nil;barrier(bot.base,false);bot=nil;return true
end
function Steal.Bot() return bot end
-- Admin test: an NPC carries one of the owner's eggs toward the village; reclaim it with E.
function Steal.SpawnBotThief(owner)
	local id=Garden.BaseIndex(owner);if not id or not Data.IsLoaded(owner) then return false,"You need a base first" end
	local inc=Data.Get(owner,"Pets.incubator");local keys={};for k in inc do table.insert(keys,k) end;table.sort(keys)
	local key;for _,k in keys do if Math.Stealable(inc[k]) then key=k;break end end
	if not key then return false,"No stealable eggs in this incubator" end
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
	local prompt=Instance.new("ProximityPrompt");prompt.Name="ReclaimPrompt";prompt.ActionText="Reclaim Egg";prompt.ObjectText="TEST THIEF";prompt.HoldDuration=0;prompt.RequiresLineOfSight=false;prompt.MaxActivationDistance=Config.ReclaimRange;prompt.Parent=body
	prompt.Triggered:Connect(function(by) Steal.Reclaim(by,m) end)
	notify(owner,"Test thief escaping! Chase and press E",true)
	return true,"Test thief spawned"
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
		for thief,entry in carrying do if entry.victim==p then clear(thief);notify(thief,"The owner left. Egg returned to its incubator",true) end end
		if Data.IsLoaded(p) then for _,egg in Data.Get(p,"Pets.incubator") do egg.carriedBy=nil end end
		local id=Garden.BaseIndex(p);if id then locks[id]=nil;barrier(id,false) end
		afk[p]=nil;cooldowns[p]=nil;lastAction[p]=nil
	end)
	Net.Function("BaseAction").OnServerInvoke=function(p,action,arg)
		if not Data.IsLoaded(p) then return false,"Loading data" end
		if action=="Presence" then Steal.Presence(p,arg);return true end
		local now=os.clock();if now-(lastAction[p] or -math.huge)<.3 then return false,"Please wait" end;lastAction[p]=now
		if action=="Lock" then return Steal.Lock(p)
		elseif action=="FriendSteal" and type(arg)=="boolean" then Data.Set(p,"Settings.FriendSteal",arg);Pet.Send(p);return true,arg and "Friends can steal eggs" or "Friends cannot steal eggs"
		elseif action=="Reclaim" and typeof(arg)=="Instance" then
			for thief in carrying do if thief==arg or (typeof(thief)=="Instance" and thief:IsA("Player") and thief.Character==arg) then return Steal.Reclaim(p,thief) end end
			return false,"Thief not found"
		end
		return false,"Invalid command"
	end
end
function Steal.Start()
	task.spawn(function() while true do
		local dt=.1
		for thief,entry in carrying do
			if entry.bot then
				local pos=thief:GetPivot().Position;local to=Vector3.new(entry.target.X,pos.Y,entry.target.Z)-pos
				if to.Magnitude<3 or os.clock()>entry.deadline or not Data.IsLoaded(entry.victim) then Steal.Return(thief,"Test thief escaped. Egg returned (test mode)")
				else thief:PivotTo(CFrame.lookAt(pos+to.Unit*math.min(to.Magnitude,10*dt),pos+to)) end
			elseif not thief.Parent or not Data.IsLoaded(thief) or not root(thief) or Data.Get(thief,"Run.Active") then Steal.Return(thief,"Theft canceled. Egg returned to its incubator")
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
