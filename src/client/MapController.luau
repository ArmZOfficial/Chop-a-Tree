-- Compass (heading + quest/event targets) and the client side of the coastal boat ride.
-- The world map window and minimap were removed 2026-10-03 (ArmZ); zone travel is the Warp tab in Quests.
local Players = game:GetService("Players")
local Run = game:GetService("RunService")
local S = game.ReplicatedStorage.Shared
local UI = require(S.UIKit)
local T = require(S.Locale).T
local Net = require(S.Net)
local Map = {}
local connections = {}
local gui, heading, compass
local boatRide
local function endBoat()
	local ride=boatRide;if not ride then return end;boatRide=nil
	if ride.model then ride.model:Destroy() end
	if ride.button then ride.button:Destroy() end
	if workspace.CurrentCamera==ride.camera and ride.camera.CameraType==Enum.CameraType.Scriptable then
		ride.camera.CameraType=ride.cameraType;ride.camera.CameraSubject=ride.subject;ride.camera.CFrame=ride.cframe
	end
end
function Map.Start()
	local player=Players.LocalPlayer
	gui=UI.New("ScreenGui",{Name="MapHUD",ResetOnSpawn=false,DisplayOrder=22,Parent=player:WaitForChild("PlayerGui")})
	heading=UI.Label("N",14,{AnchorPoint=Vector2.new(.5,0),Position=UDim2.new(.5,0,0,115),Size=UDim2.fromOffset(300,24),TextXAlignment=Enum.TextXAlignment.Center,Parent=gui})
	compass=UI.New("Frame",{Name="CompassTargets",AnchorPoint=Vector2.new(.5,0),Position=UDim2.new(.5,0,0,141),Size=UDim2.fromOffset(300,52),BackgroundTransparency=1,Parent=gui})
	local targets={}
	for _,key in {"Quest","Event"} do
		targets[key]=UI.Label("",12,{Name=key.."Target",AnchorPoint=Vector2.new(.5,0),Size=UDim2.fromOffset(150,24),TextWrapped=false,TextXAlignment=Enum.TextXAlignment.Center,TextColor3=key=="Quest" and Color3.fromRGB(255,230,100) or Color3.fromRGB(255,160,70),Visible=false,Parent=compass})
	end
	local flags=game.ReplicatedStorage:WaitForChild("FeatureFlags")
	local function enabled() gui.Enabled=flags:GetAttribute("MapSystems")==true; if not gui.Enabled then endBoat() end end
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
	local function fit()
		local camera=workspace.CurrentCamera;if not camera then return end
		local v=camera.ViewportSize;local phone=v.X<700 or v.Y<500
		-- Phones: the compass text is dropped and its targets sit under the currencies.
		heading.Visible=not phone
		compass.Position=UDim2.new(.5,0,0,phone and 76 or 141)
	end
	if workspace.CurrentCamera then table.insert(connections,workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(fit)) end
	fit()
	local elapsed=0
	table.insert(connections,Run.Heartbeat:Connect(function(dt)
		elapsed+=dt;if elapsed<.2 or not gui.Enabled then return end;elapsed=0
		local hr=player.Character and player.Character:FindFirstChild("HumanoidRootPart")
		local camera=workspace.CurrentCamera
		local event=game.ReplicatedStorage:FindFirstChild("WorldEventState")
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
			end
		end
		if camera then local angle=math.deg(math.atan2(camera.CFrame.LookVector.X,-camera.CFrame.LookVector.Z))%360;heading.Text=T("Compass {1}° • N  E  S  W",{math.floor(angle)}) end
	end))
end
function Map.Destroy()
	endBoat()
	for _,c in connections do c:Disconnect() end;table.clear(connections)
	if gui then gui:Destroy();gui=nil end
end
return Map
