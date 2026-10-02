local Players=game:GetService("Players")
local Collection=game:GetService("CollectionService")
local S=game.ReplicatedStorage.Shared
local Net=require(S.Net);local UI=require(S.UIKit);local NF=require(S.NumberFormat)
local Seeds=require(S.Config.Seeds);local Math=require(S.GardenMath);local GardenConfig=require(S.Config.Garden)
local Garden={}
function Garden.Start()
	local player=Players.LocalPlayer
	local gui=UI.New("ScreenGui",{Name="GardenHUD",ResetOnSpawn=false,DisplayOrder=9,Parent=player:WaitForChild("PlayerGui")})
	local panel=UI.New("Frame",{Name="Panel",AnchorPoint=Vector2.new(.5,.5),Position=UDim2.fromScale(.5,.5),Size=UDim2.fromOffset(780,570),Visible=false,BackgroundColor3=UI.Colors.Panel,Parent=gui},{UI.Corner(18),UI.Stroke(4),UI.Padding(14)})
	UI.Label("My Garden",22,{Parent=panel})
	local message=UI.Label("Select a seed, then a plot to plant it",14,{Name="Message",Position=UDim2.fromOffset(0,32),Size=UDim2.new(1,0,0,28),Parent=panel})
	local list=UI.New("ScrollingFrame",{Name="Items",Position=UDim2.fromOffset(0,112),Size=UDim2.new(1,0,1,-270),BackgroundTransparency=1,ScrollBarThickness=5,AutomaticCanvasSize=Enum.AutomaticSize.Y,CanvasSize=UDim2.new(),Parent=panel},{UI.List(Enum.FillDirection.Vertical,8)})
	local detail=UI.Label("",14,{Name="Detail",Position=UDim2.new(0,0,1,-149),Size=UDim2.new(1,0,0,40),Parent=panel})
	local state,seedUid,cutPending;local slot=1;local tab="Garden";local busy=false
	local render,request
	local function button(name,text,color,parent,pos,size,callback)
		local b=UI.Button({text=text,color=color,size=size,onClick=callback});b.Name=name;b.Position=pos;b.Parent=parent;return b
	end
	request=function(action,arg)
		if busy then return end;busy=true
		task.spawn(function()
			local ok,success,msg=pcall(function() return Net.Function("GardenAction"):InvokeServer(action,arg) end)
			message.Text=ok and (msg or "Garden ready") or "Could not reach the server. Try again"
			message.TextColor3=ok and success and UI.Colors.Text or UI.Colors.Accent
			task.wait(.32);busy=false
		end)
	end
	-- Rows are reused by name: state packets arrive every tick, so rebuilding would drop clicks mid-press.
	local rows,used,order={},{},0
	local function row(name,text,color,callback)
		order+=1;used[name]=true
		local r=rows[name]
		if not r then
			local holder=button(name,text,color,list,UDim2.new(),UDim2.new(1,-7,0,58),function() rows[name].fn() end)
			r={holder=holder,button=holder:FindFirstChild("Button"),label=holder:FindFirstChildWhichIsA("TextLabel",true)};rows[name]=r
		end
		r.fn=callback;r.button.BackgroundColor3=color;r.holder.LayoutOrder=order
		if r.label.Text~=text then r.label.Text=text end
		return r.holder
	end
	render=function()
		if not panel.Visible or not state then return end
		table.clear(used);order=0
		if seedUid and not state.seeds[seedUid] then seedUid=nil end
		local seed=seedUid and state.seeds[seedUid];local chosen=seed and Seeds.ById[seed.id].name or "None selected (Seeds tab)"
		local count=0;for _,f in state.fruits do count+=f.count end;local value=Math.SellQuote(state.fruits,state.sold)
		detail.Text="Slot "..slot.." • Seeds: "..chosen.."\nFruit "..count.." fruit • Total value "..NF.Short(value).." Coins • Add Slots "..NF.Short(state.upgrade).." Wood"
		if tab=="Garden" then
			if not state.base then row("NoBase","All bases occupied. Your garden will be ready when a base opens",UI.Colors.Slate,function() end) end
			for i=1,state.slots do local index=i;local plot=state.plots[tostring(i)];local text="Slot "..i.." • Empty";local color=slot==i and UI.Colors.Teal or UI.Colors.Slate
				if plot then
					local def=Seeds.ById[plot.id];local status=plot.mature and (plot.nextFruitAt<=state.now and "Ready to Harvest" or "Fruit in "..math.max(0,plot.nextFruitAt-state.now).." sec") or (math.floor(plot.progress/def.grow*100).."% • "..math.ceil((def.grow-plot.progress)/(plot.watered and 1.1 or 1)).." sec")
					text="Slot "..i.." • "..def.name.." • "..status..(plot.watered and " • Watered" or "").."\n"..Math.Key(plot.mutations)
				end
				row("Slot"..i,text,color,function() slot=index;cutPending=nil;render() end)
			end
		elseif tab=="Seeds" then
			local keys={};for uid in state.seeds do table.insert(keys,uid) end;table.sort(keys)
			if #keys==0 then row("Empty","Find seeds in trees, chests or the village shop",UI.Colors.Slate,function() end) end
			for _,uid in keys do local key=uid;local seed=state.seeds[uid];local def=Seeds.ById[seed.id]
				row("Seed_"..uid,def.name.." ×"..seed.count.." • "..def.rarity.." • Zone "..seed.zone.."\nGrowth "..math.floor(def.grow/60).." min • Repeatable",seedUid==uid and UI.Colors.Teal or UI.Colors.Green,function() seedUid=key;tab="Garden";cutPending=nil;render() end)
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
			for _,def in Seeds.List do local id=def.id
				row("Buy_"..id,def.name.." • "..NF.Short(Math.SeedPrice(id,state.shopZone)).." Coins • Left "..state.stock[id].."\n"..def.rarity.." • Restock in "..math.max(0,state.restockAt-state.now).." sec",state.stock[id]>0 and UI.Colors.Orange or UI.Colors.Disabled,function() request("Buy",id) end)
			end
		end
		for name,r in rows do if not used[name] then r.holder:Destroy();rows[name]=nil end end
	end
	for i,name in {"Garden","Seeds","Shop","Merchant"} do local target=name
		button("Tab"..name,({Garden="Garden",Seeds="Seeds",Shop="Shop / Sell Fruit",Merchant="Traveling Merchant"})[name],UI.Colors.Teal,panel,UDim2.new((i-1)/4,0,0,64),UDim2.new(1/4,-8,0,42),function() tab=target;cutPending=nil;render() end)
	end
	local actions={{"Plant","Plant",UI.Colors.Green,function() if seedUid then request("Plant",{slot=slot,seed=seedUid}) else tab="Seeds";render();message.Text="Select a seed first" end end},
		{"Water","Water",UI.Colors.Blue,function() request("Water",slot) end},
		{"Harvest","Harvest",UI.Colors.Orange,function() request("Harvest",slot) end},
		{"Cut","Cut Tree",UI.Colors.Red,function() if cutPending==slot then cutPending=nil;request("Cut",slot) else cutPending=slot;message.Text="Click Cut again to confirm plot "..slot.." will be empty" end end}}
	for i,a in actions do button(a[1],a[2],a[3],panel,UDim2.new((i-1)/4,0,1,-98),UDim2.new(.25,-8,0,42),a[4]) end
	button("Sell","Sell All Fruit",UI.Colors.Orange,panel,UDim2.new(0,0,1,-48),UDim2.new(1/3,-8,0,42),function() request("Sell") end)
	button("Upgrade","Add Planting Slots",UI.Colors.Purple,panel,UDim2.new(1/3,0,1,-48),UDim2.new(1/3,-8,0,42),function() request("Upgrade") end)
	button("Close","Close",UI.Colors.Slate,panel,UDim2.new(2/3,0,1,-48),UDim2.new(1/3,-8,0,42),function() panel.Visible=false end)
	local function resize()
		local size=workspace.CurrentCamera.ViewportSize;panel.Size=UDim2.fromOffset(math.min(780,size.X-28),math.min(570,size.Y-56))
	end
	local function show(target)
		local inv=player.PlayerGui:FindFirstChild("InventoryHUD");if inv then inv.Panel.Visible=false;inv.Result.Visible=false end
		if target then tab=target end;panel.Visible=true;cutPending=nil;resize();render();request("Sync")
	end
	button("Toggle","Garden / Seeds",UI.Colors.Teal,gui,UDim2.fromOffset(16,305),UDim2.fromOffset(178,48),function() if panel.Visible then panel.Visible=false else show() end end)
	Net.Event("GardenState").OnClientEvent:Connect(function(packet) state=packet;render() end)
	Net.Event("GardenShow").OnClientEvent:Connect(show)
	workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(resize)
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
