--!strict
-- แท็บ "Debug" + "จัดการผู้เล่น" + "ปุ่มลัด"

local Players = game:GetService("Players")
local LogService = game:GetService("LogService")
local Stats = game:GetService("Stats")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Net = require(Shared.Net)
local Balance = require(Shared.Balance)

local errors: { string } = {}
LogService.MessageOut:Connect(function(message, messageType)
	if messageType == Enum.MessageType.MessageError or messageType == Enum.MessageType.MessageWarning then
		table.insert(errors, os.date("!%H:%M:%S ") .. message)
		if #errors > 50 then
			table.remove(errors, 1)
		end
	end
end)

return function(Admin, DataService, FeatureService)
	-- ===== Debug =====
	Admin.Register({
		id = "debug.stats",
		tab = "debug",
		label = "Server Stats",
		sub = "Players / Parts / Memory",
		color = "Blue",
		order = 1,
		minLevel = "Tester",
		run = function()
			local parts = 0
			for _, d in workspace:GetDescendants() do
				if d:IsA("BasePart") then
					parts += 1
				end
			end
			local lines = {
				"Player: " .. #Players:GetPlayers(),
				"Part in Workspace: " .. parts,
				string.format("Server memory: %.0f MB", Stats:GetTotalMemoryUsageMb()),
				string.format("Heartbeat: %.1f ms", Stats.HeartbeatTimeMs),
				"DataStore: " .. DataService.DataStoreState(),
			}
			return true, "Server Stats", { text = table.concat(lines, "\n") }
		end,
	})
	Admin.Register({
		id = "debug.errors",
		tab = "debug",
		label = "View Error Log",
		sub = "50 latest entries",
		color = "Red",
		order = 2,
		minLevel = "Tester",
		run = function()
			return true, "Error/Warning Recent " .. #errors .. " entries", { text = #errors > 0 and table.concat(errors, "\n") or "(None)" }
		end,
	})
	Admin.Register({
		id = "debug.adminlog",
		tab = "debug",
		label = "View Admin Log",
		color = "Slate",
		order = 3,
		minLevel = "Moderator",
		run = function()
			local log = Admin.RecentLog()
			return true, "Recent admin commands " .. #log .. " entries", { text = #log > 0 and table.concat(log, "\n") or "(None)" }
		end,
	})
	Admin.Register({
		id = "debug.balancetest",
		tab = "debug",
		label = "Check Balance Formula",
		sub = "Compare with balance_sim.py",
		color = "Teal",
		order = 4,
		minLevel = "Tester",
		run = function()
			local ok, msg = Balance.SelfTest()
			return ok, msg
		end,
	})
	Admin.Register({
		id = "debug.flag",
		tab = "debug",
		label = "Toggle Feature",
		hidden = true,
		run = function(ctx)
			local name, enabled = ctx.args.name, ctx.args.enabled
			if type(name) ~= "string" or type(enabled) ~= "boolean" then
				return false, "Invalid data"
			end
			FeatureService.Set(name, enabled)
			return true, name .. ": " .. (enabled and "Open" or "Close")
		end,
	})
	Admin.Register({
		id = "debug.flags",
		tab = "debug",
		label = "Feature List",
		hidden = true,
		minLevel = "Tester",
		run = function()
			return true, "Feature Flags", { flags = FeatureService.All() }
		end,
	})

	-- ===== จัดการผู้เล่น =====
	Admin.Register({
		id = "mod.announce",
		tab = "mod",
		label = "Announce to This Server",
		sub = "Enter text in the text box first",
		color = "Orange",
		order = 1,
		minLevel = "Moderator",
		run = function(ctx)
			local text = ctx.args.text
			if type(text) ~= "string" or #text == 0 then
				return false, "Enter a message in the text box first"
			end
			text = string.sub(text, 1, 200)
			Net.Event("Notify"):FireAllClients({ text = "[Announcement] " .. text, kind = "announce" })
			return true, "Announced"
		end,
	})
	Admin.Register({
		id = "mod.warn",
		tab = "mod",
		label = "Warn",
		sub = "Select Player",
		color = "Orange",
		order = 2,
		minLevel = "Moderator",
		usesTarget = true,
		run = function(ctx)
			local text = type(ctx.args.text) == "string" and ctx.args.text ~= "" and ctx.args.text or "Please follow the rules"
			for _, t in ctx.targets do
				Net.Event("Notify"):FireClient(t, { text = "[Staff Warning] " .. string.sub(text, 1, 200), kind = "warn" })
			end
			return true, "Warning sent"
		end,
	})
	Admin.Register({
		id = "mod.kick",
		tab = "mod",
		label = "Kick from Server",
		sub = "Confirm 1",
		color = "Red",
		order = 3,
		minLevel = "Moderator",
		usesTarget = true,
		singleTarget = true,
		confirm = 1,
		run = function(ctx)
			local t = ctx.targets[1]
			if t == ctx.admin then
				return false, "Cannot kick yourself"
			end
			local reason = type(ctx.args.text) == "string" and ctx.args.text ~= "" and ctx.args.text or "Removed by staff"
			t:Kick(string.sub(reason, 1, 200))
			return true, "Kick " .. t.Name .. " done"
		end,
	})

	-- ===== ปุ่มลัด (ชี้ไปคำสั่งจริงในแท็บอื่น ฝั่ง UI จัดการ) =====
end
