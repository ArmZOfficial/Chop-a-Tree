--!strict
-- ช่องพิมพ์คำสั่ง (ทางเลือกสำหรับคนพิมพ์ไว — ทุกอย่างกดปุ่มได้อยู่แล้ว)
-- รูปแบบ: /คำสั่ง อาร์กิวเมนต์... [me|all|ชื่อผู้เล่น]
--   /give coins 1e15 me     /set gems 0 all     /rich     /poor
--   /fly  /noclip  /god  /speed 64  /tp ชื่อ  /bring ชื่อ|all  /spawn  /reset
--   /save  /backup  /export  /kick ชื่อ  /announce ข้อความ

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Currencies = require(ReplicatedStorage:WaitForChild("Shared").Config.Currencies)
local NumberFormat = require(ReplicatedStorage.Shared.NumberFormat)

local function findCurrency(word: string): string?
	local w = string.lower(word)
	for _, c in Currencies.List do
		if string.lower(c.id) == w or string.lower(c.label) == w then
			return c.id
		end
	end
	local alias = { coin = "Coins", gem = "Gems", token = "RebirthTokens", arena = "ArenaTokens", star = "Stardust" }
	return alias[w]
end

local function findPlayer(word: string): Player?
	local w = string.lower(word)
	for _, p in Players:GetPlayers() do
		if string.lower(p.Name) == w or string.lower(p.DisplayName) == w then
			return p
		end
	end
	for _, p in Players:GetPlayers() do
		if string.sub(string.lower(p.Name), 1, #w) == w or string.sub(string.lower(p.DisplayName), 1, #w) == w then
			return p
		end
	end
	return nil
end

-- คืน true ถ้าตั้งเป้าหมายได้ (ไม่มีคำ = ใช้เป้าหมายเดิมใน UI)
local function applyTarget(word: string?, state): (boolean, string?)
	if not word or word == "" then
		return true
	end
	local w = string.lower(word)
	if w == "me" then
		state.target = { mode = "me", userId = 0, name = "" }
	elseif w == "all" then
		state.target = { mode = "all", userId = 0, name = "" }
	else
		local p = findPlayer(word)
		if not p then
			return false, "ไม่พบผู้เล่น " .. word
		end
		state.target = { mode = "player", userId = p.UserId, name = p.Name }
	end
	return true
end

return function(text: string, state, run): (boolean, string)
	local words = string.split(string.gsub(text, "^%s*/?", ""), " ")
	local cmd = string.lower(words[1] or "")
	local function target(index: number): (boolean, string?)
		return applyTarget(words[index], state)
	end

	if cmd == "give" or cmd == "set" then
		local currency = findCurrency(words[2] or "")
		local amount = NumberFormat.Parse(words[3] or "")
		if not currency or not amount then
			return false, "ใช้แบบนี้: /" .. cmd .. " coins 1e15 me"
		end
		local ok, err = target(4)
		if not ok then
			return false, err :: string
		end
		run(cmd == "give" and "money.add" or "money.set", { currency = currency, amount = amount })
		return true, ""
	end

	local simple = {
		rich = "money.rich", poor = "money.zero", fly = "player.fly", noclip = "player.noclip",
		god = "player.god", spawn = "player.spawn", reset = "player.reset", save = "data.save",
		backup = "data.backup", export = "data.export", invisible = "player.invisible",
		clear = "player.clearall", stats = "debug.stats", errors = "debug.errors",
	}
	if simple[cmd] then
		local ok, err = target(2)
		if not ok then
			return false, err :: string
		end
		run(simple[cmd])
		return true, ""
	end
	if cmd == "speed" then
		local n = tonumber(words[2])
		local id = n and ("player.speed" .. n)
		if not id or not state.byId[id] then
			return false, "ความเร็วที่มี: 16, 32, 64, 120"
		end
		local ok, err = target(3)
		if not ok then
			return false, err :: string
		end
		run(id)
		return true, ""
	end
	if cmd == "tp" or cmd == "goto" or cmd == "kick" or cmd == "bring" then
		local ok, err = target(2)
		if not ok then
			return false, err :: string
		end
		local id = ({ tp = "player.goto", ["goto"] = "player.goto", kick = "mod.kick", bring = "player.bring" })[cmd]
		run(id)
		return true, ""
	end
	if cmd == "announce" then
		local message = table.concat(words, " ", 2)
		run("mod.announce", { text = message })
		return true, ""
	end
	return false, "ไม่รู้จักคำสั่ง /" .. cmd .. " (มี: give set rich poor fly noclip god speed tp bring spawn reset save backup export kick announce)"
end
