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
		label = "สถิติเซิร์ฟ",
		sub = "ผู้เล่น/Part/หน่วยความจำ",
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
				"ผู้เล่น: " .. #Players:GetPlayers(),
				"Part ใน Workspace: " .. parts,
				string.format("หน่วยความจำ Server: %.0f MB", Stats:GetTotalMemoryUsageMb()),
				string.format("Heartbeat: %.1f ms", Stats.HeartbeatTimeMs),
				"DataStore: " .. DataService.DataStoreState(),
			}
			return true, "สถิติเซิร์ฟ", { text = table.concat(lines, "\n") }
		end,
	})
	Admin.Register({
		id = "debug.errors",
		tab = "debug",
		label = "ดู Log error",
		sub = "50 รายการล่าสุด",
		color = "Red",
		order = 2,
		minLevel = "Tester",
		run = function()
			return true, "Error/Warning ล่าสุด " .. #errors .. " รายการ", { text = #errors > 0 and table.concat(errors, "\n") or "(ไม่มี)" }
		end,
	})
	Admin.Register({
		id = "debug.adminlog",
		tab = "debug",
		label = "ดู Log แอดมิน",
		color = "Slate",
		order = 3,
		minLevel = "Moderator",
		run = function()
			local log = Admin.RecentLog()
			return true, "คำสั่งแอดมินล่าสุด " .. #log .. " รายการ", { text = #log > 0 and table.concat(log, "\n") or "(ไม่มี)" }
		end,
	})
	Admin.Register({
		id = "debug.balancetest",
		tab = "debug",
		label = "ตรวจสูตร Balance",
		sub = "เทียบกับ balance_sim.py",
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
		label = "เปิด/ปิด Feature",
		hidden = true,
		run = function(ctx)
			local name, enabled = ctx.args.name, ctx.args.enabled
			if type(name) ~= "string" or type(enabled) ~= "boolean" then
				return false, "ข้อมูลไม่ถูกต้อง"
			end
			FeatureService.Set(name, enabled)
			return true, name .. ": " .. (enabled and "เปิด" or "ปิด")
		end,
	})
	Admin.Register({
		id = "debug.flags",
		tab = "debug",
		label = "รายการ Feature",
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
		label = "ประกาศเซิร์ฟนี้",
		sub = "พิมพ์ในช่องข้อความก่อน",
		color = "Orange",
		order = 1,
		minLevel = "Moderator",
		run = function(ctx)
			local text = ctx.args.text
			if type(text) ~= "string" or #text == 0 then
				return false, "พิมพ์ข้อความในช่องข้อความก่อน"
			end
			text = string.sub(text, 1, 200)
			Net.Event("Notify"):FireAllClients({ text = "[ประกาศ] " .. text, kind = "announce" })
			return true, "ประกาศแล้ว"
		end,
	})
	Admin.Register({
		id = "mod.warn",
		tab = "mod",
		label = "เตือน",
		sub = "เลือกผู้เล่น",
		color = "Orange",
		order = 2,
		minLevel = "Moderator",
		usesTarget = true,
		run = function(ctx)
			local text = type(ctx.args.text) == "string" and ctx.args.text ~= "" and ctx.args.text or "กรุณาเล่นตามกติกา"
			for _, t in ctx.targets do
				Net.Event("Notify"):FireClient(t, { text = "[คำเตือนจากทีมงาน] " .. string.sub(text, 1, 200), kind = "warn" })
			end
			return true, "เตือนแล้ว"
		end,
	})
	Admin.Register({
		id = "mod.kick",
		tab = "mod",
		label = "เตะออกจากเซิร์ฟ",
		sub = "ยืนยัน 1 ชั้น",
		color = "Red",
		order = 3,
		minLevel = "Moderator",
		usesTarget = true,
		singleTarget = true,
		confirm = 1,
		run = function(ctx)
			local t = ctx.targets[1]
			if t == ctx.admin then
				return false, "เตะตัวเองไม่ได้"
			end
			local reason = type(ctx.args.text) == "string" and ctx.args.text ~= "" and ctx.args.text or "ถูกเตะโดยทีมงาน"
			t:Kick(string.sub(reason, 1, 200))
			return true, "เตะ " .. t.Name .. " แล้ว"
		end,
	})

	-- ===== ปุ่มลัด (ชี้ไปคำสั่งจริงในแท็บอื่น ฝั่ง UI จัดการ) =====
end
