--!strict
-- ชิ้นส่วน UI ใช้ซ้ำ (plan.md หัวข้อ 15.6) — สไตล์เกม: ขอบดำหนา มุมมน เงาล่าง สีสด
-- ใช้ได้เฉพาะฝั่ง Client

local TweenService = game:GetService("TweenService")

local UIKit = {}

UIKit.Colors = table.freeze({
	Outline = Color3.fromRGB(11, 15, 24),
	Panel = Color3.fromRGB(30, 36, 51),
	PanelDark = Color3.fromRGB(20, 25, 37),
	Rail = Color3.fromRGB(23, 28, 41),
	Card = Color3.fromRGB(39, 48, 68),
	Input = Color3.fromRGB(15, 20, 32),
	Text = Color3.fromRGB(255, 255, 255),
	TextDim = Color3.fromRGB(203, 213, 225),
	TextDark = Color3.fromRGB(26, 26, 26),
	Accent = Color3.fromRGB(250, 204, 21),
	AccentText = Color3.fromRGB(253, 230, 138),
	Green = Color3.fromRGB(21, 128, 61),
	Blue = Color3.fromRGB(29, 78, 216),
	Red = Color3.fromRGB(185, 28, 28),
	Purple = Color3.fromRGB(109, 40, 217),
	Orange = Color3.fromRGB(180, 83, 9),
	Teal = Color3.fromRGB(15, 118, 110),
	Pink = Color3.fromRGB(157, 23, 77),
	Slate = Color3.fromRGB(51, 65, 85),
	Disabled = Color3.fromRGB(71, 85, 105),
})
local C = UIKit.Colors

UIKit.Font = Font.new("rbxasset://fonts/families/FredokaOne.json", Enum.FontWeight.Regular)
UIKit.FontBody = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Medium)
UIKit.FontBold = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Bold)

type Props = { [string]: any }

function UIKit.New(className: string, props: Props?, children: { Instance }?): any
	local inst = Instance.new(className)
	if props then
		for k, v in props do
			if k ~= "Parent" then
				(inst :: any)[k] = v
			end
		end
	end
	if children then
		for _, child in children do
			child.Parent = inst
		end
	end
	if props and props.Parent then
		inst.Parent = props.Parent
	end
	return inst
end
local New = UIKit.New

function UIKit.Corner(radius: number): UICorner
	return New("UICorner", { CornerRadius = UDim.new(0, radius) })
end

function UIKit.Stroke(thickness: number, color: Color3?): UIStroke
	return New("UIStroke", {
		Thickness = thickness,
		Color = color or C.Outline,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		LineJoinMode = Enum.LineJoinMode.Round,
	})
end

function UIKit.TextStroke(thickness: number?): UIStroke
	return New("UIStroke", { Thickness = thickness or 1.5, Color = C.Outline, ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual })
end

function UIKit.Padding(all: number): UIPadding
	local u = UDim.new(0, all)
	return New("UIPadding", { PaddingTop = u, PaddingBottom = u, PaddingLeft = u, PaddingRight = u })
end

function UIKit.List(direction: Enum.FillDirection, gap: number, align: Enum.HorizontalAlignment?): UIListLayout
	return New("UIListLayout", {
		FillDirection = direction,
		Padding = UDim.new(0, gap),
		SortOrder = Enum.SortOrder.LayoutOrder,
		HorizontalAlignment = align or Enum.HorizontalAlignment.Left,
		VerticalAlignment = Enum.VerticalAlignment.Top,
	})
end

function UIKit.Grid(columns: number, cellHeight: number, gap: number): UIGridLayout
	return New("UIGridLayout", {
		CellPadding = UDim2.fromOffset(gap, gap),
		CellSize = UDim2.new(1 / columns, -gap * (columns - 1) / columns, 0, cellHeight),
		SortOrder = Enum.SortOrder.LayoutOrder,
	})
end

function UIKit.Label(text: string, size: number, props: Props?): TextLabel
	local p: Props = {
		BackgroundTransparency = 1,
		Text = text,
		TextSize = size,
		FontFace = UIKit.Font,
		TextColor3 = C.Text,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Center,
		Size = UDim2.new(1, 0, 0, size + 8),
		TextWrapped = true,
	}
	if props then
		for k, v in props do
			p[k] = v
		end
	end
	local label = New("TextLabel", p)
	return label
end

export type ButtonOptions = {
	text: string,
	sub: string?,
	color: Color3?,
	textColor: Color3?,
	size: UDim2?,
	textSize: number?,
	radius: number?,
	stroke: number?,
	shadow: number?,
	layoutOrder: number?,
	disabled: boolean?,
	onClick: (() -> ())?,
}

