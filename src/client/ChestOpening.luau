-- Chest opening cinematic + result card / multi-open grid (track J, master prompt §9.7).
-- Cosmetic only: the server rolls and saves every weapon before this plays, so skipping, closing or
-- leaving never loses an item. Stage = full-screen ViewportFrame (retro neon parts; particles do not
-- render in viewports) + 2D sunburst, flash, banner and GIANT! stamp. One Heartbeat connection per
-- play; everything is destroyed when the card closes. Timing: Shared.ChestOpeningTimeline.
local Players=game:GetService("Players")
local RunService=game:GetService("RunService")
local GuiService=game:GetService("GuiService")
local UIS=game:GetService("UserInputService")
local Collection=game:GetService("CollectionService")
local S=game.ReplicatedStorage.Shared
local UI=require(S.UIKit)
local Net=require(S.Net)
local Timeline=require(S.ChestOpeningTimeline)
local ChestBuilder=require(S.ChestBuilder)
local Visual=require(S.WeaponVisual)
local Weapons=require(S.Config.WeaponCatalog)
local Rarities=require(S.Config.Rarities)
local Loot=require(S.Loot)
local NF=require(S.NumberFormat)
local Data=require(script.Parent.ClientData)

local player=Players.LocalPlayer
local Opening={}
local active=false

local function reduced()
	local ok,on=pcall(function() return GuiService.ReducedMotionEnabled end)
	return ok and on==true
end
local function lowFx()
	local ok,q=pcall(function() return UserSettings().GameSettings.SavedQualityLevel.Value end)
	return (UIS.TouchEnabled and not UIS.KeyboardEnabled) or (ok and q>=1 and q<=3)
end
local function glow(rarity) local l=ChestBuilder.Levels[Timeline.Rank(rarity)];return l and l.glow or Color3.new(1,1,1) end
local function ease(t) return 1-(1-t)^3 end
local function back(t) local c=1.7;return 1+(c+1)*(t-1)^3+c*(t-1)^2 end

function Opening.Mode() return Timeline.Mode(Data.Get("Settings.ChestAnimation")) end
function Opening.Playing() return active end

local function neon(parent,name,size,cf,color,shape)
	local p=Instance.new("Part");p.Name=name;p.Anchored=true;p.CanCollide=false;p.CanQuery=false;p.CanTouch=false
	p.Material=Enum.Material.Neon;p.Color=color;p.Size=size;p.CFrame=cf;p.TopSurface=Enum.SurfaceType.Smooth;p.BottomSurface=Enum.SurfaceType.Smooth
	if shape then p.Shape=shape end
	p.Parent=parent;return p
end

-- Static weapon icon for cards.
local function icon(parent,def,item,props)
	local view=UI.New("ViewportFrame",props or {});view.BackgroundTransparency=1;view.Ambient=Color3.fromRGB(200,200,200);view.LightColor=Color3.new(1,1,1);view.Parent=parent
	local world=Instance.new("WorldModel");world.Parent=view
	local model=Visual.Build(def,item,true);model.Parent=world
	local cf,size=model:GetBoundingBox()
	local cam=Instance.new("Camera");cam.FieldOfView=35
	cam.CFrame=CFrame.lookAt(cf.Position+Vector3.new(size.X*.3,size.Y*.15,math.max(size.Magnitude,4)*1.45),cf.Position);cam.Parent=view;view.CurrentCamera=cam
	return view
end

