-- Eggs, incubator, pets, pen income, follow buffs, mounts and the egg conveyor.
-- Profile data is the source of truth; visuals and mounts are runtime-only.
local Players=game:GetService("Players")
local Collection=game:GetService("CollectionService")
local Http=game:GetService("HttpService")
local Shared=game.ReplicatedStorage.Shared
local Net=require(Shared.Net)
local Pets=require(Shared.Config.Pets)
local Eggs=require(Shared.Config.Eggs)
local Config=require(Shared.Config.Base)
local Math=require(Shared.PetMath)
local Visual=require(Shared.PetVisual)
local Data=require(script.Parent.DataService)
local Features=require(script.Parent.FeatureService)
local Weather=require(script.Parent.WeatherService)
local Garden=require(script.Parent.GardenService)
local Pet={}
local rng=Random.new()
local mounts,lastAction,penSig={},{},{}
Pet.OnForeignIncubator=function() return false,"ระบบขโมยไข่ยังไม่เปิด" end -- set by StealService

local function enabled(p) return Data.IsLoaded(p) and Features.IsEnabled("Eggs") end
local function root(p)
	local c=p.Character;local h=c and c:FindFirstChildOfClass("Humanoid")
	return h and h.Health>0 and c:FindFirstChild("HumanoidRootPart")
end
local function pos(inst) return inst:IsA("BasePart") and inst.Position or inst:GetPivot().Position end
local function near(p,inst,range)
	local hr=root(p);return hr~=nil and inst~=nil and (hr.Position-pos(inst)).Magnitude<=range and not Data.Get(p,"Run.Active")
end
local function count(t) local n=0;for _ in t do n+=1 end;return n end
local function placedIn(inv,place) local n=0;for _,pet in inv do if pet.place==place then n+=1 end end;return n end
local function conveyor()
	for _,m in Collection:GetTagged("Shop") do if m:GetAttribute("ShopType")=="EggConveyor" and m:IsDescendantOf(workspace) then return m end end
end
function Pet.NearIncubator(p) local b=Garden.Base(p);return b~=nil and near(p,b:FindFirstChild("Incubator"),Config.IncubatorRange) end
function Pet.NearPen(p) local b=Garden.Base(p);return b~=nil and near(p,b:FindFirstChild("PetPen"),Config.PenRange) end
function Pet.PenCap(p) return Math.PenSlots(Data.Get(p,"Pets.upgrades").pen) end
function Pet.EquipCap(p) return math.min(Config.MaxEquipSlots,Data.Get(p,"Pets.equipSlots")) end
function Pet.EggRoom(p) return Config.MaxEggs-count(Data.Get(p,"Inventory.Eggs"))-#(Data.Get(p,"Run.Eggs") or {}) end

function Pet.GrantEgg(p,egg)
	if not Data.IsLoaded(p) or not Eggs.ById[egg.id] then return false end
	local inv=Data.Get(p,"Inventory.Eggs");if count(inv)>=Config.MaxEggs then return false end
	local uid=Http:GenerateGUID(false)
	inv[uid]={id=egg.id,zone=Eggs.ById[egg.id].zone,rebirthDrop=egg.rebirthDrop or 0,admin_spawned=egg.admin_spawned==true,robux=egg.robux==true,stolen=egg.stolen==true,progress=math.max(0,egg.progress or 0)}
	Data.Set(p,"Inventory.Eggs",inv);return true,uid
end
function Pet.GrantPet(p,id,opts)
	opts=opts or {}
	if not Data.IsLoaded(p) or not Pets.ById[id] then return false end
	local inv=Data.Get(p,"Inventory.Pets");if count(inv)>=Config.MaxPets then return false end
	local uid=Http:GenerateGUID(false)
	inv[uid]={id=id,zone=opts.zone or Pets.ById[id].zone,rebirthDrop=opts.rebirthDrop or 0,tier=math.clamp(opts.tier or 1,1,Pets.MaxTier),mutation=opts.mutation,admin_spawned=opts.admin==true,place=""}
	if placedIn(inv,"pen")<Pet.PenCap(p) then inv[uid].place="pen" end
	Data.Set(p,"Inventory.Pets",inv);Pet.Refresh(p);return true,uid
