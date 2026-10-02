local Players=game:GetService("Players")
local Http=game:GetService("HttpService")
local Collection=game:GetService("CollectionService")
local Shared=game.ReplicatedStorage.Shared
local Net=require(Shared.Net)
local Loot=require(Shared.Loot)
local Weapons=require(Shared.Config.Weapons)
local Config=require(Shared.Config.Chests)
local Visual=require(Shared.WeaponVisual)
local ForestConfig=require(Shared.Config.Forest)
local Data=require(script.Parent.DataService)
local Features=require(script.Parent.FeatureService)
local CollectionMath=require(Shared.CollectionMath)
local Weapon={}
local rng=Random.new()
local lastRequest,freeTimers={},{}
local notifyRun=function() end
function Weapon.SetRunNotifier(fn) notifyRun=fn end

function Weapon.Equipped(player)
	local d=Data.GetData(player)
	return d and d.Inventory.Weapons[d.Inventory.Equipped]
end

function Weapon.Combat(player)
	local item=Features.IsEnabled("Chests") and Weapon.Equipped(player)
	local def=item and Weapons.ById[item.id]
	if not def then return {power=125,speed=1,area=0} end
	return {power=Loot.Power(item),speed=def.speed,area=def.area*(item.giant and 2 or 1)}
end

function Weapon.RefreshTool(player)
	if not Data.IsLoaded(player) then return end
	local char=player.Character;local bag=player:FindFirstChildOfClass("Backpack")
	local hum=char and char:FindFirstChildOfClass("Humanoid")
	if not char or not bag or not hum then return end
	local item=Weapon.Equipped(player)
	for _,container in {char,bag} do for _,tool in container:GetChildren() do
		if tool:IsA("Tool") and tool:GetAttribute("ForestAxe") then tool:Destroy() end
	end end
	if item and Weapons.ById[item.id] and Features.IsEnabled("Chests") then
		local tool=Visual.Build(Weapons.ById[item.id],item,false);tool.Parent=bag;hum:EquipTool(tool)
	elseif Data.Get(player,"Run.Active") then
		local tool=Instance.new("Tool");tool.Name="StarterAxe";tool.CanBeDropped=false;tool.ToolTip="Starter Axe";tool:SetAttribute("ForestAxe",true)
		local h=Instance.new("Part");h.Name="Handle";h.Size=ForestConfig.StarterVisual.Size;h.CanCollide=false;h.Massless=true;h.Parent=tool
		local mesh=Instance.new("SpecialMesh");mesh.MeshType=Enum.MeshType.FileMesh;mesh.MeshId=ForestConfig.StarterVisual.MeshId;mesh.TextureId=ForestConfig.StarterVisual.TextureId;mesh.Scale=ForestConfig.StarterVisual.Scale;mesh.Parent=h
		tool.Parent=bag;hum:EquipTool(tool)
	end
	notifyRun(player)
end

function Weapon.Chests(player)
	local stacks=Data.Get(player,"Inventory.Chests")
	local changed=false
	for _,s in stacks do if not s.uid then s.uid=Http:GenerateGUID(false);changed=true end end
	if changed then Data.Set(player,"Inventory.Chests",stacks) end
	return stacks
end

function Weapon.AtAltar(player)
	local char=player.Character;local hr=char and char:FindFirstChild("HumanoidRootPart")
	local hum=char and char:FindFirstChildOfClass("Humanoid")
	if not hr or not hum or hum.Health<=0 or Data.Get(player,"Run.Active") then return false end
	for _,altar in Collection:GetTagged("ChestAltar") do
		if altar:IsDescendantOf(workspace) and altar:IsA("Model") and altar.PrimaryPart and (hr.Position-altar.PrimaryPart.Position).Magnitude<=Config.AltarRange then return true end
	end
	return false
end

