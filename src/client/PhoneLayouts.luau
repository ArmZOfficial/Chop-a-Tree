-- Phone window layouts (track C). On phones NavigationController rebuilds each window on a W x H
-- canvas instead of shrinking the 960x650 desktop window to ~0.45, so every control stays >= 44 px
-- (canvas scale on a 666x374 phone is ~0.82: keep controls >= 54 px here).
-- ["<ScreenGui>.<Panel>"] = { ["Child.Path"] = {Position, Size} | false (hidden on phones) }.
-- `_size = {w, h}` overrides the canvas for small windows. Padded windows (UIPadding) use content
-- coordinates. Desktop values are saved and restored by NavigationController; data only.
local function at(x, y, w, h)
	return { UDim2.fromOffset(x, y), UDim2.fromOffset(w, h) }
end
local function u(xs, xo, ys, yo, ws, wo, hs, ho)
	return { UDim2.new(xs, xo, ys, yo), UDim2.new(ws, wo, hs, ho) }
end
local CLOSE = u(1, -36, 0, 36, 0, 60, 0, 60)
local function closePadded(pad) -- same corner for windows with UIPadding
	return u(1, pad - 36, 0, 36 - pad, 0, 60, 0, 60)
end

local L = {
	W = 780,
	H = 360,
	["InventoryHUD.Panel"] = {
		TitleIcon = false,
		WindowHeading = false,
		Counter = false,
		WindowClose = CLOSE,
		Selection = at(8, 8, 262, 344),
		["Selection.Preview"] = at(31, 4, 200, 100),
		["Selection.ItemName"] = at(10, 104, 242, 34),
		["Selection.Rarity"] = u(0.5, 0, 0, 140, 0, 100, 0, 28),
		["Selection.Power"] = at(14, 172, 234, 46),
		["Selection.Details"] = at(14, 220, 234, 30),
		["Selection.Equipped"] = u(0.5, 0, 0, 250, 0, 150, 0, 34),
		["Selection.Actions.Equip"] = u(0, 0, 0, 0, 0.38, -6, 1, 0),
		["Selection.Actions.Fuse"] = u(0.38, 0, 0, 0, 0.34, -6, 1, 0),
		["Selection.Actions.Delete"] = u(0.72, 0, 0, 0, 0.28, -6, 1, 0),
		WeaponsTab = at(278, 8, 206, 56),
		ChestsTab = at(490, 8, 206, 56),
		GridFrame = at(278, 70, 494, 222),
		Body = at(286, 78, 478, 206),
		Info = at(278, 298, 494, 54),
	},
	["PetHUD.Panel"] = {
		HeaderPlaque = false,
		Stat1 = false,
		Stat2 = false,
		Stat3 = false,
		WindowClose = CLOSE,
		Items = at(8, 70, 764, 222),
		Incubator = at(8, 70, 764, 222),
		Info = at(8, 298, 456, 54),
		Actions = at(472, 296, 300, 58),
	},
	["GardenHUD.Panel"] = {
		HeaderPlaque = false,
		WindowClose = CLOSE,
		Selection = at(8, 8, 262, 344),
		["Selection.SelectedTitle"] = u(0, 16, 0, 4, 1, -32, 0, 28),
		["Selection.ArtHolder"] = u(0, 22, 0, 34, 1, -44, 0, 70),
		["Selection.State"] = u(0.5, 0, 0, 106, 0, 196, 0, 34),
		["Selection.Fruit"] = u(0, 16, 0, 144, 1, -32, 0, 38),
		["Selection.Value"] = u(0, 16, 0, 184, 1, -32, 0, 38),
		["Selection.PlotActions"] = u(0, 16, 0, 226, 1, -32, 0, 118),
		["Selection.PlotActions.Primary"] = u(0, 0, 0, 0, 1, 0, 0, 58),
		["Selection.PlotActions.Water"] = u(0, 0, 0, 60, 0.5, -4, 0, 58),
		["Selection.PlotActions.Cut"] = u(0.5, 4, 0, 60, 0.5, -4, 0, 58),
		["Selection.CutConfirm"] = u(0, 16, 0, 226, 1, -32, 0, 118),
		["Selection.CutConfirm.YesCut"] = u(0, 10, 1, -60, 0.5, -14, 0, 58),
		["Selection.CutConfirm.CancelCut"] = u(0.5, 4, 1, -60, 0.5, -14, 0, 58),
		Items = at(278, 70, 494, 222),
		SlotsBar = at(278, 298, 494, 54),
		["SlotsBar.SlotsValue"] = at(186, 0, 96, 54),
		["SlotsBar.Upgrade"] = u(1, -206, 0, -2, 0, 204, 0, 58),
		["SlotsBar.Sell"] = u(1, -206, 0, -2, 0, 204, 0, 58),
	},
	["ShopHUD.Panel"] = {
		HeaderPlaque = false,
		Footer = false,
		WindowClose = CLOSE,
		TabPasses = at(8, 8, 340, 56),
		TabProducts = at(354, 8, 340, 56),
		Items = at(8, 70, 764, 282),
	},
	["RewardsHUD.Panel"] = {
		HeaderPlaque = false,
		WindowClose = CLOSE,
		Streak = u(1, -78, 0, 36, 0, 270, 0, 50),
		["Daily.Reset"] = at(8, 298, 456, 54),
		["Daily.Claim"] = at(472, 294, 300, 62),
		Codes = at(8, 70, 764, 282),
		["Codes.Art"] = u(0.5, 0, 0, 0, 0, 80, 0, 64),
		["Codes.TextLabel"] = u(0, 0, 0, 64, 1, 0, 0, 44),
		["Codes.InputBox"] = at(60, 114, 440, 62),
		["Codes.Redeem"] = at(510, 112, 196, 66),
		["Codes.Boosts"] = at(60, 184, 646, 96),
		Boards = at(8, 70, 764, 282),
		["Boards.Server"] = at(0, 60, 170, 54),
		["Boards.Global"] = at(178, 60, 170, 54),
		["Boards.Refresh"] = u(1, -160, 0, 58, 0, 160, 0, 58),
		["Boards.Status"] = u(0, 364, 0, 60, 1, -536, 0, 54),
		["Boards.Ranks"] = u(0, 0, 0, 122, 1, 0, 1, -122),
	},
	["StoryHUD.Panel"] = {
		TitleIcon = false,
		WindowHeading = false,
		Close = false,
		WindowClose = closePadded(14),
		Message = u(0, 0, 0, 60, 1, 0, 0, 24),
		Items = u(0, 0, 0, 86, 1, 0, 1, -86),
	},
	["SeasonHUD.Panel"] = {
		TitleIcon = false,
		WindowHeading = false,
		Close = false,
		WindowClose = closePadded(14),
		Info = u(0, 0, 0, 0, 1, -66, 0, 40),
		ClaimAll = at(0, 44, 200, 58),
		BuyPremium = at(212, 44, 300, 58),
		Levels = u(0, 0, 0, 108, 1, 0, 1, -136),
		Message = u(0, 0, 1, -26, 1, 0, 0, 26),
	},
	["RebirthHUD.Panel"] = {
		TitleIcon = false,
		WindowHeading = false,
		WindowClose = closePadded(16),
		Status = u(0, 0, 0, 0, 1, -66, 0, 50),
		Message = u(0, 0, 0, 50, 1, -66, 0, 28),
		Skills = u(0, 0, 0, 82, 1, 0, 0, 178),
		Prepare = u(0, 0, 1, -60, 0, 430, 0, 58),
		Close = u(1, -155, 1, -60, 0, 155, 0, 58),
	},
	["ArenaHUD.Panel"] = {
		_size = { 640, 270 },
		TitleIcon = false,
		WindowHeading = false,
		Close = false,
		WindowClose = closePadded(16),
		Info = u(0, 0, 0, 0, 1, -66, 0, 44),
		Ranked = u(0, 0, 0, 50, 0.5, -4, 0, 58),
		JoinDuel = u(0.5, 4, 0, 50, 0.5, -4, 0, 58),
		JoinFFA = u(0, 0, 0, 114, 0.5, -4, 0, 58),
		JoinTimberClash = u(0.5, 4, 0, 114, 0.5, -4, 0, 58),
		JoinEggHeist = u(0, 0, 0, 178, 0.5, -4, 0, 58),
		Leave = u(0.5, 4, 0, 178, 0.5, -4, 0, 58),
	},
	["NavigationHUD.Settings"] = {
		_size = { 720, 290 },
		TitleIcon = false,
		WindowHeading = false,
		WindowClose = closePadded(18),
		Music = u(0, 0, 0, 0, 0.5, -39, 0, 62),
		SFX = u(0.5, -31, 0, 0, 0.5, -39, 0, 62),
		Sprint = u(0, 0, 0, 70, 0.5, -4, 0, 62),
		Language = u(0.5, 4, 0, 70, 0.5, -4, 0, 62),
		ChestAnimation = u(0, 0, 0, 140, 0.5, -4, 0, 62),
		Keys = u(0, 0, 0, 212, 1, 0, 0, 34),
	},
}

