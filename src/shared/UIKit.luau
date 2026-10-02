--!strict
-- ชิ้นส่วน UI ใช้ซ้ำ (plan.md หัวข้อ 15.6) — สไตล์เกม: ขอบดำหนา มุมมน เงาล่าง สีสด
-- ใช้ได้เฉพาะฝั่ง Client

local TweenService = game:GetService("TweenService")

local UIKit = {}
local Art = require(script.Parent.UIArt)

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
	if inst:IsA("GuiObject") then inst.ZIndex=3 end
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


function UIKit.Art(parent: Instance, atlas: string, sprite: string, props: Props?): ImageLabel?
 local data=Art.Data[atlas];if not data or not data.sprites[sprite] then return nil end
 local asset=Art.Assets[atlas]
 local gui=Art.Create("ImageLabel",atlas,sprite,asset.id,asset.size,parent)
 gui.Name="Illustration";gui.Active=false;gui.ZIndex=3
 if props then for k,v in props do (gui :: any)[k]=v end end
 return gui
end
-- Nine-slice an atlas crop so corners keep their drawn proportions at any size.
-- `inset` is the border as a fraction of the crop's short side; border scale follows the image height.
local SLICE={cards=.2,controls=.32,chrome=.3}
local ICON={close=true,delete=true,badgeClaimed=true} -- drawn symbols must keep their proportions
function UIKit.Slice(image: ImageLabel, inset: number)
 local rs=image.ImageRectSize;local i=math.floor(math.min(rs.X,rs.Y)*inset)
 image.ScaleType=Enum.ScaleType.Slice;image.SliceCenter=Rect.new(i,i,rs.X-i,rs.Y-i)
 local function fit() local a=image.AbsoluteSize;local m=math.min(a.X,a.Y);local cap=image.Parent and image.Parent:GetAttribute("SliceMax") or 2;if m>0 then image.SliceScale=math.clamp(m/math.min(rs.X,rs.Y),.05,cap) end end
 image:GetPropertyChangedSignal("AbsoluteSize"):Connect(fit);fit()
end
function UIKit.Skin(parent: GuiObject, atlas: string, sprite: string): ImageLabel?
 local old=parent:FindFirstChild("SurfaceArt")
 if old and old:GetAttribute("Sprite")==atlas.."/"..sprite then return old :: ImageLabel end
 if old then old:Destroy() end
 local image=UIKit.Art(parent,atlas,sprite,{Name="SurfaceArt",ZIndex=2,Size=UDim2.fromScale(1,1),ScaleType=Enum.ScaleType.Stretch})
 if image then
  image:SetAttribute("Sprite",atlas.."/"..sprite)
  local square=atlas=="chrome" and sprite:sub(1,3)=="nav"
  if SLICE[atlas] and not square and not ICON[sprite] then UIKit.Slice(image,SLICE[atlas]) end
  parent.BackgroundTransparency=1
  local stroke=parent:FindFirstChildOfClass("UIStroke");if stroke then stroke.Enabled=false end
  local gradient=parent:FindFirstChildOfClass("UIGradient");if gradient then gradient.Enabled=false end
  local pad=parent:FindFirstChildOfClass("UIPadding")
  if pad then image.Position=UDim2.fromOffset(-pad.PaddingLeft.Offset,-pad.PaddingTop.Offset);image.Size=UDim2.new(1,pad.PaddingLeft.Offset+pad.PaddingRight.Offset,1,pad.PaddingTop.Offset+pad.PaddingBottom.Offset) end
 end
 return image
end
local function buttonSprite(color: Color3): string
 if color==C.Disabled or color==C.Slate then return "buttonDisabled" end
 if color==C.Red then return "buttonRed" end
 if color==C.Orange then return "buttonGold" end
 return "buttonGreen"
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
	UIKit.Skin(button,"controls",buttonSprite(color));base.Visible=false
	for _,l in button:GetDescendants() do if l:IsA("UIStroke") and l.Parent:IsA("TextLabel") then l.Thickness=math.max(2,(o.textSize or 17)/10) end end
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
	if not holder:GetAttribute("ArtCard") then UIKit.Skin(button,"controls",buttonSprite(color)) end
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
-- Symbol is a woodland icon id, or "atlas/sprite" for UIArt illustrations.
function UIKit.Symbol(parent: Instance, symbol: string, props: Props?): ImageLabel?
 local atlas,sprite=string.match(symbol,"^(%w+)/([%w_]+)$")
 if atlas then return UIKit.Art(parent,atlas,sprite,props) end
 return UIKit.Icon(parent,symbol,props)
