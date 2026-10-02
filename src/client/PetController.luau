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
local TABS={{"Incubator","Incubator"},{"Eggs","Eggs"},{"Pets","Pets"},{"Base","Base"},{"Belt","Egg Conveyor"}}
local TAB_ICONS={Incubator="incubation/eggGrowing",Eggs="egg",Pets="pets/pet_fox",Base="shop",Belt="gear"}
local PLACE={equip="Carry",pen="In pen",[""]="Inventory"}
local SHIELD={new="New Player (30 min)",afk="AFK Over 10 min",admin="Admin enabled"}

local function myBase(index)
	for _,b in Collection:GetTagged("PlayerBase") do if b:GetAttribute("BaseIndex")==index then return b end end
end
local function petLine(pet)
	local def=Pets.ById[pet.id]
	return def.name.." ★"..pet.tier.." • "..def.rarity..(pet.mutation and " • "..pet.mutation or "").." • "..PLACE[pet.place or ""]..
		"\n+"..NF.Short(Math.Income(pet)).."/sec In pen • Bonus "..def.buff.." +"..math.floor(Math.Bonus(pet)*100+.5).."%"..(def.rideable and " • Rideable" or "")
end

function Controller.Start()
	local player=Players.LocalPlayer
	local gui=UI.New("ScreenGui",{Name="PetHUD",ResetOnSpawn=false,ZIndexBehavior=Enum.ZIndexBehavior.Sibling,DisplayOrder=9,Parent=player:WaitForChild("PlayerGui")})
	local panel=UI.New("Frame",{Name="Panel",AnchorPoint=Vector2.new(.5,.5),Position=UDim2.fromScale(.5,.5),Size=UDim2.fromOffset(960,650),Visible=false,BackgroundTransparency=1,Parent=gui})
	UI.Window(panel,"Pets","pets/pet_fox",{plaque=330})
	local caps={}
	for i,c in {{"Eggs","egg"},{"Pets","pets/pet_bunny"},{"Pen Income","rewards/gemsSmall"}} do
		local _,value=UI.Capsule(panel,c[2],c[1],{Name="Stat"..i,AnchorPoint=Vector2.new(0,.5),Position=UDim2.new(0,372+(i-1)*168,.105,-2),Size=UDim2.fromOffset(160,60)});caps[i]=value
	end
	local list=UI.New("ScrollingFrame",{Name="Items",Position=UDim2.fromOffset(40,190),Size=UDim2.fromOffset(880,350),BackgroundTransparency=1,ScrollBarThickness=6,ScrollBarImageColor3=Color3.fromRGB(240,180,90),AutomaticCanvasSize=Enum.AutomaticSize.Y,CanvasSize=UDim2.new(),Parent=panel},{UI.Padding(4)})
	local incubator=UI.New("Frame",{Name="Incubator",BackgroundTransparency=1,Position=UDim2.fromOffset(40,190),Size=UDim2.fromOffset(880,352),Parent=panel})
	local info,message=UI.InfoBar(panel,"",{Name="Info",Position=UDim2.fromOffset(40,556),Size=UDim2.fromOffset(568,54)},"codes")
	local bar=UI.New("Frame",{Name="Actions",BackgroundTransparency=1,Position=UDim2.fromOffset(620,552),Size=UDim2.fromOffset(300,62),Parent=panel})
	local state;local tab="Incubator";local slot=1;local eggUid;local selected={};local releasePending;local busy=false
	local HINTS={Incubator="Choose an egg, place it, then hatch when ready.",Eggs="Pick an egg, then choose an empty incubator slot.",Pets="Select pets to carry, pen, fuse or ride.",Base="Collect pen income, upgrade and protect your base.",Belt="Eggs ride the conveyor for a limited time."}
	local render
	local gridMode
	local function setLayout(mode)
		if gridMode==mode then return end;gridMode=mode
		local old=list:FindFirstChildOfClass("UIListLayout") or list:FindFirstChildOfClass("UIGridLayout");if old then old:Destroy() end
		if mode=="grid" then UI.Grid(5,186,10).Parent=list else UI.List(Enum.FillDirection.Vertical,8).Parent=list end
	end
	local function say(text,ok) message.Text=text;message.TextColor3=ok==false and Color3.fromRGB(255,140,120) or UI.Colors.Text end
	local function call(remote,action,arg)
		if busy then return end;busy=true
		task.spawn(function()
			local ok,success,msg=pcall(function() return Net.Function(remote):InvokeServer(action,arg) end)
			if action~="Sync" then say(ok and (msg or "Done") or "Could not reach the server. Try again",ok and success) end
			if ok and success and action=="Fuse" then table.clear(selected) end
			task.wait(.32);busy=false;render()
		end)
	end
	local function pet(action,arg) call("PetAction",action,arg) end
	local function button(name,text,color,parent,pos,size,callback)
		local b=UI.Button({text=text,color=color,size=size,onClick=callback});b.Name=name;b.Position=pos;b.Parent=parent;return b
	end
	-- State packets arrive every 2 seconds; elements are updated in place so a
	-- click that lands during a refresh is never lost on a destroyed instance.
	local callbacks,used,order={},{},0
	local function element(parent,name,create)
		used[name]=true
		local e=parent:FindFirstChild(name)
		if not e then e=create();e.Name=name;e.Parent=parent end
		return e
	end
	local function sweep(parent) for _,v in parent:GetChildren() do if v:IsA("GuiObject") and not used[v.Name] then v:Destroy() end end end
	local function clickable(name)
		local b=UI.New("TextButton",{Text="",AutoButtonColor=false,BackgroundTransparency=1})
		b.Activated:Connect(function() local fn=callbacks[name];if fn then fn() end end)
		return b
	end
	local function art(holder,key,make)
		local old=holder:FindFirstChild("Art")
		if old and old:GetAttribute("Key")==key then return old end
		if old then old:Destroy() end
		local a=make();if a then a.Name="Art";a:SetAttribute("Key",key) end
		return a
	end
	-- Grid card: rarity frame, illustration (or model preview), name and sub line.
	local function card(name,o)
		order+=1;callbacks[name]=o.onClick
		local c=element(list,name,function()
			local b=clickable(name)
			UI.Label("",18,{Name="Title",Position=UDim2.new(0,8,1,-56),Size=UDim2.new(1,-16,0,26),TextXAlignment=Enum.TextXAlignment.Center,TextScaled=true,Parent=b})
			UI.Label("",14,{Name="Sub",FontFace=UI.FontBold,Position=UDim2.new(0,8,1,-30),Size=UDim2.new(1,-16,0,22),TextXAlignment=Enum.TextXAlignment.Center,TextColor3=UI.Colors.TextDim,TextScaled=true,Parent=b})
			UI.Label("",22,{Name="Mark",Position=UDim2.fromOffset(12,8),Size=UDim2.fromOffset(60,26),TextColor3=UI.Colors.Accent,TextWrapped=false,Parent=b})
			UI.New("Frame",{Name="Ring",BackgroundTransparency=1,Position=UDim2.fromOffset(-2,-2),Size=UDim2.new(1,4,1,4),ZIndex=4,Visible=false,Parent=b},{UI.Corner(16),UI.Stroke(4,Color3.fromRGB(255,224,90))})
			return b
		end)
		c.LayoutOrder=order;UI.Skin(c,"cards",o.sprite)
		c.Title.Text=o.title;c.Sub.Text=o.sub or "";c.Mark.Text=o.mark or "";c.Ring.Visible=o.selected==true
		art(c,o.artKey,function() return o.makeArt(c) end)
		return c
	end
	-- List row: wooden card with live text; colour only marks selection/availability.
	local function row(name,text,color,callback)
		order+=1;callbacks[name]=callback
		local r=element(list,name,function()
			local b=clickable(name);b.Size=UDim2.new(1,-8,0,70)
			UI.Label("",18,{Name="RowText",Position=UDim2.fromOffset(22,4),Size=UDim2.new(1,-44,1,-8),Parent=b})
			return b
		end)
		r.LayoutOrder=order;UI.Skin(r,"cards",color==UI.Colors.Teal and "selected" or (color==UI.Colors.Orange or color==UI.Colors.Purple) and "today" or "product")
		r.RowText.Text=text;r.RowText.TextTransparency=color==UI.Colors.Disabled and .45 or 0
		return r
	end
	local function actions(defs)
		for i,a in defs do
			callbacks["Action_"..a[1]]=a[4]
			local b=element(bar,a[1],function() return UI.Button({text=a[2],textSize=24,color=a[3],size=UDim2.new(1/#defs,-8,1,0),onClick=function() local fn=callbacks["Action_"..a[1]];if fn then fn() end end}) end)
			b.Position=UDim2.new((i-1)/#defs,0,0,0);b.Size=UDim2.new(1/#defs,-8,1,0)
			local label=b.Button:FindFirstChildWhichIsA("TextLabel",true);if label and label.Text~=a[2] then label.Text=a[2] end
			UI.SetButtonColor(b,a[3])
		end
	end
	-- Incubator slot cards are built once and updated in place.
	local slots={}
	for i=1,Config.IncubatorSlots do
		local index=i;local w=(880-24)/Config.IncubatorSlots
		local c=UI.New("TextButton",{Name="Slot"..i,Text="",AutoButtonColor=false,BackgroundTransparency=1,Position=UDim2.fromOffset((i-1)*(w+12),0),Size=UDim2.fromOffset(w,352),Parent=incubator})
		c.Activated:Connect(function() slot=index;render() end)
		local cradle=UI.Art(c,"incubation","cradleEmpty",{Name="Cradle",Position=UDim2.fromOffset(16,10),Size=UDim2.new(1,-32,0,226)})
		local plus=UI.New("Frame",{Name="Plus",AnchorPoint=Vector2.new(.5,.5),Position=UDim2.new(.5,0,0,96),Size=UDim2.fromOffset(86,86),BackgroundColor3=Color3.fromRGB(70,45,30),BackgroundTransparency=.35,ZIndex=4,Parent=c},{UI.Corner(43),UI.Stroke(5,Color3.fromRGB(220,210,200))})
		UI.Label("+",64,{Size=UDim2.fromScale(1,1),Position=UDim2.fromOffset(0,-3),TextXAlignment=Enum.TextXAlignment.Center,TextColor3=Color3.fromRGB(230,222,212),ZIndex=5,Parent=plus})
		local name=UI.Label("",18,{Name="EggName",Position=UDim2.fromOffset(10,234),Size=UDim2.new(1,-20,0,24),TextXAlignment=Enum.TextXAlignment.Center,TextWrapped=false,Parent=c})
		local pct=UI.Label("",22,{Name="Percent",Position=UDim2.fromOffset(10,256),Size=UDim2.new(1,-20,0,26),TextXAlignment=Enum.TextXAlignment.Center,Parent=c})
		local track=UI.Progress(c,{Name="Track",AnchorPoint=Vector2.new(.5,0),Position=UDim2.new(.5,0,0,284),Size=UDim2.new(1,-50,0,30)})
		local warn=UI.Label("",17,{Name="Warning",Position=UDim2.fromOffset(10,318),Size=UDim2.new(1,-20,0,26),TextXAlignment=Enum.TextXAlignment.Center,TextWrapped=false,Parent=c})
		local badge=UI.Badge(c,"Ready","ready",{Name="ReadyBadge",AnchorPoint=Vector2.new(.5,0),Position=UDim2.new(.5,0,0,206),Size=UDim2.fromOffset(150,44),ZIndex=5})
		local action=UI.Button({text="Hatch",textSize=30,color=UI.Colors.Green,size=UDim2.new(1,-40,0,64),onClick=function()
			local egg=state and state.incubator[tostring(index)];slot=index
			if egg and egg.done then pet("Hatch")
			elseif not egg then if eggUid then pet("Place",{egg=eggUid,slot=index}) else tab="Eggs";render();say("Pick an egg for slot "..index) end end
		end});action.Name="SlotAction";action.AnchorPoint=Vector2.new(.5,0);action.Position=UDim2.new(.5,0,0,262);action.Parent=c
		slots[i]={card=c,cradle=cradle,plus=plus,name=name,pct=pct,track=track,warn=warn,badge=badge,action=action}
	end
	local function drawSlots()
		for i,s in slots do local egg=state.incubator[tostring(i)];local def=egg and Eggs.ById[egg.id]
			UI.Skin(s.card,"cards",slot==i and "selected" or "product")
			local sprite=egg and (egg.done and "cradleReady" or "cradleGrowing") or "cradleEmpty"
			if s.cradle:GetAttribute("Sprite")~=sprite then s.cradle:Destroy();s.cradle=UI.Art(s.card,"incubation",sprite,{Name="Cradle",Position=UDim2.fromOffset(16,10),Size=UDim2.new(1,-32,0,226)});s.cradle:SetAttribute("Sprite",sprite) end
			if egg and not egg.done and def then s.cradle.ImageColor3=Color3.new(1,1,1) end
			local growing=egg and not egg.done
			s.plus.Visible=not egg;s.badge.Visible=egg and egg.done or false
			s.pct.Visible=growing or false;s.track.Visible=growing or false;s.warn.Visible=(growing or (egg and egg.carriedBy)) and true or false
			s.name.Visible=not (egg and egg.done)
			s.name.Text=def and def.name or (not state.base and "No base yet" or "Empty slot")
			s.name.Position=UDim2.fromOffset(10,growing and 234 or 228)
			if growing and def then
				local p=math.clamp(egg.progress/def.hatch,0,1);s.pct.Text=math.floor(p*100).."% • "..math.ceil((def.hatch-egg.progress)/state.hatchSpeed).."s"
				UI.SetProgress(s.track,p)
				local safe=p>=Config.SafeProgress
				s.warn.Text=egg.carriedBy and "⚠ Theft in progress!" or (safe and "🛡 Protected from theft" or "🔒 Stealable below "..math.floor(Config.SafeProgress*100).."%")
				s.warn.TextColor3=(egg.carriedBy or not safe) and Color3.fromRGB(255,96,86) or UI.Colors.Accent
			end
			s.action.Visible=not growing
			local label=s.action.Button:FindFirstChildWhichIsA("TextLabel",true)
			label.Text=egg and "Hatch" or (eggUid and "Place Egg" or "Select Egg")
		end
	end
	local function selectedPets() local out={};for _,uid in selected do if state.pets[uid] then table.insert(out,uid) end end;return out end
	local tabs={}
	local function place(listH,infoX,infoW,infoY,barX,barW,barY)
		list.Size=UDim2.fromOffset(880,listH);info.Position=UDim2.fromOffset(infoX,infoY);info.Size=UDim2.fromOffset(infoW,54)
		bar.Position=UDim2.fromOffset(barX,barY);bar.Size=UDim2.fromOffset(barW,62);bar.Visible=barW>0
	end
	local draw
	render=function()
		if not panel.Visible or not state then return end
		for key,t in tabs do UI.SetTab(t,tab==key and "green" or nil) end
		incubator.Visible=tab=="Incubator";list.Visible=tab~="Incubator"
		setLayout((tab=="Eggs" or tab=="Pets") and "grid" or "list")
		if tab=="Pets" then place(286,40,880,484,40,880,548) elseif tab=="Base" or tab=="Belt" then place(352,40,880,556,0,0,552) else place(352,40,568,556,620,300,552) end
		table.clear(used);order=0
		draw();sweep(list);sweep(bar)
	end
	draw=function()
		for i=#selected,1,-1 do if not state.pets[selected[i]] then table.remove(selected,i) end end
		if eggUid and not state.eggs[eggUid] then eggUid=nil end
		local eggCount,petCount=0,0;for _ in state.eggs do eggCount+=1 end;for _ in state.pets do petCount+=1 end
		caps[1].Text=eggCount.."/"..Config.MaxEggs;caps[2].Text=petCount.."/"..Config.MaxPets;caps[3].Text=NF.Short(state.income).."/s"
		if tab=="Incubator" then
			drawSlots()
			actions({{"Hatch","Hatch Ready Eggs",UI.Colors.Green,function() pet("Hatch") end}})
		elseif tab=="Eggs" then
			local keys={};for uid in state.eggs do table.insert(keys,uid) end;table.sort(keys)
			if #keys==0 then setLayout("list");row("Empty","Find eggs in forest nests, chests or the village conveyor, or steal from other bases",UI.Colors.Slate,function() end) end
			for _,uid in keys do local key=uid;local egg=state.eggs[uid];local def=Eggs.ById[egg.id]
				card("Egg_"..uid,{sprite="product",title=def.name,sub="Hatch "..math.ceil((def.hatch-egg.progress)/60).." min"..(egg.stolen and " • Stolen" or ""),selected=eggUid==uid,
					artKey=egg.id,makeArt=function(parent) local a=UI.Art(parent,"incubation","eggGrowing",{Position=UDim2.fromOffset(34,14),Size=UDim2.new(1,-68,1,-78)});a.ImageColor3=def.color:Lerp(Color3.new(1,1,1),.45);return a end,
					onClick=function() eggUid=key;tab="Incubator";render();say("Choose an empty slot to place the "..def.name) end})
			end
			actions({{"Back","Back to Incubator",UI.Colors.Green,function() tab="Incubator";render() end}})
		elseif tab=="Pets" then
			local keys={};for uid in state.pets do table.insert(keys,uid) end
			local rank={equip=0,pen=1,[""]=2}
			table.sort(keys,function(a,b) local x,y=state.pets[a],state.pets[b]
				if rank[x.place or ""]~=rank[y.place or ""] then return rank[x.place or ""]<rank[y.place or ""] end
				local rx,ry=table.find(Pets.Order,Pets.ById[x.id].rarity),table.find(Pets.Order,Pets.ById[y.id].rarity)
				if rx~=ry then return (rx or 0)>(ry or 0) end;return a<b end)
			if #keys==0 then setLayout("list");row("Empty","No pets yet. Hatch eggs at your base",UI.Colors.Slate,function() end) end
			for _,uid in keys do local key=uid;local p=state.pets[uid];local def=Pets.ById[p.id];local on=table.find(selected,uid)~=nil
				local sprite=({Common="common",Rare="rare",Epic="epic",Legendary="legendary",Mythic="mythic"})[def.rarity] or "mythic"
				card("Pet_"..uid,{sprite=sprite,title=def.name,sub="★"..p.tier.." • "..PLACE[p.place or ""],selected=on,mark=state.mount==uid and "🐾" or (p.place=="equip" and "✓" or nil),
					artKey=p.id,makeArt=function(parent)
						local a=UI.Art(parent,"pets",p.id,{Position=UDim2.fromOffset(20,12),Size=UDim2.new(1,-40,1,-74)});if a then return a end
						local view=UI.New("ViewportFrame",{BackgroundTransparency=1,Position=UDim2.fromOffset(14,10),Size=UDim2.new(1,-28,1,-70),Ambient=Color3.new(1,1,1),Parent=parent})
						local world=Instance.new("WorldModel");world.Parent=view
						local model=Visual.Pet(p.id,1);model.Parent=world
						local cf,size=model:GetBoundingBox();local camera=Instance.new("Camera");camera.FieldOfView=35;camera.CFrame=CFrame.lookAt(cf.Position+Vector3.new(size.X*.3,size.Y*.15,math.max(size.Magnitude,3)*1.45),cf.Position);camera.Parent=view;view.CurrentCamera=camera
						return view end,onClick=function()
						releasePending=nil;local i=table.find(selected,key);if i then table.remove(selected,i) else table.insert(selected,key);if #selected>3 then table.remove(selected,1) end end
						local s=selectedPets();if #s==1 then say(petLine(state.pets[s[1]])) else say(#s.." selected • Fuse needs 3 matching species/tier") end;render() end})
			end
			local function one(action) local s=selectedPets();if #s~=1 then say("Select one pet",false);return end;pet(action,s[1]) end
			actions({{"Equip","Carry",UI.Colors.Green,function() one("Equip") end},{"Pen","Add to Pen",UI.Colors.Orange,function() one("Pen") end},
				{"Store","Stow",UI.Colors.Slate,function() one("Store") end},{"Fuse","Fuse 3",UI.Colors.Orange,function() local s=selectedPets();if #s==3 then pet("Fuse",s) else say("Select 3 matching species/tier pets",false) end end},
				{"Mount",state.mount and "Dismount" or "Mount",UI.Colors.Green,function() if state.mount then pet("Dismount") else one("Mount") end end},
				{"Release","Release",UI.Colors.Red,function() local s=selectedPets();if #s~=1 then say("Select one pet",false);return end
					if releasePending==s[1] then releasePending=nil;pet("Release",s[1]) else releasePending=s[1];say("Click Release again to confirm (permanent)",false) end end}})
		elseif tab=="Base" then
			local base=myBase(state.base);local now=os.time()
			local lockUntil=base and base:GetAttribute("LockUntil") or 0;local ready=base and base:GetAttribute("LockReadyAt") or 0
			local lockText=now<lockUntil and "Locked for "..(lockUntil-now).." sec" or (now<ready and "Cooldown "..(ready-now).." sec" or "Lock Ready "..Math.LockSeconds(state.upgrades.lock).." sec")
			row("Collect","Collect Pen Income • "..NF.Short(state.bank).." Coins\nIncome +"..NF.Short(state.income).."/sec • Storage limit "..Config.OfflineHours.." hrs",UI.Colors.Orange,function() pet("Collect") end)
			row("Lock","Lock Base • "..lockText.."\nBarrier blocks visitors Cooldown "..Config.LockCooldown.." sec",now<lockUntil and UI.Colors.Blue or UI.Colors.Purple,function() call("BaseAction","Lock") end)
			local infoText={pen={"Pet Pen","Slot "..Math.PenSlots(state.upgrades.pen)},incubator={"Faster Incubator","×"..Math.HatchSpeed(state.upgrades.incubator)},lock={"Longer Base Lock",Math.LockSeconds(state.upgrades.lock).." sec"},
				trap={"Thorn Root Trap","Thief slowed by "..math.round((1-Math.TrapSlow(state.upgrades.trap))*100).."%"},guard={"Base Guard","Chasing thief "..math.round(Math.GuardChance(state.upgrades.guard)*100).."%"}}
			for _,kind in {"pen","incubator","lock","trap","guard"} do local k=kind;local level=state.upgrades[k];local max=Math.MaxLevel(k)
				row("Upgrade_"..k,infoText[k][1].." • Lv "..level.."/"..max.." • Now "..infoText[k][2].."\n"..(level>=max and "Max reached" or "Upgrade "..NF.Short(Math.UpgradeCost(k,level)).." Wood"),level>=max and UI.Colors.Disabled or UI.Colors.Green,function() pet("Upgrade",k) end)
			end
			local shield=player:GetAttribute("Shield") or ""
			row("Shield","Theft Shield: "..(SHIELD[shield] or "None").."\nEggs over 75% hatched and hatched pets cannot be stolen",shield~="" and UI.Colors.Blue or UI.Colors.Slate,function() end)
			row("FriendSteal","Friends can steal eggs: "..(state.friendSteal and "Open" or "Close").."\nClick to toggle",UI.Colors.Slate,function() call("BaseAction","FriendSteal",not state.friendSteal) end)
			-- Decoration: place where you stand on your slab; rotate/remove act on the nearest piece.
			local decor=ClientData.Get("Decor.items") or {};local shrines=ClientData.Get("Progress.Shrines") or {};local count,beauty=0,0
			for _,it in decor do count+=1;beauty+=DecorConfig.ById[it.id] and DecorConfig.ById[it.id].beauty or 0 end
			row("DecorInfo","Base Decor • Beauty "..beauty.." • "..count.."/"..DecorConfig.MaxItems.." items\nStand on your base floor to place it. No effect on power",UI.Colors.Slate,function() end)
			row("DecorRotate","Rotate Nearest Decoration 90°",UI.Colors.Teal,function() call("DecorAction","Rotate") end)
			row("DecorRemove","Store Nearest Decoration (refund "..math.round(DecorConfig.Refund*100).."% Wood)",UI.Colors.Red,function() call("DecorAction","Remove") end)
			local weather=game.ReplicatedStorage:FindFirstChild("WeatherState");local festival=weather and weather:GetAttribute("festival")
			for _,def in DecorConfig.List do local id=def.id;local locked=(def.zone and not shrines[tostring(def.zone)]) or (def.festival and def.festival~=festival)
				local note=def.festival and (locked and "Festival only" or "This festival only! Place at your position") or (locked and "Locked: light shrine in zone "..def.zone or "Place at Your Position")
				row("Decor_"..id,def.name.." • "..NF.Short(def.price).." Wood • Beauty +"..def.beauty.."\n"..note,locked and UI.Colors.Disabled or (def.festival and UI.Colors.Orange or UI.Colors.Green),function() call("DecorAction","Place",id) end)
			end
		else
			local now=os.time()
			local offer=state.weatherOffer
			if offer then row("WeatherBuy",Eggs.ById[offer.id].name.." • "..NF.Short(offer.price).." Coins\n"..(offer.bought and "Already purchased this visit" or "One egg per Aurora event"),offer.bought and UI.Colors.Slate or UI.Colors.Purple,function() pet("BuyWeather") end) end
			for _,r in Math.BeltWindow(now) do local epoch=r.epoch;local def=Eggs.ById[r.id];local bought=state.beltBought[tostring(r.epoch)]
				row("Belt_"..r.epoch,def.name.." • "..NF.Short(Math.EggPrice(r.id)).." Coins • Zone "..def.zone.."\nHatch "..math.ceil(def.hatch/60).." min • "..(bought and "Purchased" or "On conveyor for "..math.max(0,r.leavesAt-now).." sec"),
					bought and UI.Colors.Disabled or UI.Colors.Orange,function() pet("Buy",epoch) end)
			end
		end
	end
	for i,t in TABS do local target=t[1]
		tabs[target]=UI.Tab({name="Tab"..target,text=t[2]=="Egg Conveyor" and "Conveyor" or t[2],icon=TAB_ICONS[target],size=UDim2.fromOffset(170,60),position=UDim2.fromOffset(40+(i-1)*177.5,122),parent=panel,textSize=24,onClick=function() tab=target;releasePending=nil;say(HINTS[target]);render() end})
	end
	local function show(target)
		for _,name in {"InventoryHUD","GardenHUD"} do local other=player.PlayerGui:FindFirstChild(name);if other and other:FindFirstChild("Panel") then other.Panel.Visible=false end end
		if target then tab=target end;panel.Visible=true;releasePending=nil;say(HINTS[tab]);render();pet("Sync")
	end
	button("Toggle","Eggs & Pets",UI.Colors.Pink,gui,UDim2.fromOffset(16,361),UDim2.fromOffset(178,48),function() if panel.Visible then panel.Visible=false else show() end end)
	Net.Event("PetState").OnClientEvent:Connect(function(packet) state=packet;render() end)
	Net.Event("PetShow").OnClientEvent:Connect(show)
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
					local l=Instance.new("TextLabel");l.Size=UDim2.fromScale(1,1);l.BackgroundTransparency=1;l.TextColor3=Color3.fromRGB(255,90,90);l.TextStrokeTransparency=0;l.TextSize=18;l.Text="⚠ Your egg is being stolen! Press E to reclaim";l.Parent=b
					local a0=Instance.new("Attachment");a0.Parent=mine;local a1=Instance.new("Attachment");a1.Parent=target
					local beam=Instance.new("Beam");beam.Attachment0=a0;beam.Attachment1=a1;beam.Width0=.4;beam.Width1=.4;beam.FaceCamera=true;beam.Color=ColorSequence.new(Color3.fromRGB(255,70,70));beam.Parent=mine
					markers[inst]={h,b,a0,a1,beam}
				end
			end
		end
		for inst,parts in markers do if not seen[inst] then for _,x in parts do x:Destroy() end;markers[inst]=nil end end
		for _,b in Collection:GetTagged("PlayerBase") do
			local dome=b:FindFirstChild("Incubator") and b.Incubator:FindFirstChild("Dome");local prompt=dome and dome:FindFirstChild("IncubatorPrompt")
			if prompt then prompt.ActionText=b:GetAttribute("OwnerUserId")==player.UserId and "Egg Incubator" or "Steal Egg" end
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
