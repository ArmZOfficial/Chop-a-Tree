--!strict
-- HUD: large Coins counter top-centre + Wood/Gems capsules (hud = true) — animated counters
-- + แถบประกาศจาก Server (Notify)

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local UIKit = require(Shared.UIKit)
local NumberFormat = require(Shared.NumberFormat)
local Currencies = require(Shared.Config.Currencies)
local Net = require(Shared.Net)
local ClientData = require(script.Parent.ClientData)
local Locale = require(Shared.Locale)

local HUD = {}

function HUD.Start()
	local gui = UIKit.New("ScreenGui", {
		Name = "HUD",
		ResetOnSpawn = false,
		IgnoreGuiInset = false,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		Parent = Players.LocalPlayer:WaitForChild("PlayerGui"),
	})
	-- Reference HUD: large money counter top-centre, smaller resource capsules below it.
	local column = UIKit.New("Frame", {
		Name = "Currencies",
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 2),
		Size = UDim2.fromOffset(420, 116),
		Parent = gui,
	})
	local scale = UIKit.New("UIScale", { Parent = column })
	local small = UIKit.New("Frame", { Name = "Resources", BackgroundTransparency = 1, Position = UDim2.fromOffset(0, 70), Size = UDim2.new(1, 0, 0, 44), Parent = column }, {
		UIKit.New("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, HorizontalAlignment = Enum.HorizontalAlignment.Center, Padding = UDim.new(0, 10), SortOrder = Enum.SortOrder.LayoutOrder }),
	})
	local function coin(parent, c, size, pos)
		local icon = UIKit.New("Frame", { Name = "Icon", AnchorPoint = Vector2.new(0, 0.5), Position = pos, Size = UDim2.fromOffset(size, size), BackgroundColor3 = c.color, ZIndex = 4, Parent = parent }, { UIKit.Corner(c.id == "Gems" and math.floor(size / 4) or size), UIKit.Stroke(3) })
		UIKit.New("Frame", { BackgroundTransparency = 1, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(0.62, 0.62), ZIndex = 4, Parent = icon }, { UIKit.Corner(c.id == "Gems" and 4 or size), UIKit.Stroke(2, Color3.fromRGB(255, 242, 171)) })
	end

	local rows: { { id: string, label: TextLabel, shown: number } } = {}
	for i, c in Currencies.List do
		if c.hud then
			local pill, label
			if c.id == "Coins" then
				pill = UIKit.New("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 72), Parent = column })
				label = UIKit.Label("0", 64, { AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 26, 0, 0), Size = UDim2.fromOffset(0, 72), AutomaticSize = Enum.AutomaticSize.X, TextWrapped = false, TextColor3 = Color3.fromRGB(96, 236, 62), Parent = pill })
				label:FindFirstChildOfClass("UIStroke").Thickness = 5
				coin(label, c, 50, UDim2.new(0, -60, 0.5, 2))
			else
				pill = UIKit.New("Frame", { BackgroundTransparency = 1, Size = UDim2.fromOffset(150, 44), LayoutOrder = i, Parent = small })
				UIKit.Skin(pill, "chrome", "currencyCapsule")
				coin(pill, c, 28, UDim2.new(0, 10, 0.5, 0))
				label = UIKit.Label("0", 24, { Position = UDim2.fromOffset(46, 0), Size = UDim2.new(1, -56, 1, 0), TextWrapped = false, TextColor3 = c.color:Lerp(Color3.new(1, 1, 1), 0.55), ZIndex = 3, Parent = pill })
				label:FindFirstChildOfClass("UIStroke").Thickness = 2.5
			end
			pill.Name = c.id
			table.insert(rows, { id = c.id, label = label, shown = 0 })
		end
	end
	local function fit()
		local v = workspace.CurrentCamera.ViewportSize
		scale.Scale = (v.X < 700 or v.Y < 500) and 0.62 or 1
	end
	workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(fit)
	fit()

	-- นับวิ่งแบบทวีคูณ (ไล่ตามค่าจริงไวๆ)
	RunService.RenderStepped:Connect(function(dt)
		for _, row in rows do
			local target = ClientData.Get("Currencies." .. row.id) or 0
			if row.shown ~= target then
				local alpha = math.clamp(dt * 10, 0, 1)
				local nextValue = row.shown + (target - row.shown) * alpha
				if math.abs(target - nextValue) <= math.max(1, math.abs(target) * 1e-4) then
					nextValue = target
				end
				row.shown = nextValue
				row.label.Text = NumberFormat.Short(nextValue)
			end
		end
	end)

	Net.Event("Notify").OnClientEvent:Connect(function(msg)
		if type(msg) == "string" then UIKit.Toast(gui, msg, UIKit.Colors.Accent); return end
		local color = msg.kind == "warn" and UIKit.Colors.Red or UIKit.Colors.Accent
		UIKit.Toast(gui, Locale.T(tostring(msg.text), msg.vars), color)
	end)
end

return HUD