-- results: { {uid, item, new, chest, preview} }, opts: { onEquip(uid), onAgain(), canAgain() -> bool, preview }
function Opening.Play(results,opts)
	if active or type(results)~="table" or #results==0 then return end
	opts=opts or {}
	local list={}
	for _,r in results do local def=r.item and Weapons.ById[r.item.id];if def then table.insert(list,{result=r,def=def,rarity=def.rarity,giant=r.item.giant==true}) end end
	if #list==0 then return end
	active=true
	local multi=#list>1
	local bestRarity,anyGiant=Timeline.Best(list)
	local hero=list[1];for _,e in list do if Timeline.Rank(e.rarity)>Timeline.Rank(hero.rarity) or (e.rarity==hero.rarity and e.giant and not hero.giant) then hero=e end end
	local plan=Timeline.Plan(bestRarity,Opening.Mode(),anyGiant)
	local calm,few=reduced(),lowFx()
	local color=glow(bestRarity)
	local chestRarity=list[1].result.chest or bestRarity

	local gui=UI.New("ScreenGui",{Name="ChestOpeningHUD",ResetOnSpawn=false,IgnoreGuiInset=true,DisplayOrder=60,ZIndexBehavior=Enum.ZIndexBehavior.Sibling,Parent=player.PlayerGui})
	local backdrop=UI.New("Frame",{Name="Backdrop",Size=UDim2.fromScale(1,1),BackgroundColor3=Color3.fromRGB(18,14,10),BackgroundTransparency=.05,Parent=gui})
	UI.New("UIGradient",{Rotation=90,Color=ColorSequence.new({ColorSequenceKeypoint.new(0,Color3.fromRGB(18,14,10)),ColorSequenceKeypoint.new(.5,color:Lerp(Color3.fromRGB(18,14,10),.55)),ColorSequenceKeypoint.new(1,Color3.fromRGB(18,14,10))}),Parent=backdrop})
	-- 2D sunburst: 8 bars through the centre = 16 rays, faded at the tips.
	local rays={}
	for i=0,7 do
		local bar=UI.New("Frame",{Name="Ray",AnchorPoint=Vector2.new(.5,.5),Position=UDim2.fromScale(.5,.45),Size=UDim2.new(0,54,2,0),BackgroundColor3=color:Lerp(Color3.new(1,1,1),.35),BackgroundTransparency=1,Rotation=i*22.5,Parent=gui})
		UI.New("UIGradient",{Rotation=90,Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,1),NumberSequenceKeypoint.new(.5,.55),NumberSequenceKeypoint.new(1,1)}),Parent=bar})
		rays[i+1]=bar
	end
	local view=UI.New("ViewportFrame",{Name="Stage",Size=UDim2.fromScale(1,1),BackgroundTransparency=1,Ambient=Color3.fromRGB(150,150,150),LightColor=Color3.new(1,1,1),LightDirection=Vector3.new(-.4,-1,.6),Parent=gui})
	local world=Instance.new("WorldModel");world.Parent=view
	local cam=Instance.new("Camera");cam.FieldOfView=50;cam.Parent=view;view.CurrentCamera=cam
	local flash=UI.New("Frame",{Name="Flash",Size=UDim2.fromScale(1,1),BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=1,Parent=gui})
	local title=UI.Label(chestRarity.." Chest",30,{Name="Title",AnchorPoint=Vector2.new(.5,0),Position=UDim2.new(.5,0,0,70),Size=UDim2.new(.8,0,0,40),TextXAlignment=Enum.TextXAlignment.Center,TextColor3=glow(chestRarity),Parent=gui})
	local nameLabel=UI.Label("",40,{Name="WeaponName",AnchorPoint=Vector2.new(.5,0),Position=UDim2.new(.5,0,.72,0),Size=UDim2.new(.8,0,0,50),TextXAlignment=Enum.TextXAlignment.Center,TextTransparency=1,TextColor3=color,Parent=gui})
	nameLabel:FindFirstChildOfClass("UIStroke").Thickness=3
	local rarityLabel=UI.Label("",26,{Name="WeaponRarity",AnchorPoint=Vector2.new(.5,0),Position=UDim2.new(.5,0,.72,52),Size=UDim2.new(.6,0,0,32),TextXAlignment=Enum.TextXAlignment.Center,TextTransparency=1,Parent=gui})
	local banner=UI.Label("",54,{Name="Banner",AnchorPoint=Vector2.new(.5,.5),Position=UDim2.fromScale(.5,.12),Size=UDim2.new(.9,0,0,70),TextXAlignment=Enum.TextXAlignment.Center,TextColor3=color:Lerp(Color3.new(1,1,1),.2),Visible=false,Parent=gui})
	banner:FindFirstChildOfClass("UIStroke").Thickness=5
	local stamp=UI.Label("GIANT!",64,{Name="GiantStamp",AnchorPoint=Vector2.new(.5,.5),Position=UDim2.fromScale(.72,.32),Size=UDim2.fromOffset(320,90),TextXAlignment=Enum.TextXAlignment.Center,TextColor3=Color3.fromRGB(255,214,64),Rotation=-12,Visible=false,Parent=gui})
	stamp:FindFirstChildOfClass("UIStroke").Thickness=6
	local stampScale=UI.New("UIScale",{Parent=stamp})
	local catcher=UI.New("TextButton",{Name="SkipCatcher",Text="",AutoButtonColor=false,Selectable=false,BackgroundTransparency=1,Size=UDim2.fromScale(1,1),Parent=gui})
	local skip=UI.Button({text=multi and "Skip All" or "Skip",textSize=24,color=UI.Colors.Blue,size=UDim2.fromOffset(150,56)})
	skip.Name="Skip";skip.AnchorPoint=Vector2.new(1,1);skip.Position=UDim2.new(1,-24,1,-24);skip.Parent=gui

	-- Chest model (level follows the chest that was opened) and the hero weapon.
	local chest=ChestBuilder.Build(ChestBuilder.LevelOf(chestRarity),CFrame.new());chest.Parent=world
	local ccf,csize=chest:GetBoundingBox()
	local home=CFrame.new()
	local top=ccf.Position.Y+csize.Y/2
	local dist=math.max(csize.Magnitude,5)*1.9
	local focus=Vector3.new(0,csize.Y*.45,0)
	local function frame(target,extra) cam.CFrame=CFrame.lookAt(target+Vector3.new(0,dist*.28,-(dist+(extra or 0))),target) end
	frame(focus)
	local fxModel=chest:FindFirstChild("FX");local fxBase=fxModel and fxModel:GetPivot()
	local core=neon(world,"Core",Vector3.one*.2,CFrame.new(0,top*.55,0),color,Enum.PartType.Ball);core.Transparency=1
	local weapon=Visual.Build(hero.def,hero.result.item,true);weapon.Parent=world
	local wcf,wsize=weapon:GetBoundingBox();local wscale=(csize.Y*1.5)/math.max(wsize.Y,wsize.X,.1) -- same on-screen size for every weapon
	weapon:ScaleTo(weapon:GetScale()*wscale)
	weapon:PivotTo(CFrame.new(0,-50,0))
	local beam,ring;local cubes={}

	local t,finished=0,false
	local function skipNow() if not finished then t=Timeline.Skip(plan) end end
	catcher.Activated:Connect(skipNow);skip.Button.Activated:Connect(skipNow)
	local inputConn=UIS.InputBegan:Connect(function(input) if input.KeyCode==Enum.KeyCode.ButtonA or input.KeyCode==Enum.KeyCode.ButtonB then skipNow() end end)

	local closed=false
	local function close()
		if closed then return end;closed=true;active=false
		if inputConn then inputConn:Disconnect() end
		gui:Destroy()
	end

	local function showResult()
		finished=true;catcher:Destroy();skip:Destroy();view.Visible=false -- card over sunburst only
		for _,c in cubes do c.part:Destroy() end;table.clear(cubes)
		if beam then beam.Transparency=.6 end;if ring then ring:Destroy();ring=nil end
		flash.BackgroundTransparency=1
		local equippedUid=Data.Get("Inventory.Equipped");local inv=Data.Get("Inventory.Weapons") or {}
		local current=equippedUid and inv[equippedUid]
		local card=UI.New("Frame",{Name=multi and "ResultGrid" or "ResultCard",Active=true,AnchorPoint=Vector2.new(.5,.5),Position=UDim2.fromScale(.5,.5),Size=multi and UDim2.fromOffset(720,480) or UDim2.fromOffset(440,440),BackgroundColor3=UI.Colors.Panel,Parent=gui},{UI.Corner(20),UI.Stroke(5),UI.Padding(16)})
		local stroke=card:FindFirstChildOfClass("UIStroke");stroke.Color=color
		local scale=UI.New("UIScale",{Parent=card})
		local function fit() local v=workspace.CurrentCamera.ViewportSize;scale.Scale=math.min(1,(v.X-24)/(multi and 720 or 440),(v.Y-24)/(multi and 480 or 440)) end
		fit();local fitConn=workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(fit);card.Destroying:Connect(function() fitConn:Disconnect() end)
		local buttons=UI.New("Frame",{Name="Actions",BackgroundTransparency=1,AnchorPoint=Vector2.new(.5,1),Position=UDim2.fromScale(.5,1),Size=UDim2.new(1,0,0,56),Parent=card},{UI.List(Enum.FillDirection.Horizontal,10,Enum.HorizontalAlignment.Center)})
		local function action(name,text,col,fn) local b=UI.Button({text=text,textSize=24,color=col,size=UDim2.fromOffset(multi and 200 or 128,56),onClick=fn});b.Name=name;b.Parent=buttons;return b end
		if multi then
			UI.Label("Results",30,{Name="Heading",Size=UDim2.new(1,0,0,38),TextXAlignment=Enum.TextXAlignment.Center,Parent=card})
			local grid=UI.New("Frame",{Name="Grid",BackgroundTransparency=1,Position=UDim2.fromOffset(0,44),Size=UDim2.new(1,0,1,-110),Parent=card},{UI.New("UIGridLayout",{CellSize=UDim2.new(.2,-8,.5,-8),CellPadding=UDim2.fromOffset(8,8),SortOrder=Enum.SortOrder.LayoutOrder})})
			for i,e in list do
				local cell=UI.New("Frame",{Name="Result"..i,LayoutOrder=i,BackgroundColor3=UI.Colors.PanelDark,Parent=grid},{UI.Corner(12),UI.Stroke(3,glow(e.rarity))})
				icon(cell,e.def,e.result.item,{Position=UDim2.fromOffset(4,4),Size=UDim2.new(1,-8,1,-48)})
				local n=UI.Label(e.def.name,16,{Name="ItemName",Position=UDim2.new(0,4,1,-44),Size=UDim2.new(1,-8,0,22),TextXAlignment=Enum.TextXAlignment.Center,TextScaled=true,TextColor3=glow(e.rarity),Parent=cell})
				UI.New("UITextSizeConstraint",{MaxTextSize=16,Parent=n})
				UI.Label(e.rarity,13,{Name="Rarity",Position=UDim2.new(0,4,1,-22),Size=UDim2.new(1,-8,0,18),TextXAlignment=Enum.TextXAlignment.Center,Parent=cell})
				if e.result.new then UI.Label("NEW!",15,{Name="New",Position=UDim2.fromOffset(6,4),Size=UDim2.fromOffset(60,20),TextColor3=Color3.fromRGB(120,255,120),Parent=cell}) end
				if e.giant then UI.Label("GIANT",15,{Name="Giant",AnchorPoint=Vector2.new(1,0),Position=UDim2.new(1,-6,0,4),Size=UDim2.fromOffset(70,20),TextXAlignment=Enum.TextXAlignment.Right,TextColor3=Color3.fromRGB(255,214,64),Parent=cell}) end
			end
			action("KeepAll","Keep All",UI.Colors.Green,close)
		else
			local e=list[1];local item=e.result.item
			icon(card,e.def,item,{Name="Icon",Position=UDim2.fromOffset(0,0),Size=UDim2.new(1,0,0,170)})
			if e.result.new then UI.Label("NEW!",26,{Name="New",Position=UDim2.fromOffset(4,2),Size=UDim2.fromOffset(110,32),TextColor3=Color3.fromRGB(120,255,120),Parent=card}) end
			if e.giant then UI.Label("GIANT",26,{Name="Giant",AnchorPoint=Vector2.new(1,0),Position=UDim2.new(1,-4,0,2),Size=UDim2.fromOffset(130,32),TextXAlignment=Enum.TextXAlignment.Right,TextColor3=Color3.fromRGB(255,214,64),Parent=card}) end
			local n=UI.Label(e.def.name,32,{Name="ItemName",Position=UDim2.fromOffset(0,172),Size=UDim2.new(1,0,0,40),TextXAlignment=Enum.TextXAlignment.Center,TextScaled=true,TextColor3=glow(e.rarity),Parent=card})
			UI.New("UITextSizeConstraint",{MaxTextSize=32,Parent=n})
			UI.Label(e.rarity.." • IL "..item.il,22,{Name="Rarity",Position=UDim2.fromOffset(0,214),Size=UDim2.new(1,0,0,28),TextXAlignment=Enum.TextXAlignment.Center,Parent=card})
			local power=Loot.Power(item)
			UI.Label("Power "..NF.Short(power),26,{Name="Power",Position=UDim2.fromOffset(0,248),Size=UDim2.new(1,0,0,32),TextXAlignment=Enum.TextXAlignment.Center,Parent=card})
			if current and equippedUid~=e.result.uid then
				local diff=power-Loot.Power(current)
				local up=diff>=0;local delta=(up and "▲ +" or "▼ -")..NF.Short(math.abs(diff))
				UI.Label("Compared with equipped: "..delta,20,{Name="Compare",Position=UDim2.fromOffset(0,282),Size=UDim2.new(1,0,0,26),TextXAlignment=Enum.TextXAlignment.Center,TextColor3=up and Color3.fromRGB(120,255,120) or Color3.fromRGB(255,120,110),Parent=card})
			end
			if not opts.preview and opts.onEquip and equippedUid~=e.result.uid then action("Equip","Equip",UI.Colors.Green,function() opts.onEquip(e.result.uid);close() end) end
			action("Keep","Keep",UI.Colors.Blue,close)
		end
		if not opts.preview and opts.onAgain and (not opts.canAgain or opts.canAgain()) then action("OpenAgain","Open Again",UI.Colors.Orange,function() close();task.defer(opts.onAgain) end) end
		local v=UIS:GetLastInputType().Value
		if v>=Enum.UserInputType.Gamepad1.Value and v<=Enum.UserInputType.Gamepad8.Value then
			local first=buttons:FindFirstChildWhichIsA("Frame");if first and first:FindFirstChild("Button") then GuiService.SelectedObject=first.Button end
		end
		local closeConn;closeConn=UIS.InputBegan:Connect(function(input) if input.KeyCode==Enum.KeyCode.ButtonB then close() end end)
		card.Destroying:Connect(function() closeConn:Disconnect() end)
	end

	if plan.total==0 then view.Visible=false;title.Visible=false;showResult();return end

	local burstDone,revealShown=false,false
	local nCubes=({6,10,14,18,24})[Timeline.Rank(bestRarity)];if few then nCubes=math.ceil(nCubes/2) end
	local spin=0
	local conn;conn=RunService.Heartbeat:Connect(function(dt)
		if closed then conn:Disconnect();return end
		t+=dt;spin+=dt
		for i,bar in rays do bar.Rotation=(i-1)*22.5+spin*(calm and 4 or 14) end
		if finished then return end
		local phase,p=Timeline.At(plan,t)
		if phase=="Intro" then
			chest:PivotTo(home*CFrame.new(0,(1-back(p))*8,0)*CFrame.Angles(0,(1-ease(p))*1.2,0))
		elseif phase=="Charge" then
			local amp=calm and 0 or .12*p
			chest:PivotTo(home*CFrame.new((math.random()-.5)*amp,0,(math.random()-.5)*amp))
			ChestBuilder.SetLid(chest,calm and 0 or .04*math.abs(math.sin(t*30))*p)
			core.Size=Vector3.one*(.2+p*csize.X*.5);core.Transparency=1-.6*p
			if fxModel then fxModel:PivotTo(CFrame.new(fxBase.Position)*CFrame.Angles(0,spin*(1+p*6),0)*fxBase.Rotation) end
		elseif phase=="Burst" then
			chest:PivotTo(home)
			if not burstDone then
				burstDone=true
				flash.BackgroundTransparency=calm and .85 or .25
				beam=neon(world,"Beam",Vector3.new(csize.X*.35,.1,csize.X*.35),CFrame.new(0,top,0),color);beam.Transparency=.25
				ring=neon(world,"Shockwave",Vector3.new(.15,.5,.5),CFrame.new(0,.2,0)*CFrame.Angles(0,0,math.pi/2),color,Enum.PartType.Cylinder);ring.Transparency=.2
				for _=1,nCubes do
					local s=.2+math.random()*.35
					local part=neon(world,"Spark",Vector3.one*s,CFrame.new(0,top*.8,0),color:Lerp(Color3.new(1,1,1),math.random()*.5))
					table.insert(cubes,{part=part,vel=Vector3.new(math.random()*2-1,1.2+math.random()*1.6,math.random()*2-1).Unit*(8+math.random()*8)})
				end
				if bestRarity=="Mythic" and not calm then
					for k=1,3 do local a=k*2.1;neon(world,"Bolt",Vector3.new(.12,top*2.4,.12),CFrame.new(math.cos(a)*csize.X*.7,top*1.3,math.sin(a)*csize.X*.7)*CFrame.Angles(.3*math.cos(a),0,.3*math.sin(a)),Color3.fromRGB(230,200,255)).Transparency=.1 end
				end
			end
			ChestBuilder.SetLid(chest,ease(p))
			flash.BackgroundTransparency=math.min(1,flash.BackgroundTransparency+dt*3)
			core.Transparency=math.min(1,core.Transparency+dt*4)
			beam.Size=Vector3.new(beam.Size.X,.1+ease(p)*top*6,beam.Size.Z);beam.CFrame=CFrame.new(0,top+beam.Size.Y/2,0)
			local d=.5+ease(p)*csize.X*5;ring.Size=Vector3.new(.15,d,d);ring.Transparency=.2+.8*p
			if bestRarity=="Mythic" and not calm then cam.FieldOfView=50-8*ease(p) end
		elseif phase=="Reveal" then
			if not revealShown then
				revealShown=true;if ring then ring:Destroy();ring=nil end
				for _,bar in rays do bar.BackgroundTransparency=0 end
				nameLabel.Text=hero.def.name;rarityLabel.Text=hero.giant and ("Giant "..hero.rarity) or hero.rarity
				local shout=({Legendary="LEGENDARY!",Mythic="MYTHIC!"})[hero.rarity];if shout then banner.Text=shout;banner.Visible=true end
				if anyGiant and plan.mode=="Full" then stamp.Visible=true;stampScale.Scale=2.2 end
				title.Visible=false
			end
			local lift=ease(p)
			weapon:PivotTo(CFrame.new(0,top+.5+lift*2.2,0)*CFrame.Angles(0,spin*2.4,0))
			frame(focus:Lerp(Vector3.new(0,top+2,0),lift),-dist*.15*lift)
			nameLabel.TextTransparency=1-lift;rarityLabel.TextTransparency=1-lift
			if beam then beam.Transparency=.25+.65*lift end -- fade so the weapon reads
			if stamp.Visible then stampScale.Scale=math.max(1,stampScale.Scale-dt*6) end
		else
			if not revealShown then -- skipped: show the end state
				for _,bar in rays do bar.BackgroundTransparency=0 end
				ChestBuilder.SetLid(chest,1);chest:PivotTo(home);weapon:PivotTo(CFrame.new(0,top+2.7,0))
				frame(Vector3.new(0,top+2,0),-dist*.15)
			end
			nameLabel.Visible=false;rarityLabel.Visible=false;banner.Visible=false;stamp.Visible=false
			showResult()
		end
		for i=#cubes,1,-1 do
			local c=cubes[i];c.vel+=Vector3.new(0,-22*dt,0);c.part.CFrame=c.part.CFrame+c.vel*dt
			if c.part.Position.Y<-4 then c.part:Destroy();table.remove(cubes,i) end
		end
	end)
	gui.Destroying:Connect(function() conn:Disconnect();active=false end)
