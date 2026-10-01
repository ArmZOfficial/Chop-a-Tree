--!strict
-- สำเนาข้อมูลผู้เล่นฝั่ง Client (อ่านอย่างเดียว) — อัปเดตจาก DataPatch ของ Server

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Net = require(ReplicatedStorage:WaitForChild("Shared").Net)

local ClientData = {}

local data: any = nil
local changed = Instance.new("BindableEvent")
ClientData.Changed = changed.Event -- (path) ; path = "" แปลว่าเปลี่ยนทั้งก้อน

local function setPath(path: string, value: any)
	local parts = string.split(path, ".")
	local node = data
	for i = 1, #parts - 1 do
		node = node[parts[i]]
		if type(node) ~= "table" then
			return
		end
	end
	node[parts[#parts]] = value
end

function ClientData.Get(path: string?): any
	if not path or path == "" then
		return data
	end
	local node = data
	for _, part in string.split(path, ".") do
		if type(node) ~= "table" then
			return nil
		end
		node = node[part]
	end
	return node
end

function ClientData.IsReady(): boolean
	return data ~= nil
end

function ClientData.Start()
	Net.Event("DataPatch").OnClientEvent:Connect(function(patch)
		if patch.snapshot ~= nil then
			data = patch.snapshot
			changed:Fire("")
		elseif data and patch.path then
			setPath(patch.path, patch.value)
			changed:Fire(patch.path)
		end
	end)
	task.spawn(function()
		local result = Net.Function("DataRequest"):InvokeServer()
		if result and data == nil then
			data = result
			changed:Fire("")
		end
	end)
end

return ClientData
