--!strict
-- เซฟผู้เล่น (plan.md หัวข้อ 15.3) — ProfileStore + Session Lock กันของซ้ำ
-- เซฟเฉพาะ id/จำนวน/ค่าที่คำนวณไม่ได้, มี DataVersion + Migration, เติมฟิลด์ใหม่ให้คนเก่าเอง (Reconcile)

local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Net = require(Shared.Net)
local Currencies = require(Shared.Config.Currencies)
local ProfileStore = require(script.Parent.Parent.Packages.ProfileStore)

local DataService = {}

DataService.STORE_NAME = "PlayerData_v1"
DataService.DATA_VERSION = 1

local function currencyTemplate()
	local t = {}
	for _, c in Currencies.List do
		t[c.id] = 0
	end
	return t
end

-- โครงข้อมูลเวอร์ชัน 1 — เพิ่มฟิลด์ได้เรื่อยๆ (Reconcile เติมให้คนเก่าเอง)
-- เปลี่ยนความหมาย/ย้ายฟิลด์ → เพิ่ม DATA_VERSION + เขียน Migration ข้างล่าง
DataService.Template = {
	DataVersion = DataService.DATA_VERSION,
	Currencies = currencyTemplate(),
	Stats = { TreesCut = 0, PlaySeconds = 0, HighestHit = 0 },
	Progress = { Zone = 1, UnlockedZones = { 1 }, Rebirth = 0, StoryChapter = 1 },
	Inventory = { Weapons = {}, Equipped = "", Chests = {}, Seeds = {}, Fruits = {} },
	Garden = { slots = 6, plots = {}, starterGiven = false, shopEpoch = 0, bought = {} },
	Run = { Active = false, Level = 1, Exp = 0, Zone = 1, Wood = 0, Coins = 0, Trees = 0, Chests = {}, Seeds = {}, StartedAt = 0 },
	Settings = { AutoAttack = false, AutoCut = false },
	Meta = { AdminTouched = false, FirstJoin = 0, LastJoin = 0, Joins = 0 },
}

-- MIGRATIONS[n] แปลงข้อมูลจากเวอร์ชัน n−1 → n
-- เวอร์ชัน 0 = เซฟเก่าก่อนมีระบบ (ใช้ทดสอบจากแท็บ Data)
DataService.MIGRATIONS = {
	[1] = function(data)
		-- v0 เก็บเงินไว้ที่ root เช่น data.Coins → ย้ายเข้า Currencies
		data.Currencies = data.Currencies or {}
		for _, c in Currencies.List do
			if type(data[c.id]) == "number" then
				data.Currencies[c.id] = data[c.id]
				data[c.id] = nil
			end
		end
		return data
	end,
}

local store = ProfileStore.New(DataService.STORE_NAME, DataService.Template)
local profiles: { [Player]: any } = {}
local loadedEvent = Instance.new("BindableEvent")
DataService.PlayerLoaded = loadedEvent.Event -- (player)
local changedEvent = Instance.new("BindableEvent")
DataService.Changed = changedEvent.Event -- (player, path, value)

local backupStore: DataStore? = nil
pcall(function()
	backupStore = DataStoreService:GetDataStore("PlayerBackups_v1")
end)
local memoryBackups: { [number]: string } = {} -- ใช้ตอนไม่มีสิทธิ์ DataStore (เช่นใน Studio ที่ยังไม่เปิด API)

local function deepCopy<T>(t: T): T
	if type(t) ~= "table" then
		return t
	end
	local out = {}
	for k, v in t :: any do
		out[k] = deepCopy(v)
	end
	return out :: any
end

local function reconcile(target: any, template: any)
	for k, v in template do
		if type(k) == "string" then
			if target[k] == nil then
				target[k] = deepCopy(v)
			elseif type(target[k]) == "table" and type(v) == "table" then
				reconcile(target[k], v)
			end
		end
	end
end

