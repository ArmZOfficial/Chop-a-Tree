--!strict
-- Admin Panel ฝั่ง Server (plan.md หัวข้อ 18)
-- - ตรวจยศทุกครั้งที่ Server (Client แค่ "ขอ" รันคำสั่ง)
-- - ระบบอื่นลงทะเบียนคำสั่งของตัวเองผ่าน AdminService.Register → ปุ่มขึ้นใน UI เอง
-- - ส่ง UI ให้เฉพาะคนที่มียศ (คนทั่วไปไม่ได้โหลดโค้ด UI แอดมินเลย)
-- - Log ทุกคำสั่ง, จำกัดความถี่, คำสั่งอันตรายต้องยืนยัน

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DataStoreService = game:GetService("DataStoreService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Net = require(Shared.Net)
local AdminsConfig = require(Shared.Config.Admins)

local AdminService = {}

local LEVELS = AdminsConfig.Levels
AdminService.Levels = LEVELS

export type Targets = { Player }
export type Context = {
	admin: Player,
	level: number,
	targets: Targets,
	args: { [string]: any },
}
export type Command = {
	id: string,
	tab: string,
	label: string,
	sub: string?,
	color: string?, -- ชื่อสีใน UIKit.Colors
	order: number?,
	minLevel: string?, -- "Tester" | "Moderator" | "Admin" | "Owner" (ค่าเริ่ม Admin)
	usesTarget: boolean?, -- true = ทำกับเป้าหมายที่เลือก (ตัวเอง/ผู้เล่น/ทุกคน)
	singleTarget: boolean?, -- ต้องเลือกผู้เล่น 1 คน
	confirm: number?, -- 1 = ยืนยัน 1 ชั้น, 2 = ยืนยัน 2 ชั้น
	hidden: boolean?, -- ไม่โชว์เป็นปุ่ม (เรียกจาก UI พิเศษ/ช่องพิมพ์)
	marksTarget: boolean?, -- true = ผู้เล่นที่โดนคำสั่งนี้ถูกตัดออกจาก Leaderboard
	run: (ctx: Context) -> (boolean, string?, any?),
}

local commands: { [string]: Command } = {}
local levelCache: { [Player]: number } = {}
local recentCalls: { [Player]: { number } } = {}
local logBuffer: { string } = {}
local logStore: DataStore? = nil
pcall(function()
	logStore = DataStoreService:GetDataStore("AdminLog_v1")
end)

local DataService -- ใส่ตอน Init (กัน require วน)

function AdminService.Register(cmd: Command)
	assert(commands[cmd.id] == nil, "duplicate admin command " .. cmd.id)
	commands[cmd.id] = cmd
end

local function levelName(n: number): string
	for name, v in LEVELS do
		if v == n then
			return name
		end
	end
	return "Player"
end

local function computeLevel(player: Player): number
	local best = LEVELS.Player
	if AdminsConfig.StudioIsOwner and RunService:IsStudio() then
		return LEVELS.Owner
	end
	if game.CreatorType == Enum.CreatorType.User and player.UserId == game.CreatorId and game.CreatorId ~= 0 then
		return LEVELS.Owner
	end
	local listed = (AdminsConfig.Users :: any)[player.UserId]
	if listed and LEVELS[listed] then
		best = math.max(best, LEVELS[listed])
	end
	local groupId = AdminsConfig.GroupId
	if groupId == 0 and game.CreatorType == Enum.CreatorType.Group then
		groupId = game.CreatorId
	end
	if groupId ~= 0 then
		local ok, rank = pcall(player.GetRankInGroup, player, groupId)
		if ok and type(rank) == "number" then
			for name, minRank in AdminsConfig.GroupRanks do
				if rank >= minRank then
					best = math.max(best, LEVELS[name])
				end
			end
		end
	end
	return best
end

function AdminService.GetLevel(player: Player): number
	local cached = levelCache[player]
	if cached == nil then
		cached = computeLevel(player)
		levelCache[player] = cached
	end
	return cached
end

function AdminService.IsAdmin(player: Player): boolean
	return AdminService.GetLevel(player) >= LEVELS.Tester
end

local function rateLimited(player: Player): boolean
	local now = os.clock()
	local calls = recentCalls[player] or {}
	local fresh = {}
	for _, t in calls do
		if now - t < 1 then
			table.insert(fresh, t)
		end
	end
	if #fresh >= AdminsConfig.RateLimitPerSecond then
		recentCalls[player] = fresh
		return true
	end
	table.insert(fresh, now)
	recentCalls[player] = fresh
	return false
end

function AdminService.Log(admin: Player, cmdId: string, targets: Targets, detail: string)
	local names = {}
	for _, t in targets do
		table.insert(names, t.Name)
	end
	local line = string.format(
		"%s [%s] %s → %s %s",
		os.date("!%Y-%m-%d %H:%M:%S"),
		admin.Name,
		cmdId,
		#names > 0 and table.concat(names, ",") or "-",
		detail
	)
	print("[Admin] " .. line)
	table.insert(logBuffer, line)
	if #logBuffer > 200 then
		table.remove(logBuffer, 1)
	end
	if logStore and not RunService:IsStudio() then
		local key = "log_" .. os.date("!%Y%m%d")
		task.spawn(pcall, function()
			(logStore :: DataStore):UpdateAsync(key, function(old)
				old = old or {}
				table.insert(old, line)
				while #old > 2000 do
					table.remove(old, 1)
				end
				return old
			end)
		end)
	end
end

function AdminService.RecentLog(): { string }
	return table.clone(logBuffer)
end

-- แปลงเป้าหมายจาก Client เป็นรายชื่อผู้เล่น
local function resolveTargets(admin: Player, spec: any): Targets
	if type(spec) ~= "table" or spec.mode == "me" or spec.mode == nil then
		return { admin }
	end
	if spec.mode == "all" then
		return Players:GetPlayers()
	end
	if spec.mode == "player" and type(spec.userId) == "number" then
		local p = Players:GetPlayerByUserId(spec.userId)
		return p and { p } or {}
	end
	return { admin }
end

-- ข้อมูลที่ส่งให้ UI (ไม่มีโค้ด run)
local function describeCommands(level: number)
	local out = {}
	for id, cmd in commands do
		local need = LEVELS[cmd.minLevel or "Admin"]
		if level >= need then
			table.insert(out, {
				id = id,
				tab = cmd.tab,
				label = cmd.label,
				sub = cmd.sub,
				color = cmd.color,
				order = cmd.order or 0,
				usesTarget = cmd.usesTarget == true,
				singleTarget = cmd.singleTarget == true,
				confirm = cmd.confirm or 0,
				hidden = cmd.hidden == true,
			})
		end
	end
	table.sort(out, function(a, b)
		if a.order == b.order then
			return a.id < b.id
		end
		return a.order < b.order
	end)
	return out
end

local function handleRun(admin: Player, request: any): any
	local level = AdminService.GetLevel(admin)
	if level < LEVELS.Tester then
		return { ok = false, msg = "ไม่มีสิทธิ์" }
	end
	if type(request) ~= "table" or type(request.id) ~= "string" then
		return { ok = false, msg = "คำขอไม่ถูกต้อง" }
	end
	if request.id == "__init" then
		local players = {}
		for _, p in Players:GetPlayers() do
			table.insert(players, { userId = p.UserId, name = p.Name, display = p.DisplayName })
		end
		return {
			ok = true,
			level = level,
			levelName = levelName(level),
			commands = describeCommands(level),
			players = players,
		}
	end
	if rateLimited(admin) then
		return { ok = false, msg = "กดเร็วเกินไป รอสักครู่" }
	end
	local cmd = commands[request.id]
	if not cmd then
		return { ok = false, msg = "ไม่รู้จักคำสั่ง " .. tostring(request.id) }
	end
	if level < LEVELS[cmd.minLevel or "Admin"] then
		return { ok = false, msg = "ยศไม่พอ (ต้องเป็น " .. (cmd.minLevel or "Admin") .. ")" }
	end
	local confirmNeeded = cmd.confirm or 0
	if confirmNeeded > 0 and request.confirmed ~= confirmNeeded then
		return { ok = false, msg = "ต้องกดยืนยัน " .. confirmNeeded .. " ชั้น" }
	end
	local args = type(request.args) == "table" and request.args or {}
	local targets = cmd.usesTarget and resolveTargets(admin, request.target) or { admin }
	if cmd.usesTarget and #targets == 0 then
		return { ok = false, msg = "ไม่พบผู้เล่นเป้าหมาย" }
	end
	if cmd.singleTarget and #targets ~= 1 then
		return { ok = false, msg = "ต้องเลือกผู้เล่น 1 คน" }
	end
	-- Tester ใช้ได้เฉพาะใน Studio / เซิร์ฟส่วนตัว
	if level == LEVELS.Tester and not RunService:IsStudio() and game.PrivateServerId == "" then
		return { ok = false, msg = "Tester ใช้ได้เฉพาะเซิร์ฟทดสอบ" }
	end
	local ok, success, msg, payload = pcall(cmd.run, {
		admin = admin,
		level = level,
		targets = targets,
		args = args,
	})
	if not ok then
		warn("[Admin] " .. cmd.id .. " error: " .. tostring(success))
		return { ok = false, msg = "เกิดข้อผิดพลาด: " .. tostring(success) }
	end
	if success and cmd.marksTarget and DataService then
		for _, t in targets do
			if DataService.IsLoaded(t) then
				DataService.Set(t, "Meta.AdminTouched", true)
			end
		end
	end
	local detail = ""
	for k, v in args do
		if k ~= "json" then
			detail ..= string.format("%s=%s ", tostring(k), tostring(v))
		end
	end
	AdminService.Log(admin, cmd.id, cmd.usesTarget and targets or {}, detail .. (success and "OK" or "FAIL"))
	return { ok = success, msg = msg or (success and "เรียบร้อย" or "ไม่สำเร็จ"), data = payload }
end

-- ส่ง UI ให้แอดมิน
local function giveUI(player: Player)
	if not AdminService.IsAdmin(player) then
		return
	end
	local template = ServerStorage:FindFirstChild("AdminUI") and ServerStorage.AdminUI:FindFirstChild("AdminPanel")
	if not template then
		warn("[Admin] ServerStorage.AdminUI.AdminPanel not found")
		return
	end
	local gui = player:WaitForChild("PlayerGui", 30)
	if not gui or gui:FindFirstChild("AdminPanel") then
		return
	end
	local clone = template:Clone()
	clone.Parent = gui
end

function AdminService.Init()
	DataService = require(script.Parent.DataService)
	Net.Function("AdminRun").OnServerInvoke = handleRun
end

function AdminService.Start()
	local function onPlayer(player: Player)
		task.spawn(function()
			AdminService.GetLevel(player)
			giveUI(player)
		end)
	end
	for _, p in Players:GetPlayers() do
		onPlayer(p)
	end
	Players.PlayerAdded:Connect(onPlayer)
	Players.PlayerRemoving:Connect(function(p)
		levelCache[p] = nil
		recentCalls[p] = nil
	end)
end

return AdminService
