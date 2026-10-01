-- Emote wheel + photo mode (plan 9.4). G = wheel, P = photo mode.
-- Emotes reuse the default Animate script animations; showcase asks the server for an aura.
local Players=game:GetService("Players")
local UIS=game:GetService("UserInputService")
local RunService=game:GetService("RunService")
local CAS=game:GetService("ContextActionService")
local StarterGui=game:GetService("StarterGui")
local S=game.ReplicatedStorage.Shared
local Net=require(S.Net);local UI=require(S.UIKit)
local Emote={}
local EMOTES={{"wave","โบกมือ"},{"dance","เต้น"},{"dance2","เต้น 2"},{"cheer","ดีใจ"},{"laugh","หัวเราะ"},{"sit","นั่ง"},{"showcase","โชว์อาวุธ"}}
local FILTERS={{"ปกติ",{}},{"อนิเมะ",{Saturation=.45,Contrast=.15,Brightness=.03}},{"ซีเปีย",{Saturation=-.7,TintColor=Color3.fromRGB(255,222,175)}},{"กลางคืน",{Brightness=-.12,Saturation=-.2,TintColor=Color3.fromRGB(150,170,255)}}}
local function enabled() return game.ReplicatedStorage.FeatureFlags:GetAttribute("Emotes")~=false end
function Emote.Start()
	local player=Players.LocalPlayer;local camera=workspace.CurrentCamera
	local gui=UI.New("ScreenGui",{Name="EmoteHUD",ResetOnSpawn=false,DisplayOrder=8,Parent=player:WaitForChild("PlayerGui")})
	local wheel=UI.New("Frame",{Name="Wheel",AnchorPoint=Vector2.new(.5,.5),Position=UDim2.fromScale(.5,.5),Size=UDim2.fromOffset(330,330),BackgroundTransparency=1,Visible=false,Parent=gui})
	local track
	local function stop() if track then track:Stop(.2);track=nil end end
	local function play(id)
		local char=player.Character;local hum=char and char:FindFirstChildOfClass("Humanoid");local animator=hum and hum:FindFirstChildOfClass("Animator")
		if not hum or hum.Health<=0 then return end
		wheel.Visible=false;stop()
		if id=="sit" then hum.Sit=true;return end
		if id=="showcase" then Net.Event("EmoteAction"):FireServer("Showcase");id="cheer" end
		local folder=char:FindFirstChild("Animate");local anim=folder and folder:FindFirstChild(id);anim=anim and anim:FindFirstChildWhichIsA("Animation")
		if not anim or not animator then return end
		track=animator:LoadAnimation(anim);track.Priority=Enum.AnimationPriority.Action;track.Looped=id:sub(1,5)=="dance";track:Play(.2)
	end
	for i,e in EMOTES do local id=e[1]
		local a=(i-1)/#EMOTES*math.pi*2-math.pi/2
		local b=UI.Button({text=e[2],color=id=="showcase" and UI.Colors.Purple or UI.Colors.Teal,size=UDim2.fromOffset(104,46),onClick=function() play(id) end})
		b.Name="Emote_"..id;b.AnchorPoint=Vector2.new(.5,.5);b.Position=UDim2.new(.5,math.cos(a)*120,.5,math.sin(a)*120);b.Parent=wheel
	end
	-- Moving cancels a looping emote, like the default chat emotes.
	RunService.Heartbeat:Connect(function()
		local hum=track and player.Character and player.Character:FindFirstChildOfClass("Humanoid")
		if hum and hum.MoveDirection.Magnitude>.1 then stop() end
	end)
	-- Photo mode
	local photo=UI.New("ScreenGui",{Name="PhotoHUD",ResetOnSpawn=false,DisplayOrder=50,Enabled=false,IgnoreGuiInset=true,Parent=player.PlayerGui})
	UI.New("Frame",{Name="Frame",Size=UDim2.fromScale(1,1),BackgroundTransparency=1,Parent=photo},{UI.Stroke(10,Color3.fromRGB(255,255,255))})
	UI.TextStroke(2).Parent=UI.Label("CHOP A TREE",28,{Name="Title",AnchorPoint=Vector2.new(1,1),Position=UDim2.new(1,-28,1,-22),Size=UDim2.fromOffset(300,40),TextXAlignment=Enum.TextXAlignment.Right,Parent=photo})
	local bar=UI.New("Frame",{Name="Bar",AnchorPoint=Vector2.new(.5,0),Position=UDim2.new(.5,0,0,24),Size=UDim2.fromOffset(620,96),BackgroundTransparency=1,Parent=photo})
	local tip=UI.Label("WASD/QE เลื่อนกล้อง • คลิกขวาค้างหมุน • Shift เร็ว • H ซ่อนปุ่ม • P ออก",13,{Name="Tip",Position=UDim2.fromOffset(0,52),Size=UDim2.new(1,0,0,22),TextXAlignment=Enum.TextXAlignment.Center,Parent=bar});UI.TextStroke(1.5).Parent=tip
	local cc=Instance.new("ColorCorrectionEffect");cc.Name="PhotoFilter";cc.Enabled=false;cc.Parent=camera
	local saved,active,yaw,pitch={},false,0,0
	local function filter(props)
		cc.Brightness,cc.Contrast,cc.Saturation,cc.TintColor=0,0,0,Color3.new(1,1,1)
		for k,v in props do cc[k]=v end
	end
	local exitPhoto
	for i,f in FILTERS do local props=f[2]
		local b=UI.Button({text=f[1],color=UI.Colors.Slate,size=UDim2.fromOffset(110,44),onClick=function() filter(props) end})
		b.Name="Filter"..i;b.Position=UDim2.fromOffset((i-1)*124,0);b.Parent=bar
	end
	local exitButton=UI.Button({text="ออก",color=UI.Colors.Red,size=UDim2.fromOffset(110,44),onClick=function() exitPhoto() end});exitButton.Name="Exit";exitButton.Position=UDim2.fromOffset(4*124,0);exitButton.Parent=bar
	local function sink() return Enum.ContextActionResult.Sink end
	local free=not UIS.TouchEnabled -- ponytail: touch keeps the orbit camera; free cam needs a keyboard
	local function enter()
		if active or not enabled() then return end;active=true;wheel.Visible=false
		for _,g in player.PlayerGui:GetChildren() do if g:IsA("ScreenGui") and g~=photo then saved[g]=g.Enabled;g.Enabled=false end end
		pcall(StarterGui.SetCoreGuiEnabled,StarterGui,Enum.CoreGuiType.All,false)
		photo.Enabled=true;bar.Visible=true;tip.Visible=free;filter({});cc.Enabled=true
		if free then
			local x,y=camera.CFrame:ToEulerAnglesYXZ();pitch,yaw=x,y;camera.CameraType=Enum.CameraType.Scriptable
			CAS:BindActionAtPriority("PhotoSink",sink,false,3000,Enum.KeyCode.W,Enum.KeyCode.A,Enum.KeyCode.S,Enum.KeyCode.D,Enum.KeyCode.Q,Enum.KeyCode.E,Enum.KeyCode.Space)
		end
	end
	exitPhoto=function()
		if not active then return end;active=false;photo.Enabled=false;cc.Enabled=false
		for g,v in saved do if g.Parent then g.Enabled=v end end;table.clear(saved)
		pcall(StarterGui.SetCoreGuiEnabled,StarterGui,Enum.CoreGuiType.All,true)
		CAS:UnbindAction("PhotoSink");UIS.MouseBehavior=Enum.MouseBehavior.Default;camera.CameraType=Enum.CameraType.Custom
	end
	RunService.RenderStepped:Connect(function(dt)
		if not active or not free then return end
		if UIS:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then
			UIS.MouseBehavior=Enum.MouseBehavior.LockCurrentPosition;local d=UIS:GetMouseDelta()
			yaw-=d.X*.004;pitch=math.clamp(pitch-d.Y*.004,-1.4,1.4)
		else UIS.MouseBehavior=Enum.MouseBehavior.Default end
		local move=Vector3.zero
		for key,v in {[Enum.KeyCode.W]=Vector3.new(0,0,-1),[Enum.KeyCode.S]=Vector3.new(0,0,1),[Enum.KeyCode.A]=Vector3.new(-1,0,0),[Enum.KeyCode.D]=Vector3.new(1,0,0),[Enum.KeyCode.E]=Vector3.new(0,1,0),[Enum.KeyCode.Q]=Vector3.new(0,-1,0)} do if UIS:IsKeyDown(key) then move+=v end end
		local rot=CFrame.fromEulerAnglesYXZ(pitch,yaw,0);local speed=UIS:IsKeyDown(Enum.KeyCode.LeftShift) and 60 or 20
		camera.CFrame=CFrame.new(camera.CFrame.Position+rot:VectorToWorldSpace(move)*speed*dt)*rot
	end)
	local emoteButton=UI.Button({text="ท่าทาง (G)",color=UI.Colors.Teal,size=UDim2.fromOffset(130,48),onClick=function() if enabled() then wheel.Visible=not wheel.Visible end end})
	emoteButton.Name="EmoteToggle";emoteButton.Position=UDim2.fromOffset(200,245);emoteButton.Parent=gui
	local photoButton=UI.Button({text="ถ่ายรูป (P)",color=UI.Colors.Blue,size=UDim2.fromOffset(130,48),onClick=enter})
	photoButton.Name="PhotoToggle";photoButton.Position=UDim2.fromOffset(200,305);photoButton.Parent=gui
	UIS.InputBegan:Connect(function(input,processed)
		if processed then return end
		if input.KeyCode==Enum.KeyCode.G and enabled() and not active then wheel.Visible=not wheel.Visible
		elseif input.KeyCode==Enum.KeyCode.P then if active then exitPhoto() else enter() end
		elseif input.KeyCode==Enum.KeyCode.H and active then bar.Visible=not bar.Visible end
	end)
	game.ReplicatedStorage.FeatureFlags:GetAttributeChangedSignal("Emotes"):Connect(function()
		local on=enabled();if not on then wheel.Visible=false;stop();exitPhoto() end;gui.Enabled=on
	end)
end
return Emote
