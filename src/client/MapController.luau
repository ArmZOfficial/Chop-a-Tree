-- Lightweight top-down map drawn directly from the live ring configuration (no world cloning).
local Players = game:GetService("Players")
local Input = game:GetService("UserInputService")
local Actions = game:GetService("ContextActionService")
local Selection = game:GetService("GuiService")
local Run = game:GetService("RunService")
local Collection = game:GetService("CollectionService")
local Tween = game:GetService("TweenService")
local S = game.ReplicatedStorage.Shared
local UI = require(S.UIKit)
local T = require(S.Locale).T
local Locale = require(S.Locale)
local Zones = require(S.Config.Zones)
local Explorer = require(S.Config.Explorer)
local Util = require(S.ZoneUtil)
local Net = require(S.Net)
local Data = require(script.Parent.ClientData)
local Map = {}
local connections, static, dots = {}, {}, {}
local gui, panel, heading, mini, status, rows, mapCanvas, compass
local boatRide
local function endBoat()
	local ride=boatRide;if not ride then return end;boatRide=nil
	if ride.model then ride.model:Destroy() end
	if ride.button then ride.button:Destroy() end
	if workspace.CurrentCamera==ride.camera and ride.camera.CameraType==Enum.CameraType.Scriptable then
		ride.camera.CameraType=ride.cameraType;ride.camera.CameraSubject=ride.subject;ride.camera.CFrame=ride.cframe
	end
end
local miniRings = {}
local cameraMode, selected, travelling = false, nil, false
local worldCenter, worldSpan = Vector3.new(0,0,150), 2200
local function unlocked(id) return table.find(Data.Get("Progress.UnlockedZones") or {}, id) ~= nil end
local function circle(parent, name, color, pos, size)
	return UI.New("Frame", { Name = name, BorderSizePixel = 0, BackgroundColor3 = color, Position = pos, AnchorPoint = Vector2.new(.5,.5), Size = size, Parent = parent }, { UI.Corner(999) })
end
local function lockedColor(id) return Color3.fromRGB(65+id*7,65+id*7,70+id*7) end
local function drawRings(parent)
	for _, z in Zones.List do
		local point = Util.Project(Vector3.zero, worldCenter, worldSpan)
		local ring = circle(parent, "Zone"..z.id, unlocked(z.id) and z.colors.ground or lockedColor(z.id), UDim2.fromScale(point.X,point.Y), UDim2.fromScale(z.outer*2/worldSpan,z.outer*2/worldSpan))
		local border=UI.Stroke(1,z.colors.accent:Lerp(Color3.fromRGB(130,130,135),.7));border.Parent=ring
	end
	local at = Util.Project(Zones.Hub.center, worldCenter, worldSpan)
	circle(parent, "Hub", Color3.fromRGB(212,173,102), UDim2.fromScale(at.X,at.Y), UDim2.fromScale(Zones.Hub.radius*2/worldSpan,Zones.Hub.radius*2/worldSpan))
end
local function refresh()
	if not panel then return end
	for id, row in rows do
		local z = Zones.List[id]; local open = unlocked(id)
		local count = 0; local total = 0; local collected = Data.Get("Explorer.collected") or {}
		for _, def in Explorer.List do if def.zone == id then total += 1; if collected[def.id] then count += 1 end end end
		local suffix = open and T("Explored {1}/{2}", {count,total}) or T("Defeat boss and light shrine in Zone {1}", {id-1})
		row.Button:FindFirstChildWhichIsA("TextLabel",true).Text = T(z.name).."\n"..suffix
		UI.SetButtonColor(row, open and z.colors.accent or UI.Colors.Slate)
		mapCanvas["Zone"..id].BackgroundColor3 = open and z.colors.ground or lockedColor(id)
	end
	status.Text = selected and T("Destination: {1}", { selected == "Home" and T("Home") or selected == 0 and T("Rootfall") or T(Zones.List[selected].name) }) or T("Select a zone to travel")
