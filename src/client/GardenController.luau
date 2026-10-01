local Players=game:GetService("Players")
local Collection=game:GetService("CollectionService")
local S=game.ReplicatedStorage.Shared
local Net=require(S.Net);local UI=require(S.UIKit);local NF=require(S.NumberFormat)
local Seeds=require(S.Config.Seeds);local Math=require(S.GardenMath)
local Garden={}
function Garden.Start()
	local player=Players.LocalPlayer
	local gui=UI.New("ScreenGui",{Name="GardenHUD",ResetOnSpawn=false,DisplayOrder=9,Parent=player:WaitForChild("PlayerGui")})
	local panel=UI.New("Frame",{Name="Panel",AnchorPoint=Vector2.new(.5,.5),Position=UDim2.fromScale(.5,.5),Size=UDim2.fromOffset(780,570),Visible=false,BackgroundColor3=UI.Colors.Panel,Parent=gui},{UI.Corner(18),UI.Stroke(4),UI.Padding(14)})
	UI.Label("สวนของฉัน • GARDEN",22,{Parent=panel})
	local message=UI.Label("เลือกเมล็ด แล้วเลือกช่องเพื่อปลูก",14,{Name="Message",Position=UDim2.fromOffset(0,32),Size=UDim2.new(1,0,0,28),Parent=panel})
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
			message.Text=ok and (msg or "สวนพร้อมแล้ว") or "ติดต่อเซิร์ฟเวอร์ไม่ได้ ลองใหม่"
			message.TextColor3=ok and success and UI.Colors.Text or UI.Colors.Accent
			task.wait(.32);busy=false
		end)
	end
	local function row(name,text,color,callback)
		return button(name,text,color,list,UDim2.new(),UDim2.new(1,-7,0,58),callback)
	end
	render=function()
		if not panel.Visible or not state then return end
		for _,v in list:GetChildren() do if v:IsA("GuiObject") then v:Destroy() end end
		if seedUid and not state.seeds[seedUid] then seedUid=nil end
		local seed=seedUid and state.seeds[seedUid];local chosen=seed and Seeds.ById[seed.id].name or "ยังไม่เลือก (แท็บเมล็ด)"
		local count,value=0,0;for _,f in state.fruits do count+=f.count;value+=Math.Value(f)*f.count end
		detail.Text="ช่อง "..slot.." • เมล็ด: "..chosen.."\nผล "..count.." ลูก • ขายรวม "..NF.Short(value).." Coins • เพิ่มช่อง "..NF.Short(state.upgrade).." Wood"
		if tab=="Garden" then
			if not state.base then row("NoBase","ฐานเต็ม — สวนจะพร้อมเมื่อมีฐานว่าง",UI.Colors.Slate,function() end) end
			for i=1,state.slots do local index=i;local plot=state.plots[tostring(i)];local text="ช่อง "..i.." • ว่าง";local color=slot==i and UI.Colors.Teal or UI.Colors.Slate
				if plot then
					local def=Seeds.ById[plot.id];local status=plot.mature and (plot.nextFruitAt<=state.now and "เก็บผลได้" or "ผลอีก "..math.max(0,plot.nextFruitAt-state.now).." วิ") or (math.floor(plot.progress/def.grow*100).."% • "..math.ceil((def.grow-plot.progress)/(plot.watered and 1.1 or 1)).." วิ")
					text="ช่อง "..i.." • "..def.name.." • "..status..(plot.watered and " • รดแล้ว" or "").."\n"..Math.Key(plot.mutations)
				end
				row("Slot"..i,text,color,function() slot=index;cutPending=nil;render() end)
			end
		elseif tab=="Seeds" then
			local keys={};for uid in state.seeds do table.insert(keys,uid) end;table.sort(keys)
			if #keys==0 then row("Empty","หาเมล็ดจากต้นไม้ หีบ หรือร้านในหมู่บ้าน",UI.Colors.Slate,function() end) end
			for _,uid in keys do local key=uid;local seed=state.seeds[uid];local def=Seeds.ById[seed.id]
				row("Seed_"..uid,def.name.." ×"..seed.count.." • "..def.rarity.." • Zone "..seed.zone.."\nโต "..math.floor(def.grow/60).." นาที • เก็บซ้ำได้",seedUid==uid and UI.Colors.Teal or UI.Colors.Green,function() seedUid=key;tab="Garden";cutPending=nil;render() end)
			end
		else
			for _,def in Seeds.List do local id=def.id
				row("Buy_"..id,def.name.." • "..NF.Short(Math.SeedPrice(id,state.shopZone)).." Coins • เหลือ "..state.stock[id].."\n"..def.rarity.." • รีสต็อกอีก "..math.max(0,state.restockAt-state.now).." วิ",state.stock[id]>0 and UI.Colors.Orange or UI.Colors.Disabled,function() request("Buy",id) end)
			end
		end
	end
	for i,name in {"Garden","Seeds","Shop"} do local target=name
		button("Tab"..name,({Garden="สวน",Seeds="เมล็ด",Shop="ร้าน / ขายผล"})[name],UI.Colors.Teal,panel,UDim2.new((i-1)/3,0,0,64),UDim2.new(1/3,-8,0,42),function() tab=target;cutPending=nil;render() end)
	end
	local actions={{"Plant","ปลูก",UI.Colors.Green,function() if seedUid then request("Plant",{slot=slot,seed=seedUid}) else tab="Seeds";render();message.Text="เลือกเมล็ดที่จะปลูกก่อน" end end},
		{"Water","รดน้ำ",UI.Colors.Blue,function() request("Water",slot) end},
		{"Harvest","เก็บผล",UI.Colors.Orange,function() request("Harvest",slot) end},
		{"Cut","ตัดต้น",UI.Colors.Red,function() if cutPending==slot then cutPending=nil;request("Cut",slot) else cutPending=slot;message.Text="กดตัดต้นอีกครั้งเพื่อยืนยัน ช่อง "..slot.." จะว่าง" end end}}
	for i,a in actions do button(a[1],a[2],a[3],panel,UDim2.new((i-1)/4,0,1,-98),UDim2.new(.25,-8,0,42),a[4]) end
	button("Sell","ขายผลทั้งหมด",UI.Colors.Orange,panel,UDim2.new(0,0,1,-48),UDim2.new(1/3,-8,0,42),function() request("Sell") end)
	button("Upgrade","เพิ่มช่องปลูก",UI.Colors.Purple,panel,UDim2.new(1/3,0,1,-48),UDim2.new(1/3,-8,0,42),function() request("Upgrade") end)
	button("Close","ปิด",UI.Colors.Slate,panel,UDim2.new(2/3,0,1,-48),UDim2.new(1/3,-8,0,42),function() panel.Visible=false end)
	local function resize()
		local size=workspace.CurrentCamera.ViewportSize;panel.Size=UDim2.fromOffset(math.min(780,size.X-28),math.min(570,size.Y-56))
	end
	local function show(target)
		local inv=player.PlayerGui:FindFirstChild("InventoryHUD");if inv then inv.Panel.Visible=false;inv.Result.Visible=false end
		if target then tab=target end;panel.Visible=true;cutPending=nil;resize();render();request("Sync")
	end
	button("Toggle","สวน / เมล็ด",UI.Colors.Teal,gui,UDim2.fromOffset(16,305),UDim2.fromOffset(178,48),function() if panel.Visible then panel.Visible=false else show() end end)
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