end

function Pet.Income(p)
	if not Features.IsEnabled("Eggs") then return 0 end
	local sum=0;for _,pet in Data.Get(p,"Inventory.Pets") or {} do if pet.place=="pen" then sum+=Math.Income(pet) end end;return sum
end
function Pet.Mult(p,kind)
	if not Features.IsEnabled("Eggs") or not Data.IsLoaded(p) then return 1 end
	local list={};for _,pet in Data.Get(p,"Inventory.Pets") do if pet.place=="equip" then table.insert(list,pet) end end
	return Math.Mult(list,kind)
end
function Pet.Advance(p,now,online)
	local d=Data.Get(p,"Pets");if not d then return end
	local speed=Math.HatchSpeed(d.upgrades.incubator);local weather=Weather.State().id
	for _,egg in d.incubator do
		if not egg.done and not egg.carriedBy then
			local hatch=Eggs.ById[egg.id].hatch
			egg.progress=math.min(hatch,egg.progress+math.max(0,now-(egg.updatedAt or now))*speed)
			if egg.progress>=hatch then
				egg.done=true
				-- Weather mutations need the owner online when the egg finishes.
				if online then for id,m in Pets.Mutations do if m.weather==weather and rng:NextNumber()<Pets.HatchMutationChance then egg.mutation=id end end end
			end
		end
		egg.updatedAt=now
	end
	local income=Pet.Income(p);local elapsed=d.bankAt>0 and math.max(0,now-d.bankAt) or 0
	if not online then elapsed=math.min(elapsed,Config.OfflineHours*3600) end
	d.bank=math.min(income*Config.OfflineHours*3600,d.bank+income*elapsed);d.bankAt=now
end

function Pet.Place(p,uid,slot)
	if not enabled(p) or not Pet.NearIncubator(p) then return false,"วางไข่ที่ตู้ฟักในฐานตัวเอง" end
	if type(slot)~="number" or slot%1~=0 or slot<1 or slot>Config.IncubatorSlots then return false,"ช่องตู้ฟักไม่ถูกต้อง" end
	Pet.Advance(p,os.time(),true)
	local d=Data.Get(p,"Pets");local key=tostring(slot);local inv=Data.Get(p,"Inventory.Eggs");local egg=type(uid)=="string" and inv[uid]
	if d.incubator[key] or not egg then return false,"ช่องไม่ว่างหรือไม่มีไข่" end
	inv[uid]=nil;egg.updatedAt=os.time();egg.done=false;d.incubator[key]=egg
	Data.Set(p,"Inventory.Eggs",inv);Data.Set(p,"Pets",d);return true,"วางไข่แล้ว"
