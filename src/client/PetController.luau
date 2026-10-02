-- Eggs & pets UI plus local-only visuals (followers, mounts, conveyor eggs, thief markers).
local Players=game:GetService("Players")
local Collection=game:GetService("CollectionService")
local RunService=game:GetService("RunService")
local Input=game:GetService("UserInputService")
local S=game.ReplicatedStorage.Shared
local Net=require(S.Net);local UI=require(S.UIKit);local NF=require(S.NumberFormat)
local Pets=require(S.Config.Pets);local Eggs=require(S.Config.Eggs);local Config=require(S.Config.Base)
local Math=require(S.PetMath);local Visual=require(S.PetVisual);local DecorConfig=require(S.Config.Decor);local ClientData=require(script.Parent.ClientData)
local Controller={}
local TABS={{"Incubator","ตู้ฟัก"},{"Eggs","ไข่"},{"Pets","สัตว์"},{"Base","ฐาน"},{"Belt","สายพานไข่"}}
local PLACE={equip="พกติดตัว",pen="ในคอก",[""]="กระเป๋า"}
local SHIELD={new="ผู้เล่นใหม่ (30 นาที)",afk="AFK เกิน 10 นาที",admin="แอดมินเปิด"}

local function myBase(index)
	for _,b in Collection:GetTagged("PlayerBase") do if b:GetAttribute("BaseIndex")==index then return b end end
end
local function petLine(pet)
	local def=Pets.ById[pet.id]
	return def.name.." ★"..pet.tier.." • "..def.rarity..(pet.mutation and " • "..pet.mutation or "").." • "..PLACE[pet.place or ""]..
		"\n+"..NF.Short(Math.Income(pet)).."/วิ ในคอก • บัฟ "..def.buff.." +"..math.floor(Math.Bonus(pet)*100+.5).."%"..(def.rideable and " • ขี่ได้" or "")
end

