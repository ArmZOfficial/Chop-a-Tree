--!strict
-- Sword Pack migration self-check (admin data.migratetest). Pure: builds synthetic saves, never touches
-- a live profile or DataStore. Returns (passed, summary, reportText).
local Shared = game:GetService("ReplicatedStorage").Shared
local Catalog = require(Shared.Config.WeaponCatalog)
local Loot = require(Shared.Loot)
local Chests = require(Shared.Config.Chests)

local function deepCopy(t: any): any
	if type(t) ~= "table" then
		return t
	end
	local o = {}
	for k, v in t do
		o[k] = deepCopy(v)
	end
	return o
end

local function deepEqual(a: any, b: any): boolean
	if type(a) ~= type(b) then
		return false
	end
	if type(a) ~= "table" then
		return a == b
	end
	for k, v in a do
		if not deepEqual(v, b[k]) then
			return false
		end
	end
	for k in b do
		if a[k] == nil then
			return false
		end
	end
	return true
end

-- Build a v0/v1 save covering every legacy id plus the edge cases from the master prompt.
local function sample(version: number)
	local inv, n = {}, 0
	local function put(uid: string, item: any)
		inv[uid] = item
		n += 1
	end
	for i, def in Catalog.Legacy do
		put("L" .. i, { id = def.id, il = 1 + i % 8, stars = 1 + i % 5, giant = i % 7 == 0, rebirthDrop = i % 3, roll = 1, admin_spawned = i % 11 == 0, locked = i % 4 == 0 })
	end
	local first = Catalog.Legacy[1].id
	for d = 1, 3 do -- duplicates must stay fusable together (same new id)
		put("DUP" .. d, { id = first, il = 2, stars = 1, giant = false, rebirthDrop = 0, roll = 1 })
	end
	put("GIANT_EQ", { id = Catalog.Legacy[#Catalog.Legacy].id, il = 8, stars = 5, giant = true, rebirthDrop = 2, roll = 1, locked = true })
	put("UNKNOWN", { id = "wpn_does_not_exist", il = 3, stars = 2, giant = false, rebirthDrop = 0, roll = 1 })
	put("ALREADY", { id = Catalog.List[5].id, il = 1, stars = 1, giant = false, rebirthDrop = 0, roll = 1 })
	local fill = 0
	while n < Chests.MaxWeapons do -- full inventory (MaxWeapons)
		fill += 1
		put("FILL" .. fill, { id = Catalog.List[1 + fill % #Catalog.List].id, il = 1, stars = 1, giant = false, rebirthDrop = 0, roll = 1 })
	end
	local idx = {}
	for i = 1, 12 do
		idx[Catalog.Legacy[i].id] = true
	end
	local save: any = {
		DataVersion = version,
		Inventory = { Weapons = inv, Equipped = "GIANT_EQ", Chests = {}, Seeds = {}, Fruits = {}, Eggs = {}, Pets = {} },
		Index = { weapons = idx, pets = {}, seeds = {}, mutations = {}, done = { weapons = true } },
	}
	if version == 0 then
		save.Coins, save.Wood, save.Gems = 12345, 678, 9
	else
		save.Currencies = { Coins = 12345, Wood = 678, Gems = 9 }
	end
	return save
end

return function(DataService: any): (boolean, string, string)
	local fails, rows = {}, {}
	local function check(ok: boolean, msg: string)
		if not ok then
			table.insert(fails, msg)
		end
	end
	for _, version in { 0, 1 } do
		local before = sample(version)
		local ok, after, log = pcall(DataService.Migrate, deepCopy(before))
		if not ok then
			return false, "Migration crashed: " .. tostring(after), ""
		end
		local tag = "v" .. version .. ": "
		check(after.DataVersion == DataService.DATA_VERSION, tag .. "DataVersion " .. tostring(after.DataVersion))
		check(table.concat(log, ","):find("FAILED") == nil, tag .. "a step failed: " .. table.concat(log, ", "))
		check(after.Currencies.Coins == 12345 and after.Coins == nil, tag .. "currencies")
		check(after.Inventory.Equipped == "GIANT_EQ" and after.Inventory.Weapons.GIANT_EQ ~= nil, tag .. "equipped uid")
		local count = 0
		for uid, old in before.Inventory.Weapons do
			count += 1
			local new = after.Inventory.Weapons[uid]
			if not new then
				check(false, tag .. "lost uid " .. uid)
				continue
			end
			local oldDef, newDef = Catalog.ById[old.id], Catalog.ById[new.id]
			for _, f in { "il", "stars", "giant", "rebirthDrop", "roll", "admin_spawned", "locked" } do
				check(new[f] == old[f], tag .. uid .. " field " .. f)
			end
			if old.id == "wpn_does_not_exist" then
				check(new.id == old.id and new.legacyId == nil, tag .. "unknown id must be kept as-is")
			elseif oldDef and oldDef.legacy then
				check(new.id == Catalog.LegacyMap[old.id] and new.legacyId == old.id, tag .. uid .. " mapped id/legacyId")
				check(newDef ~= nil and not newDef.legacy, tag .. uid .. " resolves to a Sword Pack def")
				if newDef then
					check(newDef.rarity == oldDef.rarity, tag .. uid .. " rarity changed")
					local pOld, pNew = Loot.Power(old), Loot.Power(new)
					check(pNew >= pOld, tag .. uid .. " power dropped " .. pOld .. " -> " .. pNew)
					if version == 1 and uid:sub(1, 1) == "L" then
						table.insert(rows, string.format("%s -> %s | %s | %s -> %s", old.id, new.id, oldDef.rarity, tostring(pOld), tostring(pNew)))
					end
				end
			else
				check(deepEqual(old, new), tag .. uid .. " non-legacy item changed")
			end
		end
		check(count == Chests.MaxWeapons, tag .. "item count " .. count)
		local dup = after.Inventory.Weapons
		check(Loot.Compatible(dup.DUP1, dup.DUP2) and Loot.Compatible(dup.DUP2, dup.DUP3), tag .. "duplicates no longer fusable")
		for id in before.Index.weapons do
			check(after.Index.weapons[id] == true and after.Index.weapons[Catalog.LegacyMap[id]] == true, tag .. "index union " .. id)
		end
		check(after.Index.done.weapons == true, tag .. "index done flag")
		-- Idempotent: re-running the whole chain or the v2 step alone changes nothing.
		local again = DataService.Migrate(deepCopy(after))
		check(deepEqual(again, after), tag .. "Migrate not idempotent")
		local stepAgain = DataService.MIGRATIONS[2](deepCopy(after))
		check(deepEqual(stepAgain, after), tag .. "MIGRATIONS[2] not idempotent")
	end
	-- A broken step must leave the save untouched (still old version).
	local saved = DataService.MIGRATIONS[2]
	DataService.MIGRATIONS[2] = function()
		error("simulated failure")
	end
	local okF, broken = pcall(DataService.Migrate, sample(1))
	DataService.MIGRATIONS[2] = saved
	check(okF and broken.DataVersion == 1 and broken.Inventory.Weapons.L1.id == Catalog.Legacy[1].id, "failed step must keep v1 data unchanged")
	table.sort(rows)
	local passed = #fails == 0
	local summary = (passed and "Migration Passed" or ("Migration FAILED (" .. #fails .. ")"))
		.. string.format(": v0/v1 -> v%d, %d legacy ids, %d items, unknown kept, idempotent", DataService.DATA_VERSION, #Catalog.Legacy, Chests.MaxWeapons)
	local text = (#fails > 0 and ("FAILS:\n" .. table.concat(fails, "\n", 1, math.min(#fails, 40)) .. "\n\n") or "")
		.. "old -> new | rarity | power before -> after\n" .. table.concat(rows, "\n")
	return passed, summary, text
end
