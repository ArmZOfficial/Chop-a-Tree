local Players=game:GetService("Players")
local Shared=game.ReplicatedStorage:WaitForChild("Shared")
local Net=require(Shared.Net)
local UI=require(Shared.UIKit)
local NF=require(Shared.NumberFormat)
local Loot=require(Shared.Loot)
local Visual=require(Shared.WeaponVisual)
local Weapons=require(Shared.Config:FindFirstChild("WeaponCatalog") or Shared.Config.Weapons)
local Rarities=require(Shared.Config.Rarities)
local Config=require(Shared.Config.Chests)
local Encounters=require(Shared.Config.WeatherEncounters)
local Data=require(script.Parent.ClientData)
local CollectionMath=require(Shared.CollectionMath)
local Inventory={}
local player=Players.LocalPlayer

function Inventory.Start()
	local gui=UI.New("ScreenGui",{Name="InventoryHUD",ResetOnSpawn=false,DisplayOrder=8,Parent=player:WaitForChild("PlayerGui")})
	local panel=UI.New("Frame",{Name="Panel",AnchorPoint=Vector2.new(.5,.5),Position=UDim2.fromScale(.5,.5),Size=UDim2.fromOffset(960,650),BackgroundColor3=UI.Colors.Panel,Visible=false,Parent=gui},{UI.Corner(18),UI.Stroke(4),UI.Padding(14)})
	local title=UI.Label("Inventory • Chests & Weapons",22,{Name="Title",Parent=panel})
	local message=UI.Label("Open chests and fuse at the village station",14,{Position=UDim2.fromOffset(72,40),Size=UDim2.new(1,-72,0,20),Parent=panel})
	local tab="Weapons";local selected,pendingSelection,pendingFuse,pendingDelete;local busy=false
	local body=UI.New("Frame",{Name="Body",BackgroundTransparency=1,Position=UDim2.fromOffset(0,112),Size=UDim2.new(1,0,1,-176),Parent=panel})
	local function list(name)
		return UI.New("ScrollingFrame",{Name=name,BackgroundTransparency=1,Size=UDim2.fromScale(1,1),AutomaticCanvasSize=Enum.AutomaticSize.Y,CanvasSize=UDim2.new(),ScrollBarThickness=5,Parent=body},{UI.List(Enum.FillDirection.Vertical,8)})
	end
	local chestList=list("Chests");local weaponList=list("Weapons")
    weaponList:FindFirstChildOfClass("UIListLayout"):Destroy();UI.Grid(4,168,10).Parent=weaponList
    local selection=UI.New("Frame",{Name="Selection",BackgroundColor3=UI.Colors.PanelDark,Size=UDim2.new(.24,-10,1,0),Parent=body},{UI.Corner(12),UI.Stroke(3,UI.Colors.Rail)})
    UI.Skin(selection,"detail","detailPanel")
    local selectionView=UI.New("ViewportFrame",{Name="Preview",BackgroundTransparency=1,Position=UDim2.fromOffset(8,8),Size=UDim2.new(1,-16,0,210),Ambient=Color3.new(1,1,1),Parent=selection})
	local details=UI.Label("Select a weapon to equip or fuse duplicates",15,{Name="Details",Position=UDim2.fromOffset(12,225),Size=UDim2.new(1,-24,1,-230),Parent=selection})
	local buttons=UI.New("Frame",{Name="Actions",BackgroundTransparency=1,Position=UDim2.new(0,0,1,-49),Size=UDim2.new(1,0,0,49),Parent=panel})
	local result=UI.New("Frame",{Name="Result",Active=true,AnchorPoint=Vector2.new(.5,.5),Position=UDim2.fromScale(.5,.5),Size=UDim2.fromOffset(380,365),BackgroundColor3=UI.Colors.PanelDark,Visible=false,ZIndex=20,Parent=gui},{UI.Corner(20),UI.Stroke(4),UI.Padding(18)})
	local resultLabel=UI.Label("Opening chest...",20,{Name="Reward",Position=UDim2.fromOffset(0,190),Size=UDim2.new(1,0,0,90),TextXAlignment=Enum.TextXAlignment.Center,ZIndex=21,Parent=result})
	local resultView=UI.New("ViewportFrame",{Name="Preview",BackgroundTransparency=1,Size=UDim2.new(1,0,0,185),ZIndex=21,Ambient=Color3.fromRGB(220,220,220),LightColor=Color3.new(1,1,1),Parent=result})
	local function preview(view,def,item)
		view:ClearAllChildren()
        local illustration=UI.Art(view,"weapons",def.id,{Size=UDim2.fromScale(1,1)})
        if illustration then return end
		local world=Instance.new("WorldModel");world.Parent=view
		local model=Visual.Build(def,item,true);model.Parent=world
		local cf,size=model:GetBoundingBox()
		local camera=Instance.new("Camera");camera.FieldOfView=35;camera.CFrame=CFrame.lookAt(cf.Position+Vector3.new(size.X*.3,size.Y*.15,math.max(size.Magnitude,4)*1.45),cf.Position);camera.Parent=view;view.CurrentCamera=camera
	end
	local render,resize
	local function request(action,arg)
		if busy then return false end
		busy=true
		local ok,success,text,extra=pcall(function() return Net.Function("InventoryAction"):InvokeServer(action,arg) end)
		busy=false
		if not ok then message.Text="Connection failed. Try again";return false end
		message.Text=text or (success and "Done" or "Try again")
		if success and extra then selected=extra.uid;pendingSelection=extra.uid end
		render()
		return success,extra
	end
	local function showReward(reward)
		if not reward then return end
		busy=true;result.Visible=true
		local def=Weapons.ById[reward.item.id]
		for i=1,12 do
			local candidate=Weapons.List[math.random(1,#Weapons.List)]
			preview(resultView,candidate,{giant=false});resultLabel.Text=candidate.name
			task.wait(.03+i*.008)
		end
		preview(resultView,def,reward.item)
		resultLabel.Text=(reward.item.giant and "GIANT!\n" or "")..def.name.."\n"..def.rarity.." • IL "..reward.item.il.." • Power "..NF.Short(Loot.Power(reward.item))
		resultLabel.TextColor3=Rarities.Color[def.rarity]:Lerp(Color3.new(1,1,1),.25)
		if reward.item.giant then
			local hum=player.Character and player.Character:FindFirstChildOfClass("Humanoid")
			if hum then local original=hum.CameraOffset;for _=1,8 do hum.CameraOffset=original+Vector3.new(math.random()-.5,math.random()-.5,0);task.wait(.04) end;hum.CameraOffset=original end
		end
		busy=false
	end
	local closeResult=UI.Button({text="Added to inventory • Close",color=UI.Colors.Green,size=UDim2.new(1,0,0,48),onClick=function() if not busy then result.Visible=false end end})
	closeResult.Name="Close";closeResult.Position=UDim2.new(0,0,1,-48);closeResult.Parent=result
	closeResult.ZIndex=22;for _,g in closeResult:GetDescendants() do if g:IsA("GuiObject") then g.ZIndex=22 end end
	local function compatibleIds()
		local inv=Data.Get("Inventory.Weapons") or {};local item=inv[selected];local ids={}
		if item then for uid,w in inv do if uid~=selected and Loot.Compatible(item,w) then table.insert(ids,uid) end end end
		table.sort(ids);if #ids>=2 then return {selected,ids[1],ids[2]} end
	end
	local equip=UI.Button({text="Equip",color=UI.Colors.Green,size=UDim2.new(.25,-6,1,0),onClick=function() if selected then request("Equip",selected) end end})
	equip.Name="Equip";equip.Parent=buttons
	local fuse=UI.Button({text="Fuse ×3",color=UI.Colors.Orange,size=UDim2.new(.25,-6,1,0),onClick=function()
		local ids=compatibleIds();if not ids then message.Text="Requires 3 weapons with matching type, IL, stars, Giant and Rot";return end
		local key=table.concat(ids,"|")
		if pendingFuse~=key then pendingFuse=key;message.Text="Click Fuse again to use 3 items and the Wood shown below";return end
		pendingFuse=nil;request("Fuse",ids)
	end})
	fuse.Name="Fuse";fuse.Position=UDim2.fromScale(.25,0);fuse.Parent=buttons
	local delete=UI.Button({text="Delete",color=UI.Colors.Red,size=UDim2.new(.25,-6,1,0),onClick=function()
		if not selected or busy then return end
		if pendingDelete~=selected then pendingDelete=selected;message.Text="Click Delete again to permanently remove this weapon";return end
		local uid=selected;pendingDelete=nil;request("Delete",uid)
	end})
	delete.Name="Delete";delete.Position=UDim2.fromScale(.5,0);delete.Parent=buttons
	local close=UI.Button({text="Close",color=UI.Colors.Blue,size=UDim2.new(.25,-6,1,0),onClick=function() panel.Visible=false;pendingFuse=nil;pendingDelete=nil end})
	close.Name="Close";close.Position=UDim2.fromScale(.75,0);close.Parent=buttons
	for i,name in {"Weapons","Chests"} do
		local holder=UI.Button({text=name=="Weapons" and "Weapons" or "Chests",color=name=="Weapons" and UI.Colors.Blue or UI.Colors.Orange,size=UDim2.new(.5,-6,0,46),onClick=function() tab=name;resize() end})
		holder.Name=name.."Tab";holder.Position=UDim2.new((i-1)*.5,0,0,62);holder.Parent=panel
	end
	local function clear(frame)
		for _,child in frame:GetChildren() do if child:IsA("GuiObject") then child:Destroy() end end
	end
	render=function()
		if not Data.IsReady() then return end
		local inv=Data.Get("Inventory.Weapons") or {};local chests=Data.Get("Inventory.Chests") or {};local equipped=Data.Get("Inventory.Equipped")
		clear(weaponList);clear(chestList)
		local ids={};for uid in inv do table.insert(ids,uid) end
		table.sort(ids,function(a,b) local pa,pb=Loot.Power(inv[a]),Loot.Power(inv[b]);return pa==pb and a<b or pa>pb end)
		title.Text="Inventory • Weapons "..#ids.." / "..Config.MaxWeapons
		-- The function response and DataPatch events can arrive in either order.
		if pendingSelection and inv[pendingSelection] then pendingSelection=nil end
		if selected and not inv[selected] and selected~=pendingSelection then selected=nil;pendingFuse=nil end
		for i,uid in ids do
			local item=inv[uid];local def=Weapons.ById[item.id]
			if def then
				local row=UI.New("TextButton",{Name="Item_"..uid,Size=UDim2.fromOffset(130,142),BackgroundColor3=Rarities.Color[def.rarity]:Lerp(Color3.new(0,0,0),.3),Text="",AutoButtonColor=true,LayoutOrder=i,Parent=weaponList},{UI.Corner(10),UI.Stroke(selected==uid and 4 or 2,selected==uid and UI.Colors.Orange or UI.Colors.Outline)})
				UI.Skin(row,"cards",selected==uid and "selected" or string.lower(def.rarity))
				local view=UI.New("ViewportFrame",{BackgroundTransparency=1,Position=UDim2.fromOffset(8,35),Size=UDim2.new(1,-16,0,94),Ambient=Color3.new(1,1,1),Parent=row});preview(view,def,item)
				UI.Label((equipped==uid and "✓ " or "")..(item.giant and "GIANT " or "")..def.name,14,{Position=UDim2.fromOffset(3,2),Size=UDim2.new(1,-6,0,32),TextXAlignment=Enum.TextXAlignment.Center,Parent=row})
				UI.Label(def.rarity.." • IL "..item.il.." • ★"..item.stars.."\nPower "..NF.Short(Loot.Power(item)),13,{Position=UDim2.fromOffset(3,130),Size=UDim2.new(1,-6,0,35),TextXAlignment=Enum.TextXAlignment.Center,TextColor3=Color3.new(1,1,1),Parent=row})
				row.Activated:Connect(function() selected=uid;pendingSelection=nil;pendingFuse=nil;pendingDelete=nil;render() end)
			end
		end
		if #ids==0 then UI.Label("No weapons yet. Collect forest chests, then open them in the village",16,{Size=UDim2.new(1,-10,0,80),Parent=weaponList}) end
		if game.ReplicatedStorage.FeatureFlags:GetAttribute("WeatherEncounters")==true then
			local dust=Data.Get("Currencies.Stardust") or 0
			local exchange=UI.Button({text="Stardust "..dust.." • Exchange "..Encounters.ChestDust.." = Rare",color=UI.Colors.Purple,size=UDim2.new(1,-8,0,48),onClick=function()
				local success,ok,msg=pcall(function() return Net.Function("EncounterAction"):InvokeServer("Exchange") end)
				message.Text=success and msg or "Connection failed";render()
			end});exchange.Name="DustExchange";exchange.LayoutOrder=0;exchange.Parent=chestList
		end
		for i,c in chests do
			local row=UI.New("Frame",{Name="Chest_"..tostring(c.uid),BackgroundColor3=UI.Colors.PanelDark,Size=UDim2.new(1,-8,0,124),LayoutOrder=i,Parent=chestList},{UI.Corner(10),UI.Padding(8)})
			UI.Label(c.rarity.." • LEVEL "..c.level.." ×"..c.count,16,{Size=UDim2.new(1,0,0,24),Parent=row})
			local flags=game.ReplicatedStorage.FeatureFlags
			local luck=CollectionMath.Luck(Data.Get(),flags:GetAttribute("Rebirth")==true,flags:GetAttribute("IndexBonuses")==true,os.time(),game.ReplicatedStorage:GetAttribute("ServerLuckUntil"))
			local odds,giant=Loot.Odds(c.rarity,c.level,luck);local out={}
			for j,v in odds do if v>0 then table.insert(out,Rarities.Order[j].." "..string.format("%.1f%%",v*100)) end end
			UI.Label("IL "..c.zone.." • Giant "..string.format("%.1f%%",giant*100).."\n"..table.concat(out," / "),12,{Position=UDim2.fromOffset(0,25),Size=UDim2.new(1,0,0,43),Parent=row})
			local open=UI.Button({text="Open 1",color=UI.Colors.Orange,size=UDim2.new(1,0,0,46),onClick=function()
				local ok,reward=request("Open",c.uid);if ok then showReward(reward) end
			end});open.Name="Open";open.Position=UDim2.fromOffset(0,70);open.Parent=row
			if (Data.Get("Purchases.passes") or {}).OpenTen and c.count>1 then
				open.Size=UDim2.new(.5,-4,0,46)
				local ten=UI.Button({text="Open 10",color=UI.Colors.Purple,size=UDim2.new(.5,-4,0,46),onClick=function()
					local ok,reward=request("OpenTen",c.uid);if ok then showReward(reward) end
				end});ten.Name="OpenTen";ten.Position=UDim2.new(.5,4,0,70);ten.Parent=row
			end
		end
		if #chests==0 then UI.Label("No chests yet. Clear trees around a chest spot, then End Run",16,{Size=UDim2.new(1,-10,0,80),Parent=chestList}) end
		if not selected then selected=equipped or ids[1] end
		local item=inv[selected];local def=item and Weapons.ById[item.id]
        if def then preview(selectionView,def,item) end
		if def then details.Text=def.name.."\nPower "..NF.Short(Loot.Power(item)).."\nSpeed "..def.speed.."\nArea "..def.area*(item.giant and 2 or 1).."\n"..(item.stars<5 and ("Fuse ★"..(item.stars+1)..": Requires 3 matching items + Wood "..NF.Short(Loot.FuseCost(item))) or "Max ★5 reached")
		else details.Text="Select a weapon to equip or fuse duplicates • Open chests at the village station" end
	end
	resize=function()
		local size=workspace.CurrentCamera.ViewportSize
		panel.Size=UDim2.fromOffset(math.min(960,size.X-28),math.min(650,size.Y-60))
		weaponList.Visible=tab=="Weapons";chestList.Visible=tab=="Chests";selection.Visible=tab=="Weapons"
		chestList.Position=UDim2.fromScale(0,0);chestList.Size=UDim2.fromScale(1,1)
		weaponList.Position=UDim2.fromScale(.25,0);weaponList.Size=UDim2.fromScale(.75,1)
		local s=result:FindFirstChildOfClass("UIScale") or Instance.new("UIScale");s.Scale=math.min(1,(size.X-20)/380,(size.Y-30)/365);s.Parent=result
	end
	local function show()
		local garden=player.PlayerGui:FindFirstChild("GardenHUD");if garden and garden:FindFirstChild("Panel") then garden.Panel.Visible=false end
		panel.Visible=true;result.Visible=false;pendingFuse=nil;pendingDelete=nil;message.Text="Open chests and fuse at the village station";resize();render()
		task.spawn(function() request("Sync") end)
	end
	local toggle=UI.Button({text="Inventory / Chests",color=UI.Colors.Purple,size=UDim2.fromOffset(178,48),onClick=function() if panel.Visible then panel.Visible=false else show() end end})
	toggle.Name="Toggle";toggle.Position=UDim2.fromOffset(16,245);toggle.Parent=gui
	Net.Event("InventoryShow").OnClientEvent:Connect(show)
	Data.Changed:Connect(function(path) if path=="" or path=="Currencies.Stardust" or path=="Purchases.passes" or path:sub(1,17)=="Purchases.passes." or path:sub(1,10)=="Inventory." or path:match("^Index") or path:match("^Rebirth") then if panel.Visible then render() end end end)
	for _,flag in {"Rebirth","IndexBonuses","WeatherEncounters"} do game.ReplicatedStorage.FeatureFlags:GetAttributeChangedSignal(flag):Connect(function() if panel.Visible then render() end end) end
	workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(resize)
	resize()
end
return Inventory
