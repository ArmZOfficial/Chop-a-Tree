-- Sprint input (track H): Shift hold/toggle (Settings.SprintMode), gamepad L3, touch RUN button.
-- Sends intent only; PetService validates and sets Character.Sprinting, which drives speed + cosmetics.
-- Off while AdminFly (Shift = descend) or photo mode (Shift = fast free-cam). Shift-lock moves to Ctrl.
local Players=game:GetService("Players")
local UIS=game:GetService("UserInputService")
local RunService=game:GetService("RunService")
local GuiService=game:GetService("GuiService")
local Tween=game:GetService("TweenService")
local Debris=game:GetService("Debris")
local ContentProvider=game:GetService("ContentProvider")
local Shared=game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Movement=require(Shared.Config.Movement)
local Net=require(Shared.Net)
local UI=require(Shared.UIKit)
local Data=require(script.Parent.ClientData)
local Sprint={}

local KEYS={[Enum.KeyCode.LeftShift]=true,[Enum.KeyCode.RightShift]=true,[Enum.KeyCode.ButtonL3]=true}

function Sprint.Mode() return Data.Get("Settings.SprintMode") or Movement.DefaultMode end
function Sprint.SetMode(mode) Net.Event("SprintIntent"):FireServer("Mode",mode) end

local function reducedMotion()
	local ok,on=pcall(function() return GuiService.ReducedMotionEnabled end)
	return ok and on==true
end
local function lowGraphics()
	local ok,level=pcall(function() return UserSettings().GameSettings.SavedQualityLevel.Value end)
	return ok and level>=1 and level<=3
end