-- รัน Migration ทีละขั้นจนถึงเวอร์ชันล่าสุด
function DataService.Migrate(data: any): (any, { string })
	local log = {}
	local version = tonumber(data.DataVersion) or 0
	while version < DataService.DATA_VERSION do
		local step = DataService.MIGRATIONS[version + 1]
		assert(step, "missing migration to v" .. (version + 1))
		data = step(data)
		version += 1
		data.DataVersion = version
		table.insert(log, "v" .. (version - 1) .. " → v" .. version)
	end
	reconcile(data, DataService.Template)
	return data, log
end

local function splitPath(path: string): { string }
	local parts = {}
	for part in string.gmatch(path, "[^%.]+") do
		table.insert(parts, part)
	end
	return parts
end

local function replicate(player: Player, path: string?, value: any)
	if path then
		Net.Event("DataPatch"):FireClient(player, { path = path, value = value })
	else
		Net.Event("DataPatch"):FireClient(player, { snapshot = profiles[player] and profiles[player].Data })
	end
end

function DataService.IsLoaded(player: Player): boolean
	return profiles[player] ~= nil
end

function DataService.GetData(player: Player): any?
	local p = profiles[player]
	return p and p.Data
end

function DataService.WaitForData(player: Player, timeout: number?): any?
	local start = os.clock()
	while not profiles[player] and player.Parent and os.clock() - start < (timeout or 30) do
		task.wait(0.1)
	end
	return DataService.GetData(player)
end

function DataService.Get(player: Player, path: string): any
	local node = DataService.GetData(player)
	for _, part in splitPath(path) do
		if type(node) ~= "table" then
			return nil
		end
		node = node[part]
	end
	return node
end

