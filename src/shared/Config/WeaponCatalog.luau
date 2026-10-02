-- Weapon catalog used by every system (hand-written; data comes from generated modules).
--   List   = Sword Pack 380 (swd_001..swd_380): chests, Index totals, galleries.
--   Legacy = original Config.Weapons (wpn_*) flagged legacy=true + replacement id. Never dropped from
--            ById so a save that still holds an old id (pre-migration, failed migration) keeps working.
--   ById   = both sets. LegacyMap = Config.LegacyWeaponMap (wpn_* -> swd_*), used by DataService MIGRATIONS[2].
local Weapons = require(script.Parent.Weapons)
local SwordPack = require(script.Parent.SwordPack)
local LegacyMap = require(script.Parent.LegacyWeaponMap)

local byId = {}
local list = {}
for _, s in SwordPack.List do
	assert(byId[s.id] == nil, "duplicate weapon id in catalog: " .. s.id)
	byId[s.id] = s
	table.insert(list, s)
end
local legacy = {}
for _, w in Weapons.List do
	assert(byId[w.id] == nil, "duplicate weapon id in catalog: " .. w.id)
	assert(LegacyMap[w.id] and SwordPack.ById[LegacyMap[w.id]], "legacy weapon without sword mapping: " .. w.id)
	local def = table.clone(w)
	def.legacy = true
	def.replacement = LegacyMap[w.id]
	table.freeze(def)
	byId[def.id] = def
	table.insert(legacy, def)
end

return table.freeze({
	List = table.freeze(list),
	Legacy = table.freeze(legacy),
	ById = table.freeze(byId),
	LegacyMap = LegacyMap,
})
