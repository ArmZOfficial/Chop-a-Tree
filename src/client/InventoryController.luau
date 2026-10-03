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
local ChestIcon=require(Shared.ChestIconRenderer)
local Inventory={}
local player=Players.LocalPlayer
local HINT="Select an item to view details and take action."

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
	local details=UI.Label("",15,{Name="Details",FontFace=UI.FontBold,Position=UDim2.fromOffset(28,356),Size=UDim2.new(1,-56,0,40),TextXAlignment=Enum.TextXAlignment.Center,TextColor3=UI.Colors.TextDim,RichText=true,TextScaled=true,Parent=selection})
	UI.New("UITextSizeConstraint",{MaxTextSize=15,MinTextSize=9,Parent=details})
	local oddsDialog=UI.New("Frame",{Name="OddsDialog",AnchorPoint=Vector2.new(.5,.5),Position=UDim2.fromScale(.5,.5),Size=UDim2.new(1,-48,1,-48),BackgroundColor3=UI.Colors.PanelDark,Visible=false,ZIndex=30,Parent=panel},{UI.Corner(18),UI.Stroke(4)})
	UI.New("TextButton",{Name="Blocker",Text="",AutoButtonColor=false,BackgroundTransparency=1,Size=UDim2.fromScale(1,1),ZIndex=30,Parent=oddsDialog})
	UI.Label("Chest chances",26,{Name="Heading",Position=UDim2.fromOffset(12,6),Size=UDim2.new(1,-24,0,34),TextXAlignment=Enum.TextXAlignment.Center,ZIndex=32,Parent=oddsDialog})
	local detailHint=UI.Label("One weapon per chest • Giant is a separate roll",16,{FontFace=UI.FontBody,Position=UDim2.fromOffset(12,40),Size=UDim2.new(1,-24,0,26),TextXAlignment=Enum.TextXAlignment.Center,TextScaled=true,ZIndex=32,Parent=oddsDialog})
	local oddsCards=UI.New("Frame",{Name="OddsCards",Position=UDim2.fromOffset(16,70),Size=UDim2.new(1,-32,1,-140),BackgroundTransparency=1,ZIndex=31,Parent=oddsDialog})
	local oddsGrid=UI.Grid(3,130,10);oddsGrid.Parent=oddsCards
	local closeOdds=UI.Button({text="Close",textSize=24,color=UI.Colors.Blue,size=UDim2.new(1,-32,0,62),onClick=function() oddsDialog.Visible=false end})
	closeOdds.Name="Close";closeOdds.ZIndex=31;closeOdds.Position=UDim2.new(0,16,1,-66);closeOdds.Parent=oddsDialog
	local oddsButton=UI.Button({text="Drop chances",textSize=20,color=UI.Colors.Blue,size=UDim2.new(1,-52,0,62),onClick=function() oddsDialog.Visible=true end})
	oddsButton.Name="OddsButton";oddsButton.Position=UDim2.fromOffset(26,366);oddsButton.Visible=false;oddsButton.Parent=selection
	local function setOdds(odds,giant,zone)
		oddsDialog.Heading.Text="Chest chances";detailHint.Text="Weapon level "..zone.." • Giant is a separate roll"
		for _,v in oddsCards:GetChildren() do if v:IsA("GuiObject") then v:Destroy() end end
		for i=1,6 do
			local rank=i==6 and "Giant" or Rarities.Order[i];local chance=i==6 and giant or odds[i]
			local c=UI.New("Frame",{Name=rank,BackgroundColor3=i==6 and UI.Colors.Purple or Rarities.Color[rank],LayoutOrder=i,ZIndex=31,Parent=oddsCards},{UI.Corner(12),UI.Stroke(2)})
			UI.Icon(c,i==6 and "boost" or "chest",{Name="Icon",Position=UDim2.fromOffset(10,6),Size=UDim2.fromOffset(36,36),ZIndex=32})
			UI.Label(rank,20,{Name="Name",Position=UDim2.fromOffset(48,4),Size=UDim2.new(1,-54,0,34),TextScaled=true,TextXAlignment=Enum.TextXAlignment.Center,ZIndex=32,Parent=c})
			UI.Label(string.format("%.2f%%",chance*100),28,{Name="Chance",Position=UDim2.fromOffset(6,42),Size=UDim2.new(1,-12,1,-48),TextScaled=true,TextXAlignment=Enum.TextXAlignment.Center,ZIndex=32,Parent=c})
		end
	end
	local function weaponStats(item,def)
		oddsDialog.Heading.Text="Weapon stats";detailHint.Text=item.stars<5 and "Fuse: combine 3 matching weapons" or "Max stars reached"
		for _,v in oddsCards:GetChildren() do if v:IsA("GuiObject") then v:Destroy() end end
		local rows={{"boost","Level",item.il},{"star","Stars",item.stars.."/5"},{"timer","Speed",def.speed},{"axe","Area",def.area*(item.giant and 2 or 1)},{"wood","Fuse cost",item.stars<5 and NF.Short(Loot.FuseCost(item)) or "Max"},{"cycle","Rot",item.rebirthDrop or 0}}
		for i,row in rows do
			local c=UI.New("Frame",{Name="Stat"..i,BackgroundColor3=UI.Colors.Blue:Lerp(UI.Colors.Panel,.45),LayoutOrder=i,ZIndex=31,Parent=oddsCards},{UI.Corner(12),UI.Stroke(2)})
			UI.Icon(c,row[1],{Position=UDim2.fromOffset(10,6),Size=UDim2.fromOffset(36,36),ZIndex=32})
			UI.Label(row[2],20,{Position=UDim2.fromOffset(48,4),Size=UDim2.new(1,-54,0,34),TextScaled=true,TextXAlignment=Enum.TextXAlignment.Center,ZIndex=32,Parent=c})
			UI.Label(tostring(row[3]),28,{Position=UDim2.fromOffset(6,42),Size=UDim2.new(1,-12,1,-48),TextScaled=true,TextXAlignment=Enum.TextXAlignment.Center,ZIndex=32,Parent=c})
		end
	end
	local function fitOdds()
		oddsDialog.Size=panel:GetAttribute("PhoneLayout") and UDim2.new(1,-48,1,-48) or UDim2.fromOffset(650,410)
		oddsGrid.CellSize=UDim2.new(1/3,-9,0,panel:GetAttribute("PhoneLayout") and 82 or 130)
	end
	panel:GetAttributeChangedSignal("PhoneLayout"):Connect(fitOdds)
	fitOdds()
	for _,v in closeOdds:GetDescendants() do if v:IsA("GuiObject") then v.ZIndex=v:IsA("TextLabel") and 33 or 32 end end
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
		local ok,success,text,extra,all=pcall(function() return Net.Function("InventoryAction"):InvokeServer(action,arg) end)
		busy=false
		if not ok then say("Connection failed. Try again");return false end
		if action~="Sync" then say(text or (success and "Done" or "Try again")) end
		if success and extra then selected=extra.uid;pendingSelection=extra.uid end
		render()
		return success,extra,all
	end
	-- Opening cinematic + result card (ChestOpening). The server already saved the weapons.
	local Opening=require(script.Parent.ChestOpening)
	local function chestLeft(uid) for _,c in Data.Get("Inventory.Chests") or {} do if c.uid==uid and c.count>0 then return true end end;return false end
	local openChest
	openChest=function(uid,ten)
		if not uid or Opening.Playing() then return end
		local ok,reward,all=request(ten and "OpenTen" or "Open",uid)
		if not ok or not reward then return end
		Opening.Play(ten and type(all)=="table" and all or {reward},{
			onEquip=function(w) request("Equip",w) end,
			onAgain=function() openChest(uid,ten) end,
			canAgain=function() return chestLeft(uid) end,
		})
	end
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
	UI.Skin(delete.Button,"controls","delete")
	local openOne=action("Open","Open 1",UI.Colors.Orange,0,1,function() openChest(selectedChest,false) end)
	local openTen=action("OpenTen","Open 10",UI.Colors.Green,.5,.5,function() openChest(selectedChest,true) end)
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
			local itemName=UI.Label((item.giant and "GIANT " or "")..(def and def.name or "Unknown item"),17,{Position=UDim2.new(0,6,1,-42),Size=UDim2.new(1,-12,0,34),TextXAlignment=Enum.TextXAlignment.Center,TextScaled=true,Parent=c})
			itemName:FindFirstChildOfClass("UIStroke").Thickness=2;UI.New("UITextSizeConstraint",{MaxTextSize=16,MinTextSize=10,Parent=itemName}) -- short names must not balloon past long ones
			if equipped==uid then UI.Label("✓",24,{Position=UDim2.fromOffset(12,8),Size=UDim2.fromOffset(28,28),TextColor3=UI.Colors.Accent,Parent=c}) end
			if item.stars and item.stars>1 then UI.Label(string.rep("★",item.stars),14,{Position=UDim2.new(1,-74,0,8),Size=UDim2.fromOffset(64,20),TextXAlignment=Enum.TextXAlignment.Right,TextColor3=Color3.fromRGB(255,214,64),TextWrapped=false,Parent=c}) end
		end
		weaponList.UIGridLayout.CellSize=UDim2.new(#ids==0 and 1 or .25,#ids==0 and -10 or -9.5,0,#ids==0 and 190 or 154)
		if #ids==0 then UI.EmptyState(weaponList,"Empty",{icon="chest",title="No weapons yet",sub="Collect forest chests, then open them in the village"}) end
		-- Chests tab
		local dustOn=game.ReplicatedStorage.FeatureFlags:GetAttribute("WeatherEncounters")==true
		local chosen
		for i,c in chests do
			local uid=c.uid
			if selectedChest==nil then selectedChest=uid end
			if selectedChest==uid then chosen=c end
			local cc=card(chestList,"Chest_"..tostring(uid),selectedChest==uid and "today" or "product",i,selectedChest==uid,function() selectedChest=uid;say();render() end)
			ChestIcon.New(c.rarity,{Position=UDim2.fromOffset(14,10),Size=UDim2.new(1,-28,1,-70),Parent=cc})
			local chestName=UI.Label(c.rarity.." Chest",20,{Position=UDim2.new(0,6,1,-62),Size=UDim2.new(1,-12,0,28),TextXAlignment=Enum.TextXAlignment.Center,TextScaled=true,TextColor3=selectedChest~=uid and Rarities.Color[c.rarity] and Rarities.Color[c.rarity]:Lerp(Color3.new(1,1,1),.55) or UI.Colors.Text,Parent=cc})
			UI.New("UITextSizeConstraint",{MaxTextSize=20,MinTextSize=14,Parent=chestName})
			local chestCount=UI.Label("Level "..c.level.." • ×"..c.count,16,{Position=UDim2.new(0,6,1,-34),Size=UDim2.new(1,-12,0,24),TextXAlignment=Enum.TextXAlignment.Center,TextScaled=true,Parent=cc})
			UI.New("UITextSizeConstraint",{MaxTextSize=16,MinTextSize=12,Parent=chestCount})
		end
		if dustOn then
			if selectedChest==nil then selectedChest="Dust" end
			local dc=card(chestList,"DustExchange",selectedChest=="Dust" and "today" or "product",#chests+1,selectedChest=="Dust",function() selectedChest="Dust";say();render() end)
			ChestIcon.New("Rare",{Position=UDim2.fromOffset(14,10),Size=UDim2.new(1,-28,1,-70),Parent=dc})
			UI.Label("Stardust "..(Data.Get("Currencies.Stardust") or 0),20,{Position=UDim2.new(0,6,1,-62),Size=UDim2.new(1,-12,0,28),TextXAlignment=Enum.TextXAlignment.Center,Parent=dc})
			UI.Label(Encounters.ChestDust.." = Rare Chest",16,{Position=UDim2.new(0,6,1,-34),Size=UDim2.new(1,-12,0,24),TextXAlignment=Enum.TextXAlignment.Center,Parent=dc})
		end
		if selectedChest~="Dust" and not chosen then selectedChest=nil;if chests[1] then selectedChest=chests[1].uid;chosen=chests[1] end end
		chestList.UIGridLayout.CellSize=UDim2.new(#chests==0 and not dustOn and 1 or 1/3,#chests==0 and not dustOn and -10 or -9,0,190)
		if #chests==0 and not dustOn then UI.EmptyState(chestList,"Empty",{icon="tree",title="No chests yet",sub="Clear trees around a chest spot, then End Run"}) end
		-- Detail panel
		selectionView:ClearAllChildren();equippedBadge.Visible=false;rarity.Visible=false;powerBar.Visible=false;oddsButton.Visible=false;details.Visible=true
		local oldIcon=powerBar:FindFirstChild("OwnedIcon");if oldIcon then oldIcon:Destroy() end
		powerBar.BarIcon.Visible=true
		if tab=="Weapons" then
			local item=inv[selected];local def=item and Weapons.ById[item.id]
			setActions(item and "weapon" or nil)
			if def then
				preview(selectionView,def,item);nameLabel.Text=(item.giant and "Giant " or "")..def.name
				rarity.Visible=true;rarity.BackgroundColor3=Rarities.Color[def.rarity]:Lerp(Color3.new(1,1,1),.15);rarityLabel.Text=def.rarity;rarity.Size=UDim2.fromOffset(math.max(90,#def.rarity*13+30),32)
				powerBar.Visible=true;powerLabel.Text="Power";powerValue.Text=NF.Short(Loot.Power(item))
				details.Text="IL "..item.il.." • ★"..item.stars.." • Speed "..def.speed.." • Area "..def.area*(item.giant and 2 or 1).."\n"..(item.stars<5 and ("Fuse ★"..(item.stars+1)..": 3 matching + "..NF.Short(Loot.FuseCost(item)).." Wood") or "Max ★5 reached")
				if def.legacy then details.Text=details.Text.."\nLegacy weapon — upgrades to "..((Weapons.ById[def.replacement] or def).name).." on next join" end
				weaponStats(item,def);details.Visible=false;oddsButton.Visible=true
				oddsButton.Button:FindFirstChildWhichIsA("TextLabel",true).Text=equipped==selected and "Equipped • Stats" or "Weapon stats"
			elseif item then nameLabel.Text="Unknown item";details.Text=tostring(item.id).."\nKept safe in your save — it will update automatically"
			else nameLabel.Text="No weapon";details.Text="Open chests at the village station" end
		else
			if selectedChest=="Dust" then
				setActions("dust");ChestIcon.New("Rare",{Size=UDim2.fromScale(1,1),Parent=selectionView})
				nameLabel.Text="Stardust";powerBar.Visible=true;powerLabel.Text="Stardust";powerValue.Text=tostring(Data.Get("Currencies.Stardust") or 0)
				details.Text="Exchange "..Encounters.ChestDust.." Stardust\nfor one Rare Chest"
			elseif chosen then
				setActions("chest",chosen.count);ChestIcon.New(chosen.rarity,{Size=UDim2.fromScale(1,1),Parent=selectionView})
				nameLabel.Text=chosen.rarity.." Chest";rarity.Visible=true;rarity.BackgroundColor3=(Rarities.Color[chosen.rarity] or UI.Colors.Slate):Lerp(Color3.new(1,1,1),.15);rarityLabel.Text="Level "..chosen.level;rarity.Size=UDim2.fromOffset(120,32)
				local flags=game.ReplicatedStorage.FeatureFlags
				local luck=CollectionMath.Luck(Data.Get(),flags:GetAttribute("Rebirth")==true,flags:GetAttribute("IndexBonuses")==true,os.time(),game.ReplicatedStorage:GetAttribute("ServerLuckUntil"))
				local odds,giant=Loot.Odds(chosen.rarity,chosen.level,luck);setOdds(odds,giant,chosen.zone)
				powerBar.Visible=true;powerLabel.Text="Owned";powerValue.Text="×"..chosen.count
				powerBar.BarIcon.Visible=false;UI.Icon(powerBar,"chest",{Name="OwnedIcon",AnchorPoint=Vector2.new(0,.5),Position=UDim2.new(0,16,.5,0),Size=UDim2.fromOffset(32,32),ZIndex=4})
				details.Visible=false;oddsButton.Visible=true
				oddsButton.Button:FindFirstChildWhichIsA("TextLabel",true).Text="Drop chances"
			else setActions(nil);nameLabel.Text="No chests";details.Text="Clear trees around a chest spot, then End Run" end
		end
		details.TextSize=#details.Text>70 and 13 or 15
	end
	resize=function()
		local size=workspace.CurrentCamera.ViewportSize
		weaponList.Visible=tab=="Weapons";chestList.Visible=tab=="Chests"
		for name,t in tabs do UI.SetTab(t,tab==name and "gold" or nil) end
	end
	panel:GetPropertyChangedSignal("Visible"):Connect(function() if not panel.Visible then oddsDialog.Visible=false end end)
	local function show()
		local garden=player.PlayerGui:FindFirstChild("GardenHUD");if garden and garden:FindFirstChild("Panel") then garden.Panel.Visible=false end
		panel.Visible=true;pendingFuse=nil;pendingDelete=nil;say();resize();render()
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
