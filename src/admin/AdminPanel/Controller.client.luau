--!strict
-- Admin Panel ฝั่ง Client (plan.md หัวข้อ 18) — Server ส่ง ScreenGui นี้ให้เฉพาะคนที่มียศเท่านั้น
-- ทุกปุ่มแค่ "ขอ" ให้ Server รันคำสั่ง; Server ตรวจสิทธิ์เองทุกครั้ง
-- รายการปุ่มมาจาก Server (AdminService.Register) → ระบบใหม่เพิ่มปุ่มเองไม่ต้องแก้ไฟล์นี้

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Stats = game:GetService("Stats")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local UIKit = require(Shared.UIKit)
local Net = require(Shared.Net)
local NumberFormat = require(Shared.NumberFormat)
local Currencies = require(Shared.Config.Currencies)
local AdminTabs = require(Shared.Config.AdminTabs)

local C = UIKit.Colors
local New = UIKit.New
local gui = script.Parent :: ScreenGui
local localPlayer = Players.LocalPlayer

-- ===== สถานะ =====
type CommandInfo = {
	id: string, tab: string, label: string, sub: string?, color: string?, order: number,
	usesTarget: boolean, singleTarget: boolean, confirm: number, hidden: boolean,
}
local state = {
	open = false,
	tab = "quick",
	target = { mode = "me", userId = 0, name = "" },
	amountIndex = 2,
	customAmount = nil :: number?,
	commands = {} :: { CommandInfo },
	byId = {} :: { [string]: CommandInfo },
	players = {} :: { { userId: number, name: string, display: string } },
	levelName = "",
	fpsOverlay = false,
}

local AMOUNTS = { { "1K", 1e3 }, { "1M", 1e6 }, { "1B", 1e9 }, { "1T", 1e12 }, { "1Qa", 1e15 }, { "1Qi", 1e18 } }

-- ปุ่มลัด: ชี้ไปคำสั่งจริง (cmds = รันต่อกันหลายคำสั่ง) / phase = ยังไม่มา
local QUICK = {
	{ label = "รวยทันที", sub = "ทุกสกุลเงิน = 1Qi", color = "Orange", cmds = { "money.rich" } },
	{ label = "บิน + อมตะ", sub = "สลับเปิด/ปิด", color = "Blue", cmds = { "player.fly", "player.god" } },
	{ label = "บันทึกเซฟ", sub = "ของเป้าหมาย", color = "Green", cmds = { "data.save" } },
	{ label = "กลับจุดเกิด", sub = "วาร์ปทันที", color = "Teal", cmds = { "player.spawn" } },
	{ label = "ตรวจสูตร Balance", sub = "เทียบ balance_sim", color = "Purple", cmds = { "debug.balancetest" } },
	{ label = "ปิดทุกโหมดแอดมิน", sub = "บิน/ทะลุ/อมตะ/ความเร็ว", color = "Slate", cmds = { "player.clearall" } },
	{ label = "เลเวลรอบ 50", sub = "มาใน Phase 2", phase = 2 },
	{ label = "เสกหีบ Mythic ×10", sub = "มาใน Phase 3", phase = 3 },
	{ label = "ฆ่าต้นไม้ทั้งโซน", sub = "มาใน Phase 2", phase = 2 },
	{ label = "โตทันทีทั้งสวน", sub = "มาใน Phase 4", phase = 4 },
	{ label = "ฝนดาวตก", sub = "มาใน Phase 4", phase = 4 },
	{ label = "Rebirth ทันที", sub = "มาใน Phase 8", phase = 8 },
}

local function color(name: string?): Color3
	return (name and (C :: any)[name]) or C.Blue
end

-- ===== โครง UI =====
local adminButtonHolder = New("Frame", {
	Name = "AdminButton",
	BackgroundTransparency = 1,
	AnchorPoint = Vector2.new(0, 1),
	Position = UDim2.new(0, 16, 1, -16),
	Size = UDim2.fromOffset(96, 120),
	Parent = gui,
}, { UIKit.List(Enum.FillDirection.Vertical, 6, Enum.HorizontalAlignment.Center) })

local toggleOpen: () -> ()

local adminButton = UIKit.Button({
	text = "ADMIN",
	color = C.Accent,
	textColor = C.TextDark,
	size = UDim2.fromOffset(92, 88),
	textSize = 20,
	radius = 22,
	stroke = 4,
	shadow = 5,
	layoutOrder = 1,
	onClick = function()
		toggleOpen()
	end,
})
adminButton.Parent = adminButtonHolder
local rankTag = UIKit.Label("", 12, {
	FontFace = UIKit.FontBold,
	TextColor3 = C.AccentText,
	TextXAlignment = Enum.TextXAlignment.Center,
	BackgroundTransparency = 0,
	BackgroundColor3 = C.Panel,
	Size = UDim2.fromOffset(92, 20),
	LayoutOrder = 2,
	Parent = adminButtonHolder,
}, nil)
New("UICorner", { CornerRadius = UDim.new(0, 8), Parent = rankTag })
UIKit.Stroke(2).Parent = rankTag