end
function Pet.Hatch(p)
	if not enabled(p) or not Pet.NearIncubator(p) then return false,"ฟักไข่ที่ตู้ฟักในฐานตัวเอง" end
	Pet.Advance(p,os.time(),true)
	local d=Data.Get(p,"Pets");local inv=Data.Get(p,"Inventory.Pets");local hatched,names={},{}
	local keys={};for key in d.incubator do table.insert(keys,key) end;table.sort(keys)
	for _,key in keys do local egg=d.incubator[key]
		if egg.done and not egg.carriedBy and count(inv)<Config.MaxPets then
			local id=Math.Weighted(Eggs.ById[egg.id].pets,rng)
			local pet={id=id,zone=egg.zone,rebirthDrop=egg.rebirthDrop,tier=1,mutation=egg.mutation,admin_spawned=egg.admin_spawned==true,place=""}
			inv[Http:GenerateGUID(false)]=pet;d.incubator[key]=nil;table.insert(hatched,pet)
			table.insert(names,Pets.ById[id].name..(egg.mutation and " ("..egg.mutation..")" or ""))
		end
	end
	if #hatched==0 then return false,"ยังไม่มีไข่ที่ฟักเสร็จ" end
	local room=Pet.PenCap(p)-placedIn(inv,"pen");for _,pet in hatched do if room>0 then pet.place="pen";room-=1 end end
	Data.Set(p,"Inventory.Pets",inv);Data.Set(p,"Pets",d);Data.Increment(p,"Stats.EggsHatched",#hatched)
	for _,pet in hatched do local r=Pets.ById[pet.id].rarity
		if r=="Mythic" or r=="Secret" then Net.Event("Notify"):FireAllClients({text=p.DisplayName.." ฟักได้ "..r.." "..Pets.ById[pet.id].name.."!",color="Accent"}) end
	end
	Pet.Refresh(p);return true,"ฟักได้ "..table.concat(names,", "),hatched
end
function Pet.SetPlace(p,uid,place)
	if not enabled(p) then return false,"ระบบสัตว์ยังไม่เปิด" end
	if place~="" and place~="pen" and place~="equip" then return false,"คำสั่งไม่ถูกต้อง" end
	Pet.Advance(p,os.time(),true)
	local inv=Data.Get(p,"Inventory.Pets");local pet=type(uid)=="string" and inv[uid]
	if not pet then return false,"ไม่พบสัตว์" end
	if pet.place==place then return true,"อยู่ที่นั่นแล้ว" end
	if place=="pen" and placedIn(inv,"pen")>=Pet.PenCap(p) then return false,"คอกเต็ม — อัปเกรดคอกด้วย Wood" end
	if place=="equip" and placedIn(inv,"equip")>=Pet.EquipCap(p) then return false,"พกได้สูงสุด "..Pet.EquipCap(p).." ตัว" end
	pet.place=place;Data.Set(p,"Inventory.Pets",inv);Pet.Refresh(p)
	return true,({[""]="เก็บเข้ากระเป๋าแล้ว",pen="ใส่คอกแล้ว",equip="พกติดตัวแล้ว"})[place]
end
function Pet.Fuse(p,uids)
	if not enabled(p) then return false,"ระบบสัตว์ยังไม่เปิด" end
	if type(uids)~="table" or #uids~=3 then return false,"เลือกสัตว์ตัวเดียวกัน 3 ตัว" end
	Pet.Advance(p,os.time(),true)
	local inv=Data.Get(p,"Inventory.Pets");local seen={};local first
	for _,uid in uids do
		local pet=type(uid)=="string" and inv[uid]
		if not pet or seen[uid] then return false,"สัตว์ไม่ครบหรือเลือกซ้ำ" end
		seen[uid]=true;first=first or pet
		if pet.id~=first.id or pet.zone~=first.zone or pet.rebirthDrop~=first.rebirthDrop or pet.tier~=first.tier then return false,"ต้องเป็นสัตว์ชนิด/โซน/ขั้นเดียวกัน" end
	end
	if first.tier>=Pets.MaxTier then return false,"ขั้นสูงสุดแล้ว" end
	local out=table.clone(first);out.tier+=1
	for _,uid in uids do local pet=inv[uid]
		if Math.MutationMult(pet.mutation)>Math.MutationMult(out.mutation) then out.mutation=pet.mutation end
		if pet.admin_spawned then out.admin_spawned=true end
		if mounts[p]==uid then mounts[p]=nil end
	end
	for _,uid in uids do inv[uid]=nil end;inv[uids[1]]=out
	Data.Set(p,"Inventory.Pets",inv);Pet.Refresh(p)
	return true,"หลอมเป็นขั้น "..out.tier,{uid=uids[1],pet=table.clone(out)}
end
function Pet.Release(p,uid)
	if not enabled(p) then return false,"ระบบสัตว์ยังไม่เปิด" end
	Pet.Advance(p,os.time(),true)
	local inv=Data.Get(p,"Inventory.Pets");if type(uid)~="string" or not inv[uid] then return false,"ไม่พบสัตว์" end
	inv[uid]=nil;if mounts[p]==uid then mounts[p]=nil end
	Data.Set(p,"Inventory.Pets",inv);Pet.Refresh(p);return true,"ปล่อยสัตว์แล้ว"
end
function Pet.Collect(p)
	if not enabled(p) or not Pet.NearPen(p) then return false,"เก็บเงินที่คอกสัตว์ในฐานตัวเอง" end
	Pet.Advance(p,os.time(),true)
	local d=Data.Get(p,"Pets");local amount=math.floor(d.bank)
	if amount<=0 then return false,"ยังไม่มีเงินในคอก" end
	d.bank-=amount;Data.Set(p,"Pets",d);Data.AddCurrency(p,"Coins",amount)
	return true,"เก็บเงินคอก +"..amount.." Coins"
end
function Pet.Upgrade(p,kind)
	if not enabled(p) or not Garden.NearBase(p) then return false,"อัปเกรดที่ฐานตัวเอง" end
	if not Math.MaxLevel(kind) then return false,"คำสั่งไม่ถูกต้อง" end
	Pet.Advance(p,os.time(),true)
	local d=Data.Get(p,"Pets");local level=d.upgrades[kind] or 0
	if level>=Math.MaxLevel(kind) then return false,"อัปเกรดสูงสุดแล้ว" end
	local cost=Math.UpgradeCost(kind,level)
	if Data.GetCurrency(p,"Wood")<cost then return false,"Wood ไม่พอ" end
	Data.AddCurrency(p,"Wood",-cost);d.upgrades[kind]=level+1;Data.Set(p,"Pets",d);Pet.Refresh(p)
	return true,"อัปเกรดแล้ว (เลเวล "..(level+1)..")"
end
function Pet.Buy(p,epoch)
	local belt=conveyor()
	if not enabled(p) or not belt or not near(p,belt,Config.PenRange) then return false,"ซื้อไข่ที่สายพานในหมู่บ้าน" end
	if type(epoch)~="number" then return false,"ไข่นี้ไม่อยู่บนสายพานแล้ว" end
	local row;for _,r in Math.BeltWindow(os.time()) do if r.epoch==epoch then row=r end end
	if not row then return false,"ไข่นี้ไม่อยู่บนสายพานแล้ว" end
	local d=Data.Get(p,"Pets");local key=tostring(epoch)
	if d.beltBought[key] then return false,"ซื้อไข่ใบนี้ไปแล้ว" end
	local def=Eggs.ById[row.id]
	if not table.find(Data.Get(p,"Progress.UnlockedZones"),def.zone) then return false,"ต้องปลดล็อกโซน "..def.zone.." ก่อน" end
	if Pet.EggRoom(p)<=0 then return false,"ไข่เต็มกระเป๋า" end
	local price=Math.EggPrice(row.id)
	if Data.GetCurrency(p,"Coins")<price then return false,"Coins ไม่พอ" end
	-- No yields: consume Coins, mark the belt egg and grant it together.
	Data.AddCurrency(p,"Coins",-price)
	for k in d.beltBought do if tonumber(k)<epoch-20 then d.beltBought[k]=nil end end
	d.beltBought[key]=true;Data.Set(p,"Pets",d)
	Pet.GrantEgg(p,{id=row.id,rebirthDrop=Data.Get(p,"Progress.Rebirth")})
	return true,"ซื้อ "..def.name.." แล้ว"
end
function Pet.ChestDrop(p,chest)
	if not enabled(p) or rng:NextNumber()>=Config.ChestEggChance then return end
	local pick=Eggs.List[1];for _,e in Eggs.List do if e.nestType and e.zone==chest.zone then pick=e end end
	Pet.GrantEgg(p,{id=pick.id,rebirthDrop=chest.rebirthDrop or 0,admin_spawned=chest.admin_spawned==true})
end

function Pet.Mount(p,uid)
	if not enabled(p) then return false,"ระบบสัตว์ยังไม่เปิด" end
	local pet=type(uid)=="string" and Data.Get(p,"Inventory.Pets")[uid]
	if not pet or not Pets.ById[pet.id].rideable then return false,"สัตว์ตัวนี้ขี่ไม่ได้" end
	if p:GetAttribute("CarryingEgg") then return false,"ขี่ไม่ได้ขณะถือไข่" end
	if Features.IsEnabled("Story") and (Data.Get(p,"Progress.StoryChapter") or 1)<Config.MountChapter then return false,"ปลดล็อกการขี่ในบทที่ "..Config.MountChapter end
	mounts[p]=uid;Pet.Refresh(p);return true,"ขี่ "..Pets.ById[pet.id].name.." แล้ว"
end
function Pet.Dismount(p) if mounts[p] then mounts[p]=nil;Pet.Refresh(p) end end
function Pet.Mounted(p) return mounts[p] end
function Pet.SpeedMult(p)
	local m=Pet.Mult(p,"Speed");local mount=mounts[p] and Data.Get(p,"Inventory.Pets")[mounts[p]]
	if mount and Features.IsEnabled("Eggs") and not p:GetAttribute("CarryingEgg") then m*=Config.MountSpeed[Pets.ById[mount.id].rarity] end
	return m*(p:GetAttribute("CarryMult") or 1)
end
function Pet.ApplySpeed(p)
	local c=p.Character;local hum=c and c:FindFirstChildOfClass("Humanoid");if not hum then return end
	local base=p:GetAttribute("AdminSpeed");base=type(base)=="number" and base or 16
	local want=base*Pet.SpeedMult(p);if math.abs(hum.WalkSpeed-want)>.01 then hum.WalkSpeed=want end
end
-- Shared by stealing and nest eggs: one carried egg, slower walk, no mount.
function Pet.SetCarry(p,color,mult,from)
	local c=p.Character;local head=c and c:FindFirstChild("Head");local old=c and c:FindFirstChild("CarriedEgg")
	if old then old:Destroy() end
	if color then
		mounts[p]=nil;p:SetAttribute("CarryingEgg",true);p:SetAttribute("CarryMult",mult);p:SetAttribute("StealingFrom",from)
		if head then
			local egg=Visual.Egg(color,1.1);egg.Name="CarriedEgg";egg:PivotTo(head.CFrame*CFrame.new(0,2.6,0))
			for _,part in egg:GetDescendants() do if part:IsA("BasePart") then part.Anchored=false;part.Massless=true;local w=Instance.new("WeldConstraint");w.Part0=part;w.Part1=head;w.Parent=part end end
			egg.Parent=c
		end
	else
		p:SetAttribute("CarryingEgg",nil);p:SetAttribute("CarryMult",nil);p:SetAttribute("StealingFrom",nil)
	end
	Pet.Refresh(p)
end
function Pet.Refresh(p)
	if not Data.IsLoaded(p) then return end
	local list={}
	if Features.IsEnabled("Eggs") then
		local inv=Data.Get(p,"Inventory.Pets");local keys={};for uid,pet in inv do if pet.place=="equip" then table.insert(keys,uid) end end;table.sort(keys)
		for _,uid in keys do table.insert(list,inv[uid].id) end
		if mounts[p] and not inv[mounts[p]] then mounts[p]=nil end
	else mounts[p]=nil end
	p:SetAttribute("PetFollow",table.concat(list,","))
	local mount=mounts[p] and Data.Get(p,"Inventory.Pets")[mounts[p]]
	p:SetAttribute("MountPet",mount and mount.id or "")
	Pet.ApplySpeed(p)
end

local function renderPen(p)
	local b=Garden.Base(p);local pen=b and b:FindFirstChild("PetPen");if not pen then return end
	local ids={};if Features.IsEnabled("Eggs") then for _,pet in Data.Get(p,"Inventory.Pets") do if pet.place=="pen" then table.insert(ids,pet.id) end end end
	table.sort(ids);local sig=table.concat(ids,",")
	if penSig[p]==sig and pen:FindFirstChild("PenPets") then return end;penSig[p]=sig
	local old=pen:FindFirstChild("PenPets");if old then old:Destroy() end
	local folder=Instance.new("Folder");folder.Name="PenPets";folder.Parent=pen
	local center=pen:GetPivot().Position
	for i,id in ids do
		local angle=i*2.4;local radius=1.5+math.sqrt(i)*1.4
		local m=Visual.Pet(id,.6);local at=Vector3.new(center.X+math.cos(angle)*radius,center.Y-.3,center.Z+math.sin(angle)*radius)
		m:PivotTo(CFrame.lookAt(at,Vector3.new(center.X,at.Y,center.Z)));m.Parent=folder
	end
end
local function clearPen(p)
	local b=Garden.Base(p);local pen=b and b:FindFirstChild("PetPen");local old=pen and pen:FindFirstChild("PenPets")
	if old then old:Destroy() end;penSig[p]=nil
end
function Pet.Send(p)
	if not Data.IsLoaded(p) or not p.Parent then return end
	local d=Data.Get(p,"Pets");local inc={}
	for k,e in d.incubator do inc[k]=table.clone(e) end
	Net.Event("PetState"):FireClient(p,{
		base=Garden.BaseIndex(p),incubator=inc,eggs=Data.Get(p,"Inventory.Eggs"),pets=Data.Get(p,"Inventory.Pets"),
		bank=d.bank,income=Pet.Income(p),penCap=Pet.PenCap(p),equipCap=Pet.EquipCap(p),upgrades=table.clone(d.upgrades),
		hatchSpeed=Math.HatchSpeed(d.upgrades.incubator),mount=mounts[p],beltBought=table.clone(d.beltBought),now=os.time(),
		mults={Power=Pet.Mult(p,"Power"),Wood=Pet.Mult(p,"Wood"),Exp=Pet.Mult(p,"Exp"),Speed=Pet.Mult(p,"Speed")},
		friendSteal=Data.Get(p,"Settings.FriendSteal")==true,
	})
end

function Pet.Init()
	for _,b in Collection:GetTagged("PlayerBase") do if b:IsDescendantOf(workspace) then
		local id=b:GetAttribute("BaseIndex");local inc=b:FindFirstChild("Incubator");local pen=b:FindFirstChild("PetPen")
		local dome=inc and (inc:FindFirstChild("Dome") or inc:FindFirstChildWhichIsA("BasePart"))
		if dome then
			local prompt=Instance.new("ProximityPrompt");prompt.Name="IncubatorPrompt";prompt.ActionText="ตู้ฟักไข่";prompt.ObjectText="INCUBATOR";prompt.RequiresLineOfSight=false;prompt.MaxActivationDistance=Config.IncubatorRange;prompt.HoldDuration=.25;prompt.Parent=dome
			prompt.Triggered:Connect(function(p)
				if not enabled(p) then return end
				if Garden.BaseIndex(p)==id then Net.Event("PetShow"):FireClient(p,"Incubator");Pet.Send(p)
				else local ok,msg=Pet.OnForeignIncubator(p,id);Net.Event("Notify"):FireClient(p,{text=msg,kind=not ok and "warn" or nil}) end
			end)
		end
		if pen then
			local post=Instance.new("Part");post.Name="PenPromptAnchor";post.Size=Vector3.new(1,1,1);post.Transparency=1;post.Anchored=true;post.CanCollide=false;post.CanQuery=false;post.CFrame=CFrame.new(pen:GetPivot().Position+Vector3.new(0,2,0));post.Parent=pen
			local prompt=Instance.new("ProximityPrompt");prompt.Name="PenPrompt";prompt.ActionText="เก็บเงินคอก";prompt.ObjectText="PET PEN";prompt.RequiresLineOfSight=false;prompt.MaxActivationDistance=Config.PenRange;prompt.Parent=post
			prompt.Triggered:Connect(function(p)
				if enabled(p) and Garden.BaseIndex(p)==id then local ok,msg=Pet.Collect(p);Net.Event("Notify"):FireClient(p,{text=msg});Net.Event("PetShow"):FireClient(p,"Pets");Pet.Send(p) end
			end)
		end
	end end
	local belt=conveyor()
	if belt and belt.PrimaryPart then
		local prompt=Instance.new("ProximityPrompt");prompt.Name="EggBeltPrompt";prompt.ActionText="ซื้อไข่";prompt.ObjectText="EGG CONVEYOR";prompt.RequiresLineOfSight=false;prompt.MaxActivationDistance=Config.PenRange;prompt.Parent=belt.PrimaryPart
		prompt.Triggered:Connect(function(p) if enabled(p) then Net.Event("PetShow"):FireClient(p,"Belt");Pet.Send(p) end end)
	end
	Data.PlayerLoaded:Connect(function(p)
		-- A crash or disconnect can leave an egg marked as carried; it was never transferred.
		local d=Data.Get(p,"Pets");for _,egg in d.incubator do egg.carriedBy=nil end
		Pet.Advance(p,os.time(),false);Data.Set(p,"Pets",d);Pet.Refresh(p);Pet.Send(p)
		p.CharacterAdded:Connect(function(char) char:WaitForChild("Humanoid",5);task.defer(Pet.Refresh,p) end)
	end)
	Data.Changed:Connect(function(p,path) if path=="" then task.defer(function() Pet.Advance(p,os.time(),false);Pet.Refresh(p);penSig[p]=nil;Pet.Send(p) end) end end)
	Players.PlayerRemoving:Connect(function(p)
		if Data.IsLoaded(p) then Pet.Advance(p,os.time(),true);Data.Set(p,"Pets",Data.Get(p,"Pets")) end
		clearPen(p);mounts[p]=nil;lastAction[p]=nil;penSig[p]=nil
	end)
	game.ReplicatedStorage.FeatureFlags:GetAttributeChangedSignal("Eggs"):Connect(function() for _,p in Players:GetPlayers() do Pet.Refresh(p) end end)
	Net.Function("PetAction").OnServerInvoke=function(p,action,arg)
		if not enabled(p) then return false,"ระบบไข่และสัตว์ยังไม่เปิด" end
		local now=os.clock();if now-(lastAction[p] or -math.huge)<.3 then return false,"รอสักครู่" end;lastAction[p]=now
		local ok,msg,extra=false,"คำสั่งไม่ถูกต้อง",nil
		if action=="Sync" then Pet.Advance(p,os.time(),true);ok,msg=true,"พร้อมแล้ว"
		elseif action=="Place" and type(arg)=="table" then ok,msg=Pet.Place(p,arg.egg,arg.slot)
		elseif action=="Hatch" then ok,msg,extra=Pet.Hatch(p)
		elseif action=="Equip" then ok,msg=Pet.SetPlace(p,arg,"equip")
		elseif action=="Pen" then ok,msg=Pet.SetPlace(p,arg,"pen")
		elseif action=="Store" then ok,msg=Pet.SetPlace(p,arg,"")
		elseif action=="Fuse" then ok,msg,extra=Pet.Fuse(p,arg)
		elseif action=="Release" then ok,msg=Pet.Release(p,arg)
		elseif action=="Collect" then ok,msg=Pet.Collect(p)
		elseif action=="Upgrade" and type(arg)=="string" then ok,msg=Pet.Upgrade(p,arg)
		elseif action=="Buy" then ok,msg=Pet.Buy(p,arg)
		elseif action=="Mount" then ok,msg=Pet.Mount(p,arg)
		elseif action=="Dismount" then Pet.Dismount(p);ok,msg=true,"ลงจากหลังแล้ว" end
		Pet.Send(p);return ok,msg,extra
	end
end
function Pet.Start()
	task.spawn(function() while true do
		for _,p in Players:GetPlayers() do if Data.IsLoaded(p) then
			Pet.Advance(p,os.time(),true);renderPen(p);Pet.Send(p)
		end end
		task.wait(2)
	end end)
	task.spawn(function() while true do
		for _,p in Players:GetPlayers() do if Data.IsLoaded(p) then Pet.ApplySpeed(p) end end
		task.wait(.5)
	end end)
end
return Pet
