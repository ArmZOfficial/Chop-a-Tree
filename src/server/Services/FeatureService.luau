--!strict
-- Feature Flags สด (plan.md หัวข้อ 15.5) — ค่าเริ่มจาก Config.Features
-- เก็บเป็น Attribute บน ReplicatedStorage.FeatureFlags → Client อ่านได้ทันที

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Features = require(ReplicatedStorage:WaitForChild("Shared").Config.Features)

local FeatureService = {}

local folder: Folder

function FeatureService.IsEnabled(name: string): boolean
	return folder:GetAttribute(name) == true
end

function FeatureService.Set(name: string, enabled: boolean)
	assert((Features :: any)[name] ~= nil, "unknown feature " .. name)
	folder:SetAttribute(name, enabled)
end

function FeatureService.All(): { { name: string, enabled: boolean, default: boolean } }
	local out = {}
	for name, default in Features :: any do
		table.insert(out, { name = name, enabled = FeatureService.IsEnabled(name), default = default })
	end
	table.sort(out, function(a, b)
		return a.name < b.name
	end)
	return out
end

function FeatureService.Init()
	local existing = ReplicatedStorage:FindFirstChild("FeatureFlags")
	if existing then
		existing:Destroy()
	end
	folder = Instance.new("Folder")
	folder.Name = "FeatureFlags"
	for name, enabled in Features :: any do
		folder:SetAttribute(name, enabled)
	end
	folder.Parent = ReplicatedStorage
end

function FeatureService.Start() end

return FeatureService