local panel = New("Frame", {
	Name = "Panel",
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.5),
	Size = UDim2.fromOffset(1000, 640),
	BackgroundColor3 = C.Panel,
	Visible = false,
	ClipsDescendants = true,
	Parent = gui,
}, { UIKit.Corner(24), UIKit.Stroke(4) })
local scale = New("UIScale", { Parent = panel })

local function updateScale()
	local vp = workspace.CurrentCamera.ViewportSize
	scale.Scale = math.min(1, (vp.X - 32) / 1000, (vp.Y - 32) / 640)
end
updateScale()
workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(updateScale)

-- แถบบน
local header = New("Frame", {
	Name = "Header",
	BackgroundColor3 = C.PanelDark,
	BorderSizePixel = 0,
	Size = UDim2.new(1, 0, 0, 68),
	Parent = panel,
}, {
	New("UIPadding", { PaddingLeft = UDim.new(0, 20), PaddingRight = UDim.new(0, 14) }),
	New("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		VerticalAlignment = Enum.VerticalAlignment.Center,
		Padding = UDim.new(0, 10),
		SortOrder = Enum.SortOrder.LayoutOrder,
	}),
})
New("Frame", { BackgroundColor3 = C.Outline, BorderSizePixel = 0, Position = UDim2.new(0, 0, 0, 68), Size = UDim2.new(1, 0, 0, 3), Parent = panel })
UIKit.Label("ADMIN PANEL", 24, { AutomaticSize = Enum.AutomaticSize.X, Size = UDim2.fromOffset(0, 40), TextWrapped = false, LayoutOrder = 1, Parent = header })
local rankBadge = UIKit.Label("", 13, {
	FontFace = UIKit.FontBold,
	TextColor3 = C.TextDark,
	BackgroundTransparency = 0,
	BackgroundColor3 = C.Accent,
	TextXAlignment = Enum.TextXAlignment.Center,
	AutomaticSize = Enum.AutomaticSize.X,
	Size = UDim2.fromOffset(0, 24),
	TextWrapped = false,
	LayoutOrder = 2,
	Parent = header,
})
New("UICorner", { CornerRadius = UDim.new(0, 8), Parent = rankBadge })
New("UIPadding", { PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10), Parent = rankBadge })
UIKit.Stroke(2).Parent = rankBadge
New("Frame", { BackgroundTransparency = 1, Size = UDim2.fromOffset(10, 10), LayoutOrder = 3, Parent = header }, {
	New("UIFlexItem", { FlexMode = Enum.UIFlexMode.Grow }),
})
UIKit.Label("ทำกับ:", 15, {
	FontFace = UIKit.FontBody,
	TextColor3 = C.TextDim,
	AutomaticSize = Enum.AutomaticSize.X,
	Size = UDim2.fromOffset(0, 30),
	TextWrapped = false,
	LayoutOrder = 4,
	Parent = header,
})
local targetChips: { [string]: Frame } = {}
local renderTargetChips: () -> ()
local openPlayerPicker: () -> ()
for i, t in { { "me", "ตัวเอง" }, { "player", "เลือกผู้เล่น" }, { "all", "ทุกคน" } } do
	local chip = UIKit.Button({
		text = t[2],
		color = C.Card,
		size = UDim2.fromOffset(t[1] == "player" and 150 or 92, 44),
		textSize = 15,
		radius = 12,
		shadow = 3,
		layoutOrder = 4 + i,
		onClick = function()
			if t[1] == "player" then
				openPlayerPicker()
			else
				state.target = { mode = t[1], userId = 0, name = "" }
				renderTargetChips()
			end
		end,
	})
	chip.Parent = header
	targetChips[t[1]] = chip
end
local closeButton = UIKit.Button({
	text = "X",
	color = C.Red,
	size = UDim2.fromOffset(48, 48),
	textSize = 20,
	radius = 12,
	shadow = 3,
	layoutOrder = 10,
	onClick = function()
		toggleOpen()
	end,
})
closeButton.Parent = header