-- ปุ่มสไตล์เกม: มีเงาด้านล่าง กดแล้วยุบลง
function UIKit.Button(o: ButtonOptions): (Frame, TextButton)
	local shadow = o.shadow or 4
	local radius = o.radius or 14
	local holder = New("Frame", {
		BackgroundTransparency = 1,
		Size = o.size or UDim2.new(1, 0, 0, 56),
		LayoutOrder = o.layoutOrder or 0,
	})
	local base = New("Frame", {
		Name = "Shadow",
		BackgroundColor3 = C.Outline,
		Size = UDim2.new(1, 0, 1, -shadow),
		Position = UDim2.fromOffset(0, shadow),
		Parent = holder,
	}, { UIKit.Corner(radius) })
	local color = if o.disabled then C.Disabled else (o.color or C.Green)
	local button = New("TextButton", {
		Name = "Button",
		AutoButtonColor = false,
		BackgroundColor3 = color,
		Size = UDim2.new(1, 0, 1, -shadow),
		Text = "",
		Parent = holder,
	}, { UIKit.Corner(radius), UIKit.Stroke(o.stroke or 3) })
	local textColor = o.textColor or C.Text
	if o.sub then
		New("Frame", {
			BackgroundTransparency = 1,
			Size = UDim2.fromScale(1, 1),
			Parent = button,
		}, {
			UIKit.List(Enum.FillDirection.Vertical, 0, Enum.HorizontalAlignment.Center),
			New("UIPadding", { PaddingLeft = UDim.new(0, 6), PaddingRight = UDim.new(0, 6) }),
			New("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0.5, -16), LayoutOrder = 0 }),
			UIKit.Label(o.text, o.textSize or 18, {
				TextColor3 = textColor,
				TextXAlignment = Enum.TextXAlignment.Center,
				Size = UDim2.new(1, 0, 0, (o.textSize or 18) + 4),
				LayoutOrder = 1,
				TextWrapped = false,
				TextScaled = false,
			}),
			UIKit.Label(o.sub, 12, {
				FontFace = UIKit.FontBody,
				TextColor3 = Color3.fromRGB(241, 245, 249),
				TextXAlignment = Enum.TextXAlignment.Center,
				Size = UDim2.new(1, 0, 0, 16),
				LayoutOrder = 2,
			}),
		})
	else
		UIKit.Label(o.text, o.textSize or 17, {
			TextColor3 = textColor,
			TextXAlignment = Enum.TextXAlignment.Center,
			Size = UDim2.fromScale(1, 1),
			Parent = button,
		})
	end
	local pressed = false
	button.MouseButton1Down:Connect(function()
		pressed = true
		button.Position = UDim2.fromOffset(0, shadow - 1)
	end)
	local function release()
		if pressed then
			pressed = false
			button.Position = UDim2.fromOffset(0, 0)
		end
	end
	button.MouseButton1Up:Connect(release)
	button.MouseLeave:Connect(release)
	button.Activated:Connect(function()
		if o.disabled or not o.onClick then
			return
		end
		o.onClick()
	end)
	return holder, button
end

-- เปลี่ยนสีปุ่ม (ใช้กับปุ่มแบบเลือกได้ เช่น ชิป)
function UIKit.SetButtonColor(holder: Frame, color: Color3, textColor: Color3?)
	local button = holder:FindFirstChild("Button") :: TextButton?
	if not button then
		return
	end
	button.BackgroundColor3 = color
	for _, d in button:GetDescendants() do
		if d:IsA("TextLabel") and textColor then
			d.TextColor3 = textColor
		end
	end
end

-- กล่องเม็ดยา (เช่น สกุลเงินบน HUD)
function UIKit.Pill(color: Color3, text: string, props: Props?): (Frame, TextLabel)
	local p: Props = {
		BackgroundColor3 = C.Panel,
		Size = UDim2.fromOffset(170, 40),
		AutomaticSize = Enum.AutomaticSize.X,
	}
	if props then
		for k, v in props do
			p[k] = v
		end
	end
	local pill = New("Frame", p, {
		UIKit.Corner(20),
		UIKit.Stroke(3),
		New("UIPadding", { PaddingLeft = UDim.new(0, 6), PaddingRight = UDim.new(0, 14) }),
		UIKit.List(Enum.FillDirection.Horizontal, 8),
	})
	New("Frame", {
		BackgroundColor3 = color,
		Size = UDim2.fromOffset(26, 26),
		Position = UDim2.fromScale(0, 0.5),
		LayoutOrder = 0,
		Parent = pill,
	}, { UIKit.Corner(13), UIKit.Stroke(2) })
	local layout = pill:FindFirstChildOfClass("UIListLayout") :: UIListLayout
	layout.VerticalAlignment = Enum.VerticalAlignment.Center
	local label = UIKit.Label(text, 20, {
		AutomaticSize = Enum.AutomaticSize.X,
		Size = UDim2.fromOffset(0, 28),
		TextWrapped = false,
		LayoutOrder = 1,
		Parent = pill,
	})
	return pill, label
end

-- แถบแจ้งผลด้านล่าง (หายเองใน 3 วิ)
function UIKit.Toast(parent: Instance, text: string, color: Color3?)
	local old = parent:FindFirstChild("Toast")
	if old then
		old:Destroy()
	end
	local toast = New("TextLabel", {
		Name = "Toast",
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -16),
		Size = UDim2.fromOffset(0, 40),
		AutomaticSize = Enum.AutomaticSize.X,
		BackgroundColor3 = C.Input,
		Text = text,
		TextSize = 16,
		FontFace = UIKit.FontBody,
		TextColor3 = C.Text,
		ZIndex = 50,
		Parent = parent,
	}, {
		UIKit.Corner(12),
		UIKit.Stroke(3, color or C.Green),
		New("UIPadding", { PaddingLeft = UDim.new(0, 16), PaddingRight = UDim.new(0, 16) }),
	})
	task.delay(3, function()
		if toast.Parent then
			local t = TweenService:Create(toast, TweenInfo.new(0.3), { TextTransparency = 1, BackgroundTransparency = 1 })
			t:Play()
			t.Completed:Wait()
			toast:Destroy()
		end
	end)
end

return UIKit