function Controller.Start()
	local player=Players.LocalPlayer
	local gui=UI.New("ScreenGui",{Name="PetHUD",ResetOnSpawn=false,DisplayOrder=9,Parent=player:WaitForChild("PlayerGui")})
	local panel=UI.New("Frame",{Name="Panel",AnchorPoint=Vector2.new(.5,.5),Position=UDim2.fromScale(.5,.5),Size=UDim2.fromOffset(780,570),Visible=false,BackgroundColor3=UI.Colors.Panel,Parent=gui},{UI.Corner(18),UI.Stroke(4),UI.Padding(14)})
	UI.Label("ไข่ & สัตว์เลี้ยง • PETS",22,{Parent=panel})
	local message=UI.Label("ฟักไข่ เลี้ยงสัตว์ และป้องกันฐานของคุณ",14,{Name="Message",Position=UDim2.fromOffset(0,32),Size=UDim2.new(1,0,0,28),Parent=panel})
	local list=UI.New("ScrollingFrame",{Name="Items",Position=UDim2.fromOffset(0,112),Size=UDim2.new(1,0,1,-270),BackgroundTransparency=1,ScrollBarThickness=5,AutomaticCanvasSize=Enum.AutomaticSize.Y,CanvasSize=UDim2.new(),Parent=panel},{UI.List(Enum.FillDirection.Vertical,8)})
	local detail=UI.Label("",14,{Name="Detail",Position=UDim2.new(0,0,1,-149),Size=UDim2.new(1,0,0,40),Parent=panel})
	local bar=UI.New("Frame",{Name="Actions",BackgroundTransparency=1,Position=UDim2.new(0,0,1,-98),Size=UDim2.new(1,0,0,96),Parent=panel})
	local state;local tab="Incubator";local slot=1;local eggUid;local selected={};local releasePending;local busy=false
	local render
	local function call(remote,action,arg)
		if busy then return end;busy=true
		task.spawn(function()
			local ok,success,msg=pcall(function() return Net.Function(remote):InvokeServer(action,arg) end)
			message.Text=ok and (msg or "เรียบร้อย") or "ติดต่อเซิร์ฟเวอร์ไม่ได้ ลองใหม่"
			message.TextColor3=ok and success and UI.Colors.Text or UI.Colors.Accent
			if ok and success and action=="Fuse" then table.clear(selected) end
			task.wait(.32);busy=false;render()
		end)
	end
	local function pet(action,arg) call("PetAction",action,arg) end
	local function button(name,text,color,parent,pos,size,callback)
		local b=UI.Button({text=text,color=color,size=size,onClick=callback});b.Name=name;b.Position=pos;b.Parent=parent;return b
	end
	-- State packets arrive every 2 seconds; buttons are updated in place so a
	-- click that lands during a refresh is never lost on a destroyed instance.
	local callbacks,keep,order={},{},0
	local function reuse(parent,name,text,color,pos,size,callback)
		callbacks[parent][name]=callback;keep[parent][name]=true
		local b=parent:FindFirstChild(name)
		if b then
			local label=b.Button:FindFirstChildWhichIsA("TextLabel",true);if label then label.Text=text end
			UI.SetButtonColor(b,color);b.Position=pos;b.Size=size
		else b=button(name,text,color,parent,pos,size,function() local fn=callbacks[parent][name];if fn then fn() end end) end
		return b
	end
	local function sweep(parent) for _,v in parent:GetChildren() do if v:IsA("GuiObject") and not keep[parent][v.Name] then v:Destroy() end end end
	local function row(name,text,color,callback)
		order+=1;local b=reuse(list,name,text,color,UDim2.new(),UDim2.new(1,-7,0,58),callback);b.LayoutOrder=order;return b
	end
	local function actions(defs)
		local top=math.min(4,#defs)
		for i,a in defs do
			local line=i<=top and 0 or 1;local n=line==0 and top or #defs-top;local col=line==0 and i-1 or i-top-1
			reuse(bar,a[1],a[2],a[3],UDim2.new(col/n,0,0,line*50),UDim2.new(1/n,-8,0,42),a[4])
		end
	end
	local function selectedPets() local out={};for _,uid in selected do if state.pets[uid] then table.insert(out,uid) end end;return out end
	callbacks[list],callbacks[bar]={},{}
	local draw
	render=function()
		if not panel.Visible or not state then return end
		keep[list],keep[bar],order={},{},0
		draw();sweep(list);sweep(bar)
	end
	draw=function()
		for i=#selected,1,-1 do if not state.pets[selected[i]] then table.remove(selected,i) end end
		if eggUid and not state.eggs[eggUid] then eggUid=nil end
		local eggCount,petCount=0,0;for _ in state.eggs do eggCount+=1 end;for _ in state.pets do petCount+=1 end
		local m=state.mults
		detail.Text="ไข่ "..eggCount.."/"..Config.MaxEggs.." • สัตว์ "..petCount.."/"..Config.MaxPets.." • คอก +"..NF.Short(state.income).."/วิ • เงินในคอก "..NF.Short(state.bank)..
			"\nบัฟ: Power ×"..string.format("%.2f",m.Power).." • Wood ×"..string.format("%.2f",m.Wood).." • EXP ×"..string.format("%.2f",m.Exp).." • Speed ×"..string.format("%.2f",m.Speed)
		if tab=="Incubator" then
			if not state.base then row("NoBase","ฐานเต็ม — ตู้ฟักจะพร้อมเมื่อมีฐานว่าง",UI.Colors.Slate,function() end) end
			for i=1,Config.IncubatorSlots do local index=i;local egg=state.incubator[tostring(i)];local text="ช่อง "..i.." • ว่าง";local color=slot==i and UI.Colors.Teal or UI.Colors.Slate
				if egg then local def=Eggs.ById[egg.id];local pct=math.floor(egg.progress/def.hatch*100)
					text="ช่อง "..i.." • "..def.name.." • "..(egg.done and "ฟักเสร็จแล้ว!"..(egg.mutation and " ("..egg.mutation..")" or "") or pct.."% • อีก "..math.ceil((def.hatch-egg.progress)/state.hatchSpeed).." วิ")..
						"\n"..(egg.carriedBy and "⚠ กำลังถูกขโมย!" or (egg.done and "กดฟักไข่" or (pct>=Config.SafeProgress*100 and "ปลอดภัยจากการขโมย" or "ขโมยได้จนถึง 75%")))
				end
				row("Slot"..i,text,color,function() slot=index;render() end)
			end
			actions({{"Place","วางไข่ที่เลือก",UI.Colors.Green,function() if eggUid then pet("Place",{egg=eggUid,slot=slot}) else tab="Eggs";render();message.Text="เลือกไข่ที่จะวางก่อน" end end},
				{"Hatch","ฟักไข่ที่พร้อม",UI.Colors.Orange,function() pet("Hatch") end},
				{"PickEgg","เลือกไข่",UI.Colors.Teal,function() tab="Eggs";render() end},
				{"Close","ปิด",UI.Colors.Slate,function() panel.Visible=false end}})
		elseif tab=="Eggs" then
			local keys={};for uid in state.eggs do table.insert(keys,uid) end;table.sort(keys)
			if #keys==0 then row("Empty","หาไข่จากรังในป่า หีบ สายพานในหมู่บ้าน หรือขโมยจากฐานอื่น",UI.Colors.Slate,function() end) end
			for _,uid in keys do local key=uid;local egg=state.eggs[uid];local def=Eggs.ById[egg.id]
				row("Egg_"..uid,def.name.." • ฟัก "..math.ceil((def.hatch-egg.progress)/60).." นาที"..(egg.stolen and " • ขโมยมา" or "").."\n"..def.thai.." • โซน "..egg.zone..(egg.progress>0 and " • ฟักไปแล้ว "..math.floor(egg.progress/def.hatch*100).."%" or ""),
					eggUid==uid and UI.Colors.Teal or UI.Colors.Pink,function() eggUid=key;tab="Incubator";render();message.Text="เลือกช่องว่าง แล้วกดวางไข่" end)
			end
			actions({{"Back","กลับตู้ฟัก",UI.Colors.Teal,function() tab="Incubator";render() end},{"Close","ปิด",UI.Colors.Slate,function() panel.Visible=false end}})
		elseif tab=="Pets" then
			local keys={};for uid in state.pets do table.insert(keys,uid) end
			local rank={equip=0,pen=1,[""]=2}
			table.sort(keys,function(a,b) local x,y=state.pets[a],state.pets[b]
				if rank[x.place]~=rank[y.place] then return rank[x.place]<rank[y.place] end
				local rx,ry=table.find(Pets.Order,Pets.ById[x.id].rarity),table.find(Pets.Order,Pets.ById[y.id].rarity)
				if rx~=ry then return rx>ry end;return a<b end)
			if #keys==0 then row("Empty","ยังไม่มีสัตว์ — ฟักไข่ที่ตู้ฟักในฐาน",UI.Colors.Slate,function() end) end
			for _,uid in keys do local key=uid;local p=state.pets[uid];local on=table.find(selected,uid)
				row("Pet_"..uid,(state.mount==uid and "🐾 กำลังขี่ • " or "")..petLine(p),on and UI.Colors.Teal or (p.place=="equip" and UI.Colors.Green or (p.place=="pen" and UI.Colors.Orange or UI.Colors.Slate)),function()
					releasePending=nil;local i=table.find(selected,key);if i then table.remove(selected,i) else table.insert(selected,key);if #selected>3 then table.remove(selected,1) end end;render() end)
			end
			local function one(action) local s=selectedPets();if #s~=1 then message.Text="เลือกสัตว์ 1 ตัว";return end;pet(action,s[1]) end
			actions({{"Equip","พกติดตัว",UI.Colors.Green,function() one("Equip") end},{"Pen","ใส่คอก",UI.Colors.Orange,function() one("Pen") end},
				{"Store","เก็บกระเป๋า",UI.Colors.Slate,function() one("Store") end},{"Fuse","หลอม 3 ตัว",UI.Colors.Purple,function() local s=selectedPets();if #s==3 then pet("Fuse",s) else message.Text="เลือกสัตว์ชนิด/ขั้นเดียวกัน 3 ตัว" end end},
				{"Mount",state.mount and "ลงจากหลัง" or "ขี่",UI.Colors.Teal,function() if state.mount then pet("Dismount") else one("Mount") end end},
				{"Release","ปล่อยสัตว์",UI.Colors.Red,function() local s=selectedPets();if #s~=1 then message.Text="เลือกสัตว์ 1 ตัว";return end
					if releasePending==s[1] then releasePending=nil;pet("Release",s[1]) else releasePending=s[1];message.Text="กดปล่อยสัตว์อีกครั้งเพื่อยืนยัน (หายถาวร)" end end},
				{"Close","ปิด",UI.Colors.Slate,function() panel.Visible=false end}})
		elseif tab=="Base" then
			local base=myBase(state.base);local now=os.time()
			local lockUntil=base and base:GetAttribute("LockUntil") or 0;local ready=base and base:GetAttribute("LockReadyAt") or 0
			local lockText=now<lockUntil and "ล็อกอยู่ อีก "..(lockUntil-now).." วิ" or (now<ready and "คูลดาวน์ "..(ready-now).." วิ" or "พร้อมล็อก "..Math.LockSeconds(state.upgrades.lock).." วิ")
			row("Collect","เก็บเงินคอก • "..NF.Short(state.bank).." Coins\nรายได้ +"..NF.Short(state.income).."/วิ • สะสมได้สูงสุด "..Config.OfflineHours.." ชม.",UI.Colors.Orange,function() pet("Collect") end)
			row("Lock","ล็อกฐาน • "..lockText.."\nบาเรียร์กันคนอื่นเข้า คูลดาวน์ "..Config.LockCooldown.." วิ",now<lockUntil and UI.Colors.Blue or UI.Colors.Purple,function() call("BaseAction","Lock") end)
			local info={pen={"คอกสัตว์","ช่อง "..Math.PenSlots(state.upgrades.pen)},incubator={"ตู้ฟักเร็วขึ้น","×"..Math.HatchSpeed(state.upgrades.incubator)},lock={"ล็อกฐานนานขึ้น",Math.LockSeconds(state.upgrades.lock).." วิ"},
				trap={"กับดักรากหนาม","คนขโมยช้าลง "..math.round((1-Math.TrapSlow(state.upgrades.trap))*100).."%"},guard={"สัตว์เฝ้าฐาน","ไล่คนขโมย "..math.round(Math.GuardChance(state.upgrades.guard)*100).."%"}}
			for _,kind in {"pen","incubator","lock","trap","guard"} do local k=kind;local level=state.upgrades[k];local max=Math.MaxLevel(k)
				row("Upgrade_"..k,info[k][1].." • Lv "..level.."/"..max.." • ตอนนี้ "..info[k][2].."\n"..(level>=max and "สูงสุดแล้ว" or "อัปเกรด "..NF.Short(Math.UpgradeCost(k,level)).." Wood"),level>=max and UI.Colors.Disabled or UI.Colors.Green,function() pet("Upgrade",k) end)
			end
			local shield=player:GetAttribute("Shield") or ""
			row("Shield","โล่ป้องกันขโมย: "..(SHIELD[shield] or "ไม่มี").."\nไข่ที่ฟักเกิน 75% และสัตว์ที่ฟักแล้วขโมยไม่ได้",shield~="" and UI.Colors.Blue or UI.Colors.Slate,function() end)
			row("FriendSteal","เพื่อนขโมยไข่ได้: "..(state.friendSteal and "เปิด" or "ปิด").."\nกดเพื่อสลับ",UI.Colors.Slate,function() call("BaseAction","FriendSteal",not state.friendSteal) end)
			-- Decoration: place where you stand on your slab; rotate/remove act on the nearest piece.
			local decor=ClientData.Get("Decor.items") or {};local shrines=ClientData.Get("Progress.Shrines") or {};local count,beauty=0,0
			for _,it in decor do count+=1;beauty+=DecorConfig.ById[it.id] and DecorConfig.ById[it.id].beauty or 0 end
			row("DecorInfo","ตกแต่งฐาน • ความสวย "..beauty.." • "..count.."/"..DecorConfig.MaxItems.." ชิ้น\nยืนบนพื้นฐานแล้วกดวาง • ไม่มีผลต่อพลัง",UI.Colors.Slate,function() end)
			row("DecorRotate","หมุนชิ้นที่ใกล้ที่สุด 90°",UI.Colors.Teal,function() call("DecorAction","Rotate") end)
			row("DecorRemove","เก็บชิ้นที่ใกล้ที่สุด (คืน "..math.round(DecorConfig.Refund*100).."% Wood)",UI.Colors.Red,function() call("DecorAction","Remove") end)
			for _,def in DecorConfig.List do local id=def.id;local locked=def.zone and not shrines[tostring(def.zone)]
				row("Decor_"..id,def.name.." • "..NF.Short(def.price).." Wood • สวย +"..def.beauty.."\n"..(locked and "ล็อก: จุดศาลเจ้าโซน "..def.zone or "วางตรงที่ยืน"),locked and UI.Colors.Disabled or UI.Colors.Green,function() call("DecorAction","Place",id) end)
			end
			actions({{"Close","ปิด",UI.Colors.Slate,function() panel.Visible=false end}})
		else
			local now=os.time()
			local offer=state.weatherOffer
			if offer then row("WeatherBuy",Eggs.ById[offer.id].name.." • "..NF.Short(offer.price).." Coins\n"..(offer.bought and "ซื้อรอบนี้แล้ว" or "ซื้อได้ 1 ใบต่อรอบออโรรา"),offer.bought and UI.Colors.Slate or UI.Colors.Purple,function() pet("BuyWeather") end) end
			for _,r in Math.BeltWindow(now) do local epoch=r.epoch;local def=Eggs.ById[r.id];local bought=state.beltBought[tostring(r.epoch)]
				row("Belt_"..r.epoch,def.name.." • "..NF.Short(Math.EggPrice(r.id)).." Coins • โซน "..def.zone.."\nฟัก "..math.ceil(def.hatch/60).." นาที • "..(bought and "ซื้อแล้ว" or "อยู่บนสายพานอีก "..math.max(0,r.leavesAt-now).." วิ"),
					bought and UI.Colors.Disabled or UI.Colors.Orange,function() pet("Buy",epoch) end)
			end
			actions({{"Close","ปิด",UI.Colors.Slate,function() panel.Visible=false end}})
		end
	end
	for i,t in TABS do local target=t[1]
		button("Tab"..target,t[2],UI.Colors.Pink,panel,UDim2.new((i-1)/#TABS,0,0,64),UDim2.new(1/#TABS,-8,0,42),function() tab=target;releasePending=nil;render() end)
	end
	local function resize() local size=workspace.CurrentCamera.ViewportSize;panel.Size=UDim2.fromOffset(math.min(780,size.X-28),math.min(570,size.Y-56)) end
	local function show(target)
		for _,name in {"InventoryHUD","GardenHUD"} do local other=player.PlayerGui:FindFirstChild(name);if other and other:FindFirstChild("Panel") then other.Panel.Visible=false end end
		if target then tab=target end;panel.Visible=true;releasePending=nil;resize();render();pet("Sync")
	end
	button("Toggle","ไข่ & สัตว์",UI.Colors.Pink,gui,UDim2.fromOffset(16,361),UDim2.fromOffset(178,48),function() if panel.Visible then panel.Visible=false else show() end end)
	Net.Event("PetState").OnClientEvent:Connect(function(packet) state=packet;render() end)
	Net.Event("PetShow").OnClientEvent:Connect(show)
	workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(resize)
	for _,name in {"InventoryHUD","GardenHUD"} do task.spawn(function()
		local other=player.PlayerGui:WaitForChild(name,30);local p=other and other:WaitForChild("Panel",10)
		if p then p:GetPropertyChangedSignal("Visible"):Connect(function() if p.Visible then panel.Visible=false end end) end
	end) end
	task.spawn(function() while true do task.wait(1);if panel.Visible and (tab=="Base" or tab=="Belt") then render() end end end)

	-- Local-only visuals: every client renders followers/mounts from player attributes.
	local folder=Instance.new("Folder");folder.Name="LocalPets";folder.Parent=workspace
	local rigs={}
	local function rebuild(p)
		local rig=rigs[p];local follow=p:GetAttribute("PetFollow") or "";local mount=p:GetAttribute("MountPet") or ""
		local sig=follow.."|"..mount;if rig and rig.sig==sig then return end
		if rig then for _,m in rig.models do m:Destroy() end;if rig.mount then rig.mount:Destroy() end end
		rig={sig=sig,models={}};rigs[p]=rig
		for id in string.gmatch(follow,"[^,]+") do if Pets.ById[id] then local m=Visual.Pet(id,.8);m.Parent=folder;table.insert(rig.models,m) end end
		if Pets.ById[mount] then rig.mount=Visual.Pet(mount,1.7);rig.mount.Parent=folder end
	end
	Players.PlayerRemoving:Connect(function(p) local rig=rigs[p];if rig then for _,m in rig.models do m:Destroy() end;if rig.mount then rig.mount:Destroy() end;rigs[p]=nil end end)
	RunService.RenderStepped:Connect(function(dt)
		local t=os.clock()
		for _,p in Players:GetPlayers() do
			rebuild(p);local rig=rigs[p];local hr=p.Character and p.Character:FindFirstChild("HumanoidRootPart")
			for i,m in rig.models do
				if hr then
					local n=#rig.models;local target=hr.CFrame*CFrame.new((i-(n+1)/2)*3.2,-1.9+math.sin(t*4+i)*.15,5+(i%2)*1.5)
					local cur=m:GetPivot();m:PivotTo(cur:Lerp(target,math.clamp(dt*6,0,1)))
				else m:PivotTo(CFrame.new(0,-500,0)) end
			end
			if rig.mount then rig.mount:PivotTo(hr and hr.CFrame*CFrame.new(0,-2.4,0) or CFrame.new(0,-500,0)) end
		end
	end)

	-- Conveyor eggs follow the same UTC schedule the server sells from.
	local beltEggs={}
	RunService.Heartbeat:Connect(function()
		local belt;for _,m in Collection:GetTagged("Shop") do if m:GetAttribute("ShopType")=="EggConveyor" then belt=m.PrimaryPart end end
		if not belt then return end
		local now=workspace:GetServerTimeNow();local alive={}
		for _,r in Math.BeltWindow(math.floor(now)) do
			alive[r.epoch]=true
			local m=beltEggs[r.epoch];if not m then m=Visual.Egg(Eggs.ById[r.id].color,1.2);m.Parent=folder;beltEggs[r.epoch]=m end
			local a=math.clamp((now-r.epoch*Config.BeltSeconds)/(Config.BeltSeconds*Config.BeltVisible),0,1)
			m:PivotTo(belt.CFrame*CFrame.new((a-.5)*(belt.Size.X-3),belt.Size.Y/2+1.2,0))
		end
		for epoch,m in beltEggs do if not alive[epoch] then m:Destroy();beltEggs[epoch]=nil end end
	end)

	-- Owner sees who is carrying their egg; incubator prompts read "steal" on other bases.
	local markers={}
	task.spawn(function() while true do
		local mine=player.Character and player.Character:FindFirstChild("HumanoidRootPart");local seen={}
		for _,inst in Collection:GetTagged("EggThief") do
			local owner=Players:GetPlayerFromCharacter(inst);local from=owner and owner:GetAttribute("StealingFrom") or inst:GetAttribute("StealingFrom")
			local target=inst:IsA("Model") and (inst:FindFirstChild("HumanoidRootPart") or inst.PrimaryPart)
			if from==player.UserId and target and mine then
				seen[inst]=true
				if not markers[inst] then
					local h=Instance.new("Highlight");h.FillColor=Color3.fromRGB(255,60,60);h.OutlineColor=Color3.new(1,1,1);h.DepthMode=Enum.HighlightDepthMode.AlwaysOnTop;h.Parent=inst
					local b=Instance.new("BillboardGui");b.AlwaysOnTop=true;b.Size=UDim2.fromOffset(190,40);b.StudsOffset=Vector3.new(0,6,0);b.Parent=target
					local l=Instance.new("TextLabel");l.Size=UDim2.fromScale(1,1);l.BackgroundTransparency=1;l.TextColor3=Color3.fromRGB(255,90,90);l.TextStrokeTransparency=0;l.TextSize=18;l.Text="⚠ ขโมยไข่คุณ! กด E ทวงคืน";l.Parent=b
					local a0=Instance.new("Attachment");a0.Parent=mine;local a1=Instance.new("Attachment");a1.Parent=target
					local beam=Instance.new("Beam");beam.Attachment0=a0;beam.Attachment1=a1;beam.Width0=.4;beam.Width1=.4;beam.FaceCamera=true;beam.Color=ColorSequence.new(Color3.fromRGB(255,70,70));beam.Parent=mine
					markers[inst]={h,b,a0,a1,beam}
				end
			end
		end
		for inst,parts in markers do if not seen[inst] then for _,x in parts do x:Destroy() end;markers[inst]=nil end end
		for _,b in Collection:GetTagged("PlayerBase") do
			local dome=b:FindFirstChild("Incubator") and b.Incubator:FindFirstChild("Dome");local prompt=dome and dome:FindFirstChild("IncubatorPrompt")
			if prompt then prompt.ActionText=b:GetAttribute("OwnerUserId")==player.UserId and "ตู้ฟักไข่" or "ขโมยไข่" end
		end
		task.wait(.25)
	end end)

	-- AFK shield needs the server to know how long this player has been idle.
	local lastInput=os.clock()
	Input.InputBegan:Connect(function() lastInput=os.clock() end)
	task.spawn(function() while true do task.wait(20);pcall(function() Net.Function("BaseAction"):InvokeServer("Presence",os.clock()-lastInput) end) end end)
	task.spawn(function() while not require(script.Parent.ClientData).IsReady() do task.wait(.1) end;pet("Sync") end)
end
return Controller
