--!strict
-- จุดเริ่มฝั่ง Server: โหลด Service ทั้งหมด → Init ทุกตัว → ลงทะเบียนคำสั่งแอดมิน → Start ทุกตัว
-- เพิ่มระบบใหม่ = เพิ่มชื่อใน SERVICES (ลำดับสำคัญ: ตัวที่ถูกใช้ต้องมาก่อน)

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
require(Shared.Net) -- สร้าง Remotes ก่อนทุกอย่าง

local SERVICES = { "FeatureService", "DataService", "AdminService", "WeatherService", "GardenService", "WeaponService", "RunService", "TreeService" }

local loaded: { [string]: any } = {}
for _, name in SERVICES do
	loaded[name] = require(script.Parent.Services[name])
end

for _, name in SERVICES do
	local ok, err = pcall(loaded[name].Init)
	if not ok then
		warn("[Main] Init " .. name .. " failed: " .. tostring(err))
	end
end

-- คำสั่งแอดมินของแต่ละระบบ
local Admin = loaded.AdminService
local commandSets = {
	{ "PlayerCommands" },
	{ "MoneyCommands", loaded.DataService },
	{ "DataCommands", loaded.DataService },
	{ "DebugCommands", loaded.DataService, loaded.FeatureService },
	{ "ForestCommands", loaded.RunService, loaded.TreeService },
	{ "WeaponCommands", loaded.WeaponService },
	{ "GardenCommands", loaded.GardenService, loaded.WeatherService },
}
for _, set in commandSets do
	local ok, err = pcall(function()
		require(script.Parent.AdminCommands[set[1]])(Admin, set[2], set[3])
	end)
	if not ok then
		warn("[Main] AdminCommands " .. set[1] .. " failed: " .. tostring(err))
	end
end

for _, name in SERVICES do
	task.spawn(function()
		local ok, err = pcall(loaded[name].Start)
		if not ok then
			warn("[Main] Start " .. name .. " failed: " .. tostring(err))
		end
	end)
end

local balanceOk, balanceMsg = require(Shared.Balance).SelfTest()
print("[Main] Chop a Tree server ready — " .. balanceMsg)
if not balanceOk then
	warn("[Main] Balance self-test FAILED")
end
