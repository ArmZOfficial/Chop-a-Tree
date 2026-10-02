-- Garden window (concept: assets/ui/elements-v1/concepts/garden.png). Server intents unchanged.
local Players=game:GetService("Players")
local Collection=game:GetService("CollectionService")
local S=game.ReplicatedStorage.Shared
local Net=require(S.Net);local UI=require(S.UIKit);local NF=require(S.NumberFormat)
local Seeds=require(S.Config.Seeds);local Math=require(S.GardenMath);local GardenConfig=require(S.Config.Garden)
local Garden={}
function Garden.Start()
	local player=Players.LocalPlayer
	local gui=UI.New("ScreenGui",{Name="GardenHUD",ResetOnSpawn=false,ZIndexBehavior=Enum.ZIndexBehavior.Sibling,DisplayOrder=9,Parent=player:WaitForChild("PlayerGui")})
	local panel=UI.New("Frame",{Name="Panel",AnchorPoint=Vector2.new(.5,.5),Position=UDim2.fromScale(.5,.5),Size=UDim2.fromOffset(960,650),Visible=false,BackgroundTransparency=1,Parent=gui})
	UI.Window(panel,"Garden","leaf",{plaque=360,center=true})
	local message=UI.Label("Select a seed, then a plot to plant it",14,{Name="Message",Visible=false,Parent=panel})
	local list=UI.New("ScrollingFrame",{Name="Items",Position=UDim2.fromOffset(40,190),Size=UDim2.fromOffset(600,352),BackgroundTransparency=1,ScrollBarThickness=6,ScrollBarImageColor3=Color3.fromRGB(240,180,90),AutomaticCanvasSize=Enum.AutomaticSize.Y,CanvasSize=UDim2.new(),Parent=panel},{UI.Padding(4)})
	-- Right: selected plot.
	local selection=UI.New("Frame",{Name="Selection",BackgroundTransparency=1,Position=UDim2.fromOffset(652,118),Size=UDim2.fromOffset(272,494),Parent=panel})
	UI.Skin(selection,"detail","detailPanel")
	local selTitle=UI.Label("Selected Plot",26,{Name="SelectedTitle",Position=UDim2.fromOffset(16,14),Size=UDim2.new(1,-32,0,34),TextXAlignment=Enum.TextXAlignment.Center,TextScaled=true,Parent=selection})
	UI.New("UITextSizeConstraint",{MaxTextSize=27,Parent=selTitle})
	local selArt=UI.New("Frame",{Name="ArtHolder",BackgroundTransparency=1,Position=UDim2.fromOffset(22,50),Size=UDim2.new(1,-44,0,150),Parent=selection})
	local selBadge=UI.Badge(selection,"Empty",nil,{Name="State",AnchorPoint=Vector2.new(.5,0),Position=UDim2.new(.5,0,0,186),Size=UDim2.fromOffset(196,40),ZIndex=5})
	local fruitRow,fruitLabel=UI.InfoBar(selection,"Fruit",{Name="Fruit",Position=UDim2.fromOffset(20,234),Size=UDim2.new(1,-40,0,46)},"garden/fruit")
	local fruitValue=UI.Label("",18,{Name="FruitValue",Size=UDim2.new(1,-14,1,0),TextXAlignment=Enum.TextXAlignment.Right,TextWrapped=false,TextScaled=true,ZIndex=3,Parent=fruitRow})
	UI.New("UITextSizeConstraint",{MaxTextSize=19,Parent=fruitValue})
	local valueRow,valueLabel=UI.InfoBar(selection,"Value",{Name="Value",Position=UDim2.fromOffset(20,286),Size=UDim2.new(1,-40,0,46)},"garden/fruit")
	valueRow.BarIcon.Image="";UI.New("Frame",{Name="Coin",AnchorPoint=Vector2.new(0,.5),Position=UDim2.new(0,16,.5,0),Size=UDim2.fromOffset(30,30),BackgroundColor3=Color3.fromRGB(250,204,21),ZIndex=3,Parent=valueRow},{UI.Corner(15),UI.Stroke(3)})
	local valueText=UI.Label("",20,{Name="ValueText",Size=UDim2.new(1,-14,1,0),TextXAlignment=Enum.TextXAlignment.Right,TextWrapped=false,TextColor3=Color3.fromRGB(255,220,90),ZIndex=3,Parent=valueRow})
	local plotActions=UI.New("Frame",{Name="PlotActions",BackgroundTransparency=1,Position=UDim2.fromOffset(16,342),Size=UDim2.new(1,-32,0,132),Parent=selection})
	local confirm=UI.New("Frame",{Name="CutConfirm",BackgroundTransparency=1,Position=UDim2.fromOffset(16,342),Size=UDim2.new(1,-32,0,132),Visible=false,ZIndex=6,Parent=selection})
	UI.Skin(confirm,"cards","product")
	UI.Label("Are you sure you want to cut this tree?",18,{Position=UDim2.fromOffset(14,10),Size=UDim2.new(1,-28,0,52),TextXAlignment=Enum.TextXAlignment.Center,ZIndex=7,Parent=confirm})
	local state,seedUid,cutPending;local slot=1;local tab="Garden";local busy=false
	local render,request
	local function say(text,ok)
		message.Text=text;if text~="" then UI.Toast(gui,text,ok==false and UI.Colors.Red or UI.Colors.Accent) end
	end
	local function button(name,text,color,parent,pos,size,callback,textSize)
		local b=UI.Button({text=text,textSize=textSize or 22,color=color,size=size,onClick=callback});b.Name=name;b.Position=pos;b.Parent=parent;return b
	end
	request=function(action,arg)
		if busy then return end;busy=true
		task.spawn(function()
			local ok,success,msg=pcall(function() return Net.Function("GardenAction"):InvokeServer(action,arg) end)
			if action~="Sync" then say(ok and (msg or "Garden ready") or "Could not reach the server. Try again",ok and success) end
			task.wait(.32);busy=false
		end)
	end
	local primary=button("Primary","Harvest",UI.Colors.Green,plotActions,UDim2.new(),UDim2.new(1,0,0,66),function()
		local plot=state and state.plots[tostring(slot)]
		if plot then request("Harvest",slot) elseif seedUid then request("Plant",{slot=slot,seed=seedUid}) else tab="Seeds";render();say("Select a seed first") end
	end,32)
	UI.Icon(primary.Button,"leaf",{Name="LeafIcon",AnchorPoint=Vector2.new(0,.5),Position=UDim2.new(0,12,.5,0),Size=UDim2.fromOffset(40,40),ZIndex=4})
	primary.Button:FindFirstChildWhichIsA("TextLabel",true).Position=UDim2.fromOffset(24,0)
	local water=button("Water","Water",UI.Colors.Slate,plotActions,UDim2.fromOffset(0,74),UDim2.new(.5,-4,0,54),function() request("Water",slot) end,20)
	local cut=button("Cut","Cut Tree",UI.Colors.Red,plotActions,UDim2.new(.5,4,0,74),UDim2.new(.5,-4,0,54),function() cutPending=slot;render() end,20)
	UI.Art(water.Button,"garden","wateringCan",{Name="CanIcon",AnchorPoint=Vector2.new(0,.5),Position=UDim2.new(0,8,.5,-2),Size=UDim2.fromOffset(32,32),ZIndex=4})
	water.Button:FindFirstChildWhichIsA("TextLabel",true).Position=UDim2.fromOffset(16,0)
	button("YesCut","Yes, Cut It",UI.Colors.Red,confirm,UDim2.new(0,10,1,-62),UDim2.new(.5,-14,0,52),function() if cutPending==slot then cutPending=nil;request("Cut",slot);render() end end,17)
	button("CancelCut","Cancel",UI.Colors.Slate,confirm,UDim2.new(.5,4,1,-62),UDim2.new(.5,-14,0,52),function() cutPending=nil;render() end,17)
	for _,v in confirm:GetDescendants() do if v:IsA("GuiObject") then v.ZIndex=math.max(v.ZIndex,7) end end
	-- Bottom bar: planting slots + upgrade, or fruit total + sell on the Shop tab.
	local slotsBar,slotsLabel=UI.InfoBar(panel,"Planting Slots",{Name="SlotsBar",Position=UDim2.fromOffset(40,552),Size=UDim2.fromOffset(600,58)},"leaf")
	local slotsValue=UI.Label("",26,{Name="SlotsValue",Position=UDim2.fromOffset(250,0),Size=UDim2.fromOffset(120,58),TextWrapped=false,ZIndex=3,Parent=slotsBar})
	local upgrade=button("Upgrade","Upgrade Slots",UI.Colors.Orange,slotsBar,UDim2.new(1,-212,0,4),UDim2.fromOffset(204,52),function() request("Upgrade") end,20)
	local sell=button("Sell","Sell All Fruit",UI.Colors.Green,slotsBar,UDim2.new(1,-212,0,4),UDim2.fromOffset(204,52),function() request("Sell") end,20)
	local gridMode
	local function layoutRows(mode)
		if gridMode==mode then return end;gridMode=mode
		local old=list:FindFirstChildOfClass("UIListLayout") or list:FindFirstChildOfClass("UIGridLayout");if old then old:Destroy() end
		if mode then UI.Grid(3,168,12).Parent=list else UI.List(Enum.FillDirection.Vertical,8).Parent=list end
	end
	-- Elements are reused by name: state packets arrive every tick, so rebuilding would drop clicks mid-press.
	local callbacks,used,order={},{},0
	local function element(name,create)
		order+=1;used[name]=true
		local e=list:FindFirstChild(name)
		if not e then e=create();e.Name=name;e.Parent=list;e.Activated:Connect(function() local fn=callbacks[name];if fn then fn() end end) end
		e.LayoutOrder=order
		return e
	end
	local function setArt(holder,atlas,sprite,props)
		local key=atlas.."/"..sprite;local old=holder:FindFirstChild("Illustration")
		if old and old:GetAttribute("Key")==key then return old end
		if old then old:Destroy() end
		local a=UI.Art(holder,atlas,sprite,props);if a then a:SetAttribute("Key",key) end
		return a
	end
	-- Plot / seed card.
	local function card(name,o)
		callbacks[name]=o.onClick
		local c=element(name,function()
			local b=UI.New("TextButton",{Text="",AutoButtonColor=false,BackgroundTransparency=1})
			UI.Badge(b,"",nil,{Name="Pill",AnchorPoint=Vector2.new(.5,1),Position=UDim2.new(.5,0,1,-30),Size=UDim2.fromOffset(130,34),ZIndex=5})
			UI.Progress(b,{Name="Track",AnchorPoint=Vector2.new(.5,1),Position=UDim2.new(.5,0,1,-6),Size=UDim2.new(1,-40,0,22),ZIndex=5})
			UI.Label("",15,{Name="Title",FontFace=UI.FontBold,Position=UDim2.fromOffset(10,6),Size=UDim2.new(1,-20,0,20),TextXAlignment=Enum.TextXAlignment.Center,TextWrapped=false,ZIndex=5,Parent=b})
			return b
		end)
		UI.Skin(c,"cards",o.selected and "selected" or "product")
		local a=setArt(c,o.atlas,o.sprite,{Position=UDim2.fromOffset(14,20),Size=UDim2.new(1,-28,1,-58)});if a then a.ImageColor3=o.tint or Color3.new(1,1,1) end
		UI.SetBadge(c.Pill,o.pill,o.kind);c.Pill.Size=UDim2.fromOffset(math.clamp(#o.pill*11+34,96,170),34)
		c.Track.Visible=o.progress~=nil;if o.progress then UI.SetProgress(c.Track,o.progress,Color3.fromRGB(110,214,70)) end
		c.Pill.Position=UDim2.new(.5,0,1,o.progress and -30 or -10)
		c.Title.Text=o.title or ""
		return c
	end
	local function row(name,text,color,onClick)
		callbacks[name]=onClick
		local r=element(name,function()
			local b=UI.New("TextButton",{Text="",AutoButtonColor=false,BackgroundTransparency=1,Size=UDim2.new(1,-8,0,70)})
			UI.Label("",18,{Name="Text",Position=UDim2.fromOffset(22,4),Size=UDim2.new(1,-44,1,-8),Parent=b})
			return b
		end)
		UI.Skin(r,"cards",color==UI.Colors.Orange and "today" or "product")
		r.Text.Text=text;r.Text.TextTransparency=color==UI.Colors.Disabled and .45 or 0
	end
	local tabs={}
	render=function()
		if not panel.Visible or not state then return end
		for key,t in tabs do UI.SetTab(t,tab==key and "green" or nil) end
		local gardenTab=tab=="Garden" or tab=="Seeds"
		selection.Visible=gardenTab
		list.Size=gardenTab and UDim2.fromOffset(600,352) or UDim2.fromOffset(880,352)
		slotsBar.Size=gardenTab and UDim2.fromOffset(600,58) or UDim2.fromOffset(880,58)
		layoutRows(gardenTab);table.clear(used);order=0
		if seedUid and not state.seeds[seedUid] then seedUid=nil end
		local seed=seedUid and state.seeds[seedUid]
		-- Selected plot panel
		local plot=state.plots[tostring(slot)];local def=plot and Seeds.ById[plot.id]
		selTitle.Text=def and ("Slot "..slot.." • "..def.name) or ("Slot "..slot)
		setArt(selArt,"garden",plot and (plot.mature and "plotReady" or "plotGrowing") or "plotEmpty",{Size=UDim2.fromScale(1,1)})
		local ready=plot and plot.mature and plot.nextFruitAt<=state.now
		if not plot then UI.SetBadge(selBadge,seed and "Ready to plant" or "Empty",seed and "gold" or nil)
		elseif ready then UI.SetBadge(selBadge,"Ready to harvest","ready")
		elseif plot.mature then UI.SetBadge(selBadge,"Fruit in "..math.max(0,plot.nextFruitAt-state.now).."s",nil)
		else UI.SetBadge(selBadge,"Growing "..math.floor(plot.progress/def.grow*100).."%",nil) end
		fruitValue.Text=def and (def.name.." ×"..def.yield) or (seed and Seeds.ById[seed.id].name.." seed" or "—")
		valueText.Text=def and NF.Short(Math.Value({id=plot.id,zone=plot.zone,rebirthDrop=plot.rebirthDrop,mutations=plot.mutations})*def.yield) or "—"
		local label=primary.Button:FindFirstChildWhichIsA("TextLabel",true)
		label.Text=plot and "Harvest" or (seed and "Plant" or "Select Seed")
		UI.SetButtonColor(primary,(not plot or ready) and UI.Colors.Green or UI.Colors.Slate)
		water.Visible=plot~=nil;cut.Visible=plot~=nil
		UI.SetButtonColor(water,plot and not plot.mature and not plot.watered and UI.Colors.Blue or UI.Colors.Slate)
		water.Button:FindFirstChildWhichIsA("TextLabel",true).Text=plot and plot.watered and "Watered" or "Water"
		if cutPending~=slot then cutPending=nil end
		confirm.Visible=cutPending~=nil;plotActions.Visible=cutPending==nil
		-- Bottom bar
		local count=0;for _,f in state.fruits do count+=f.count end
		if tab=="Shop" then slotsLabel.Text="Fruit "..count.." • Value";slotsValue.Text=NF.Short((Math.SellQuote(state.fruits,state.sold)));slotsValue.Position=UDim2.fromOffset(250,0)
		else slotsLabel.Text="Planting Slots";slotsValue.Text=state.slots.." / "..GardenConfig.MaxSlots end
		upgrade.Visible=tab~="Shop";sell.Visible=tab=="Shop"
		local ulabel=upgrade.Button:FindFirstChildWhichIsA("TextLabel",true);ulabel.Text=state.slots>=GardenConfig.MaxSlots and "Max Slots" or ("Upgrade • "..NF.Short(state.upgrade).." Wood")
		if tab=="Garden" then
			if not state.base then row("NoBase","All bases occupied. Your garden will be ready when a base opens",UI.Colors.Slate,function() end) end
			for i=1,state.slots do local index=i;local p=state.plots[tostring(i)];local d=p and Seeds.ById[p.id]
				local o={atlas="garden",selected=slot==i,onClick=function() slot=index;cutPending=nil;render() end,title=d and d.name or ("Slot "..i)}
				if not p then o.sprite="plotEmpty";o.pill=(slot==i and seed) and "Plant here" or (slot==i and "Select Seed" or "Empty");o.kind=(slot==i and seed) and "gold" or nil
				elseif p.mature and p.nextFruitAt<=state.now then o.sprite="plotReady";o.pill="Ready";o.kind="ready"
				elseif p.mature then o.sprite="plotReady";o.pill="Fruit "..math.max(0,p.nextFruitAt-state.now).."s"
				else o.sprite="plotGrowing";o.pill=p.watered and "Watered" or "Growing";o.progress=math.clamp(p.progress/d.grow,0,1) end
				card("Slot"..i,o)
			end
		elseif tab=="Seeds" then
			local keys={};for uid in state.seeds do table.insert(keys,uid) end;table.sort(keys)
			if #keys==0 then row("Empty","Find seeds in trees, chests or the village shop",UI.Colors.Slate,function() end) end
			for _,uid in keys do local key=uid;local s=state.seeds[uid];local d=Seeds.ById[s.id]
				card("Seed_"..uid,{atlas="garden",sprite="seedPouch",tint=d.color:Lerp(Color3.new(1,1,1),.6),selected=seedUid==uid,title=d.name.." ×"..s.count,pill=d.rarity.." • "..math.floor(d.grow/60).."m",
					onClick=function() seedUid=key;tab="Garden";cutPending=nil;render();say("Pick a plot, then press Plant") end})
			end
		elseif tab=="Merchant" then
			local m=state.merchant
			if not m then row("NoMerchant","Merchant absent. Arrives at :30 UTC every hour for 10 min",UI.Colors.Slate,function() end) else
				for _,o in m.offers do local id=o.id
					row("Merchant_"..id,o.name.." • "..NF.Short(o.price).." "..o.currency.." • Left "..o.left.."\nMerchant leaves in "..math.max(0,m.endsAt-state.now).." sec",o.left>0 and UI.Colors.Purple or UI.Colors.Disabled,function() request("MerchantBuy",id) end)
				end
			end
		else
			local caps={};for id,n in GardenConfig.SellCaps do table.insert(caps,id.." "..math.max(0,n-(state.sold[id] or 0)).."/"..n) end;table.sort(caps)
			row("SellCaps","Full-price items today (UTC): "..table.concat(caps," • ").."\nCan exceed cap by ×"..GardenConfig.OverCapMult,UI.Colors.Slate,function() end)
			for _,d in Seeds.List do local id=d.id
				row("Buy_"..id,d.name.." • "..NF.Short(Math.SeedPrice(id,state.shopZone)).." Coins • Left "..state.stock[id].."\n"..d.rarity.." • Restock in "..math.max(0,state.restockAt-state.now).." sec",state.stock[id]>0 and UI.Colors.Orange or UI.Colors.Disabled,function() request("Buy",id) end)
			end
		end
		for _,v in list:GetChildren() do if v:IsA("GuiObject") and not used[v.Name] then v:Destroy();callbacks[v.Name]=nil end end
	end
	for i,t in {{"Garden","Garden","leaf"},{"Seeds","Seeds","garden/seedPouch"},{"Shop","Shop","shop"},{"Merchant","Merchant","bag"}} do local target=t[1]
		tabs[target]=UI.Tab({name="Tab"..target,text=t[2],icon=t[3],size=UDim2.fromOffset(144,60),position=UDim2.fromOffset(40+(i-1)*152,122),parent=panel,textSize=23,iconSize=34,onClick=function() tab=target;cutPending=nil;render() end})
	end
	local function show(target)
		local inv=player.PlayerGui:FindFirstChild("InventoryHUD");if inv then inv.Panel.Visible=false;inv.Result.Visible=false end
		if target then tab=target end;panel.Visible=true;cutPending=nil;render();request("Sync")
	end
	button("Toggle","Garden / Seeds",UI.Colors.Teal,gui,UDim2.fromOffset(16,305),UDim2.fromOffset(178,48),function() if panel.Visible then panel.Visible=false else show() end end)
	Net.Event("GardenState").OnClientEvent:Connect(function(packet) state=packet;render() end)
	Net.Event("GardenShow").OnClientEvent:Connect(show)
	local hooked=setmetatable({},{__mode="k"})
	local function hook(tool)
		if not tool:IsA("Tool") or not tool:GetAttribute("GardenWater") or hooked[tool] then return end;hooked[tool]=true
		tool.Activated:Connect(function()
			local hr=player.Character and player.Character:FindFirstChild("HumanoidRootPart");if not hr then return end
			local nearest,distance=nil,18
			for _,part in Collection:GetTagged("GardenSlot") do if part:GetAttribute("RuntimeGarden") and part:GetAttribute("OwnerUserId")==player.UserId then local d=(part.Position-hr.Position).Magnitude;if d<distance then nearest=part;distance=d end end end
			if nearest then request("Water",nearest:GetAttribute("SlotIndex")) end
		end)
	end
	local function watch(container) for _,tool in container:GetChildren() do hook(tool) end;container.ChildAdded:Connect(hook) end
	watch(player:WaitForChild("Backpack"));if player.Character then watch(player.Character) end;player.CharacterAdded:Connect(watch)
	player.ChildAdded:Connect(function(child) if child:IsA("Backpack") then watch(child) end end)
	task.spawn(function() while not require(script.Parent.ClientData).IsReady() do task.wait(.1) end;request("Sync") end)
end
return Garden