-- ราง (แท็บ) ซ้าย + เนื้อหา
local body = New("Frame", {
	Name = "Body",
	BackgroundTransparency = 1,
	Position = UDim2.fromOffset(0, 71),
	Size = UDim2.new(1, 0, 1, -71),
	Parent = panel,
})
local rail = New("ScrollingFrame", {
	Name = "Rail",
	BackgroundColor3 = C.Rail,
	BorderSizePixel = 0,
	Size = UDim2.new(0, 210, 1, 0),
	CanvasSize = UDim2.new(),
	AutomaticCanvasSize = Enum.AutomaticSize.Y,
	ScrollBarThickness = 6,
	Parent = body,
}, { UIKit.Padding(10), UIKit.List(Enum.FillDirection.Vertical, 6) })
New("Frame", { BackgroundColor3 = C.Outline, BorderSizePixel = 0, Position = UDim2.fromOffset(210, 0), Size = UDim2.new(0, 3, 1, 0), Parent = body })

local content = New("ScrollingFrame", {
	Name = "Content",
	BackgroundTransparency = 1,
	BorderSizePixel = 0,
	Position = UDim2.fromOffset(213, 0),
	Size = UDim2.new(1, -213, 1, 0),
	CanvasSize = UDim2.new(),
	AutomaticCanvasSize = Enum.AutomaticSize.Y,
	ScrollBarThickness = 8,
	Parent = body,
}, {
	New("UIPadding", {
		PaddingTop = UDim.new(0, 16),
		PaddingBottom = UDim.new(0, 70),
		PaddingLeft = UDim.new(0, 20),
		PaddingRight = UDim.new(0, 20),
	}),
	UIKit.List(Enum.FillDirection.Vertical, 12),
})

-- ช่องข้อความรวม (ผล Export / ใส่ JSON / ข้อความประกาศ) — สร้างครั้งเดียว ย้ายไปแท็บที่ใช้
local textAreaHolder = New("Frame", {
	Name = "TextArea",
	BackgroundColor3 = C.Input,
	Size = UDim2.new(1, 0, 0, 170),
	LayoutOrder = 100,
}, { UIKit.Corner(12), UIKit.Stroke(3) })
local textBox = New("TextBox", {
	BackgroundTransparency = 1,
	Size = UDim2.new(1, -20, 1, -16),
	Position = UDim2.fromOffset(10, 8),
	ClearTextOnFocus = false,
	MultiLine = true,
	TextEditable = true,
	TextWrapped = true,
	TextXAlignment = Enum.TextXAlignment.Left,
	TextYAlignment = Enum.TextYAlignment.Top,
	TextSize = 14,
	FontFace = UIKit.FontBody,
	TextColor3 = C.Text,
	PlaceholderText = "ช่องข้อความ: ผลลัพธ์ Export จะขึ้นที่นี่ / วาง JSON เพื่อ Import / พิมพ์ข้อความประกาศหรือเหตุผล",
	PlaceholderColor3 = C.TextDim,
	Text = "",
	Parent = textAreaHolder,
})

local function toast(msg: string, ok: boolean)
	UIKit.Toast(panel, msg, ok and C.Green or C.Red)
end

-- ===== คุยกับ Server =====
local function invoke(request: any): any
	local ok, result = pcall(function()
		return Net.Function("AdminRun"):InvokeServer(request)
	end)
	if not ok then
		return { ok = false, msg = "ติดต่อ Server ไม่ได้: " .. tostring(result) }
	end
	return result
end

local function targetLabel(): string
	if state.target.mode == "me" then
		return "ตัวเอง"
	elseif state.target.mode == "all" then
		return "ทุกคน"
	end
	return state.target.name
end

local confirmDialog: (text: string, onYes: () -> ()) -> ()
local renderTab: () -> ()

local function handleResult(cmd: CommandInfo?, result: any)
	local suffix = (cmd and cmd.usesTarget) and (" → " .. targetLabel()) or ""
	toast((result.ok and "ทำแล้ว: " or "ไม่สำเร็จ: ") .. tostring(result.msg) .. suffix, result.ok)
	if result.data and type(result.data.text) == "string" then
		textBox.Text = result.data.text
	end
end

local function runCommand(id: string, args: { [string]: any }?, silent: boolean?): any
	local cmd = state.byId[id]
	if not cmd then
		toast("ยศของคุณใช้คำสั่งนี้ไม่ได้: " .. id, false)
		return nil
	end
	local function send(confirmed: number?)
		local result = invoke({ id = id, args = args or {}, target = state.target, confirmed = confirmed })
		if not silent then
			handleResult(cmd, result)
		end
		return result
	end
	if cmd.confirm >= 1 then
		confirmDialog("ยืนยัน \"" .. cmd.label .. "\" กับ " .. targetLabel() .. "?", function()
			if cmd.confirm >= 2 then
				confirmDialog("แน่ใจจริงๆ ใช่ไหม? ย้อนกลับไม่ได้", function()
					send(2)
				end)
			else
				send(1)
			end
		end)
		return nil
	end
	return send(nil)
