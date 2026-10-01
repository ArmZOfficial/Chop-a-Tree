local Players=game:GetService("Players")
local Collection=game:GetService("CollectionService")
local Http=game:GetService("HttpService")
local Shared=game.ReplicatedStorage.Shared
local Seeds=require(Shared.Config.Seeds)
local Config=require(Shared.Config.Garden)
local Math=require(Shared.GardenMath)
local Balance=require(Shared.Balance)
local Mutations=require(Shared.Config.Mutations)
local Net=require(Shared.Net)
local Data=require(script.Parent.DataService)
local Features=require(script.Parent.FeatureService)
local Weather=require(script.Parent.WeatherService)
local Garden={}
local bases,owners,slots,visuals,signatures,lastAction={},{},{},{},{},{}
local rng=Random.new()

local function enabled(p) return Data.IsLoaded(p) and Features.IsEnabled("Garden") end
local function root(p)
	local char=p.Character;local hum=char and char:FindFirstChildOfClass("Humanoid")
	return hum and hum.Health>0 and char:FindFirstChild("HumanoidRootPart")
end
local function near(p,part,range)
	local hr=root(p);return hr and part and (hr.Position-part.Position).Magnitude<=range and not Data.Get(p,"Run.Active")
end
function Garden.Base(p) return bases[owners[p]] end
function Garden.BaseIndex(p) return owners[p] end
function Garden.BaseById(id) return bases[id] end
function Garden.OwnerOf(id) for p,b in owners do if b==id then return p end end end
function Garden.NearBase(p) local b=Garden.Base(p);return b and near(p,b.PrimaryPart,Config.BaseRange) end
function Garden.NearSlot(p,index)
	return owners[p] and slots[owners[p]][index] and near(p,slots[owners[p]][index],Config.PlotRange)
end
local function shopPart()
	for _,m in Collection:GetTagged("Shop") do if m:GetAttribute("ShopType")=="SeedShop" and m:IsDescendantOf(workspace) then return m.PrimaryPart end end
end

function Garden.GrantSeed(p,id,zone,rebirth,count,admin)
	if not Data.IsLoaded(p) or not Seeds.ById[id] then return false end
	admin=admin==true
	local inv=Data.Get(p,"Inventory.Seeds")
	for uid,s in inv do if s.id==id and s.zone==zone and s.rebirthDrop==rebirth and s.admin_spawned==admin then s.count+=count;Data.Set(p,"Inventory.Seeds",inv);return true,uid end end
	local uid=Http:GenerateGUID(false);inv[uid]={id=id,zone=zone,rebirthDrop=rebirth,count=count,admin_spawned=admin==true}
	Data.Set(p,"Inventory.Seeds",inv);return true,uid