end
local Heading=Color3.fromRGB(255,255,255)
-- Concept window: wood frame, big outlined title (optionally on a protruding plaque) and red X.
-- opts.plaque = plaque width; opts.center centres the plaque over the window.
function UIKit.Window(panel: GuiObject, title: string?, symbol: string?, opts: Props?)
 if panel:FindFirstChild("SurfaceArt") then return end
 local surface=UIKit.Skin(panel,"window","wideWindow");if surface then surface.ZIndex=1 end
 if not title then return end
 local o=opts or {}
 local pad=panel:FindFirstChildOfClass("UIPadding");local px,py=pad and pad.PaddingLeft.Offset or 0,pad and pad.PaddingTop.Offset or 0
 local original=panel:FindFirstChild("Title") or panel:FindFirstChildWhichIsA("TextLabel")
 if original then original.Visible=false end
 local host: GuiObject=panel
 local heading
 if o.plaque then
  local w=o.plaque
  host=New("Frame",{Name="HeaderPlaque",BackgroundTransparency=1,AnchorPoint=Vector2.new(o.center and .5 or 0,0),Position=o.center and UDim2.new(.5,-px,0,-34-py) or UDim2.fromOffset(22-px,-32-py),Size=UDim2.fromOffset(w,108),ZIndex=4,Parent=panel})
  UIKit.Skin(host,"chrome","headerPlaque")
  UIKit.Symbol(host,symbol or "book",{Name="TitleIcon",AnchorPoint=Vector2.new(0,.5),Position=UDim2.new(0,14,.5,-2),Size=UDim2.fromOffset(92,92),ZIndex=5})
  heading=UIKit.Label(title,56,{Name="WindowHeading",Position=UDim2.fromOffset(108,6),Size=UDim2.new(1,-120,1,-16),TextXAlignment=Enum.TextXAlignment.Center,TextScaled=true,TextColor3=Heading,ZIndex=5,Parent=host})
  New("UITextSizeConstraint",{MaxTextSize=58,Parent=heading})
 else
  UIKit.Symbol(panel,symbol or "book",{Name="TitleIcon",AnchorPoint=Vector2.new(0,.5),Position=UDim2.new(0,30-px,.105,-py-2),Size=UDim2.fromOffset(78,78),ZIndex=5})
  heading=UIKit.Label(title,46,{Name="WindowHeading",AnchorPoint=Vector2.new(0,.5),Position=UDim2.new(0,112-px,.105,-py-2),Size=UDim2.new(.62,-112,0,64),TextColor3=Heading,TextWrapped=false,TextTruncate=Enum.TextTruncate.AtEnd,ZIndex=5,Parent=panel})
 end
 heading:FindFirstChildOfClass("UIStroke").Thickness=4
 if original then original:GetPropertyChangedSignal("Text"):Connect(function() heading.Text=original.Text end) end
 local close=UIKit.Button({text="×",textSize=38,color=C.Red,radius=10,stroke=4,size=UDim2.fromOffset(70,70),onClick=function() panel.Visible=false end});close.Name="WindowClose";close.AnchorPoint=Vector2.new(.5,.5);close.Position=UDim2.new(1,px-30,0,-py+18);close.ZIndex=6;close.Parent=panel
 UIKit.Skin(close.Button,"controls","close");close.Button:FindFirstChildWhichIsA("TextLabel",true).Visible=false
 for _,v in close:GetDescendants() do if v:IsA("GuiObject") then v.ZIndex=6 end end
 return heading
end

-- Wooden tab: normal / gold / green states, optional icon and live label.
function UIKit.Tab(o: Props): TextButton
 local tab=New("TextButton",{Name=o.name or "Tab",AutoButtonColor=false,Text="",BackgroundTransparency=1,Size=o.size or UDim2.fromOffset(200,54),Position=o.position or UDim2.new(),LayoutOrder=o.layoutOrder or 0,Parent=o.parent})
 local row=New("Frame",{Name="Content",BackgroundTransparency=1,Size=UDim2.new(1,0,1,-4),ZIndex=3,Parent=tab},{New("UIListLayout",{FillDirection=Enum.FillDirection.Horizontal,HorizontalAlignment=Enum.HorizontalAlignment.Center,VerticalAlignment=Enum.VerticalAlignment.Center,Padding=UDim.new(0,10),SortOrder=Enum.SortOrder.LayoutOrder})})
 if o.icon then UIKit.Symbol(row,o.icon,{Name="TabIcon",Size=UDim2.fromOffset(o.iconSize or 38,o.iconSize or 38),LayoutOrder=1,ZIndex=3}) end
 UIKit.Label(o.text,o.textSize or 26,{Name="TabLabel",AutomaticSize=Enum.AutomaticSize.X,Size=UDim2.fromOffset(0,40),TextWrapped=false,LayoutOrder=2,ZIndex=3,Parent=row}):FindFirstChildOfClass("UIStroke").Thickness=2.5
 tab.Activated:Connect(function() if o.onClick then o.onClick() end end)
 UIKit.SetTab(tab,o.state)
 return tab
end
function UIKit.SetTab(tab: GuiObject, state: string?)
 UIKit.Skin(tab,"chrome",state=="gold" and "tabGold" or state=="green" and "tabGreen" or "tabNormal")
 local label=tab:FindFirstChild("TabLabel",true);if label then label.TextColor3=state and Color3.new(1,1,1) or Color3.fromRGB(228,206,176) end