function DataService.Set(player: Player, path: string, value: any)
	local data = DataService.GetData(player)
	assert(data, "data not loaded for " .. player.Name)
	local parts = splitPath(path)
	local node = data
	for i = 1, #parts - 1 do
		node = node[parts[i]]
		assert(type(node) == "table", "bad path " .. path)
	end
	node[parts[#parts]] = value
	replicate(player, path, value)
	changedEvent:Fire(player, path, value)
end

function DataService.Increment(player: Player, path: string, delta: number): number
	local current = DataService.Get(player, path)
	assert(type(current) == "number", "not a number at " .. path)
	local nextValue = math.clamp(current + delta, 0, 1e300)
	DataService.Set(player, path, nextValue)
	return nextValue
end

-- สกุลเงิน
function DataService.GetCurrency(player: Player, id: string): number
	return DataService.Get(player, "Currencies." .. id) or 0
end

function DataService.AddCurrency(player: Player, id: string, amount: number): number
	assert(Currencies.ById[id], "unknown currency " .. id)
	return DataService.Increment(player, "Currencies." .. id, amount)
end

function DataService.SetCurrency(player: Player, id: string, amount: number)
	assert(Currencies.ById[id], "unknown currency " .. id)
	DataService.Set(player, "Currencies." .. id, math.clamp(amount, 0, 1e300))
end

-- แทนข้อมูลทั้งก้อน (ใช้กับ คืนเซฟ / Import) — ผ่าน Migration + Reconcile เสมอ
function DataService.ReplaceData(player: Player, newData: any): { string }
	local profile = profiles[player]
	assert(profile, "data not loaded")
	local migrated, log = DataService.Migrate(deepCopy(newData))
	for k in profile.Data do
		profile.Data[k] = nil
	end
	for k, v in migrated do
		profile.Data[k] = v
	end
	replicate(player)
	changedEvent:Fire(player, "", nil)
	return log
end

function DataService.ResetData(player: Player)
	DataService.ReplaceData(player, deepCopy(DataService.Template))
end

function DataService.SaveNow(player: Player): boolean
	local profile = profiles[player]
	if not profile then
		return false
	end
	profile:Save()
	return true
end

function DataService.ExportJSON(player: Player): string
	return HttpService:JSONEncode(DataService.GetData(player))
end

function DataService.ImportJSON(player: Player, json: string): (boolean, string)
	local ok, decoded = pcall(HttpService.JSONDecode, HttpService, json)
	if not ok or type(decoded) ~= "table" then
		return false, "JSON ไม่ถูกต้อง"
	end
	local log = DataService.ReplaceData(player, decoded)
	return true, #log > 0 and ("แปลงเวอร์ชัน " .. table.concat(log, ", ")) or "นำเข้าแล้ว"
end

function DataService.Backup(player: Player): (boolean, string)
	local json = DataService.ExportJSON(player)
	local stamp = os.date("!%Y-%m-%d %H:%M UTC")
	local payload = HttpService:JSONEncode({ at = stamp, data = json })
	local ok = false
	if backupStore then
		ok = pcall(function()
			(backupStore :: DataStore):SetAsync("u_" .. player.UserId, payload)
		end)
	end
	memoryBackups[player.UserId] = payload
	return true, "สำรองแล้ว " .. stamp .. (ok and "" or " (เก็บในเซิร์ฟนี้ชั่วคราว — DataStore ใช้ไม่ได้)")
end

function DataService.Restore(player: Player): (boolean, string)
	local payload: string? = nil
	if backupStore then
		pcall(function()
			payload = (backupStore :: DataStore):GetAsync("u_" .. player.UserId)
		end)
	end
	payload = payload or memoryBackups[player.UserId]
	if not payload then
		return false, "ยังไม่มีเซฟสำรอง"
	end
	local decoded = HttpService:JSONDecode(payload :: string)
	local ok, msg = DataService.ImportJSON(player, decoded.data)
	return ok, ok and ("คืนเซฟจาก " .. decoded.at) or msg
end

function DataService.DataStoreState(): string
	return ProfileStore.DataStoreState
end

local function onPlayerAdded(player: Player)
	local profile = store:StartSessionAsync("Player_" .. player.UserId, {
		Cancel = function()
			return player.Parent ~= Players
		end,
	})
	if profile == nil then
		player:Kick("โหลดเซฟไม่สำเร็จ กรุณาเข้าเกมใหม่อีกครั้ง")
		return
	end
	profile:AddUserId(player.UserId)
	local migrated, log = DataService.Migrate(profile.Data)
	if #log > 0 then
		for k, v in migrated do
			profile.Data[k] = v
		end
		print(string.format("[DataService] %s migrated %s", player.Name, table.concat(log, ", ")))
	end
	profile:Reconcile()
	profile.OnSessionEnd:Connect(function()
		profiles[player] = nil
		player:Kick("เซฟถูกเปิดจากที่อื่น กรุณาเข้าเกมใหม่")
	end)
	if player.Parent ~= Players then
		profile:EndSession()
		return
	end
	local meta = profile.Data.Meta
	if meta.FirstJoin == 0 then
		meta.FirstJoin = os.time()
	end
	meta.LastJoin = os.time()
	meta.Joins += 1
	profiles[player] = profile
	replicate(player)
	loadedEvent:Fire(player)
end

function DataService.Init()
	Net.Function("DataRequest").OnServerInvoke = function(player)
		local data = DataService.WaitForData(player, 15)
		return data
	end
	ProfileStore.OnError:Connect(function(message, storeName, key)
		warn(string.format("[DataService] %s %s: %s", storeName, key, message))
	end)
end

function DataService.Start()
	for _, player in Players:GetPlayers() do
		task.spawn(onPlayerAdded, player)
	end
	Players.PlayerAdded:Connect(onPlayerAdded)
	Players.PlayerRemoving:Connect(function(player)
		local profile = profiles[player]
		if profile then
			profile:EndSession()
			profiles[player] = nil
		end
	end)
	-- นับเวลาเล่น
	task.spawn(function()
		while true do
			task.wait(60)
			for player, profile in profiles do
				if player.Parent then
					profile.Data.Stats.PlaySeconds += 60
				end
			end
		end
	end)
end

return DataService
