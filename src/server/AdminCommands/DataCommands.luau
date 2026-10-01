--!strict
-- แท็บ "ข้อมูลเซฟ" — บันทึก, สำรอง/คืน, Export/Import JSON, ทดสอบ Migration, รีเซ็ต

local HttpService = game:GetService("HttpService")

return function(Admin, DataService)
	local function single(ctx): (Player?, string?)
		local t = ctx.targets[1]
		if not t or not DataService.IsLoaded(t) then
			return nil, "ผู้เล่นยังโหลดเซฟไม่เสร็จ"
		end
		return t, nil
	end

	Admin.Register({
		id = "data.save",
		tab = "data",
		label = "บันทึกทันที",
		color = "Green",
		order = 1,
		usesTarget = true,
		run = function(ctx)
			local n = 0
			for _, t in ctx.targets do
				if DataService.SaveNow(t) then
					n += 1
				end
			end
			return true, "สั่งบันทึก " .. n .. " คน (สถานะ DataStore: " .. DataService.DataStoreState() .. ")"
		end,
	})
	Admin.Register({
		id = "data.backup",
		tab = "data",
		label = "สำรองเซฟ",
		color = "Blue",
		order = 2,
		usesTarget = true,
		singleTarget = true,
		run = function(ctx)
			local t, err = single(ctx)
			if not t then
				return false, err
			end
			return DataService.Backup(t)
		end,
	})
	Admin.Register({
		id = "data.restore",
		tab = "data",
		label = "คืนเซฟจากสำรอง",
		color = "Orange",
		order = 3,
		usesTarget = true,
		singleTarget = true,
		confirm = 1,
		marksTarget = true,
		run = function(ctx)
			local t, err = single(ctx)
			if not t then
				return false, err
			end
			return DataService.Restore(t)
		end,
	})
	Admin.Register({
		id = "data.export",
		tab = "data",
		label = "Export JSON",
		sub = "ก๊อปเซฟออกมาดู",
		color = "Purple",
		order = 4,
		usesTarget = true,
		singleTarget = true,
		run = function(ctx)
			local t, err = single(ctx)
			if not t then
				return false, err
			end
			local json = DataService.ExportJSON(t)
			return true, "Export เซฟของ " .. t.Name .. " แล้ว (" .. #json .. " ตัวอักษร)", { text = json }
		end,
	})
	Admin.Register({
		id = "data.import",
		tab = "data",
		label = "Import JSON",
		sub = "วางในช่องข้อความก่อน",
		color = "Teal",
		order = 5,
		usesTarget = true,
		singleTarget = true,
		confirm = 1,
		minLevel = "Owner",
		marksTarget = true,
		run = function(ctx)
			local t, err = single(ctx)
			if not t then
				return false, err
			end
			local json = ctx.args.json
			if type(json) ~= "string" or #json < 2 then
				return false, "วาง JSON ในช่องข้อความก่อน"
			end
			if #json > 3_000_000 then
				return false, "JSON ใหญ่เกินไป"
			end
			return DataService.ImportJSON(t, json)
		end,
	})
	Admin.Register({
		id = "data.migratetest",
		tab = "data",
		label = "ทดสอบ Migration",
		sub = "แปลงเซฟ v0 ตัวอย่าง",
		color = "Slate",
		order = 6,
		run = function()
			local sample = { Coins = 12345, Wood = 678, Gems = 9 } -- เซฟ v0 (เงินอยู่ที่ root)
			local ok, result, log = pcall(DataService.Migrate, sample)
			if not ok then
				return false, "Migration พัง: " .. tostring(result)
			end
			local good = result.Currencies.Coins == 12345 and result.Currencies.Wood == 678 and result.Coins == nil
			local text = HttpService:JSONEncode(result)
			return good,
				(good and "Migration ผ่าน: " or "Migration ผิด: ") .. table.concat(log, ", "),
				{ text = text }
		end,
	})
	Admin.Register({
		id = "data.view",
		tab = "data",
		label = "ดูสรุปเซฟ",
		color = "Blue",
		order = 7,
		usesTarget = true,
		singleTarget = true,
		run = function(ctx)
			local t, err = single(ctx)
			if not t then
				return false, err
			end
			local d = DataService.GetData(t)
			local lines = {
				"ผู้เล่น: " .. t.Name .. " (" .. t.UserId .. ")",
				"DataVersion: " .. tostring(d.DataVersion),
				"เข้าเกม: " .. d.Meta.Joins .. " ครั้ง, เล่นไป " .. math.floor(d.Stats.PlaySeconds / 60) .. " นาที",
				"โดนแอดมินแก้: " .. tostring(d.Meta.AdminTouched),
				"เงิน: " .. HttpService:JSONEncode(d.Currencies),
				"โซน: " .. d.Progress.Zone .. ", Rebirth: " .. d.Progress.Rebirth,
			}
			return true, "สรุปเซฟของ " .. t.Name, { text = table.concat(lines, "\n") }
		end,
	})
	Admin.Register({
		id = "data.reset",
		tab = "data",
		label = "รีเซ็ตเซฟ",
		sub = "ยืนยัน 2 ชั้น",
		color = "Red",
		order = 20,
		usesTarget = true,
		singleTarget = true,
		confirm = 2,
		minLevel = "Owner",
		run = function(ctx)
			local t, err = single(ctx)
			if not t then
				return false, err
			end
			DataService.Backup(t)
			DataService.ResetData(t)
			return true, "รีเซ็ตเซฟของ " .. t.Name .. " แล้ว (สำรองอัตโนมัติไว้ก่อนรีเซ็ต)"
		end,
	})
end
