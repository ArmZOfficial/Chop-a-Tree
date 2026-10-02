-- Chest icons for 2D UI: a ViewportFrame showing the ChestBuilder model at a 3/4 front view.
-- Replaces the two-sprite chest art so every rarity gets its own chest (Inventory cards/detail).
local ChestBuilder = require(script.Parent.ChestBuilder)

local ChestIconRenderer = {}
local templates = {}

-- props are applied to the ViewportFrame (Position/Size/Parent…); Parent is set last.
function ChestIconRenderer.New(rarity: string, props: { [string]: any }?): ViewportFrame
	local view = Instance.new("ViewportFrame")
	view.Name = "ChestIcon"
	view.BackgroundTransparency = 1
	view.ZIndex = 3
	view.Ambient = Color3.fromRGB(200, 200, 200)
	view.LightColor = Color3.new(1, 1, 1)
	view.LightDirection = Vector3.new(-1, -1, -0.6)
	local level = ChestBuilder.LevelOf(rarity)
	templates[level] = templates[level] or ChestBuilder.Build(level)
	local model = templates[level]:Clone()
	model.Parent = view
	local cf, size = model:GetBoundingBox()
	local camera = Instance.new("Camera")
	camera.FieldOfView = 30
	camera.CFrame = CFrame.lookAt(cf.Position + Vector3.new(-0.55, 0.5, -1).Unit * size.Magnitude * 1.9, cf.Position)
	camera.Parent = view
	view.CurrentCamera = camera
	local parent
	for k, v in props or {} do
		if k == "Parent" then parent = v else (view :: any)[k] = v end
	end
	view.Parent = parent
	return view
end

return ChestIconRenderer
