-- Phone window layouts (track C). On phones NavigationController rebuilds each window on a W x H
-- canvas instead of shrinking the 960x650 desktop window to ~0.45. Scale is ~0.82 at 666x374
-- and ~0.78 in the notched phone safe area; buttons need 62 px including their 4 px bottom lip.
-- ["<ScreenGui>.<Panel>"] = { ["Child.Path"] = {Position, Size} | false (hidden on phones) }.
-- `_size = {w, h}` overrides the canvas for small windows. Padded windows (UIPadding) use content
-- coordinates. Desktop values are saved and restored by NavigationController; data only.
local function at(x, y, w, h)
	return { UDim2.fromOffset(x, y), UDim2.fromOffset(w, h) }
end
local function u(xs, xo, ys, yo, ws, wo, hs, ho)
	return { UDim2.new(xs, xo, ys, yo), UDim2.new(ws, wo, hs, ho) }
end
local CLOSE = u(1, -36, 0, 36, 0, 64, 0, 64)
local function closePadded(pad) -- same corner for windows with UIPadding
	return u(1, pad - 36, 0, 36 - pad, 0, 64, 0, 64)
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
		["Selection.OddsButton"] = at(14, 226, 234, 62),
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
		Actions = at(472, 292, 300, 62),
	},
	["GardenHUD.Panel"] = {
		HeaderPlaque = false,
		WindowClose = CLOSE,
		Selection = at(8, 8, 262, 344),
		["Selection.SelectedTitle"] = u(0, 16, 0, 4, 1, -32, 0, 28),
		["Selection.ArtHolder"] = u(0, 22, 0, 34, 1, -44, 0, 70),
		["Selection.State"] = u(0.5, 0, 0, 104, 0, 196, 0, 34),
		["Selection.Fruit"] = u(0, 16, 0, 140, 1, -32, 0, 34),
		["Selection.Value"] = u(0, 16, 0, 176, 1, -32, 0, 34),
		["Selection.PlotActions"] = u(0, 16, 0, 214, 1, -32, 0, 130),
		["Selection.PlotActions.Primary"] = u(0, 0, 0, 0, 1, 0, 0, 62),
		["Selection.PlotActions.Water"] = u(0, 0, 0, 64, 0.5, -4, 0, 62),
		["Selection.PlotActions.Cut"] = u(0.5, 4, 0, 64, 0.5, -4, 0, 62),
		["Selection.CutConfirm"] = u(0, 16, 0, 214, 1, -32, 0, 130),
		["Selection.CutConfirm.YesCut"] = u(0, 10, 1, -64, 0.5, -14, 0, 62),
		["Selection.CutConfirm.CancelCut"] = u(0.5, 4, 1, -64, 0.5, -14, 0, 62),
		Items = at(278, 70, 494, 222),
		SlotsBar = at(278, 298, 494, 54),
		["SlotsBar.SlotsValue"] = at(186, 0, 96, 54),
		["SlotsBar.Upgrade"] = u(1, -206, 0, -4, 0, 204, 0, 62),
		["SlotsBar.Sell"] = u(1, -206, 0, -4, 0, 204, 0, 62),
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
		["Boards.Scope"] = u(1, -124, 0, 0, 0, 124, 0, 60),
		["Boards.Ranks"] = u(0, 0, 0, 62, 1, 0, 1, -62),
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
		Info = u(0, 0, 0, 0, 1, -66, 0, 26),
		Xp = u(0, 0, 0, 28, 1, -66, 0, 22),
		HeadFree = u(0, 70, 0, 120, 0.5, -74, 0, 30),
		HeadPremium = u(0.5, 4, 0, 120, 0.5, -12, 0, 30),
		ClaimAll = at(0, 54, 200, 62),
		BuyPremium = at(212, 54, 300, 62),
		Levels = u(0, 0, 0, 154, 1, 0, 1, -182),
		Message = u(0, 0, 1, -26, 1, 0, 0, 26),
	},
	["RebirthHUD.Panel"] = {
		TitleIcon = false,
		WindowHeading = false,
		WindowClose = closePadded(16),
		StatCycle = at(0, 0, 222, 54),
		StatPower = at(228, 0, 222, 54),
		StatTokens = at(456, 0, 222, 54),
		Requirement = u(0, 0, 0, 58, 1, 0, 0, 58),
		Message = u(0, 0, 0, 118, 1, 0, 0, 18),
		Skills = u(0, 0, 0, 138, 1, 0, 1, -202),
		Prepare = u(0, 0, 1, -64, 1, 0, 0, 62),
		["Confirmation.Heading"] = u(0, 0, 0, 0, 1, 0, 0, 40),
		["Confirmation.Body"] = u(0, 0, 0, 48, 1, 0, 1, -120),
		["Confirmation.Confirm"] = u(0, 0, 1, -64, 0.55, -6, 0, 62),
		["Confirmation.Cancel"] = u(0.55, 6, 1, -64, 0.45, -6, 0, 62),
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
	L["PetHUD.Panel"]["Tab" .. name] = at(8 + (i - 1) * 140, 8, 136, 60)
	L["PetHUD.Panel"]["Tab" .. name .. ".Content.TabLabel"] = false
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
	P[slot .. ".SlotAction"] = u(0.5, 0, 0, 156, 1, -40, 0, 64)
end
for i, name in { "Garden", "Seeds", "Shop", "Merchant" } do
	L["GardenHUD.Panel"]["Tab" .. name] = at(278 + (i - 1) * 106, 8, 102, 56)
	L["GardenHUD.Panel"]["Tab" .. name .. ".Content.TabIcon"] = false -- 102 px: label only
end
-- Rewards: three tabs, the seven days in one row, leaderboard metric tabs on one line.
for i, tab in { { "Daily", 8, 110 }, { "Codes", 122, 110 }, { "Boards", 236, 190 } } do
	L["RewardsHUD.Panel"]["Tab" .. tab[1]] = at(tab[2], 8, tab[3], 60)
	L["RewardsHUD.Panel"]["Tab" .. tab[1] .. ".Content.TabIcon"] = false -- label only: leaves room for the streak
end
for i = 1, 7 do
	L["RewardsHUD.Panel"]["Daily.Day" .. i] = at(8 + (i - 1) * 110, 70, 104, 218)
	L["RewardsHUD.Panel"]["Daily.Day" .. i .. ".Status"] = u(0.5, 0, 1, -4, 0, 98, 0, 32)
end
for i, name in { "TreesCut", "HighestHit", "Rebirth", "Income", "Likes" } do
	L["RewardsHUD.Panel"]["Boards." .. name] = at((i - 1) * 126, 0, 122, 60)
	L["RewardsHUD.Panel"]["Boards." .. name .. ".Content.TabLabel"] = false
end
-- Quests: six icon-only tabs on phones (the icon names the tab).
for i, name in { "Main", "Daily", "Weekly", "Index", "Achievements", "Warp" } do
	L["StoryHUD.Panel"]["Tab" .. name] = at((i - 1) * 114, 0, 110, 58)
	L["StoryHUD.Panel"]["Tab" .. name .. ".Content.TabLabel"] = false
end

-- Pets needs a full-width action row when six pet actions are shown. Base/Conveyor use
-- the footer for the hint only. Navigation reapplies this variant on every tab change.
function L.PetLayout(tab)
	local p = table.clone(L["PetHUD.Panel"])
	if tab == "Pets" then
		p.Items = at(8, 70, 764, 158)
		p.Info = at(8, 234, 764, 54)
		p.Actions = at(8, 292, 764, 62)
	elseif tab == "Base" or tab == "Belt" then
		p.Info = at(8, 298, 764, 54)
	end
	return p
end

function L.StoryLayout(tab)
	local p=table.clone(L["StoryHUD.Panel"])
	p.CollectionSummary=at(0,62,752,58)
	p.CollectionHint=at(0,120,752,26)
	p.CollectionPages=at(0,266,752,66)
	if tab=="Index" then p.Items=at(0,148,752,112);p.Message=false end
	return p
end

function L.GardenLayout(tab)
	local p=table.clone(L["GardenHUD.Panel"])
	if tab=="Shop" or tab=="Merchant" then
		p.Selection=false;p.Items=at(8,70,764,tab=="Merchant" and 282 or 222)
		p.SlotsBar=tab=="Merchant" and false or at(8,298,764,54)
	end
	return p
end

return L