end

-- ===== กล่องยืนยัน =====
local overlay = New("TextButton", {
	Name = "Confirm",
	AutoButtonColor = false,
	Text = "",
	BackgroundColor3 = Color3.new(0, 0, 0),
	BackgroundTransparency = 0.4,
	Size = UDim2.fromScale(1, 1),
	Visible = false,
	ZIndex = 40,
	Parent = panel,
})
local dialog = New("Frame", {
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.5),
	Size = UDim2.fromOffset(460, 210),
	BackgroundColor3 = C.Panel,
	ZIndex = 41,
	Parent = overlay,
}, { UIKit.Corner(18), UIKit.Stroke(4, C.Red), UIKit.Padding(18), UIKit.List(Enum.FillDirection.Vertical, 16, Enum.HorizontalAlignment.Center) })
local dialogText = UIKit.Label("", 20, { Size = UDim2.new(1, 0, 0, 70), TextXAlignment = Enum.TextXAlignment.Center, ZIndex = 42, LayoutOrder = 1, Parent = dialog })
local dialogButtons = New("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 56), LayoutOrder = 2, ZIndex = 42, Parent = dialog }, {
	UIKit.List(Enum.FillDirection.Horizontal, 14, Enum.HorizontalAlignment.Center),
})
local onDialogYes: (() -> ())? = nil
local yes = UIKit.Button({ text = "ยืนยัน", color = C.Red, size = UDim2.fromOffset(160, 54), layoutOrder = 1, onClick = function()
	overlay.Visible = false
	local fn = onDialogYes
	onDialogYes = nil
	if fn then
		fn()
	end
end })
yes.Parent = dialogButtons
local no = UIKit.Button({ text = "ยกเลิก", color = C.Slate, size = UDim2.fromOffset(160, 54), layoutOrder = 2, onClick = function()
	overlay.Visible = false
	onDialogYes = nil
end })
no.Parent = dialogButtons
for _, d in dialog:GetDescendants() do
	if d:IsA("GuiObject") then
		d.ZIndex = 42
	end
end

confirmDialog = function(text, onYes)
	dialogText.Text = text
	onDialogYes = onYes
	overlay.Visible = true
end

-- ===== เลือกผู้เล่น =====
local picker = New("Frame", {
	Name = "PlayerPicker",
	AnchorPoint = Vector2.new(1, 0),
	Position = UDim2.new(1, -70, 0, 70),
	Size = UDim2.fromOffset(260, 300),
	BackgroundColor3 = C.PanelDark,
	Visible = false,
	ZIndex = 30,
	Parent = panel,
}, { UIKit.Corner(14), UIKit.Stroke(3) })
local pickerList = New("ScrollingFrame", {
	BackgroundTransparency = 1,
	Size = UDim2.new(1, 0, 1, 0),
	CanvasSize = UDim2.new(),
	AutomaticCanvasSize = Enum.AutomaticSize.Y,
	ScrollBarThickness = 6,
	ZIndex = 31,
	Parent = picker,
}, { UIKit.Padding(10), UIKit.List(Enum.FillDirection.Vertical, 6) })

renderTargetChips = function()
	for mode, chip in targetChips do
		local on = state.target.mode == mode
		UIKit.SetButtonColor(chip, on and C.Accent or C.Card, on and C.TextDark or C.Text)
	end
	local playerChip = targetChips.player
	local label = playerChip:FindFirstChild("Button") and playerChip.Button:FindFirstChildOfClass("TextLabel")
	if label then
		label.Text = state.target.mode == "player" and state.target.name or "เลือกผู้เล่น"
	end
end

openPlayerPicker = function()
	if picker.Visible then
		picker.Visible = false
		return
	end
	for _, child in pickerList:GetChildren() do
		if child:IsA("Frame") then
			child:Destroy()
		end
	end
	for i, p in Players:GetPlayers() do
		local b = UIKit.Button({
			text = p.DisplayName .. " (@" .. p.Name .. ")",
			color = C.Card,
			size = UDim2.new(1, 0, 0, 46),
			textSize = 14,
			radius = 10,
			shadow = 3,
			layoutOrder = i,
			onClick = function()
				state.target = { mode = "player", userId = p.UserId, name = p.Name }
				picker.Visible = false
				renderTargetChips()
			end,
		})
		for _, d in b:GetDescendants() do
			if d:IsA("GuiObject") then
				d.ZIndex = 32
			end
		end
		b.ZIndex = 32
		b.Parent = pickerList
	end
	picker.Visible = true
