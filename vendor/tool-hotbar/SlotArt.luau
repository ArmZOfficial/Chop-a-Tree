-- Reference-style item cards. Keep Tool inputs/equip behavior in the vendor handler.
local Art = {}
local TweenService = game:GetService("TweenService")
local INK = Color3.fromRGB(13, 25, 35)
local WATER = "rbxassetid://114410369919234"
local GuiService = game:GetService("GuiService")
local states = setmetatable({}, {__mode = "k"})

local function motion(frame)
	if not states[frame] then states[frame] = {equipped = false, enabled = true, hover = false, pressed = false, tweens = {}} end
	return states[frame]
end

local function tween(frame, target, key, duration, goals, easing)
	local state = motion(frame)
	if state.tweens[key] then state.tweens[key]:Cancel() end
	local t = TweenService:Create(target, TweenInfo.new(GuiService.ReducedMotionEnabled and 0 or duration, easing or Enum.EasingStyle.Quad, Enum.EasingDirection.Out), goals)
	state.tweens[key] = t
	t:Play()
end

local function settle(frame)
	local state = motion(frame)
	local active = state.enabled
	local scale = active and state.pressed and 0.94 or (state.equipped and 1.08 or 1) + (active and state.hover and 0.025 or 0)
	tween(frame, frame.SelectionScale, "scale", 0.2, {Scale = scale}, Enum.EasingStyle.Back)
	tween(frame, frame, "tilt", 0.18, {Rotation = state.equipped and -4 or (active and state.hover and 2 or 0)})
	tween(frame, frame.UIStroke, "border", 0.14, {Color = state.equipped and Color3.new(1, 1, 1) or (active and state.hover and Color3.fromRGB(134, 223, 255) or INK), Thickness = state.equipped and 4 or 3})
end

local function pulse(frame)
	local ring = frame:FindFirstChild("EquipPulse")
	if not ring or GuiService.ReducedMotionEnabled then return end
	local state = motion(frame)
	for _,key in {"ringSize", "ringFade"} do if state.tweens[key] then state.tweens[key]:Cancel() end end
	ring.Size = UDim2.fromScale(0.82, 0.82)
	ring.UIStroke.Transparency = 0.15
	tween(frame, ring, "ringSize", 0.32, {Size = UDim2.fromScale(1.06, 1.06)})
	tween(frame, ring.UIStroke, "ringFade", 0.32, {Transparency = 1})
end

function Art.Intro(frame, index)
	local state = motion(frame)
	state.hover, state.pressed = false, false
	state.intro = (state.intro or 0) + 1
	local token = state.intro
	if GuiService.ReducedMotionEnabled then settle(frame); return end
	if state.tweens.scale then state.tweens.scale:Cancel() end
	frame.SelectionScale.Scale = 0.78
	task.delay(math.min((index or 1) - 1, 4) * 0.045, function()
		if frame.Parent and state.intro == token then settle(frame) end
	end)
end

function Art.Cleanup(frame)
	local state = states[frame]
	if not state then return end
	state.intro = (state.intro or 0) + 1
	for _,t in state.tweens do t:Cancel() end
	states[frame] = nil
end

function Art.Bind(frame)
	local state = motion(frame)
	local ring = Instance.new("Frame")
	ring.Name = "EquipPulse"
	ring.BackgroundTransparency = 1
	ring.AnchorPoint = Vector2.new(0.5, 0.5)
	ring.Position = UDim2.fromScale(0.5, 0.5)
	ring.Size = UDim2.fromScale(1, 1)
	ring.ZIndex = 2
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 12)
	corner.Parent = ring
	local border = Instance.new("UIStroke")
	border.Color = Color3.fromRGB(157, 234, 255)
	border.Thickness = 2
	border.Transparency = 1
	border.Parent = ring
	ring.Parent = frame
	local connections = {}
	connections.MotionEnter = frame.MouseEnter:Connect(function() state.hover = true; settle(frame) end)
	connections.MotionLeave = frame.MouseLeave:Connect(function() state.hover = false; state.pressed = false; settle(frame) end)
	connections.MotionDown = frame.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then state.pressed = true; settle(frame) end
	end)
	connections.MotionUp = frame.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then state.pressed = false; settle(frame) end
	end)
	connections.MotionDestroy = frame.Destroying:Connect(function()
		Art.Cleanup(frame)
	end)
	Art.Intro(frame, tonumber(frame.Name))
	return connections
end

