local Players=game:GetService("Players")
local Shared=game.ReplicatedStorage:WaitForChild("Shared")
local Net=require(Shared.Net)
local UI=require(Shared.UIKit)
local NF=require(Shared.NumberFormat)
local Loot=require(Shared.Loot)
local Visual=require(Shared.WeaponVisual)
local Weapons=require(Shared.Config.Weapons)
local Rarities=require(Shared.Config.Rarities)
local Config=require(Shared.Config.Chests)
local Data=require(script.Parent.ClientData)
local Inventory={}
local player=Players.LocalPlayer

function Inventory.Start()
	local gui=UI.New("ScreenGui",{Name="InventoryHUD",ResetOnSpawn=false,DisplayOrder=8,Parent=player:WaitForChild("PlayerGui")})
	local panel=UI.New("Frame",{Name="Panel",AnchorPoint=Vector2.new(.5,.5),Position=UDim2.fromScale(.5,.5),Size=UDim2.fromOffset(820,570),BackgroundColor3=UI.Colors.Panel,Visible=false,Parent=gui},{UI.Corner(18),UI.Stroke(4),UI.Padding(14)})
	local title=UI.Label("กระเป๋า • หีบและอาวุธ",22,{Name="Title",Parent=panel})
	local message=UI.Label("เปิดหีบและหลอมที่แท่นในหมู่บ้าน",14,{Position=UDim2.fromOffset(0,32),Size=UDim2.new(1,0,0,28),Parent=panel})
	local tab="Weapons";local selected,pendingSelection,pendingFuse,pendingDelete;local busy=false
	local body=UI.New("Frame",{Name="Body",BackgroundTransparency=1,Position=UDim2.fromOffset(0,112),Size=UDim2.new(1,0,1,-244),Parent=panel})
	local function list(name)
		return UI.New("ScrollingFrame",{Name=name,BackgroundTransparency=1,Size=UDim2.fromScale(1,1),AutomaticCanvasSize=Enum.AutomaticSize.Y,CanvasSize=UDim2.new(),ScrollBarThickness=5,Parent=body},{UI.List(Enum.FillDirection.Vertical,8)})
	end
	local chestList=list("Chests");local weaponList=list("Weapons")
	local details=UI.Label("เลือกอาวุธเพื่อสวมใส่หรือหลอมของซ้ำ",15,{Name="Details",Position=UDim2.new(0,0,1,-122),Size=UDim2.new(1,0,0,65),Parent=panel})
	local buttons=UI.New("Frame",{Name="Actions",BackgroundTransparency=1,Position=UDim2.new(0,0,1,-49),Size=UDim2.new(1,0,0,49),Parent=panel})
	local result=UI.New("Frame",{Name="Result",Active=true,AnchorPoint=Vector2.new(.5,.5),Position=UDim2.fromScale(.5,.5),Size=UDim2.fromOffset(380,365),BackgroundColor3=UI.Colors.PanelDark,Visible=false,ZIndex=20,Parent=gui},{UI.Corner(20),UI.Stroke(4),UI.Padding(18)})
	local resultLabel=UI.Label("กำลังเปิดหีบ...",20,{Name="Reward",Position=UDim2.fromOffset(0,190),Size=UDim2.new(1,0,0,90),TextXAlignment=Enum.TextXAlignment.Center,ZIndex=21,Parent=result})
	local resultView=UI.New("ViewportFrame",{Name="Preview",BackgroundTransparency=1,Size=UDim2.new(1,0,0,185),ZIndex=21,Ambient=Color3.fromRGB(220,220,220),LightColor=Color3.new(1,1,1),Parent=result})
	local function preview(view,def,item)
		view:ClearAllChildren()
		local world=Instance.new("WorldModel");world.Parent=view
		local model=Visual.Build(def,item,true);model.Parent=world
		local cf,size=model:GetBoundingBox()
		local camera=Instance.new("Camera");camera.FieldOfView=35;camera.CFrame=CFrame.lookAt(cf.Position+Vector3.new(0,size.Y*.15,math.max(size.Magnitude,4)*1.9),cf.Position);camera.Parent=view;view.CurrentCamera=camera
	end
	local render,resize
	local function request(action,arg)
		if busy then return false end
		busy=true
		local ok,success,text,extra=pcall(function() return Net.Function("InventoryAction"):InvokeServer(action,arg) end)
		busy=false
		if not ok then message.Text="เชื่อมต่อไม่สำเร็จ ลองอีกครั้ง";return false end
		message.Text=text or (success and "เรียบร้อย" or "ลองอีกครั้ง")
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
		resultLabel.Text=(reward.item.giant and "GIANT!\n" or "")..def.thai.."\n"..def.rarity.." • IL "..reward.item.il.." • Power "..NF.Short(Loot.Power(reward.item))
		resultLabel.TextColor3=Rarities.Color[def.rarity]:Lerp(Color3.new(1,1,1),.5)
		if reward.item.giant then
			local hum=player.Character and player.Character:FindFirstChildOfClass("Humanoid")
			if hum then local original=hum.CameraOffset;for _=1,8 do hum.CameraOffset=original+Vector3.new(math.random()-.5,math.random()-.5,0);task.wait(.04) end;hum.CameraOffset=original end
		end
		busy=false
	end
	local closeResult=UI.Button({text="เก็บเข้ากระเป๋าแล้ว • ปิด",color=UI.Colors.Green,size=UDim2.new(1,0,0,48),onClick=function() if not busy then result.Visible=false end end})
	closeResult.Name="Close";closeResult.Position=UDim2.new(0,0,1,-48);closeResult.Parent=result
	closeResult.ZIndex=22;for _,g in closeResult:GetDescendants() do if g:IsA("GuiObject") then g.ZIndex=22 end end
	local function compatibleIds()
		local inv=Data.Get("Inventory.Weapons") or {};local item=inv[selected];local ids={}
		if item then for uid,w in inv do if uid~=selected and Loot.Compatible(item,w) then table.insert(ids,uid) end end end
		table.sort(ids);if #ids>=2 then return {selected,ids[1],ids[2]} end
	end
	local equip=UI.Button({text="สวมใส่",color=UI.Colors.Green,size=UDim2.new(.25,-6,1,0),onClick=function() if selected then request("Equip",selected) end end})
	equip.Name="Equip";equip.Parent=buttons
	local fuse=UI.Button({text="หลอม ×3",color=UI.Colors.Orange,size=UDim2.new(.25,-6,1,0),onClick=function()
		local ids=compatibleIds();if not ids then message.Text="ต้องมีอาวุธ / IL / ดาว / Giant / Rot เดียวกัน 3 ชิ้น";return end
		local key=table.concat(ids,"|")
		if pendingFuse~=key then pendingFuse=key;message.Text="กดหลอมอีกครั้งเพื่อใช้ของ 3 ชิ้นและ Wood ตามราคาด้านล่าง";return end
		pendingFuse=nil;request("Fuse",ids)
	end})
	fuse.Name="Fuse";fuse.Position=UDim2.fromScale(.25,0);fuse.Parent=buttons
	local delete=UI.Button({text="ทิ้ง",color=UI.Colors.Red,size=UDim2.new(.25,-6,1,0),onClick=function()
		if not selected or busy then return end
		if pendingDelete~=selected then pendingDelete=selected;message.Text="กดทิ้งอีกครั้งเพื่อลบอาวุธที่เลือกถาวร";return end
		local uid=selected;pendingDelete=nil;request("Delete",uid)
	end})
	delete.Name="Delete";delete.Position=UDim2.fromScale(.5,0);delete.Parent=buttons
	local close=UI.Button({text="ปิด",color=UI.Colors.Blue,size=UDim2.new(.25,-6,1,0),onClick=function() panel.Visible=false;pendingFuse=nil;pendingDelete=nil end})
	close.Name="Close";close.Position=UDim2.fromScale(.75,0);close.Parent=buttons
	for i,name in {"Weapons","Chests"} do
		local holder=UI.Button({text=name=="Weapons" and "อาวุธ" or "หีบ",color=name=="Weapons" and UI.Colors.Blue or UI.Colors.Orange,size=UDim2.new(.5,-6,0,46),onClick=function() tab=name;resize() end})
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
		title.Text="กระเป๋า • อาวุธ "..#ids.." / "..Config.MaxWeapons
		-- The function response and DataPatch events can arrive in either order.
		if pendingSelection and inv[pendingSelection] then pendingSelection=nil end
		if selected and not inv[selected] and selected~=pendingSelection then selected=nil;pendingFuse=nil end
		for i,uid in ids do
			local item=inv[uid];local def=Weapons.ById[item.id]
			if def then
				local row=UI.New("TextButton",{Name="Item_"..uid,Size=UDim2.new(1,-8,0,90),BackgroundColor3=selected==uid and UI.Colors.Blue or UI.Colors.PanelDark,Text="",AutoButtonColor=true,LayoutOrder=i,Parent=weaponList},{UI.Corner(10)})
				local view=UI.New("ViewportFrame",{BackgroundTransparency=1,Position=UDim2.fromOffset(4,4),Size=UDim2.fromOffset(64,80),Ambient=Color3.new(1,1,1),Parent=row});preview(view,def,item)
				UI.Label((equipped==uid and "✓ " or "")..(item.giant and "GIANT " or "")..def.thai,14,{Position=UDim2.fromOffset(74,4),Size=UDim2.new(1,-80,0,38),Parent=row})
				UI.Label(def.rarity.." • IL "..item.il.." • ★"..item.stars.."\nPower "..NF.Short(Loot.Power(item)),13,{Position=UDim2.fromOffset(74,42),Size=UDim2.new(1,-80,0,43),TextColor3=Rarities.Color[def.rarity]:Lerp(Color3.new(1,1,1),.55),Parent=row})
				row.Activated:Connect(function() selected=uid;pendingSelection=nil;pendingFuse=nil;pendingDelete=nil;render() end)
			end
		end
		if #ids==0 then UI.Label("ยังไม่มีอาวุธ — เก็บหีบจากป่าแล้วกลับมาเปิด",16,{Size=UDim2.new(1,-10,0,80),Parent=weaponList}) end
		for i,c in chests do
			local row=UI.New("Frame",{Name="Chest_"..tostring(c.uid),BackgroundColor3=UI.Colors.PanelDark,Size=UDim2.new(1,-8,0,124),LayoutOrder=i,Parent=chestList},{UI.Corner(10),UI.Padding(8)})
			UI.Label(c.rarity.." • LEVEL "..c.level.." ×"..c.count,16,{Size=UDim2.new(1,0,0,24),Parent=row})
			local odds,giant=Loot.Odds(c.rarity,c.level);local out={}
			for j,v in odds do if v>0 then table.insert(out,Rarities.Order[j].." "..string.format("%.1f%%",v*100)) end end
			UI.Label("IL "..c.zone.." • Giant "..string.format("%.1f%%",giant*100).."\n"..table.concat(out," / "),12,{Position=UDim2.fromOffset(0,25),Size=UDim2.new(1,0,0,43),Parent=row})
			local open=UI.Button({text="เปิด 1 ใบ",color=UI.Colors.Orange,size=UDim2.new(1,0,0,46),onClick=function()
				local ok,reward=request("Open",c.uid);if ok then showReward(reward) end
			end});open.Name="Open";open.Position=UDim2.fromOffset(0,70);open.Parent=row
		end
		if #chests==0 then UI.Label("ยังไม่มีหีบ — เคลียร์ต้นไม้รอบจุดหีบแล้ว End Run",16,{Size=UDim2.new(1,-10,0,80),Parent=chestList}) end
		local item=inv[selected];local def=item and Weapons.ById[item.id]
		if def then details.Text=def.thai.." • Power "..NF.Short(Loot.Power(item)).." • Speed "..def.speed.." • Area "..def.area*(item.giant and 2 or 1).."\n"..(item.stars<5 and ("หลอม ★"..(item.stars+1)..": ใช้ของเหมือนกัน 3 ชิ้น + Wood "..NF.Short(Loot.FuseCost(item))) or "สูงสุด ★5 แล้ว")
		else details.Text="เลือกอาวุธเพื่อสวมใส่หรือหลอมของซ้ำ • เปิดหีบที่แท่นหมู่บ้าน" end
	end
	resize=function()
		local size=workspace.CurrentCamera.ViewportSize
		panel.Size=UDim2.fromOffset(math.min(820,size.X-28),math.min(570,size.Y-60))
		local wide=size.X>=760
		weaponList.Visible=wide or tab=="Weapons";chestList.Visible=wide or tab=="Chests"
		chestList.Position=UDim2.fromScale(0,0);chestList.Size=UDim2.fromScale(wide and .43 or 1,1)
		weaponList.Position=UDim2.fromScale(wide and .45 or 0,0);weaponList.Size=UDim2.fromScale(wide and .55 or 1,1)
		local s=result:FindFirstChildOfClass("UIScale") or Instance.new("UIScale");s.Scale=math.min(1,(size.X-20)/380,(size.Y-30)/365);s.Parent=result
	end
	local function show()
		panel.Visible=true;result.Visible=false;pendingFuse=nil;pendingDelete=nil;message.Text="เปิดหีบและหลอมที่แท่นในหมู่บ้าน";resize();render()
		task.spawn(function() request("Sync") end)
	end
	local toggle=UI.Button({text="กระเป๋า / หีบ",color=UI.Colors.Purple,size=UDim2.fromOffset(178,48),onClick=function() if panel.Visible then panel.Visible=false else show() end end})
	toggle.Name="Toggle";toggle.Position=UDim2.fromOffset(16,245);toggle.Parent=gui
	Net.Event("InventoryShow").OnClientEvent:Connect(show)
	Data.Changed:Connect(function(path) if path=="" or path:sub(1,10)=="Inventory." then if panel.Visible then render() end end end)
	workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(resize)
	resize()
end
return Inventory