-- Toggles fill their settings row; small Music/SFX ones keep their width.
for name, width in { Music = 88, SFX = 88, Sprint = 138, Language = 138, ChestAnimation = 138 } do
	L["NavigationHUD.Settings"][name .. ".Toggle"] = u(1, -width - 10, 0, 4, 0, width, 0, 54)
end
-- Pets: five tabs beside the close button; three shorter incubator slots.
for i, name in { "Incubator", "Eggs", "Pets", "Base", "Belt" } do
	L["PetHUD.Panel"]["Tab" .. name] = at(8 + (i - 1) * 140, 8, 136, 56)
end
for i = 1, 3 do
	local slot = "Incubator.Slot" .. i
	local P = L["PetHUD.Panel"]
	P[slot] = at((i - 1) * 258, 0, 248, 222)
	P[slot .. ".Cradle"] = u(0, 16, 0, 4, 1, -32, 0, 118)
	P[slot .. ".Plus"] = u(0.5, 0, 0, 62, 0, 70, 0, 70)
	P[slot .. ".EggName"] = u(0, 10, 0, 122, 1, -20, 0, 22)
	P[slot .. ".Percent"] = u(0, 10, 0, 142, 1, -20, 0, 24)
	P[slot .. ".Track"] = u(0.5, 0, 0, 168, 1, -50, 0, 24)
	P[slot .. ".Warning"] = u(0, 10, 0, 194, 1, -20, 0, 24)
	P[slot .. ".ReadyBadge"] = u(0.5, 0, 0, 100, 0, 150, 0, 40)
	P[slot .. ".SlotAction"] = u(0.5, 0, 0, 160, 1, -40, 0, 60)
