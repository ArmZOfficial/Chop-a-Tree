--!strict
-- จัดการ RemoteEvent / RemoteFunction ที่เดียว
-- Server สร้าง, Client รอ — ชื่อทั้งหมดต้องอยู่ในลิสต์นี้

local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local EVENTS = {
	"DataPatch", -- server → client: { path, value } หรือ snapshot ทั้งก้อน
	"Notify", -- server → client: ข้อความแจ้งเตือน/ประกาศ
	"AdminEvent", -- server → admin client: ผลคำสั่ง, ข้อความยาว (export), log
}
local FUNCTIONS = {
	"DataRequest", -- client → server: ขอข้อมูลตัวเองทั้งก้อน
	"AdminRun", -- admin client → server: ขอรันคำสั่ง
}

local Net = {}

local folder: Folder
if RunService:IsServer() then
	local existing = ReplicatedStorage:FindFirstChild("Remotes")
	if existing then
		existing:Destroy()
	end
	folder = Instance.new("Folder")
	folder.Name = "Remotes"
	for _, name in EVENTS do
		local r = Instance.new("RemoteEvent")
		r.Name = name
		r.Parent = folder
	end
	for _, name in FUNCTIONS do
		local r = Instance.new("RemoteFunction")
		r.Name = name
		r.Parent = folder
	end
	folder.Parent = ReplicatedStorage
else
	folder = ReplicatedStorage:WaitForChild("Remotes") :: Folder
end

function Net.Event(name: string): RemoteEvent
	assert(table.find(EVENTS, name), "unknown RemoteEvent " .. name)
	return folder:WaitForChild(name) :: RemoteEvent
end

function Net.Function(name: string): RemoteFunction
	assert(table.find(FUNCTIONS, name), "unknown RemoteFunction " .. name)
	return folder:WaitForChild(name) :: RemoteFunction
end

return Net