end
function Garden.RollSeed(tier)
	local pool={};for _,s in Seeds.List do if s.tier<=tier then table.insert(pool,s) end end
	return pool[rng:NextInteger(1,#pool)].id
end
function Garden.TreeDrop(p,zone,tier,auto)
	if enabled(p) and rng:NextNumber()<Config.TreeSeedChance*(auto and Balance.Get("AutoCutReward") or 1) then
		local run=Data.Get(p,"Run");run.Seeds=run.Seeds or {}
		local id=Garden.RollSeed(tier)
		for _,s in run.Seeds do if s.id==id and s.zone==zone and s.rebirthDrop==Data.Get(p,"Progress.Rebirth") then s.count+=1;return end end
		table.insert(run.Seeds,{id=id,zone=zone,rebirthDrop=Data.Get(p,"Progress.Rebirth"),count=1,admin_spawned=Data.Get(p,"Meta.AdminTouched")})
	end
end
function Garden.ChestDrop(p,chest)
	if enabled(p) and rng:NextNumber()<Config.ChestSeedChance then Garden.GrantSeed(p,Garden.RollSeed(6),chest.zone,chest.rebirthDrop or 0,1,chest.admin_spawned==true) end
end

function Garden.Shop(now)
	local epoch=math.floor(now/Config.RestockSeconds);local random=Random.new((epoch*69621+40261001)%2147483647)
	local out={}
	for _,s in Seeds.List do local n=0;if random:NextNumber()<s.stockChance then n=random:NextInteger(s.stockMin,s.stockMax) end;out[s.id]=n end
	return out,epoch,(epoch+1)*Config.RestockSeconds
end
local function shopZone(p)
	local zone=1;for _,z in Data.Get(p,"Progress.UnlockedZones") do zone=math.max(zone,z) end;return zone
end
function Garden.Buy(p,id)
	if not enabled(p) or not Seeds.ById[id] or not near(p,shopPart(),Config.ShopRange) then return false,"ซื้อเมล็ดที่ร้านในหมู่บ้าน" end
	local stock,epoch=Garden.Shop(os.time());local data=Data.Get(p,"Garden")
	if data.shopEpoch~=epoch then data.shopEpoch=epoch;data.bought={} end
	if (data.bought[id] or 0)>=stock[id] then return false,"เมล็ดหมด รอรีสต็อก" end
	local zone=shopZone(p);local price=Math.SeedPrice(id,zone)
	if Data.GetCurrency(p,"Coins")<price then return false,"Coins ไม่พอ" end
	Data.AddCurrency(p,"Coins",-price);data.bought[id]=(data.bought[id] or 0)+1;Data.Set(p,"Garden",data)
	Garden.GrantSeed(p,id,zone,Data.Get(p,"Progress.Rebirth"),1,false)
	return true,"ซื้อเมล็ดแล้ว"
end
function Garden.Plant(p,index,uid)
	if not enabled(p) or type(index)~="number" or index%1~=0 or index<1 or index>Data.Get(p,"Garden.slots") or not Garden.NearSlot(p,index) then return false,"ไปที่ช่องสวนของตัวเองก่อน" end
	local data=Data.Get(p,"Garden");local key=tostring(index);local inv=Data.Get(p,"Inventory.Seeds");local seed=type(uid)=="string" and inv[uid]
	if data.plots[key] or not seed or seed.count<1 then return false,"ช่องไม่ว่างหรือไม่มีเมล็ด" end
	data.plots[key]={id=seed.id,zone=seed.zone,rebirthDrop=seed.rebirthDrop,progress=0,updatedAt=os.time(),mature=false,watered=false,nextFruitAt=0,mutations={},admin_spawned=seed.admin_spawned}
	seed.count-=1;if seed.count==0 then inv[uid]=nil end
	Data.Set(p,"Inventory.Seeds",inv);Data.Set(p,"Garden",data);Data.Increment(p,"Stats.SeedsPlanted",1);return true,"ปลูกแล้ว"
end
function Garden.Advance(p,now,online)
	local data=Data.Get(p,"Garden");if not data then return end
	local state=Weather.State();local weather=Weather.Def()
	for _,plot in data.plots do
		Math.Advance(plot,now,weather.growth,online)
		if online and plot.mature and plot.nextFruitAt<=now and weather.mutation and plot.weatherSeen~=state.eventKey then
			plot.weatherSeen=state.eventKey
			if rng:NextNumber()<weather.chance then Math.Apply(plot.mutations,weather.mutation) end
		end
	end
end
function Garden.Water(p,index)
	if not enabled(p) or not Garden.NearSlot(p,index) then return false,"อยู่ใกล้ต้นไม้ในสวนตัวเองก่อน" end
	Garden.Advance(p,os.time(),true)
	local data=Data.Get(p,"Garden");local plot=data.plots[tostring(index)]
	if not plot or plot.mature or plot.watered then return false,"รดได้ครั้งเดียวก่อนโตเต็ม" end
	plot.watered=true;Data.Set(p,"Garden",data);return true,"รดน้ำแล้ว — โตไว +10%"
end
function Garden.Harvest(p,index)
	if not enabled(p) or not Garden.NearSlot(p,index) then return false,"เก็บจากสวนตัวเองเท่านั้น" end
	Garden.Advance(p,os.time(),true)
	local data=Data.Get(p,"Garden");local plot=data.plots[tostring(index)]
	if not plot or not plot.mature or plot.nextFruitAt>os.time() then return false,"ผลยังไม่พร้อม" end
	local fruits=Data.Get(p,"Inventory.Fruits");local count=0;local match
	for uid,f in fruits do count+=1;if f.id==plot.id and f.zone==plot.zone and f.rebirthDrop==plot.rebirthDrop and Math.Key(f.mutations)==Math.Key(plot.mutations) and f.admin_spawned==plot.admin_spawned then match=uid end end
	if not match and count>=Config.MaxFruitStacks then return false,"กระเป๋าผลเต็ม — ขายผลก่อน" end
	local def=Seeds.ById[plot.id]
	if match then fruits[match].count+=def.yield else fruits[Http:GenerateGUID(false)]={id=plot.id,zone=plot.zone,rebirthDrop=plot.rebirthDrop,mutations=table.clone(plot.mutations),count=def.yield,admin_spawned=plot.admin_spawned} end
	plot.nextFruitAt=os.time()+def.fruitTime;plot.mutations={}
	Data.Set(p,"Inventory.Fruits",fruits);Data.Set(p,"Garden",data);Data.Increment(p,"Stats.Harvests",1);return true,"เก็บผลแล้ว ต้นเดิมจะออกผลใหม่"
end
function Garden.Sell(p)
	if not enabled(p) or not near(p,shopPart(),Config.ShopRange) then return false,"ขายผลที่ร้านเมล็ดในหมู่บ้าน" end
	local fruits=Data.Get(p,"Inventory.Fruits");local total=0
	for _,f in fruits do total+=Math.Value(f)*f.count end
	if total<=0 then return false,"ยังไม่มีผลให้ขาย" end
	Data.Set(p,"Inventory.Fruits",{});Data.AddCurrency(p,"Coins",total);return true,"ขายผลแล้ว +"..total.." Coins"
end
function Garden.Cut(p,index)
	if not enabled(p) or not Garden.NearSlot(p,index) then return false,"อยู่ใกล้สวนตัวเองก่อน" end
	Garden.Advance(p,os.time(),true);local data=Data.Get(p,"Garden");local plot=data.plots[tostring(index)]
	if not plot or not plot.mature then return false,"ตัดได้เมื่อต้นโตเต็มเท่านั้น" end
	local wood=Seeds.ById[plot.id].wood*Balance.ZoneScale(plot.zone)*Balance.Rot(plot.rebirthDrop)
	data.plots[tostring(index)]=nil;Data.Set(p,"Garden",data);Data.AddCurrency(p,"Wood",wood)
	if rng:NextNumber()<Config.CutSeedChance then Garden.GrantSeed(p,Garden.RollSeed(6),plot.zone,plot.rebirthDrop,1,plot.admin_spawned) end
	return true,"ตัดต้นไม้แล้ว +"..wood.." Wood"
end
function Garden.Upgrade(p)
	if not enabled(p) or not Garden.NearBase(p) then return false,"อัปเกรดที่ฐานตัวเอง" end
	local data=Data.Get(p,"Garden");local price=Math.UpgradeCost(data.slots)
	if data.slots>=Config.MaxSlots then return false,"สูงสุด 30 ช่องแล้ว" end
	if Data.GetCurrency(p,"Wood")<price then return false,"Wood ไม่พอ" end
	Data.AddCurrency(p,"Wood",-price);data.slots=math.min(Config.MaxSlots,data.slots+Config.UpgradeStep);Data.Set(p,"Garden",data);return true,"เพิ่มช่องสวนแล้ว"
end
function Garden.ExpBuff()
	if not Features.IsEnabled("Garden") then return 1 end
	local buff=0
	for _,p in Players:GetPlayers() do local d=Data.Get(p,"Garden");if d then for _,plot in d.plots do buff+=Seeds.ById[plot.id].expBuff or 0 end end end
	return 1+math.min(Config.MaxExpBuff,buff)
end

local function actor(p,index,plot,part)
	local folder=visuals[p];local old=folder:FindFirstChild("Plant"..index);if old then old:Destroy() end
	if not plot then return end
	local def=Seeds.ById[plot.id];local scale=math.clamp(plot.progress/def.grow,.1,1)
	local m=Instance.new("Model");m.Name="Plant"..index;m:SetAttribute("OwnerUserId",p.UserId);m:SetAttribute("Slot",index);m.Parent=folder
	local origin=part.Position+Vector3.new(0,.4,0)
	local function piece(name,size,offset,color,ball)
		local x=Instance.new("Part");x.Name=name;x.Size=size*scale;x.Position=origin+offset*scale;x.Anchored=true;x.CanCollide=false;x.CanQuery=false;x.Color=color;x.Material=Enum.Material.SmoothPlastic;if ball then x.Shape=Enum.PartType.Ball end;x.Parent=m;return x
	end
	local trunk=piece("Trunk",Vector3.new(.45,3.4,.45),Vector3.new(0,1.7,0),Color3.fromRGB(117,80,49))
	piece("Leaves",Vector3.new(3,2.2,3),Vector3.new(0,3.5,0),Color3.fromRGB(99,187,94),true)
	if plot.mature and plot.nextFruitAt<=os.time() then
		local color=def.color;for id in plot.mutations do color=Mutations.Colors[id] or color end
		for i=1,3 do piece("Fruit",Vector3.new(.7,.7,.7),Vector3.new(math.cos(i*2)*1.2,3,math.sin(i*2)*1.2),color,true) end
	end
	m.PrimaryPart=trunk
	local b=Instance.new("BillboardGui");b.Size=UDim2.fromOffset(145,38);b.StudsOffset=Vector3.new(0,4.4,0);b.MaxDistance=50;b.Parent=trunk
	local l=Instance.new("TextLabel");l.Size=UDim2.fromScale(1,1);l.BackgroundTransparency=1;l.TextColor3=Color3.new(1,1,1);l.TextStrokeTransparency=0;l.TextSize=13;l.Text=def.name.."\n"..(plot.mature and (plot.nextFruitAt<=os.time() and "เก็บผลได้ • "..Math.Key(plot.mutations) or "รอผลรอบใหม่") or (math.floor(scale*100).."%"));l.Parent=b
end
function Garden.Render(p)
	local data=Data.Get(p,"Garden");local id=owners[p];if not id or not data then return end
	for index,part in slots[id] do
		part.Transparency=index<=data.slots and 0 or .7
		local plot=data.plots[tostring(index)]
		local sig=plot and (plot.id..math.floor(plot.progress/Seeds.ById[plot.id].grow*20)..tostring(plot.mature)..tostring(plot.nextFruitAt<=os.time())..Math.Key(plot.mutations)) or "empty"
		if signatures[p][index]~=sig then signatures[p][index]=sig;actor(p,index,plot,part) end
	end
end
function Garden.Send(p)
	if not Data.IsLoaded(p) or not p.Parent then return end
	Garden.Render(p)
	local stock,epoch,restock=Garden.Shop(os.time());local data=Data.Get(p,"Garden");local available={}
	for id,n in stock do available[id]=math.max(0,n-(data.shopEpoch==epoch and (data.bought[id] or 0) or 0)) end
	local plots={};for k,v in data.plots do plots[k]=table.clone(v);plots[k].mutations=table.clone(v.mutations) end
	Net.Event("GardenState"):FireClient(p,{base=owners[p],slots=data.slots,plots=plots,seeds=Data.Get(p,"Inventory.Seeds"),fruits=Data.Get(p,"Inventory.Fruits"),stock=available,shopZone=shopZone(p),restockAt=restock,now=os.time(),upgrade=Math.UpgradeCost(data.slots)})
end

function Garden.MatureAll(p)
	local d=Data.Get(p,"Garden");if not d then return end
	for _,plot in d.plots do plot.mature=true;plot.progress=Seeds.ById[plot.id].grow;plot.nextFruitAt=os.time();plot.admin_spawned=true end
	Data.Set(p,"Garden",d);Garden.Send(p)
end
function Garden.MutateAll(p,id)
	local d=Data.Get(p,"Garden");if not d or not Mutations.Values[id] then return end
	for _,plot in d.plots do if plot.mature then Math.Apply(plot.mutations,id);plot.admin_spawned=true end end
	Data.Set(p,"Garden",d);Garden.Send(p)
end
local function wateringTool(p)
	local bag=p:FindFirstChildOfClass("Backpack");if not bag then return end
	if bag:FindFirstChild("WateringCan") or (p.Character and p.Character:FindFirstChild("WateringCan")) then return end
	local tool=Instance.new("Tool");tool.Name="WateringCan";tool.CanBeDropped=false;tool.ToolTip="รดน้ำต้นอ่อนในสวน +10%";tool:SetAttribute("GardenWater",true)
	local h=Instance.new("Part");h.Name="Handle";h.Size=Vector3.new(1.2,1.1,1);h.Color=Color3.fromRGB(54,189,178);h.CanCollide=false;h.Massless=true;h.Parent=tool;tool.Parent=bag
end
function Garden.Assign(p)
	if owners[p] then return end
	for id=1,7 do local b=bases[id];if b and b:GetAttribute("OwnerUserId")==0 then
		owners[p]=id;b:SetAttribute("OwnerUserId",p.UserId);p:SetAttribute("BaseIndex",id)
		local folder=Instance.new("Folder");folder.Name="GardenPlants";folder.Parent=b;visuals[p]=folder;signatures[p]={}
		for _,part in slots[id] do part:SetAttribute("OwnerUserId",p.UserId) end
		for _,l in b.OwnerSign:GetDescendants() do if l:IsA("TextLabel") then l.Text="สวน "..p.DisplayName end end
		return
	end end
end
function Garden.Release(p)
	local id=owners[p];if id then local b=bases[id];b:SetAttribute("OwnerUserId",0);for _,part in slots[id] do part:SetAttribute("OwnerUserId",0) end;for _,l in b.OwnerSign:GetDescendants() do if l:IsA("TextLabel") then l.Text="ฐาน "..id.." · ว่าง" end end end
	if visuals[p] then visuals[p]:Destroy() end;owners[p]=nil;visuals[p]=nil;signatures[p]=nil;lastAction[p]=nil
end
function Garden.Init()
	for _,b in Collection:GetTagged("PlayerBase") do if b:IsDescendantOf(workspace) then
		local id=b:GetAttribute("BaseIndex");bases[id]=b;slots[id]={};b:SetAttribute("OwnerUserId",0)
		for _,old in b.GardenPlot:GetChildren() do if old:IsA("BasePart") then old.Transparency=1;old.CanQuery=false;old.CanCollide=false end end
		local grid=Instance.new("Folder");grid.Name="GardenSlots";grid.Parent=b
		for i=1,Config.MaxSlots do
			local part=Instance.new("Part");part.Name="Slot"..i;part.Size=Vector3.new(3.5,.8,3.5);part.CFrame=b.PrimaryPart.CFrame*CFrame.new(((i-1)%6-2.5)*7.8,.8,6+math.floor((i-1)/6)*3.8);part.Color=Color3.fromRGB(112,74,42);part.Material=Enum.Material.Ground;part.Anchored=true;part.CanCollide=false;part.Transparency=i<=6 and 0 or .7
			part:SetAttribute("BaseIndex",id);part:SetAttribute("SlotIndex",i);part:SetAttribute("OwnerUserId",0);part:SetAttribute("RuntimeGarden",true);part.Parent=grid;Collection:AddTag(part,"GardenSlot");slots[id][i]=part
		end
		local prompt=Instance.new("ProximityPrompt");prompt.Name="GardenPrompt";prompt.ActionText="สวนของฉัน";prompt.ObjectText="GARDEN";prompt.RequiresLineOfSight=false;prompt.MaxActivationDistance=24;prompt.Parent=b.BaseSpawn
		prompt.Triggered:Connect(function(p) if owners[p]==id and enabled(p) then Net.Event("GardenShow"):FireClient(p,"Garden");Garden.Send(p) end end)
	end end
	local shop=shopPart();if shop then
		local prompt=Instance.new("ProximityPrompt");prompt.Name="SeedShopPrompt";prompt.ActionText="ซื้อเมล็ด / ขายผล";prompt.ObjectText="SEED SHOP";prompt.RequiresLineOfSight=false;prompt.MaxActivationDistance=Config.ShopRange;prompt.Parent=shop
		prompt.Triggered:Connect(function(p) if enabled(p) then Net.Event("GardenShow"):FireClient(p,"Shop");Garden.Send(p) end end)
	end
	Data.PlayerLoaded:Connect(function(p)
		Garden.Assign(p);Garden.Advance(p,os.time(),false)
		if not Data.Get(p,"Garden.starterGiven") then Garden.GrantSeed(p,"seed_sunapple",1,0,3,false);Data.Set(p,"Garden.starterGiven",true) end
		Data.Set(p,"Garden",Data.Get(p,"Garden"));Garden.Send(p);wateringTool(p)
		p.CharacterAdded:Connect(function(char) task.spawn(function() char:WaitForChild("Humanoid",5);p:WaitForChild("Backpack",5);wateringTool(p) end) end)
	end)
	Data.Changed:Connect(function(p,path) if path=="" then task.defer(function() Garden.Advance(p,os.time(),false);signatures[p]={};Garden.Send(p) end) end end)
	Players.PlayerRemoving:Connect(function(p) if Data.IsLoaded(p) then Garden.Advance(p,os.time(),true);Data.Set(p,"Garden",Data.Get(p,"Garden")) end;Garden.Release(p) end)
	Net.Function("GardenAction").OnServerInvoke=function(p,action,arg)
		if not enabled(p) then return false,"ระบบสวนยังไม่เปิด" end
		local now=os.clock();if now-(lastAction[p] or -math.huge)<.3 then return false,"รอสักครู่" end;lastAction[p]=now
		local ok,msg=false,"คำสั่งไม่ถูกต้อง"
		if action=="Sync" then Garden.Advance(p,os.time(),true);ok=true;msg="สวนพร้อมแล้ว"
		elseif action=="Buy" and type(arg)=="string" then ok,msg=Garden.Buy(p,arg)
		elseif action=="Plant" and type(arg)=="table" then ok,msg=Garden.Plant(p,arg.slot,arg.seed)
		elseif action=="Water" and type(arg)=="number" then ok,msg=Garden.Water(p,arg)
		elseif action=="Harvest" and type(arg)=="number" then ok,msg=Garden.Harvest(p,arg)
		elseif action=="Cut" and type(arg)=="number" then ok,msg=Garden.Cut(p,arg)
		elseif action=="Sell" then ok,msg=Garden.Sell(p)
		elseif action=="Upgrade" then ok,msg=Garden.Upgrade(p) end
		Garden.Send(p);return ok,msg
	end
end
function Garden.Start() task.spawn(function() while true do
	if Features.IsEnabled("Garden") then for _,p in Players:GetPlayers() do if Data.IsLoaded(p) then Garden.Advance(p,os.time(),true);Garden.Send(p) end end end
	task.wait(2)
end end) end
return Garden