end

-- Idle FX at Chest Altars: gentle bob + a pulsing light; one Heartbeat at ~30 Hz, near the camera only.
local function startIdle()
	local items={}
	local function add(altar)
		for _,m in altar:GetChildren() do
			if m:IsA("Model") and m.Name:match("^Chest_L%d") then
				local level=tonumber(m.Name:match("%d+")) or 1
				local light
				if not lowFx() then
					local body=m:FindFirstChild("Body",true)
					if body and body:IsA("BasePart") then light=Instance.new("PointLight");light.Color=(ChestBuilder.Levels[level] or ChestBuilder.Levels[1]).glow;light.Range=10+level*2;light.Brightness=1;light.Parent=body end
				end
				table.insert(items,{model=m,base=m:GetPivot(),amp=.15+level*.08,light=light})
			end
		end
	end
	for _,a in Collection:GetTagged("ChestAltar") do add(a) end
	Collection:GetInstanceAddedSignal("ChestAltar"):Connect(add)
	local acc,clock=0,0
	RunService.Heartbeat:Connect(function(dt)
		acc+=dt;clock+=dt;if acc<1/30 or #items==0 then return end;acc=0
		local camPos=workspace.CurrentCamera.CFrame.Position
		for i=#items,1,-1 do
			local it=items[i]
			if not it.model.Parent then table.remove(items,i)
			elseif (it.base.Position-camPos).Magnitude<150 then
				it.model:PivotTo(it.base*CFrame.new(0,math.sin(clock*1.6)*(reduced() and 0 or it.amp),0))
				if it.light then it.light.Brightness=.8+.6*math.sin(clock*2) end
			end
		end
	end)
end

function Opening.Start()
	-- Admin QA: `chest preview <rarity|giant> [multi]` sends fake results here; nothing is saved.
	Net.Event("ChestPreview").OnClientEvent:Connect(function(results)
		if type(results)=="table" then Opening.Play(results,{preview=true}) end
	end)
	task.spawn(startIdle)
end

return Opening