function Weapon.Open(player,uid)
	if not Data.IsLoaded(player) or not Features.IsEnabled("Chests") then return false,"Chests unavailable" end
	if type(uid)~="string" or not Weapon.AtAltar(player) then return false,"End your run, then visit the village chest station" end
	local inventory=Data.Get(player,"Inventory.Weapons");local count=0;for _ in inventory do count+=1 end
	if count>=Config.MaxWeapons then return false,"Inventory full. Fuse duplicate weapons first" end
	local chests=Weapon.Chests(player)
	local index,chest
	for i,s in chests do if s.uid==uid and s.count>0 then index,chest=i,s;break end end
	if not chest then return false,"Chest no longer available" end
	local luck=CollectionMath.Luck(Data.GetData(player),Features.IsEnabled("Rebirth"),Features.IsEnabled("IndexBonuses"),os.time(),game.ReplicatedStorage:GetAttribute("ServerLuckUntil"))
	local item=Loot.Roll(chest,rng,luck);local weaponUid=Http:GenerateGUID(false)
	-- No yields: consume exactly one chest and create exactly one weapon.
	chest.count-=1;if chest.count==0 then table.remove(chests,index) end
	inventory[weaponUid]=item
	Data.Set(player,"Inventory.Chests",chests);Data.Set(player,"Inventory.Weapons",inventory);Data.Increment(player,"Stats.ChestsOpened",1)
	require(script.Parent.GardenService).ChestDrop(player,chest)
	require(script.Parent.PetService).ChestDrop(player,chest)
	if Data.Get(player,"Inventory.Equipped")=="" then Data.Set(player,"Inventory.Equipped",weaponUid);Weapon.RefreshTool(player) end
	if item.giant then Net.Event("Notify"):FireAllClients({text=player.DisplayName.." Earned GIANT "..Weapons.ById[item.id].name.."!",color="Accent"}) end
	return true,"Chest opened",{uid=weaponUid,item=table.clone(item)}
end

function Weapon.Equip(player,uid)
	if not Data.IsLoaded(player) or not Features.IsEnabled("Chests") then return false,"Weapons unavailable" end
	if type(uid)~="string" or not Data.Get(player,"Inventory.Weapons")[uid] then return false,"Weapon not found in inventory" end
	Data.Set(player,"Inventory.Equipped",uid);Weapon.RefreshTool(player)
	return true,"Equipped"
end

function Weapon.Fuse(player,uids)
	if not Data.IsLoaded(player) or not Features.IsEnabled("Chests") then return false,"Weapons unavailable" end
	if not Weapon.AtAltar(player) then return false,"Fuse at the village station after ending your run" end
	if type(uids)~="table" or #uids~=3 then return false,"Requires 3 weapons" end
	local inv=Data.Get(player,"Inventory.Weapons");local seen={};local first
	for _,uid in uids do
		if type(uid)~="string" or seen[uid] or not inv[uid] then return false,"Missing or duplicate weapons" end
		seen[uid]=true;first=first or inv[uid]
		if not Loot.Compatible(first,inv[uid]) then return false,"Weapons must match type, IL, stars, Giant and Rot" end
	end
	if first.stars>=Config.MaxStars then return false,"Max 5 stars reached" end
	local cost=Loot.FuseCost(first)
	if Data.GetCurrency(player,"Wood")<cost then return false,"Wood Not enough" end
	local upgraded=table.clone(first);upgraded.stars+=1
	for _,uid in uids do if inv[uid].admin_spawned then upgraded.admin_spawned=true end end
	local output=uids[1];local equipped=Data.Get(player,"Inventory.Equipped")
	Data.AddCurrency(player,"Wood",-cost)
	for _,uid in uids do inv[uid]=nil end;inv[output]=upgraded
	Data.Set(player,"Inventory.Weapons",inv)
	if seen[equipped] then Data.Set(player,"Inventory.Equipped",output) end
	Weapon.RefreshTool(player)
	return true,"Fused to ★"..upgraded.stars,{uid=output,item=table.clone(upgraded)}
end

function Weapon.Delete(player,uid)
	if not Data.IsLoaded(player) or not Features.IsEnabled("Chests") then return false,"Weapons unavailable" end
	local inv=Data.Get(player,"Inventory.Weapons")
	if type(uid)~="string" or not inv[uid] then return false,"Weapon not found" end
	inv[uid]=nil;Data.Set(player,"Inventory.Weapons",inv)
	if Data.Get(player,"Inventory.Equipped")==uid then Data.Set(player,"Inventory.Equipped","");Weapon.RefreshTool(player) end
	return true,"Weapon deleted"
end