end
for i, name in { "Garden", "Seeds", "Shop", "Merchant" } do
	L["GardenHUD.Panel"]["Tab" .. name] = at(278 + (i - 1) * 106, 8, 102, 56)
	L["GardenHUD.Panel"]["Tab" .. name .. ".Content.TabIcon"] = false -- 102 px: label only
end
-- Rewards: three tabs, the seven days in one row, leaderboard metric tabs on one line.
for i, tab in { { "Daily", 8, 110 }, { "Codes", 122, 110 }, { "Boards", 236, 190 } } do
	L["RewardsHUD.Panel"]["Tab" .. tab[1]] = at(tab[2], 8, tab[3], 56)
	L["RewardsHUD.Panel"]["Tab" .. tab[1] .. ".Content.TabIcon"] = false -- label only: leaves room for the streak
end
for i = 1, 7 do
	L["RewardsHUD.Panel"]["Daily.Day" .. i] = at(8 + (i - 1) * 110, 70, 104, 218)
	L["RewardsHUD.Panel"]["Daily.Day" .. i .. ".Status"] = u(0.5, 0, 1, -4, 0, 98, 0, 32)
end
for i, name in { "TreesCut", "HighestHit", "Rebirth", "Income" } do
	L["RewardsHUD.Panel"]["Boards." .. name] = at((i - 1) * 192, 0, 188, 56)
end
for i, name in { "Main", "Daily", "Weekly", "Index", "Achievements", "Warp" } do
	L["StoryHUD.Panel"]["Tab" .. name] = at((i - 1) * 114, 0, 110, 58)
end

return L