function Art.Style(frame)
	frame.BackgroundColor3 = Color3.fromRGB(43, 76, 96)
	frame.BackgroundTransparency = 0.12
	frame.AutoButtonColor = false
	frame.ClipsDescendants = false
	frame.UIStroke.Color = INK
	frame.UIStroke.Thickness = 3
	frame.UICorner.CornerRadius = UDim.new(0, 12)
	local scale = Instance.new("UIScale")
	scale.Name = "SelectionScale"
	scale.Parent = frame
	local name = frame.toolName
	name.AnchorPoint = Vector2.new(0.5, 1)
	name.Position = UDim2.new(0.5, 0, 1, -4)
	name.Size = UDim2.new(1, -8, 0.31, 0)
	name.Font = Enum.Font.GothamBold
	name.TextColor3 = Color3.new(1, 1, 1)
	name.TextScaled = true
	name.TextWrapped = true
	name.ZIndex = 4
	name.UIStroke.Color = INK
	name.UIStroke.Thickness = 1.5
	local limit = Instance.new("UITextSizeConstraint")
	limit.MinTextSize = 9
	limit.MaxTextSize = 16
	limit.Parent = name
	local number = frame.toolNumber
	number.Position = UDim2.fromOffset(6, 3)
	number.Size = UDim2.fromScale(0.22, 0.22)
	number.Font = Enum.Font.GothamBold
	number.TextColor3 = Color3.fromRGB(212, 231, 242)
	number.ZIndex = 5
	number:SetAttribute("NoTranslate", true)
	local icon = frame.toolIcon
	icon.AnchorPoint = Vector2.new(0.5, 0)
	icon.Position = UDim2.fromScale(0.5, 0.06)
	icon.Size = UDim2.fromScale(0.86, 0.55)
	icon.ScaleType = Enum.ScaleType.Fit
	icon.ZIndex = 3
end

function Art.State(frame, equipped, enabled)
	local state = motion(frame)
	local newlyEquipped = equipped and not state.equipped
	local changed = state.equipped ~= equipped or state.enabled ~= enabled
	state.equipped, state.enabled = equipped, enabled
	if changed then settle(frame) end
	if newlyEquipped and enabled then pulse(frame) end
	local preview = frame:FindFirstChild("ItemPreview")
	if preview then preview.ImageTransparency = enabled and 0 or 0.5 end
end

function Art.Icon(frame, tool)
	local old = frame:FindFirstChild("ItemPreview")
	if old then old:Destroy() end
	local icon = frame.toolIcon
	frame.toolName.Visible = true
	icon.Image = tool.TextureId
	if tool:GetAttribute("GardenWater") or tool.Name == "WateringCan" then icon.Image = WATER end
	icon.Visible = icon.Image ~= ""
	if icon.Visible then return end
	-- Render only inert geometry from the actual tool; no scripts, joints or effects.
	local model = Instance.new("Model")
	local handle = tool:FindFirstChild("Handle")
	local origin = handle and handle:IsA("BasePart") and handle.CFrame or CFrame.new()
	for _, part in tool:GetDescendants() do
		if part:IsA("BasePart") and part.Transparency < 1 and part.Archivable then
			local copy = part:Clone()
			for _, child in copy:GetDescendants() do
				if not (child:IsA("DataModelMesh") or child:IsA("Decal") or child:IsA("Texture") or child:IsA("SurfaceAppearance")) then child:Destroy() end
			end
			copy.CFrame = CFrame.Angles(0, 0, math.rad(-28)) * origin:ToObjectSpace(part.CFrame)
			copy.Anchored = true
			copy.CanCollide = false
			copy.Parent = model
		end
	end
	if #model:GetChildren() == 0 then model:Destroy(); return end
	local viewport = Instance.new("ViewportFrame")
	viewport.Name = "ItemPreview"
	viewport.BackgroundTransparency = 1
	viewport.AnchorPoint = icon.AnchorPoint
	viewport.Position = icon.Position
	viewport.Size = icon.Size
	viewport.ZIndex = icon.ZIndex
	viewport.Ambient = Color3.fromRGB(200, 200, 200)
	viewport.LightColor = Color3.new(1, 1, 1)
	viewport.LightDirection = Vector3.new(-1, -1, -2)
	model.Parent = viewport
	local cf, size = model:GetBoundingBox()
	local camera = Instance.new("Camera")
	camera.FieldOfView = 35
	local distance = math.max(size.Y, size.X / 1.35) / (2 * math.tan(math.rad(17.5))) + size.Z / 2
	camera.CFrame = CFrame.lookAt(cf.Position + Vector3.new(0, 0, distance * 1.12), cf.Position)
	camera.Parent = viewport
	viewport.CurrentCamera = camera
	viewport.Parent = frame
end

return Art
