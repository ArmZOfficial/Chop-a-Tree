--!strict
-- แท็บ "ข้อมูลเซฟ" — บันทึก, สำรอง/คืน, Export/Import JSON, ทดสอบ Migration, รีเซ็ต

local HttpService = game:GetService("HttpService")

return function(Admin, DataService)
	local function single(ctx): (Player?, string?)
		local t = ctx.targets[1]
		if not t or not DataService.IsLoaded(t) then
			return nil, "Player save still loading"
		end
		return t, nil
	end

	Admin.Register({
		id = "data.save",
		tab = "data",
		label = "Save Now",
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
			return true, "Save requested for " .. n .. " players (Status DataStore: " .. DataService.DataStoreState() .. ")"
		end,
	})
	Admin.Register({
		id = "data.backup",
		tab = "data",
		label = "Back Up Save",
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
		label = "Restore Backup",
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
		sub = "Export Save",
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
			return true, "Export Save for " .. t.Name .. " done (" .. #json .. " characters)", { text = json }
		end,
	})
	Admin.Register({
		id = "data.import",
		tab = "data",
		label = "Import JSON",
		sub = "Paste in the text box first",
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
				return false, "Paste JSON in the text box first"
			end
			if #json > 3_000_000 then
				return false, "JSON too large"
			end
			return DataService.ImportJSON(t, json)
		end,
	})
	Admin.Register({
		id = "data.migratetest",
		tab = "data",
		label = "Test Migration",
		sub = "Synthetic saves: Sword Pack + map v3",
		color = "Slate",
		order = 6,
		run = function()
			-- v0/v1 synthetic saves -> current version: currencies, every legacy weapon id, equip, giant,
			-- locked, duplicates, unknown id, full inventory, Index union, idempotency, failed-step safety.
			local ok, passed, summary, text = pcall(require(script.Parent.SwordMigrationCheck), DataService)
			if not ok then
				return false, "Migration test crashed: " .. tostring(passed)
			end
			local mapOK, mapSummary, mapText = require(script.Parent.MapMigrationCheck)(DataService)
			return passed and mapOK, summary .. " / " .. mapSummary, { text = text .. "\n" .. mapText }
		end,
	})
	Admin.Register({
		id = "data.view",
		tab = "data",
		label = "View Save Summary",
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
				"Player: " .. t.Name .. " (" .. t.UserId .. ")",
				"DataVersion: " .. tostring(d.DataVersion),
				"Joined: " .. d.Meta.Joins .. " times, played " .. math.floor(d.Stats.PlaySeconds / 60) .. " min",
				"Admin modified: " .. tostring(d.Meta.AdminTouched),
				"Currency: " .. HttpService:JSONEncode(d.Currencies),
				"Zone: " .. d.Progress.Zone .. ", Rebirth: " .. d.Progress.Rebirth,
			}
			return true, "Save summary for " .. t.Name, { text = table.concat(lines, "\n") }
		end,
	})
	Admin.Register({
		id = "data.reset",
		tab = "data",
		label = "Reset Save",
		sub = "Confirm 2",
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
			return true, "Reset save for " .. t.Name .. " complete (automatically backed up before reset)"
		end,
	})
end
