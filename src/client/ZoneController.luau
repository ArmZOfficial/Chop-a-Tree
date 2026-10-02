local Players = game:GetService("Players")
local Tween = game:GetService("TweenService")
local S = game.ReplicatedStorage.Shared
local UI = require(S.UIKit)
local Locale = require(S.Locale)
local Util = require(S.ZoneUtil)
local Controller = {}
local gui, connections, token, lastShown = nil, {}, 0, {}
function Controller.Start()
	local p = Players.LocalPlayer
	gui = UI.New("ScreenGui", { Name = "ZoneHUD", ResetOnSpawn = false, DisplayOrder = 5, Parent = p:WaitForChild("PlayerGui") })
	local banner = UI.Label("", 23, { Name = "ZoneBanner", AnchorPoint = Vector2.new(.5, 0), Position = UDim2.new(.5,0,0,155),
		Size = UDim2.new(.7,0,0,44), BackgroundColor3 = UI.Colors.PanelDark, BackgroundTransparency = .1,
		TextXAlignment = Enum.TextXAlignment.Center, TextWrapped = true, Visible = false, Parent = gui })
	UI.Stroke(3, UI.Colors.Accent).Parent = banner
	local function update()
		local id = p:GetAttribute("Zone"); local def = id and Util.Config(id)
		if not def or os.clock() - (lastShown[id] or -math.huge) < 5 then return end
		lastShown[id] = os.clock(); token += 1; local current = token
		banner.Text = Locale.T(def.name); banner.Visible = true; banner.TextTransparency = 0
		banner.Position = UDim2.new(.5,0,0,135)
		Tween:Create(banner, TweenInfo.new(.2), { Position = UDim2.new(.5,0,0,155) }):Play()
		task.delay(3, function() if token == current and banner.Parent then banner.Visible = false end end)
	end
	table.insert(connections, p:GetAttributeChangedSignal("Zone"):Connect(update))
	table.insert(connections, Locale.Changed:Connect(function() local def = Util.Config(p:GetAttribute("Zone")); if def then banner.Text = Locale.T(def.name) end end))
	update()
end
function Controller.Destroy() token += 1; for _, c in connections do c:Disconnect() end; table.clear(connections); if gui then gui:Destroy(); gui = nil end end
return Controller
