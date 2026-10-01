--!strict
-- HUD มุมซ้ายบน: สกุลเงินที่ตั้ง hud = true (Coins, Wood, Gems) — ตัวเลขนับวิ่ง
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

local HUD = {}

function HUD.Start()
	local gui = UIKit.New("ScreenGui", {
		Name = "HUD",
		ResetOnSpawn = false,
		IgnoreGuiInset = false,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		Parent = Players.LocalPlayer:WaitForChild("PlayerGui"),
	})
	local column = UIKit.New("Frame", {
		Name = "Currencies",
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(16, 12),
		Size = UDim2.fromOffset(240, 160),
		Parent = gui,
	}, { UIKit.List(Enum.FillDirection.Vertical, 8) })

	local rows: { { id: string, label: TextLabel, shown: number } } = {}
	for i, c in Currencies.List do
		if c.hud then
			local pill, label = UIKit.Pill(c.color, "0", { LayoutOrder = i, Parent = column })
			pill.Name = c.id
			table.insert(rows, { id = c.id, label = label, shown = 0 })
		end
	end

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
		local color = msg.kind == "warn" and UIKit.Colors.Red or UIKit.Colors.Accent
		UIKit.Toast(gui, tostring(msg.text), color)
	end)
end

return HUD