end

-- Dark wooden strip for hints/stats; returns the frame and its live label.
function UIKit.InfoBar(parent: Instance, text: string, props: Props?, symbol: string?): (Frame, TextLabel)
 local p: Props={Name="InfoBar",BackgroundTransparency=1,Size=UDim2.new(1,0,0,52),Parent=parent}
 if props then for k,v in props do p[k]=v end end
 local bar=New("Frame",p);UIKit.Skin(bar,"chrome","infoRow")
 local left=18
 if symbol then UIKit.Symbol(bar,symbol,{Name="BarIcon",AnchorPoint=Vector2.new(0,.5),Position=UDim2.new(0,12,.5,0),Size=UDim2.fromOffset(40,40),ZIndex=3});left=62 end
 local label=UIKit.Label(text,20,{Name="BarLabel",Position=UDim2.fromOffset(left,0),Size=UDim2.new(1,-left-14,1,0),TextWrapped=true,ZIndex=3,Parent=bar})
 return bar,label
end

-- Stat capsule (icon + caption + value) used in window headers.
function UIKit.Capsule(parent: Instance, symbol: string?, caption: string, props: Props?): (Frame, TextLabel)
 local p: Props={Name="Capsule",BackgroundTransparency=1,Size=UDim2.fromOffset(170,60),Parent=parent}
 if props then for k,v in props do p[k]=v end end
 local cap=New("Frame",p);UIKit.Skin(cap,"chrome","currencyCapsule")
 local left=16
 if symbol then UIKit.Symbol(cap,symbol,{Name="CapsuleIcon",AnchorPoint=Vector2.new(0,.5),Position=UDim2.new(0,10,.5,0),Size=UDim2.fromOffset(42,42),ZIndex=3});left=58 end
 UIKit.Label(caption,15,{Name="Caption",Position=UDim2.new(0,left,0,7),Size=UDim2.new(1,-left-10,0,18),TextWrapped=false,ZIndex=3,Parent=cap})
 local value=UIKit.Label("",24,{Name="Value",Position=UDim2.new(0,left,0,24),Size=UDim2.new(1,-left-10,0,30),TextWrapped=false,TextScaled=true,ZIndex=3,Parent=cap})
 New("UITextSizeConstraint",{MaxTextSize=25,Parent=value})
 return cap,value
end

-- Small rounded status pill ("Ready", "Growing", "Empty" ...).
function UIKit.Badge(parent: Instance, text: string, kind: string?, props: Props?): (Frame, TextLabel)
 local p: Props={Name="Badge",BackgroundTransparency=1,Size=UDim2.fromOffset(150,40),Parent=parent}
 if props then for k,v in props do p[k]=v end end
 local badge=New("Frame",p)
 local label=UIKit.Label(text,20,{Name="BadgeLabel",Size=UDim2.fromScale(1,1),TextXAlignment=Enum.TextXAlignment.Center,TextWrapped=false,ZIndex=(p.ZIndex or 3)+1,Parent=badge})
 UIKit.SetBadge(badge,text,kind)
 return badge,label
end
function UIKit.SetBadge(badge: GuiObject, text: string, kind: string?)
 local sprite=kind=="ready" and "buttonGreen" or kind=="gold" and "buttonGold" or kind=="red" and "buttonRed" or kind=="claimed" and "badgeClaimed" or "progressTrack"
 local art=UIKit.Skin(badge,"controls",sprite);if art then art.ZIndex=badge.ZIndex end
 local label=badge:FindFirstChild("BadgeLabel") :: TextLabel?
 if label then label.Text=text;label.Position=UDim2.fromOffset(kind=="claimed" and 18 or 0,0) end
end

-- Track with native fill; value is 0..1.
function UIKit.Progress(parent: Instance, props: Props?): (Frame, Frame)
 local p: Props={Name="Progress",BackgroundTransparency=1,Size=UDim2.fromOffset(240,30),Parent=parent}
 if props then for k,v in props do p[k]=v end end
 local track=New("Frame",p);UIKit.Skin(track,"controls","progressTrack")
 local fill=New("Frame",{Name="Fill",BackgroundColor3=Color3.fromRGB(255,196,46),Position=UDim2.new(0,7,.5,0),AnchorPoint=Vector2.new(0,.5),Size=UDim2.new(0,0,1,-14),ZIndex=3,Parent=track},{UIKit.Corner(8),New("UIGradient",{Rotation=90,Color=ColorSequence.new(Color3.new(1,1,1),Color3.fromRGB(230,150,20))})})
 return track,fill
end
function UIKit.SetProgress(track: Frame, value: number, color: Color3?)
 local fill=track:FindFirstChild("Fill") :: Frame?;if not fill then return end
 fill.Size=UDim2.new(math.clamp(value,0,1),-14*math.clamp(value,0,1),1,-14);fill.Visible=value>0
 if color then fill.BackgroundColor3=color end
end

return UIKit