end
local function marker(key, position, color, label)
	local entry = dots[key]
	if not entry then
		local large = circle(mapCanvas,"Marker",color,UDim2.new(),UDim2.fromOffset(8,8))
		large.ZIndex=10; large:SetAttribute("NoTranslate",true)
		local small = circle(mini,"Marker",color,UDim2.new(),UDim2.fromOffset(5,5)); small.ZIndex=10
		entry={large=large,small=small}; dots[key]=entry
	end
	local at = Util.Project(position,worldCenter,worldSpan)
	entry.large.Position=UDim2.fromScale(at.X,at.Y); entry.large.BackgroundColor3=color
	local root = Players.LocalPlayer.Character and Players.LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
	local camera=workspace.CurrentCamera
	local yaw = cameraMode and camera and math.atan2(camera.CFrame.LookVector.X,-camera.CFrame.LookVector.Z) or 0
	local point = Util.Project(position,root and root.Position or worldCenter,440,yaw)
	entry.small.Position=UDim2.fromScale(point.X,point.Y);entry.small.BackgroundColor3=color
	entry.small.Visible=(point-Vector2.new(.5,.5)).Magnitude<.47
	entry.seen=true
end
function Map.Start()
	local player=Players.LocalPlayer
	gui=UI.New("ScreenGui",{Name="MapHUD",ResetOnSpawn=false,DisplayOrder=22,Parent=player:WaitForChild("PlayerGui")})
	mini=UI.New("Frame",{Name="Minimap",AnchorPoint=Vector2.new(1,1),Position=UDim2.new(1,-12,1,-160),Size=UDim2.fromOffset(140,140),BackgroundColor3=Color3.fromRGB(40,70,75),ClipsDescendants=true,Parent=gui},{UI.Corner(999),UI.Stroke(3,UI.Colors.Accent)})
	for _,z in Zones.List do miniRings[z.id]=circle(mini,"Zone"..z.id,z.colors.ground,UDim2.new(),UDim2.fromScale(z.outer*2/440,z.outer*2/440)) end
	heading=UI.Label("N",14,{AnchorPoint=Vector2.new(.5,0),Position=UDim2.new(.5,0,0,115),Size=UDim2.fromOffset(300,24),TextXAlignment=Enum.TextXAlignment.Center,Parent=gui})
	compass=UI.New("Frame",{Name="CompassTargets",AnchorPoint=Vector2.new(.5,0),Position=UDim2.new(.5,0,0,141),Size=UDim2.fromOffset(300,52),BackgroundTransparency=1,Parent=gui})
	local targets={}
	for _,key in {"Quest","Event"} do
		targets[key]=UI.Label("",12,{Name=key.."Target",AnchorPoint=Vector2.new(.5,0),Size=UDim2.fromOffset(150,24),TextWrapped=false,TextXAlignment=Enum.TextXAlignment.Center,TextColor3=key=="Quest" and Color3.fromRGB(255,230,100) or Color3.fromRGB(255,160,70),Visible=false,Parent=compass})
	end
	panel=UI.New("Frame",{Name="Panel",ZIndex=20,AnchorPoint=Vector2.new(.5,.5),Position=UDim2.fromScale(.5,.5),Size=UDim2.fromOffset(740,526),BackgroundColor3=UI.Colors.Panel,Visible=false,Parent=gui})
	UI.Window(panel,"World Map","book")
	mapCanvas=UI.New("Frame",{Name="Island",Position=UDim2.fromOffset(20,66),Size=UDim2.fromOffset(390,390),BackgroundColor3=Color3.fromRGB(44,106,148),ClipsDescendants=true,Parent=panel})
	drawRings(mapCanvas)
	local scroll=UI.New("ScrollingFrame",{Name="Zones",Position=UDim2.fromOffset(425,64),Size=UDim2.fromOffset(295,300),BackgroundTransparency=1,CanvasSize=UDim2.new(),AutomaticCanvasSize=Enum.AutomaticSize.Y,ScrollBarThickness=5,Parent=panel},{UI.List(Enum.FillDirection.Vertical,5)})
	rows={}
	for _, z in Zones.List do
		local id=z.id;local row=UI.Button({text=T(z.name),textSize=16,color=z.colors.accent,size=UDim2.fromOffset(280,55),onClick=function() selected=id;refresh() end})
		row.Button:FindFirstChildWhichIsA("TextLabel",true).TextWrapped=true
		row.Name="Zone"..id; row.Parent=scroll; rows[id]=row
	end
	status=UI.Label(T("Select a zone to travel"),15,{Position=UDim2.fromOffset(425,365),Size=UDim2.fromOffset(295,40),TextWrapped=true,Parent=panel})
	local fade=UI.New("Frame",{Name="TravelFade",Size=UDim2.fromScale(1,1),BackgroundColor3=Color3.new(0,0,0),BackgroundTransparency=1,BorderSizePixel=0,ZIndex=100,Parent=gui})
	local travel=UI.Button({text=T("Travel"),color=UI.Colors.Green,size=UDim2.fromOffset(140,48),onClick=function()
		if not selected or travelling then return end; travelling=true
		Tween:Create(fade,TweenInfo.new(.15),{BackgroundTransparency=.3}):Play()
		task.spawn(function()
			local ok,success,message=pcall(function() return Net.Function("StoryAction"):InvokeServer("Warp",selected) end)
			travelling=false
			if not gui then return end
			Tween:Create(fade,TweenInfo.new(.25),{BackgroundTransparency=1}):Play()
			if ok and success then panel.Visible=false else status.Text=T(ok and message or "Travel unavailable") end
		end)
	end});travel.Position=UDim2.fromOffset(425,414);travel.Parent=panel
	local homeButtons={}
	for i, destination in {0,"Home"} do
		local button=UI.Button({text=T(destination==0 and "Rootfall" or "Home"),color=UI.Colors.Blue,size=UDim2.fromOffset(140,48),onClick=function() selected=destination;refresh() end})
		button.Position=UDim2.fromOffset(425+(i-1)*150,464);button.Parent=panel;homeButtons[i]=button
	end
	local toggle=UI.Button({text=T("Map"),color=UI.Colors.Blue,size=UDim2.fromOffset(72,38),onClick=function() panel.Visible=not panel.Visible;refresh() end})
	toggle.AnchorPoint=Vector2.new(1,1);toggle.Position=UDim2.new(1,-12,1,-115);toggle.Parent=gui
	table.insert(connections,panel:GetPropertyChangedSignal("Visible"):Connect(function()
		mini.Visible=not panel.Visible;heading.Visible=not panel.Visible;compass.Visible=not panel.Visible;toggle.Visible=not panel.Visible
		if not panel.Visible and Selection.SelectedObject and Selection.SelectedObject:IsDescendantOf(panel) then Selection.SelectedObject=nil end
	end))
	local north=UI.Button({text=T("North / Camera"),textSize=13,color=UI.Colors.Slate,size=UDim2.fromOffset(145,48),onClick=function() cameraMode=not cameraMode end})
	north.Position=UDim2.fromOffset(575,414);north.Parent=panel
	Actions:BindActionAtPriority("MapToggle",function(_,state,input)
		if not gui.Enabled or Input:GetFocusedTextBox() then return Enum.ContextActionResult.Pass end
		if input.KeyCode==Enum.KeyCode.ButtonB and not panel.Visible then return Enum.ContextActionResult.Pass end
		if state==Enum.UserInputState.Begin then
			panel.Visible=input.KeyCode~=Enum.KeyCode.ButtonB and not panel.Visible;refresh()
			if panel.Visible and input.KeyCode==Enum.KeyCode.ButtonSelect then Selection.SelectedObject=rows[1].Button end
		end
		return Enum.ContextActionResult.Sink
	end,false,Enum.ContextActionPriority.High.Value,Enum.KeyCode.M,Enum.KeyCode.ButtonSelect,Enum.KeyCode.ButtonB)
	table.insert(connections,Data.Changed:Connect(refresh)); table.insert(connections,Locale.Changed:Connect(refresh))
	local flags=game.ReplicatedStorage:WaitForChild("FeatureFlags")
	local function enabled() gui.Enabled=flags:GetAttribute("MapSystems")==true; if not gui.Enabled then panel.Visible=false;endBoat() end end
	table.insert(connections,flags:GetAttributeChangedSignal("MapSystems"):Connect(enabled));enabled()
	table.insert(connections,player.CharacterRemoving:Connect(endBoat))
	table.insert(connections,Net.Event("StoryShow").OnClientEvent:Connect(function(msg)
		if msg.kind=="boatEnd" then if boatRide and boatRide.token==msg.token then endBoat() end;return end
		if msg.kind~="boat" or not gui.Enabled then return end
		endBoat();local camera=workspace.CurrentCamera
		if not camera or camera.CameraType~=Enum.CameraType.Custom or not msg.boat or not msg.boat.Parent then return end
		local model=msg.boat:Clone()
		for _,x in model:GetDescendants() do if x:IsA("ProximityPrompt") then x:Destroy() end end
		model.Name="LocalBoatRide";model.Parent=workspace
		boatRide={token=msg.token,model=model,camera=camera,cameraType=camera.CameraType,subject=camera.CameraSubject,cframe=camera.CFrame,from=msg.from,to=msg.to,bend=msg.bend,duration=msg.duration,started=os.clock()}
		camera.CameraType=Enum.CameraType.Scriptable
		local ride=boatRide
		local button=UI.Button({text=T("Skip boat ride"),color=UI.Colors.Blue,size=UDim2.fromOffset(180,48),onClick=function()
			if boatRide~=ride or ride.skipping then return end;ride.skipping=true
			task.spawn(function() local ok,accepted=pcall(function() return Net.Function("StoryAction"):InvokeServer("BoatSkip",ride.token) end);if not ok or not accepted then ride.skipping=false end end)
		end})
		button.Name="BoatSkip";button.AnchorPoint=Vector2.new(.5,1);button.Position=UDim2.new(.5,0,1,-64);button.ZIndex=110;button.Parent=gui;ride.button=button
	end))
	table.insert(connections,Run.RenderStepped:Connect(function()
		local ride=boatRide;if not ride then return end
		if not ride.model.Parent or workspace.CurrentCamera~=ride.camera or ride.camera.CameraType~=Enum.CameraType.Scriptable or os.clock()-ride.started>ride.duration+4 then endBoat();return end
		local alpha=math.clamp((os.clock()-ride.started)/ride.duration,0,1)
		local a,b,c=ride.from.Position,ride.bend,ride.to.Position
		local pos=a*(1-alpha)^2+b*(2*(1-alpha)*alpha)+c*alpha^2
		local direction=(b-a)*(2*(1-alpha))+(c-b)*(2*alpha)
		local cf=CFrame.lookAt(pos,pos+direction)+Vector3.new(0,math.sin(alpha*math.pi)*.4,0)
		ride.model:PivotTo(cf);ride.camera.CFrame=CFrame.lookAt(cf.Position+Vector3.new(18,14,24),cf.Position)
	end))
	for _, tag in {"PlayerBase","Shop","ChestAltar","WarpStone","ExplorerCollectible","BossArena","Shrine"} do
		local function add(x) static[x]=tag end
		for _,x in Collection:GetTagged(tag) do add(x) end
		table.insert(connections,Collection:GetInstanceAddedSignal(tag):Connect(add))
		table.insert(connections,Collection:GetInstanceRemovedSignal(tag):Connect(function(x) static[x]=nil end))
	end
	local scale=UI.New("UIScale",{Parent=panel})
	local function fit()
		local camera=workspace.CurrentCamera;if not camera then return end
		local v=camera.ViewportSize
		if v.X<700 or v.Y<560 then
			-- Native-sized type on phones; scrolling zone list instead of shrinking the whole window.
			local w=math.min(v.X-20,740);local h=math.min(v.Y-60,690);scale.Scale=1;panel.Size=UDim2.fromOffset(w,h)
			local wide=w>=540
			local size=math.min(wide and w*.43 or w-40,math.max(90,h-300)*.7)
			local right=wide and size+35 or 20;local top=wide and 65 or size+75
			mapCanvas.Position=UDim2.fromOffset(20,65);mapCanvas.Size=UDim2.fromOffset(size,size)
			local width=w-right-20
			scroll.Position=UDim2.fromOffset(right,top);scroll.Size=UDim2.fromOffset(width,math.max(45,h-top-164))
			for _,row in rows do row.Size=UDim2.fromOffset(width-10,55) end
			status.Position=UDim2.fromOffset(right,h-154);status.Size=UDim2.fromOffset(width,40)
			travel.Position=UDim2.fromOffset(right,h-112);north.Position=UDim2.fromOffset(right+width/2+3,h-112)
			travel.Size=UDim2.fromOffset(width/2-4,48);north.Size=UDim2.fromOffset(width/2-4,48)
			for i,button in homeButtons do button.Position=UDim2.fromOffset(right+(i-1)*(width/2+3),h-56);button.Size=UDim2.fromOffset(width/2-4,48) end
		else
			scale.Scale=1;panel.Size=UDim2.fromOffset(740,526)
			mapCanvas.Position=UDim2.fromOffset(20,66);mapCanvas.Size=UDim2.fromOffset(390,390)
			scroll.Position=UDim2.fromOffset(425,64);scroll.Size=UDim2.fromOffset(295,300)
			for _,row in rows do row.Size=UDim2.fromOffset(280,55) end
			status.Position=UDim2.fromOffset(425,365);status.Size=UDim2.fromOffset(295,40)
			travel.Position=UDim2.fromOffset(425,414);travel.Size=UDim2.fromOffset(140,48)
			north.Position=UDim2.fromOffset(575,414);north.Size=UDim2.fromOffset(145,48)
			for i,button in homeButtons do button.Position=UDim2.fromOffset(425+(i-1)*150,464);button.Size=UDim2.fromOffset(140,48) end
		end
		local size=v.X<700 and 90 or 140;mini.Size=UDim2.fromOffset(size,size)
		toggle.Size=UDim2.fromOffset(72,(Input.TouchEnabled or v.X<700) and 48 or 38)
	end
	if workspace.CurrentCamera then table.insert(connections,workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(fit)) end
	fit();refresh()
	local elapsed=0
	table.insert(connections,Run.Heartbeat:Connect(function(dt)
		elapsed+=dt;if elapsed<.2 or not gui.Enabled then return end;elapsed=0
		for _,entry in dots do entry.seen=false end
		local hr=player.Character and player.Character:FindFirstChild("HumanoidRootPart")
		local camera=workspace.CurrentCamera
		local yaw=cameraMode and camera and math.atan2(camera.CFrame.LookVector.X,-camera.CFrame.LookVector.Z) or 0
		local at=Util.Project(Vector3.zero,hr and hr.Position or worldCenter,440,yaw)
		for id,ring in miniRings do ring.Position=UDim2.fromScale(at.X,at.Y);ring.BackgroundColor3=unlocked(id) and Zones.List[id].colors.ground or lockedColor(id) end
		for _,p in Players:GetPlayers() do
			local root=p.Character and p.Character:FindFirstChild("HumanoidRootPart")
			if root then marker(p,root.Position,p==player and Color3.new(1,1,1) or Color3.fromRGB(80,220,255)) end
		end
		for x,tag in static do if x:IsDescendantOf(workspace) then
			local hide=tag=="ExplorerCollectible" and (Data.Get("Explorer.collected") or {})[x:GetAttribute("ExplorerId")]
			if not hide then marker(x,x:GetPivot().Position,tag=="PlayerBase" and x:GetAttribute("OwnerUserId")==player.UserId and Color3.fromRGB(80,255,110) or Color3.fromRGB(255,210,80)) end
		end end
		local event=game.ReplicatedStorage:FindFirstChild("WorldEventState")
		if event and event:GetAttribute("position") then marker("WorldEvent",event:GetAttribute("position"),Color3.fromRGB(255,140,40)) end
		local guide=workspace:FindFirstChild("QuestGuide")
		local positions={Quest=guide and guide:GetAttribute("TargetPosition"),Event=event and event:GetAttribute("position")}
		for key,label in targets do
			local position=positions[key];label.Visible=hr~=nil and camera~=nil and position~=nil
			if label.Visible then
				local delta=position-hr.Position
				local bearing=math.atan2(delta.X,-delta.Z)-math.atan2(camera.CFrame.LookVector.X,-camera.CFrame.LookVector.Z)
				bearing=(bearing+math.pi)%(2*math.pi)-math.pi
				label.Position=UDim2.new(.5+math.clamp(bearing/math.rad(120),-.25,.25),0,0,key=="Quest" and 0 or 24)
				local name=key=="Quest" and T("Quest target") or T("Event target")
				label.Text=T("{1} {2} • {3}",{bearing<math.rad(-60) and "◀" or bearing>math.rad(60) and "▶" or "◆",name,math.floor(delta.Magnitude)})
				if key=="Quest" then marker("QuestTarget",position,Color3.fromRGB(255,230,100)) end
			end
		end
		for key,entry in dots do if not entry.seen then entry.large:Destroy();entry.small:Destroy();dots[key]=nil end end
		if camera then local angle=math.deg(math.atan2(camera.CFrame.LookVector.X,-camera.CFrame.LookVector.Z))%360;heading.Text=T("Compass {1}° • N  E  S  W",{math.floor(angle)}) end
	end))
end
function Map.Destroy()
	endBoat()
	Actions:UnbindAction("MapToggle")
	for _,c in connections do c:Disconnect() end;table.clear(connections);table.clear(static);table.clear(dots)
	if gui then gui:Destroy();gui=nil end
end
return Map
