-- UI audit (track C). Paste into execute_luau (datamodel Client) during Play.
-- Reports, for every visible GuiObject in PlayerGui:
--   OVER  text that does not fit (TextFits=false, non-scaled text)
--   OFF   element outside the viewport (ignores children of clipping frames)
--   SMALL clickable button below MIN px on its short side (touch target)
local MIN = 44
local Players = game:GetService("Players")
local GuiService = game:GetService("GuiService")
local pg = Players.LocalPlayer:WaitForChild("PlayerGui")
local cam = workspace.CurrentCamera
local v = cam.ViewportSize
local inset = GuiService:GetGuiInset()

local function shown(o)
	local p = o
	while p and p ~= pg do
		if p:IsA("ScreenGui") then
			return p.Enabled
		elseif p:IsA("GuiObject") and not p.Visible then
			return false
		end
		p = p.Parent
	end
	return true
end
local function clipped(o)
	local p = o.Parent
	while p and not p:IsA("ScreenGui") do
		if p:IsA("ScrollingFrame") or (p:IsA("GuiObject") and p.ClipsDescendants) then
			return true
		end
		p = p.Parent
	end
	return false
end
local function name(o)
	return (o:GetFullName():gsub("^Players%.[^.]+%.PlayerGui%.", ""))
end

local SKIP = { AdminPanel = true, TouchGui = true } -- admin-only tools stay English and are not player-facing

local function audit()
v = cam.ViewportSize
local out, counts = {}, { OVER = 0, OFF = 0, SMALL = 0 }
local function add(kind, o, extra)
	counts[kind] += 1
	if #out < 60 then
		table.insert(out, kind .. " " .. name(o) .. " " .. extra)
	end
end
for _, sg in pg:GetChildren() do
	if sg:IsA("ScreenGui") and sg.Enabled and not SKIP[sg.Name] then
		local top = sg.IgnoreGuiInset and 0 or -inset.Y
		for _, o in sg:GetDescendants() do
			if o:IsA("GuiObject") and shown(o) and o.AbsoluteSize.X > 1 and o.AbsoluteSize.Y > 1 then
				local p, s = o.AbsolutePosition, o.AbsoluteSize
				if (o:IsA("TextLabel") or o:IsA("TextButton")) and o.Text ~= "" and not o.TextScaled and not o.TextFits and o.TextTransparency < 1 then
					-- cut on a UTF-8 boundary: a split Thai character breaks the MCP reply
					local cut = utf8.offset(o.Text, 25)
					add("OVER", o, string.format("[%q %dx%d need %dx%d]", cut and o.Text:sub(1, cut - 1) or o.Text, s.X, s.Y, o.TextBounds.X, o.TextBounds.Y))
				end
				if not clipped(o) and (p.X < -2 or p.Y < top - 2 or p.X + s.X > v.X + 2 or p.Y + s.Y > v.Y + top + 2) then
					add("OFF", o, string.format("[%d,%d %dx%d]", p.X, p.Y, s.X, s.Y))
				end
				if o:IsA("GuiButton") and (o.BackgroundTransparency < 1 or (o:IsA("TextButton") and o.Text ~= "") or o:FindFirstChildWhichIsA("TextLabel") or o:IsA("ImageButton")) then
					if math.min(s.X, s.Y) < MIN then
						add("SMALL", o, string.format("[%dx%d]", s.X, s.Y))
					end
				end
			end
		end
	end
end
return string.format("viewport %dx%d inset %d | OVER %d OFF %d SMALL %d\n", v.X, v.Y, inset.Y, counts.OVER, counts.OFF, counts.SMALL)
	.. table.concat(out, "\n")
end

-- Each window is opened (Visible = true, as its menu button does), audited and closed.
-- Run a few windows per call (execute_luau times out after 60 s on slow devices): set WINDOWS to a slice.
local WINDOWS = { "", "InventoryHUD.Panel", "PetHUD.Panel", "GardenHUD.Panel", "ShopHUD.Panel", "RewardsHUD.Panel",
	"StoryHUD.Panel", "SeasonHUD.Panel", "RebirthHUD.Panel", "ArenaHUD.Panel", "NavigationHUD.Settings", "NavigationHUD.MoreMenus" }
local report = {}
for _, path in WINDOWS do
	local w = pg
	for part in path:gmatch("[^.]+") do
		w = w and w:FindFirstChild(part)
	end
	if path ~= "" and w then
		w.Visible = true
	end
	task.wait(0.5)
	table.insert(report, "## " .. (path == "" and "HUD" or path) .. "  " .. audit())
	if path ~= "" and w then
		w.Visible = false
	end
end
return table.concat(report, "\n")