function Sprint.Start()
	local player=Players.LocalPlayer
	-- Reuse Roblox Animate so idle/jump/climb/emotes and speed-based playback keep their normal behavior.
	local function locomotion(character)
		task.spawn(function()
			local animate=character:WaitForChild("Animate",30)
			if not animate or character~=player.Character then return end
			local connections={}
			local function apply(animation)
				if not animation:IsA("Animation") then return end
				local folder=animation.Parent
				if folder.Parent~=animate or (folder.Name~="walk" and folder.Name~="run") then return end
				local function set()
					if animation.AnimationId~=Movement.LocomotionAnimation then animation.AnimationId=Movement.LocomotionAnimation end
				end
				set();table.insert(connections,animation:GetPropertyChangedSignal("AnimationId"):Connect(set))
			end
			for _,animation in animate:GetDescendants() do apply(animation) end
			table.insert(connections,animate.DescendantAdded:Connect(apply))
			character.Destroying:Once(function() for _,connection in connections do connection:Disconnect() end end)
		end)
	end
	task.spawn(function()
		local animation=Instance.new("Animation");animation.AnimationId=Movement.LocomotionAnimation
		local loaded=false
		local ok=pcall(function()
			ContentProvider:PreloadAsync({animation},function(_,status) loaded=status==Enum.AssetFetchStatus.Success end)
		end)
		animation:Destroy()
		if not ok or not loaded then
			warn("[Movement] Demo1 unavailable; keeping avatar walk/run. Grant the experience animation access, then rejoin.")
			return
		end
		player.CharacterAdded:Connect(locomotion)
		if player.Character then locomotion(player.Character) end
	end)
	local flags=game:GetService("ReplicatedStorage"):WaitForChild("FeatureFlags")
	local want,sent=false,false
	local function blocked()
		if flags:GetAttribute("Sprint")~=true or player:GetAttribute("AdminFly") then return true end
		local photo=player.PlayerGui:FindFirstChild("PhotoHUD")
		return photo~=nil and photo.Enabled
	end
	local button
	local function push()
		local on=want and not blocked()
		if button then UI.SetButtonColor(button,on and UI.Colors.Green or UI.Colors.Blue) end
		if on==sent then return end
		sent=on;Net.Event("SprintIntent"):FireServer("Sprint",on)
	end
	UIS.InputBegan:Connect(function(input,processed)
		if processed or not KEYS[input.KeyCode] then return end
		want=if Sprint.Mode()=="Toggle" then not want else true;push()
	end)
	UIS.InputEnded:Connect(function(input)
		if KEYS[input.KeyCode] and Sprint.Mode()~="Toggle" then want=false;push() end
	end)
	-- Touch: one toggle button just left of Roblox's jump button (small screens: 70px jump at bottom-right corner).
	local gui=UI.New("ScreenGui",{Name="SprintHUD",ResetOnSpawn=false,DisplayOrder=4,Parent=player.PlayerGui})
	button=UI.Button({text="RUN",textSize=20,color=UI.Colors.Blue,size=UDim2.fromOffset(84,60),onClick=function() want=not want;push() end})
	button.Name="SprintButton";button.AnchorPoint=Vector2.new(1,1);button.Parent=gui
	local function place() local v=workspace.CurrentCamera.ViewportSize;button.Position=math.min(v.X,v.Y)<=500 and UDim2.new(1,-105,1,-22) or UDim2.new(1,-170,1,-120) end
	place();workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(place)
	local function showButton() gui.Enabled=UIS.TouchEnabled and flags:GetAttribute("Sprint")==true end
	showButton();flags:GetAttributeChangedSignal("Sprint"):Connect(function() showButton();push() end)
	player:GetAttributeChangedSignal("AdminFly"):Connect(push)
	player.CharacterAdded:Connect(function() want=false;sent=false;push() end) -- new character = not sprinting
	-- Shift-lock defaults to Shift; rebind it so Shift is free for sprint.
	task.spawn(function()
		local pm=player:WaitForChild("PlayerScripts"):WaitForChild("PlayerModule",10)
		local cm=pm and pm:WaitForChild("CameraModule",10)
		local mlc=cm and cm:WaitForChild("MouseLockController",10)
		local keys=mlc and mlc:WaitForChild("BoundKeys",10)
		if keys and keys:IsA("StringValue") then keys.Value=Movement.ShiftLockKeys end
	end)
	-- Cosmetics from the server-set attribute: FOV ramp + retro dust blocks. One Heartbeat connection.
	local fovOffset,dustAt=0,0
	RunService.Heartbeat:Connect(function(dt)
		local cam=workspace.CurrentCamera;local char=player.Character
		local hum=char and char:FindFirstChildOfClass("Humanoid");local root=char and char:FindFirstChild("HumanoidRootPart")
		local moving=hum~=nil and hum.MoveDirection.Magnitude>.1
		local active=char~=nil and char:GetAttribute("Sprinting")==true and moving
		if cam and cam.CameraType==Enum.CameraType.Custom then
			local target=(active and not reducedMotion()) and Movement.SprintFov or 0
			local nextOffset=fovOffset+(target-fovOffset)*math.clamp(dt/Movement.SprintAcceleration,0,1)
			cam.FieldOfView+=nextOffset-fovOffset;fovOffset=nextOffset
		end
		if active and root and hum.FloorMaterial~=Enum.Material.Air and not lowGraphics() and not reducedMotion() and os.clock()>=dustAt then
			dustAt=os.clock()+Movement.DustInterval
			local b=Instance.new("Part");b.Anchored=true;b.CanCollide=false;b.CanQuery=false;b.CanTouch=false;b.CastShadow=false
			b.Material=Enum.Material.Plastic;b.BrickColor=BrickColor.new("Brick yellow");b.Size=Vector3.one*.5
			b.CFrame=root.CFrame*CFrame.new(math.random(-6,6)/10,-2.6,.8);b.Parent=workspace
			Tween:Create(b,TweenInfo.new(.4),{CFrame=b.CFrame+Vector3.new(0,.8,0),Size=Vector3.one*.15,Transparency=1}):Play();Debris:AddItem(b,.45)
		end
	end)
end
return Sprint
