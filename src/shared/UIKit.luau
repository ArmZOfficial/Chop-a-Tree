--!strict
-- ชิ้นส่วน UI ใช้ซ้ำ (plan.md หัวข้อ 15.6) — สไตล์เกม: ขอบดำหนา มุมมน เงาล่าง สีสด
-- ใช้ได้เฉพาะฝั่ง Client

local TweenService = game:GetService("TweenService")

local UIKit = {}

UIKit.Colors = table.freeze({
	Outline = Color3.fromRGB(49, 30, 20),
	Panel = Color3.fromRGB(116, 59, 37),
	PanelDark = Color3.fromRGB(78, 37, 24),
	Rail = Color3.fromRGB(120, 78, 45),
	Card = Color3.fromRGB(145, 77, 49),
	Input = Color3.fromRGB(73, 35, 25),
	Text = Color3.fromRGB(255, 248, 228),
	TextDim = Color3.fromRGB(239, 208, 176),
	TextDark = Color3.fromRGB(26, 26, 26),
	Accent = Color3.fromRGB(153, 235, 58),
	AccentText = Color3.fromRGB(153, 235, 58),
	Green = Color3.fromRGB(105, 198, 52),
	Blue = Color3.fromRGB(81, 165, 235),
	Red = Color3.fromRGB(239, 108, 82),
	Purple = Color3.fromRGB(180, 133, 231),
	Orange = Color3.fromRGB(241, 170, 64),
	Teal = Color3.fromRGB(72, 189, 163),
	Pink = Color3.fromRGB(232, 142, 169),
	Slate = Color3.fromRGB(173, 153, 123),
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
		CellSize = UDim2.new(1 / columns, -gap * (columns - 1) / columns - 2, 0, cellHeight),
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
	UIKit.TextStroke(1.5).Parent=label
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
		Selectable = true,
		BackgroundColor3 = color,
		Size = UDim2.new(1, 0, 1, -shadow),
		Text = "",
		Parent = holder,
	}, { UIKit.Corner(radius), UIKit.Stroke(o.stroke or 3) })
	New("UIGradient", {Rotation=90,Color=ColorSequence.new({ColorSequenceKeypoint.new(0,Color3.new(1,1,1)),ColorSequenceKeypoint.new(1,Color3.fromRGB(194,178,153))}),Parent=button})
	local textColor = o.textColor or Color3.new(1,1,1)
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
		BackgroundColor3 = C.Outline,
		Text = text,
		TextSize = 16,
		FontFace = UIKit.FontBody,
		TextColor3 = Color3.new(1,1,1),
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

-- Common woodland window and existing atlas artwork, shared by every system.
function UIKit.Icon(parent: Instance, id: string, props: Props?): ImageLabel?
 local atlas=require(game.ReplicatedStorage.Shared.Config.UIIcons)
 local r=atlas.Rects[id];if not r then return nil end
 local p: Props={Name="Art",BackgroundTransparency=1,Size=UDim2.fromOffset(64,64),ScaleType=Enum.ScaleType.Fit,Image="rbxassetid://"..atlas.AssetId,ImageRectOffset=Vector2.new(r[1],r[2]),ImageRectSize=Vector2.new(r[3],r[4]),Parent=parent}
 if props then for k,v in props do p[k]=v end end
 return New("ImageLabel",p)
end
function UIKit.Window(panel: GuiObject, title: string?, symbol: string?)
 if panel:FindFirstChild("WindowRim") then return end
 panel.BackgroundColor3=C.Panel
 for _,child in panel:GetChildren() do if child:IsA("GuiObject") then child.ZIndex=math.max(2,child.ZIndex) end end
 New("Frame",{Name="WindowRim",BackgroundTransparency=1,Position=UDim2.fromOffset(5,5),Size=UDim2.new(1,-10,1,-10),ZIndex=1,Parent=panel},{UIKit.Corner(13),UIKit.Stroke(6,Color3.fromRGB(183,108,71))})
 for i=1,7 do
  New("Frame",{Name="Grain",BorderSizePixel=0,BackgroundColor3=Color3.fromRGB(222,151,105),BackgroundTransparency=.92,Position=UDim2.new(0,3,i/8,0),Size=UDim2.new(1,-6,0,2),Rotation=i%2==0 and 3 or -2,ZIndex=1,Parent=panel})
 end
 if not title then return end
 local original=panel:FindFirstChild("Title") or panel:FindFirstChildWhichIsA("TextLabel")
 if original then original.Visible=false end
 local heading=UIKit.Label(title,30,{Name="WindowHeading",Position=UDim2.fromOffset(58,-19),Size=UDim2.new(1,-125,0,44),TextColor3=Color3.fromRGB(255,217,111),ZIndex=5,Parent=panel});UIKit.TextStroke(3).Parent=heading
 if original then original:GetPropertyChangedSignal("Text"):Connect(function() heading.Text=original.Text end) end
 UIKit.Icon(panel,symbol or "book",{Position=UDim2.fromOffset(-5,-29),Size=UDim2.fromOffset(60,60),ZIndex=5})
 local close=UIKit.Button({text="×",textSize=38,color=C.Red,radius=10,stroke=4,size=UDim2.fromOffset(54,54),onClick=function() panel.Visible=false end});close.Name="WindowClose";close.Position=UDim2.new(1,-42,0,-27);close.ZIndex=6;close.Parent=panel
 for _,v in close:GetDescendants() do if v:IsA("GuiObject") then v.ZIndex=6 end end
end

return UIKit
