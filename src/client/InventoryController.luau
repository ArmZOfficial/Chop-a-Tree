-- Inventory window (concept: assets/ui/elements-v1/concepts/inventory.png). Server intents unchanged.
local Players=game:GetService("Players")
local Shared=game.ReplicatedStorage:WaitForChild("Shared")
local Net=require(Shared.Net)
local UI=require(Shared.UIKit)
local NF=require(Shared.NumberFormat)
local Loot=require(Shared.Loot)
local Visual=require(Shared.WeaponVisual)
local Weapons=require(Shared.Config.WeaponCatalog)
local Rarities=require(Shared.Config.Rarities)
local Config=require(Shared.Config.Chests)
local Encounters=require(Shared.Config.WeatherEncounters)
local Data=require(script.Parent.ClientData)
local CollectionMath=require(Shared.CollectionMath)
local Inventory={}
local player=Players.LocalPlayer
local HINT="Select an item to view details and take action."
local CHEST_ART={Common="rareChest",Rare="rareChest",Epic="epicChest",Legendary="epicChest",Mythic="epicChest"}

function Inventory.Start()
	local gui=UI.New("ScreenGui",{Name="InventoryHUD",ResetOnSpawn=false,DisplayOrder=8,ZIndexBehavior=Enum.ZIndexBehavior.Sibling,Parent=player:WaitForChild("PlayerGui")})
	local panel=UI.New("Frame",{Name="Panel",AnchorPoint=Vector2.new(.5,.5),Position=UDim2.fromScale(.5,.5),Size=UDim2.fromOffset(960,650),BackgroundTransparency=1,Visible=false,Parent=gui})
	UI.Window(panel,"Inventory","bag")
	local counter=UI.New("Frame",{Name="Counter",BackgroundTransparency=1,AnchorPoint=Vector2.new(1,.5),Position=UDim2.new(1,-92,.105,-2),Size=UDim2.fromOffset(190,54),Parent=panel})
	UI.Skin(counter,"chrome","infoRow")
	local title=UI.Label("0 / "..Config.MaxWeapons,30,{Name="Title",Size=UDim2.fromScale(1,1),TextXAlignment=Enum.TextXAlignment.Center,TextWrapped=false,Parent=counter})
	local tab="Weapons";local selected,selectedChest,pendingSelection,pendingFuse,pendingDelete;local busy=false
	-- Left: selected item detail.
	local selection=UI.New("Frame",{Name="Selection",BackgroundTransparency=1,Position=UDim2.fromOffset(34,128),Size=UDim2.fromOffset(300,486),Parent=panel})
	UI.Skin(selection,"detail","detailPanel")
	local selectionView=UI.New("ViewportFrame",{Name="Preview",BackgroundTransparency=1,Position=UDim2.fromOffset(40,26),Size=UDim2.new(1,-80,0,190),Ambient=Color3.new(1,1,1),Parent=selection})
	local nameLabel=UI.Label("",34,{Name="ItemName",Position=UDim2.fromOffset(14,218),Size=UDim2.new(1,-28,0,44),TextXAlignment=Enum.TextXAlignment.Center,TextScaled=true,Parent=selection})
	UI.New("UITextSizeConstraint",{MaxTextSize=36,Parent=nameLabel})
	local rarity=UI.New("Frame",{Name="Rarity",AnchorPoint=Vector2.new(.5,0),Position=UDim2.new(.5,0,0,264),Size=UDim2.fromOffset(100,32),BackgroundColor3=Rarities.Color.Rare,Parent=selection},{UI.Corner(9),UI.Stroke(2)})
	local rarityLabel=UI.Label("",19,{Size=UDim2.fromScale(1,1),TextXAlignment=Enum.TextXAlignment.Center,TextWrapped=false,Parent=rarity})
	local powerBar,powerLabel=UI.InfoBar(selection,"Power",{Name="Power",Position=UDim2.fromOffset(26,304),Size=UDim2.new(1,-52,0,50)},"axe")
	local powerValue=UI.Label("",26,{Name="PowerValue",Position=UDim2.new(0,0,0,0),Size=UDim2.new(1,-16,1,0),TextXAlignment=Enum.TextXAlignment.Right,TextWrapped=false,ZIndex=3,Parent=powerBar})
	local details=UI.Label("",15,{Name="Details",FontFace=UI.FontBold,Position=UDim2.fromOffset(28,356),Size=UDim2.new(1,-56,0,40),TextXAlignment=Enum.TextXAlignment.Center,TextColor3=UI.Colors.TextDim,Parent=selection})
	local equippedBadge=UI.Badge(selection,"✓ Equipped","ready",{Name="Equipped",AnchorPoint=Vector2.new(.5,0),Position=UDim2.new(.5,0,0,398),Size=UDim2.fromOffset(150,38)})
	local buttons=UI.New("Frame",{Name="Actions",BackgroundTransparency=1,Position=UDim2.new(0,8,1,-56),Size=UDim2.new(1,-16,0,62),Parent=selection})
	-- Right: tabs, grid, info.
	local body=UI.New("Frame",{Name="Body",BackgroundTransparency=1,Position=UDim2.fromOffset(352,186),Size=UDim2.fromOffset(566,358),Parent=panel})
	local frame=UI.New("Frame",{Name="GridFrame",BackgroundTransparency=1,Position=UDim2.fromOffset(344,176),Size=UDim2.fromOffset(582,376),ZIndex=1,Parent=panel});frame:SetAttribute("SliceMax",.4);UI.Skin(frame,"cards","product")
	local function list(name)
		return UI.New("ScrollingFrame",{Name=name,BackgroundTransparency=1,Size=UDim2.fromScale(1,1),AutomaticCanvasSize=Enum.AutomaticSize.Y,CanvasSize=UDim2.new(),ScrollBarThickness=6,ScrollBarImageColor3=Color3.fromRGB(240,180,90),Parent=body},{UI.Padding(4)})
	end
	local chestList=list("Chests");local weaponList=list("Weapons")
	UI.Grid(4,154,10).Parent=weaponList;UI.Grid(3,190,10).Parent=chestList
	local info,message=UI.InfoBar(panel,HINT,{Name="Info",Position=UDim2.fromOffset(344,556),Size=UDim2.fromOffset(582,50)},"book")
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
	local function say(text) message.Text=text or HINT end
	local function request(action,arg)
		if busy then return false end
		busy=true
		local ok,success,text,extra=pcall(function() return Net.Function("InventoryAction"):InvokeServer(action,arg) end)
		busy=false
		if not ok then say("Connection failed. Try again");return false end
		if action~="Sync" then say(text or (success and "Done" or "Try again")) end
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
	local function action(name,text,color,x,w,fn)
		local b=UI.Button({text=text,textSize=26,color=color,size=UDim2.new(w,-6,1,0),onClick=fn});b.Name=name;b.Position=UDim2.fromScale(x,0);b.Parent=buttons;return b
	end
	local equip=action("Equip","Equip",UI.Colors.Green,0,.42,function() if selected then request("Equip",selected) end end)
	local fuse=action("Fuse","Fuse 3",UI.Colors.Orange,.42,.36,function()
		local ids=compatibleIds();if not ids then say("Requires 3 weapons with matching type, IL, stars, Giant and Rot");return end
		local key=table.concat(ids,"|")
		if pendingFuse~=key then pendingFuse=key;say("Click Fuse again to use 3 items and the Wood shown");return end
		pendingFuse=nil;request("Fuse",ids)
	end)
	local delete=action("Delete","",UI.Colors.Red,.78,.22,function()
		if not selected or busy then return end
		if pendingDelete~=selected then pendingDelete=selected;say("Click Delete again to permanently remove this weapon");return end
		local uid=selected;pendingDelete=nil;request("Delete",uid)
	end)
	UI.Skin(delete.Button,"controls","delete");delete.Button.SurfaceArt.ScaleType=Enum.ScaleType.Fit
	local openOne=action("Open","Open 1",UI.Colors.Orange,0,1,function() if selectedChest then local ok,reward=request("Open",selectedChest);if ok then showReward(reward) end end end)
	local openTen=action("OpenTen","Open 10",UI.Colors.Green,.5,.5,function() if selectedChest then local ok,reward=request("OpenTen",selectedChest);if ok then showReward(reward) end end end)
	local exchange=action("DustExchange","Exchange",UI.Colors.Green,0,1,function()
		local success,ok,msg=pcall(function() return Net.Function("EncounterAction"):InvokeServer("Exchange") end)
		say(success and msg or "Connection failed");render()
	end)
	local tabs={}
	for i,name in {"Weapons","Chests"} do
		tabs[name]=UI.Tab({name=name.."Tab",text=name,icon=name=="Weapons" and "axe" or "rewards/rareChest",size=UDim2.fromOffset(282,62),position=UDim2.fromOffset(350+(i-1)*290,118),parent=panel,textSize=30,onClick=function() tab=name;pendingFuse=nil;pendingDelete=nil;resize();render() end})
	end
	-- Cards are rebuilt from data; a ring marks the selection without hiding rarity.
	local function card(parent,name,sprite,order,isSelected,onClick)
		local c=UI.New("TextButton",{Name=name,Text="",AutoButtonColor=false,BackgroundTransparency=1,LayoutOrder=order,Parent=parent})
		UI.Skin(c,"cards",sprite)
		if isSelected then UI.New("Frame",{Name="SelectRing",BackgroundTransparency=1,Position=UDim2.fromOffset(-2,-2),Size=UDim2.new(1,4,1,4),ZIndex=4,Parent=c},{UI.Corner(16),UI.Stroke(4,Color3.fromRGB(255,224,90))}) end
		c.Activated:Connect(onClick)
		return c
	end
	local function clear(frame)
		for _,child in frame:GetChildren() do if child:IsA("GuiObject") then child:Destroy() end end
	end
	local function setActions(kind,count)
		equip.Visible=kind=="weapon";fuse.Visible=kind=="weapon";delete.Visible=kind=="weapon"
		local ten=kind=="chest" and (Data.Get("Purchases.passes") or {}).OpenTen and count>1
		openOne.Visible=kind=="chest";openTen.Visible=ten==true;openOne.Size=UDim2.new(ten and .5 or 1,-6,1,0)
		exchange.Visible=kind=="dust"
	end
	render=function()
		if not Data.IsReady() then return end
		local inv=Data.Get("Inventory.Weapons") or {};local chests=Data.Get("Inventory.Chests") or {};local equipped=Data.Get("Inventory.Equipped")
		clear(weaponList);clear(chestList)
		local ids={};for uid in inv do table.insert(ids,uid) end
		table.sort(ids,function(a,b) local pa,pb=Loot.Power(inv[a]),Loot.Power(inv[b]);return pa==pb and a<b or pa>pb end)
		title.Text=#ids.." / "..Config.MaxWeapons
		-- The function response and DataPatch events can arrive in either order.
		if pendingSelection and inv[pendingSelection] then pendingSelection=nil end
		if selected and not inv[selected] and selected~=pendingSelection then selected=nil;pendingFuse=nil end
		if not selected then selected=equipped or ids[1] end
		for i,uid in ids do
			local item=inv[uid];local def=Weapons.ById[item.id];local key=uid
			local c=card(weaponList,"Item_"..uid,def and string.lower(def.rarity) or "unknown",i,selected==uid,function() selected=key;pendingSelection=nil;pendingFuse=nil;pendingDelete=nil;say();render() end)
			if def then local view=UI.New("ViewportFrame",{BackgroundTransparency=1,Position=UDim2.fromOffset(12,10),Size=UDim2.new(1,-24,1,-50),Ambient=Color3.new(1,1,1),Parent=c});preview(view,def,item) end
			UI.Label((item.giant and "GIANT " or "")..(def and def.name or "Unknown item"),17,{Position=UDim2.new(0,6,1,-42),Size=UDim2.new(1,-12,0,34),TextXAlignment=Enum.TextXAlignment.Center,TextScaled=true,Parent=c}):FindFirstChildOfClass("UIStroke").Thickness=2
			if equipped==uid then UI.Label("✓",24,{Position=UDim2.fromOffset(12,8),Size=UDim2.fromOffset(28,28),TextColor3=UI.Colors.Accent,Parent=c}) end
			if item.stars and item.stars>1 then UI.Label(string.rep("★",item.stars),14,{Position=UDim2.new(1,-74,0,8),Size=UDim2.fromOffset(64,20),TextXAlignment=Enum.TextXAlignment.Right,TextColor3=Color3.fromRGB(255,214,64),TextWrapped=false,Parent=c}) end
		end
		if #ids==0 then UI.Label("No weapons yet. Collect forest chests, then open them in the village",20,{Size=UDim2.new(1,-10,0,80),Parent=weaponList}) end
		-- Chests tab
		local dustOn=game.ReplicatedStorage.FeatureFlags:GetAttribute("WeatherEncounters")==true
		local chosen
		for i,c in chests do
			local uid=c.uid
			if selectedChest==nil then selectedChest=uid end
			if selectedChest==uid then chosen=c end
			local cc=card(chestList,"Chest_"..tostring(uid),selectedChest==uid and "today" or "product",i,selectedChest==uid,function() selectedChest=uid;say();render() end)
			UI.Art(cc,"rewards",CHEST_ART[c.rarity] or "rareChest",{Position=UDim2.fromOffset(14,10),Size=UDim2.new(1,-28,1,-70)})
			UI.Label(c.rarity.." Chest",20,{Position=UDim2.new(0,6,1,-62),Size=UDim2.new(1,-12,0,28),TextXAlignment=Enum.TextXAlignment.Center,TextColor3=Rarities.Color[c.rarity] and Rarities.Color[c.rarity]:Lerp(Color3.new(1,1,1),.55) or UI.Colors.Text,Parent=cc})
			UI.Label("Level "..c.level.." • ×"..c.count,16,{Position=UDim2.new(0,6,1,-34),Size=UDim2.new(1,-12,0,24),TextXAlignment=Enum.TextXAlignment.Center,Parent=cc})
		end
		if dustOn then
			if selectedChest==nil then selectedChest="Dust" end
			local dc=card(chestList,"DustExchange",selectedChest=="Dust" and "today" or "product",#chests+1,selectedChest=="Dust",function() selectedChest="Dust";say();render() end)
			UI.Art(dc,"rewards","rareChest",{Position=UDim2.fromOffset(14,10),Size=UDim2.new(1,-28,1,-70)})
			UI.Label("Stardust "..(Data.Get("Currencies.Stardust") or 0),20,{Position=UDim2.new(0,6,1,-62),Size=UDim2.new(1,-12,0,28),TextXAlignment=Enum.TextXAlignment.Center,Parent=dc})
			UI.Label(Encounters.ChestDust.." = Rare Chest",16,{Position=UDim2.new(0,6,1,-34),Size=UDim2.new(1,-12,0,24),TextXAlignment=Enum.TextXAlignment.Center,Parent=dc})
		end
		if selectedChest~="Dust" and not chosen then selectedChest=nil;if chests[1] then selectedChest=chests[1].uid;chosen=chests[1] end end
		if #chests==0 and not dustOn then UI.Label("No chests yet. Clear trees around a chest spot, then End Run",20,{Size=UDim2.new(1,-10,0,80),Parent=chestList}) end
		-- Detail panel
		selectionView:ClearAllChildren();equippedBadge.Visible=false;rarity.Visible=false;powerBar.Visible=false
		if tab=="Weapons" then
			local item=inv[selected];local def=item and Weapons.ById[item.id]
			setActions(item and "weapon" or nil)
			if def then
				preview(selectionView,def,item);nameLabel.Text=(item.giant and "Giant " or "")..def.name
				rarity.Visible=true;rarity.BackgroundColor3=Rarities.Color[def.rarity]:Lerp(Color3.new(1,1,1),.15);rarityLabel.Text=def.rarity;rarity.Size=UDim2.fromOffset(math.max(90,#def.rarity*13+30),32)
				powerBar.Visible=true;powerLabel.Text="Power";powerValue.Text=NF.Short(Loot.Power(item))
				details.Text="IL "..item.il.." • ★"..item.stars.." • Speed "..def.speed.." • Area "..def.area*(item.giant and 2 or 1).."\n"..(item.stars<5 and ("Fuse ★"..(item.stars+1)..": 3 matching + "..NF.Short(Loot.FuseCost(item)).." Wood") or "Max ★5 reached")
				if def.legacy then details.Text=details.Text.."\nLegacy weapon — upgrades to "..((Weapons.ById[def.replacement] or def).name).." on next join" end
				equippedBadge.Visible=equipped==selected
			elseif item then nameLabel.Text="Unknown item";details.Text=tostring(item.id).."\nKept safe in your save — it will update automatically"
			else nameLabel.Text="No weapon";details.Text="Open chests at the village station" end
		else
			if selectedChest=="Dust" then
				setActions("dust");UI.Art(selectionView,"rewards","rareChest",{Size=UDim2.fromScale(1,1)})
				nameLabel.Text="Stardust";powerBar.Visible=true;powerLabel.Text="Stardust";powerValue.Text=tostring(Data.Get("Currencies.Stardust") or 0)
				details.Text="Exchange "..Encounters.ChestDust.." Stardust\nfor one Rare Chest"
			elseif chosen then
				setActions("chest",chosen.count);UI.Art(selectionView,"rewards",CHEST_ART[chosen.rarity] or "rareChest",{Size=UDim2.fromScale(1,1)})
				nameLabel.Text=chosen.rarity.." Chest";rarity.Visible=true;rarity.BackgroundColor3=(Rarities.Color[chosen.rarity] or UI.Colors.Slate):Lerp(Color3.new(1,1,1),.15);rarityLabel.Text="Level "..chosen.level;rarity.Size=UDim2.fromOffset(120,32)
				local flags=game.ReplicatedStorage.FeatureFlags
				local luck=CollectionMath.Luck(Data.Get(),flags:GetAttribute("Rebirth")==true,flags:GetAttribute("IndexBonuses")==true,os.time(),game.ReplicatedStorage:GetAttribute("ServerLuckUntil"))
				local odds,giant=Loot.Odds(chosen.rarity,chosen.level,luck);local out={}
				for j,v in odds do if v>0 then table.insert(out,string.sub(Rarities.Order[j],1,4).." "..string.format("%.1f%%",v*100)) end end
				powerBar.Visible=true;powerLabel.Text="Owned";powerValue.Text="×"..chosen.count
				details.Text="IL "..chosen.zone.." • Giant "..string.format("%.1f%%",giant*100).."\n"..table.concat(out," / ")
			else setActions(nil);nameLabel.Text="No chests";details.Text="Clear trees around a chest spot, then End Run" end
		end
		details.TextSize=#details.Text>70 and 13 or 15
	end
	resize=function()
		local size=workspace.CurrentCamera.ViewportSize
		weaponList.Visible=tab=="Weapons";chestList.Visible=tab=="Chests"
		for name,t in tabs do UI.SetTab(t,tab==name and "gold" or nil) end
		local s=result:FindFirstChildOfClass("UIScale") or Instance.new("UIScale");s.Scale=math.min(1,(size.X-20)/380,(size.Y-30)/365);s.Parent=result
	end
	local function show()
		local garden=player.PlayerGui:FindFirstChild("GardenHUD");if garden and garden:FindFirstChild("Panel") then garden.Panel.Visible=false end
		panel.Visible=true;result.Visible=false;pendingFuse=nil;pendingDelete=nil;say();resize();render()
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
