-- Synthetic saves only; the same check is used by data.migratetest and the isolated harness.
return function(Data)
	local issues = {}
	local function check(ok, message) if not ok then table.insert(issues, message) end end
	for _, version in {0, 1, 2, 3} do
		local old = { DataVersion = version, Progress = { UnlockedZones = {1,2}, Bosses = { ["1"] = 1 } }, Currencies = { Coins = 123 }, Inventory = { Weapons = {} } }
		local result = Data.Migrate(old)
		check(result.DataVersion == Data.DATA_VERSION, "version "..version)
		check(result.Currencies.Coins == 123 and result.Progress.Bosses["1"] == 1, "existing data changed")
		check(#result.Progress.UnlockedZones == 2 and next(result.Progress.VisitedZones) == nil, "unlock/visit inference")
		check(next(result.Explorer.collected) == nil and next(result.Explorer.completed) == nil, "new defaults")
		result.Progress.VisitedZones["1"] = true; result.Explorer.collected.explorer_z1_1_v1 = true; result.Explorer.completed["1"] = true
		local again = Data.Migrate(result)
		check(again.Progress.VisitedZones["1"] and again.Explorer.collected.explorer_z1_1_v1 and again.Explorer.completed["1"], "idempotency/progress lost")
	end
	local step = Data.MIGRATIONS[3]
	Data.MIGRATIONS[3] = function(data) data.Currencies.Coins = -1; error("synthetic v3 failure") end
	local ok, result = pcall(Data.Migrate, {DataVersion=2,Currencies={Coins=123}})
	Data.MIGRATIONS[3] = step
	check(ok and result.DataVersion == 2 and result.Currencies.Coins == 123, "failed v3 mutated save")
	return #issues == 0, "Map migration: "..(#issues==0 and "passed" or "FAILED"), table.concat(issues,"\n")
end