function Weapon.GrantChest(player,rarity,level,zone,count,admin)
	if not Data.IsLoaded(player) or not Config.Weights[rarity] then return false end
	local chests=Weapon.Chests(player)
	local rb=Data.Get(player,"Progress.Rebirth")
	for _,c in chests do if c.rarity==rarity and c.level==level and c.zone==zone and (c.rebirthDrop or 0)==rb and c.admin_spawned==admin then c.count+=count;Data.Set(player,"Inventory.Chests",chests);return true end end
	table.insert(chests,{uid=Http:GenerateGUID(false),rarity=rarity,level=level,zone=zone,count=count,rebirthDrop=rb,admin_spawned=admin})
	Data.Set(player,"Inventory.Chests",chests);return true
end

function Weapon.Grant(player,id,stars,giant)
	if not Data.IsLoaded(player) or not Weapons.ById[id] then return false end
	local inv=Data.Get(player,"Inventory.Weapons");local n=0;for _ in inv do n+=1 end
	if n>=Config.MaxWeapons then return false end
	local uid=Http:GenerateGUID(false)
	inv[uid]={id=id,il=1,stars=math.clamp(stars or 1,1,5),giant=giant==true,rebirthDrop=0,roll=1,admin_spawned=true}
	Data.Set(player,"Inventory.Weapons",inv);return true,uid
end

function Weapon.Init()
	Net.Function("InventoryAction").OnServerInvoke=function(player,action,arg)
		if not Data.IsLoaded(player) then return false,"Loading data" end
		local now=os.clock();if now-(lastRequest[player] or -math.huge)<.35 then return false,"Please wait" end;lastRequest[player]=now
		if action=="Open" then return Weapon.Open(player,arg)
		elseif action=="OpenTen" then
			if not (Data.Get(player,"Purchases.passes") or {}).OpenTen then return false,"Requires the Open Ten pass" end
			local n,ok,msg,last=0,true
			for _=1,10 do local r;ok,msg,r=Weapon.Open(player,arg);if not ok then break end;n+=1;last=r end
			if n==0 then return false,msg end
			return true,"Open Chest "..n.." eggs",last
		elseif action=="Equip" then return Weapon.Equip(player,arg)
		elseif action=="Fuse" then return Weapon.Fuse(player,arg)
		elseif action=="Delete" then return Weapon.Delete(player,arg)
		elseif action=="Sync" then Weapon.Chests(player);return true end
		return false,"Invalid command"
	end
	Data.PlayerLoaded:Connect(function(player)
		Weapon.Chests(player);freeTimers[player]=os.clock()+Config.FreeChestSeconds
		player.CharacterAdded:Connect(function(char) char:WaitForChild("Humanoid");task.defer(Weapon.RefreshTool,player) end)
		task.defer(Weapon.RefreshTool,player)
	end)
	Data.Changed:Connect(function(player,path)
		if path=="" then task.defer(Weapon.RefreshTool,player) end
	end)
	Players.PlayerRemoving:Connect(function(p) lastRequest[p]=nil;freeTimers[p]=nil end)
	game.ReplicatedStorage.FeatureFlags:GetAttributeChangedSignal("Chests"):Connect(function()
		for _,p in Players:GetPlayers() do Weapon.RefreshTool(p) end
	end)
	for _,altar in Collection:GetTagged("ChestAltar") do
		if altar:IsDescendantOf(workspace) and altar:IsA("Model") and altar.PrimaryPart then
			local prompt=altar.PrimaryPart:FindFirstChild("OpenChestsPrompt") or Instance.new("ProximityPrompt")
			prompt.Name="OpenChestsPrompt";prompt.ActionText="Open Chests / Fuse Weapons";prompt.ObjectText="CHEST ALTAR";prompt.MaxActivationDistance=Config.AltarRange;prompt.RequiresLineOfSight=false;prompt.Parent=altar.PrimaryPart
			prompt.Triggered:Connect(function(p) if Features.IsEnabled("Chests") then Net.Event("InventoryShow"):FireClient(p) end end)
		end
	end
end

function Weapon.Start()
	task.spawn(function() while true do
		for p,due in freeTimers do if Features.IsEnabled("Chests") and os.clock()>=due then
			Weapon.GrantChest(p,"Common",1,1,1,false);freeTimers[p]=os.clock()+Config.FreeChestSeconds
			Net.Event("Notify"):FireClient(p,{text="Free 15-minute chest received! Open at the village station",color="Green"})
		end end
		task.wait(5)
	end end)
end
return Weapon