end

-- ===== FPS overlay (ฝั่ง Client) =====
local fpsLabel = UIKit.Label("", 14, {
	Name = "FPS",
	FontFace = UIKit.FontBold,
	AnchorPoint = Vector2.new(1, 0),
	Position = UDim2.new(1, -12, 0, 60),
	Size = UDim2.fromOffset(220, 22),
	TextXAlignment = Enum.TextXAlignment.Right,
	Visible = false,
	Parent = gui,
})
UIKit.TextStroke(1.5).Parent = fpsLabel
local frames, lastFps = 0, os.clock()
RunService.RenderStepped:Connect(function()
	if not state.fpsOverlay then
		return
	end
	frames += 1
	local now = os.clock()
	if now - lastFps >= 0.5 then
		local fps = frames / (now - lastFps)
		frames, lastFps = 0, now
		local ping = math.floor(localPlayer:GetNetworkPing() * 1000)
		fpsLabel.Text = string.format("FPS %d · Ping %d ms · Mem %d MB", fps, ping, Stats:GetTotalMemoryUsageMb())
	end
end)

-- ===== ส่วนประกอบเนื้อหา =====
local function clearContent()
	textAreaHolder.Parent = nil
	for _, child in content:GetChildren() do
		if not child:IsA("UIListLayout") and not child:IsA("UIPadding") then
			child:Destroy()
		end
	end
end

local function sectionTitle(text: string, order: number)
	UIKit.Label(text, 14, {
		FontFace = UIKit.FontBody,
		TextColor3 = C.TextDim,
		Size = UDim2.new(1, 0, 0, 20),
		LayoutOrder = order,
		Parent = content,
	})
end

local function buttonGrid(order: number, columns: number, height: number): Frame
	return New("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		LayoutOrder = order,
		Parent = content,
	}, { UIKit.Grid(columns, height, 12) })
end

local function commandButtons(tab: string, order: number)
	local list = {}
	for _, cmd in state.commands do
		if cmd.tab == tab and not cmd.hidden then
			table.insert(list, cmd)
		end
	end
	if #list == 0 then
		return 0
	end
	local grid = buttonGrid(order, 3, 74)
	for i, cmd in list do
		local danger = cmd.confirm > 0 and cmd.color == "Red"
		local b = UIKit.Button({
			text = cmd.label,
			sub = cmd.sub,
			color = danger and C.Red or color(cmd.color),
			textSize = 17,
			radius = 16,
			stroke = 4,
			layoutOrder = i,
			onClick = function()
				local args: { [string]: any } = {}
				if cmd.id == "data.import" then
					args.json = textBox.Text
				elseif cmd.tab == "mod" then
					args.text = textBox.Text
				end
				runCommand(cmd.id, args)
			end,
		})
		b.Parent = grid
	end
	return #list
end

local function amountValue(): number
	return state.customAmount or AMOUNTS[state.amountIndex][2]
end

local function amountLabel(): string
	return NumberFormat.Short(amountValue())
end

-- ===== แต่ละแท็บ =====
local tabRenderers: { [string]: () -> () } = {}

tabRenderers.quick = function()
	sectionTitle("ปุ่มที่ใช้บ่อย กดครั้งเดียวจบ (ปุ่มสีเทา = ระบบยังไม่มา)", 1)
	local grid = buttonGrid(2, 3, 96)
	for i, q in QUICK do
		local available = q.cmds ~= nil
		if available then
			for _, id in q.cmds do
				if not state.byId[id] then
					available = false
				end
			end
		end
		local b = UIKit.Button({
			text = q.label,
			sub = q.sub,
			color = color(q.color),
			disabled = not available,
			textSize = 19,
			radius = 18,
			stroke = 4,
			shadow = 5,
			layoutOrder = i,
			onClick = function()
				for _, id in q.cmds do
					runCommand(id)
				end
			end,
		})
		b.Parent = grid
	end
end

tabRenderers.money = function()
	sectionTitle("เลือกจำนวน (หรือพิมพ์เอง เช่น 2.5Qa, 1e30) → กดปุ่มในแถวสกุลเงิน", 1)
	local chips = New("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 46),
		LayoutOrder = 2,
		Parent = content,
	}, { UIKit.List(Enum.FillDirection.Horizontal, 8) })
	local chipFrames: { Frame } = {}
	local amountBox: TextBox
	local function paint()
		for i, chip in chipFrames do
			local on = state.customAmount == nil and state.amountIndex == i
			UIKit.SetButtonColor(chip, on and C.Accent or C.Card, on and C.TextDark or C.Text)
		end
	end
	for i, a in AMOUNTS do
		local chip = UIKit.Button({
			text = a[1],
			color = C.Card,
			size = UDim2.fromOffset(70, 44),
			textSize = 16,
			radius = 10,
			shadow = 3,
			layoutOrder = i,
			onClick = function()
				state.amountIndex = i
				state.customAmount = nil
				amountBox.Text = ""
				paint()
			end,
		})
		chip.Parent = chips
		table.insert(chipFrames, chip)
	end
	local boxHolder = New("Frame", {
		BackgroundColor3 = C.Input,
		Size = UDim2.fromOffset(150, 40),
		LayoutOrder = 10,
		Parent = chips,
	}, { UIKit.Corner(10), UIKit.Stroke(3) })
	amountBox = New("TextBox", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, -16, 1, 0),
		Position = UDim2.fromOffset(8, 0),
		PlaceholderText = "พิมพ์จำนวน",
		PlaceholderColor3 = C.TextDim,
		Text = state.customAmount and NumberFormat.Short(state.customAmount) or "",
		TextColor3 = C.Text,
		TextSize = 16,
		FontFace = UIKit.FontBody,
		ClearTextOnFocus = false,
		Parent = boxHolder,
	})
	amountBox.FocusLost:Connect(function()
		local n = NumberFormat.Parse(amountBox.Text)
		if n and n >= 0 then
			state.customAmount = n
			amountBox.Text = NumberFormat.Short(n)
		else
			state.customAmount = nil
			amountBox.Text = ""
		end
		paint()
	end)
	paint()

	local rows = New("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		LayoutOrder = 3,
		Parent = content,
	}, { UIKit.List(Enum.FillDirection.Vertical, 10) })
	local valueLabels: { [string]: TextLabel } = {}
	for i, c in Currencies.List do
		local row = New("Frame", {
			BackgroundColor3 = C.Card,
			Size = UDim2.new(1, 0, 0, 58),
			LayoutOrder = i,
			Parent = rows,
		}, {
			UIKit.Corner(14),
			UIKit.Stroke(3),
			New("UIPadding", { PaddingLeft = UDim.new(0, 12), PaddingRight = UDim.new(0, 10) }),
			New("UIListLayout", {
				FillDirection = Enum.FillDirection.Horizontal,
				VerticalAlignment = Enum.VerticalAlignment.Center,
				Padding = UDim.new(0, 10),
				SortOrder = Enum.SortOrder.LayoutOrder,
			}),
		})
		New("Frame", { BackgroundColor3 = c.color, Size = UDim2.fromOffset(22, 22), LayoutOrder = 1, Parent = row }, { UIKit.Corner(6), UIKit.Stroke(2) })
		UIKit.Label(c.label, 17, { Size = UDim2.fromOffset(140, 30), TextWrapped = false, LayoutOrder = 2, Parent = row })
		valueLabels[c.id] = UIKit.Label("-", 17, {
			TextColor3 = C.AccentText,
			Size = UDim2.fromOffset(150, 30),
			TextWrapped = false,
			LayoutOrder = 3,
			Parent = row,
		})
		local actions = {
			{ "+ เสก", C.Green, "money.add", false },
			{ "ตั้งค่า", C.Blue, "money.set", false },
			{ "เป็น 0", C.Red, "money.set", true },
		}
		for j, a in actions do
			local b = UIKit.Button({
				text = a[1],
				color = a[2],
				size = UDim2.fromOffset(92, 44),
				textSize = 15,
				radius = 10,
				shadow = 3,
				layoutOrder = 3 + j,
				onClick = function()
					runCommand(a[3], { currency = c.id, amount = a[4] and 0 or amountValue() })
				end,
			})
			b.Parent = row
		end
	end
	-- ค่าปัจจุบันของตัวเอง (ดึงจาก HUD data ผ่าน Attribute ไม่ได้ → ขอจาก DataPatch)
	local conn
	local function refresh(data)
		if not rows.Parent then
			if conn then
				conn:Disconnect()
			end
			return
		end
		if data and data.Currencies then
			for id, label in valueLabels do
				label.Text = NumberFormat.Short(data.Currencies[id] or 0) .. " (ของคุณ)"
			end
		end
	end
	local cache: any = nil
	conn = Net.Event("DataPatch").OnClientEvent:Connect(function(patch)
		if patch.snapshot then
			cache = patch.snapshot
		elseif cache and patch.path then
			local parts = string.split(patch.path, ".")
			local node = cache
			for k = 1, #parts - 1 do
				node = node[parts[k]]
			end
			node[parts[#parts]] = patch.value
		end
		refresh(cache)
	end)
	task.spawn(function()
		cache = Net.Function("DataRequest"):InvokeServer()
		refresh(cache)
	end)
	commandButtons("money", 4)
end

local function textAreaTab(tab: string, hint: string)
	return function()
		sectionTitle(hint, 1)
		commandButtons(tab, 2)
		sectionTitle("ช่องข้อความ", 3)
		textAreaHolder.Parent = content
	end
end

tabRenderers.data = textAreaTab("data", "เซฟของเป้าหมาย (เลือกผู้เล่นทางขวาบน) · Import/รีเซ็ต ใช้ได้เฉพาะ Owner")
tabRenderers.mod = textAreaTab("mod", "พิมพ์ข้อความประกาศ/เหตุผลในช่องข้อความก่อนกด")

tabRenderers.player = function()
	sectionTitle("ทำกับเป้าหมายที่เลือกทางขวาบน · บินบนมือถือใช้จอยสติ๊ก", 1)
	commandButtons("player", 2)
end

tabRenderers.debug = function()
	sectionTitle("ข้อมูลเซิร์ฟและการทดสอบ", 1)
	local localGrid = buttonGrid(2, 3, 74)
	local fps = UIKit.Button({
		text = state.fpsOverlay and "ซ่อน FPS / Ping" or "แสดง FPS / Ping",
		sub = "เฉพาะจอคุณ",
		color = C.Teal,
		radius = 16,
		stroke = 4,
		onClick = function()
			state.fpsOverlay = not state.fpsOverlay
			fpsLabel.Visible = state.fpsOverlay
			renderTab()
		end,
	})
	fps.Parent = localGrid
	commandButtons("debug", 3)
	sectionTitle("Feature Flags (เปิด/ปิดสดในเซิร์ฟนี้)", 4)
	local flagGrid = buttonGrid(5, 4, 52)
	local result = invoke({ id = "debug.flags" })
	if result.ok and result.data then
		for i, f in result.data.flags do
			local b = UIKit.Button({
				text = f.name .. (f.enabled and "  ON" or "  OFF"),
				color = f.enabled and C.Green or C.Slate,
				textSize = 14,
				radius = 12,
				shadow = 3,
				layoutOrder = i,
				onClick = function()
					runCommand("debug.flag", { name = f.name, enabled = not f.enabled })
					task.wait(0.2)
					renderTab()
				end,
			})
			b.Parent = flagGrid
		end
	end
	sectionTitle("ผลลัพธ์", 6)
	textAreaHolder.LayoutOrder = 7
	textAreaHolder.Parent = content
end

local function comingSoon(tabInfo)
	local box = New("Frame", {
		BackgroundColor3 = C.Card,
		Size = UDim2.new(1, 0, 0, 150),
		LayoutOrder = 1,
		Parent = content,
	}, { UIKit.Corner(16), UIKit.Stroke(3), UIKit.Padding(20), UIKit.List(Enum.FillDirection.Vertical, 8) })
	UIKit.Label("ระบบนี้มาใน Phase " .. tabInfo.phase, 24, { TextColor3 = C.AccentText, Parent = box })
	UIKit.Label("ปุ่มทดสอบของแท็บ \"" .. tabInfo.label .. "\" จะขึ้นเองเมื่อระบบนี้ถูกสร้าง (ดู plan.md หัวข้อ 18.3)", 15, {
		FontFace = UIKit.FontBody,
		TextColor3 = C.TextDim,
		Size = UDim2.new(1, 0, 0, 44),
		Parent = box,
	})
end

-- ===== ราง (แท็บ) =====
local tabButtons: { [string]: Frame } = {}
local contentTitle: TextLabel

local function paintTabs()
	for id, b in tabButtons do
		local on = id == state.tab
		UIKit.SetButtonColor(b, on and C.Accent or C.Card, on and C.TextDark or C.Text)
	end
end

renderTab = function()
	clearContent()
	local info
	for _, t in AdminTabs do
		if t.id == state.tab then
			info = t
		end
	end
	local titleRow = New("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 40),
		LayoutOrder = 0,
		Parent = content,
	}, {
		New("UIListLayout", {
			FillDirection = Enum.FillDirection.Horizontal,
			VerticalAlignment = Enum.VerticalAlignment.Center,
			Padding = UDim.new(0, 10),
			SortOrder = Enum.SortOrder.LayoutOrder,
		}),
	})
	contentTitle = UIKit.Label(info and info.label or state.tab, 24, {
		AutomaticSize = Enum.AutomaticSize.X,
		Size = UDim2.fromOffset(0, 36),
		TextWrapped = false,
		LayoutOrder = 1,
		Parent = titleRow,
	})
	New("Frame", { BackgroundTransparency = 1, Size = UDim2.fromOffset(10, 10), LayoutOrder = 2, Parent = titleRow }, {
		New("UIFlexItem", { FlexMode = Enum.UIFlexMode.Grow }),
	})
	local cmdHolder = New("Frame", {
		BackgroundColor3 = C.Input,
		Size = UDim2.fromOffset(280, 38),
		LayoutOrder = 3,
		Parent = titleRow,
	}, { UIKit.Corner(10), UIKit.Stroke(3) })
	local cmdBox = New("TextBox", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, -16, 1, 0),
		Position = UDim2.fromOffset(8, 0),
		PlaceholderText = "พิมพ์คำสั่ง เช่น /give coins 1e15 me",
		PlaceholderColor3 = C.TextDim,
		Text = "",
		TextColor3 = C.Text,
		TextSize = 14,
		FontFace = UIKit.FontBody,
		TextXAlignment = Enum.TextXAlignment.Left,
		ClearTextOnFocus = false,
		Parent = cmdHolder,
	})
	cmdBox.FocusLost:Connect(function(enter)
		if enter and cmdBox.Text ~= "" then
			local text = cmdBox.Text
			cmdBox.Text = ""
			local parse = require(script.Parent.CommandParser)
			local ok, msg = parse(text, state, runCommand)
			if not ok then
				toast(msg, false)
			end
		end
	end)

	local renderer = tabRenderers[state.tab]
	if renderer then
		renderer()
	elseif info then
		local count = 0
		for _, c in state.commands do
			if c.tab == state.tab and not c.hidden then
				count += 1
			end
		end
		if count > 0 then
			commandButtons(state.tab, 1)
		else
			comingSoon(info)
		end
	end
	content.CanvasPosition = Vector2.zero
end

for i, t in AdminTabs do
	local b = UIKit.Button({
		text = t.label,
		color = C.Card,
		size = UDim2.new(1, 0, 0, 44),
		textSize = 15,
		radius = 12,
		shadow = 3,
		layoutOrder = i,
		onClick = function()
			state.tab = t.id
			picker.Visible = false
			paintTabs()
			renderTab()
		end,
	})
	-- จุดสีประจำแท็บ
	local dot = New("Frame", {
		BackgroundColor3 = t.color,
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 10, 0.5, 0),
		Size = UDim2.fromOffset(14, 14),
		Parent = b:FindFirstChild("Button"),
	}, { UIKit.Corner(4), UIKit.Stroke(2) })
	dot.ZIndex = 2
	local label = (b :: any).Button:FindFirstChildOfClass("TextLabel")
	if label then
		label.TextXAlignment = Enum.TextXAlignment.Left
		label.Position = UDim2.fromOffset(32, 0)
		label.Size = UDim2.new(1, -36, 1, 0)
	end
	b.Name = "Tab_" .. t.id
	b.Parent = rail
	tabButtons[t.id] = b
end

-- ===== เปิด/ปิด =====
local initialized = false
local function refreshCommands(): boolean
	local result = invoke({ id = "__init" })
	if not result.ok then
		toast(tostring(result.msg), false)
		return false
	end
	state.commands = result.commands
	state.byId = {}
	for _, c in result.commands do
		state.byId[c.id] = c
	end
	state.levelName = result.levelName
	rankBadge.Text = string.upper(result.levelName)
	rankTag.Text = string.upper(result.levelName)
	return true
end

-- ซ่อนหน้าต่างแชทตอนเปิดแผง (แชทของ Roblox ทับฝั่งซ้ายของแผงและกินการกด)
local TextChatService = game:GetService("TextChatService")
local chatWindow = TextChatService:FindFirstChildOfClass("ChatWindowConfiguration")
local chatWasEnabled = chatWindow and chatWindow.Enabled

toggleOpen = function()
	state.open = not state.open
	panel.Visible = state.open
	picker.Visible = false
	if chatWindow then
		if state.open then
			chatWasEnabled = chatWindow.Enabled
			chatWindow.Enabled = false
		else
			chatWindow.Enabled = chatWasEnabled
		end
	end
	if state.open then
		if not initialized then
			initialized = refreshCommands()
		end
		paintTabs()
		renderTargetChips()
		renderTab()
	end
end

UserInputService.InputBegan:Connect(function(input, processed)
	if processed then
		return
	end
	if input.KeyCode == Enum.KeyCode.F2 then
		toggleOpen()
	end
end)

task.spawn(function()
	if refreshCommands() then
		initialized = true
	end
end)
