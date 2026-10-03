--!strict
-- ชิ้นส่วน UI ใช้ซ้ำ (plan.md หัวข้อ 15.6) — สไตล์เกม: ขอบดำหนา มุมมน เงาล่าง สีสด
-- ใช้ได้เฉพาะฝั่ง Client

local TweenService = game:GetService("TweenService")

local UIKit = {}
local Art = require(script.Parent.UIArt)

-- Studs theme palette (2026-10-03): saturated fills, near-black ink for outlines and inset panels.
UIKit.Colors = table.freeze({
	Outline = Color3.fromRGB(14, 16, 28),
	Panel = Color3.fromRGB(38, 46, 74),
	PanelDark = Color3.fromRGB(24, 28, 46),
	Rail = Color3.fromRGB(96, 108, 140),
	Card = Color3.fromRGB(52, 62, 96),
	Input = Color3.fromRGB(20, 24, 40),
	Text = Color3.fromRGB(255, 255, 255),
	TextDim = Color3.fromRGB(214, 222, 238),
	TextDark = Color3.fromRGB(26, 26, 26),
	Accent = Color3.fromRGB(140, 255, 60),
	AccentText = Color3.fromRGB(140, 255, 60),
	Green = Color3.fromRGB(70, 212, 40),
	Blue = Color3.fromRGB(0, 150, 255),
	Red = Color3.fromRGB(255, 48, 70),
	Purple = Color3.fromRGB(170, 70, 255),
	Orange = Color3.fromRGB(255, 176, 0),
	Teal = Color3.fromRGB(0, 200, 190),
	Pink = Color3.fromRGB(255, 90, 170),
	Slate = Color3.fromRGB(120, 128, 148),
	Disabled = Color3.fromRGB(96, 102, 118),
})
local C = UIKit.Colors

UIKit.Font = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Heavy)
UIKit.FontBody = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Bold)
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
	if inst:IsA("ScrollingFrame") then
		task.defer(function() if inst.Parent then UIKit.ScrollEdges(inst) end end)
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
-- ===== Studs theme =====
-- Chrome is drawn with native parts instead of the old wood atlases: one ImageLabel per surface
-- (flat fill + vertical gradient, buttons get a darker bottom lip), dark outline, rounded corners
-- and a tiled stud overlay. Taken from the reference kit in "Asset 3d" (2.rbxl MainUI, Buttons.fig);
-- tokens: assets/ui/studs/README.md. Illustration atlases (pets, garden, rewards...) still use UIKit.Art.
local STUDS="rbxassetid://136024762697460" -- translucent 4x4 stud tile
local VIGNETTE="rbxassetid://79723271062969" -- soft inner shadow
local rgb=Color3.fromRGB
local INK=C.Outline
-- {window body, title plate} per ScreenGui; other windows use DEFAULT.
UIKit.Windows=table.freeze({
 InventoryHUD={rgb(0,132,255),rgb(255,176,0)},
 PetHUD={rgb(160,72,255),rgb(255,84,170)},
 GardenHUD={rgb(46,184,60),rgb(255,196,0)},
 ShopHUD={rgb(243,89,0),rgb(255,30,60)},
 RewardsHUD={rgb(240,50,90),rgb(255,186,0)},
 StoryHUD={rgb(0,168,190),rgb(255,176,0)},
 SeasonHUD={rgb(255,160,0),rgb(120,80,255)},
 RebirthHUD={rgb(90,70,230),rgb(255,186,0)},
 ArenaHUD={rgb(170,30,40),rgb(255,186,0)},
})
local DEFAULT={rgb(64,86,140),rgb(0,150,255)}
-- Every list: padding keeps full cards' outlines intact and the scrollbar gets its own lane.
function UIKit.ScrollEdges(scroll: ScrollingFrame)
 local owner=scroll:FindFirstAncestorWhichIsA("ScreenGui")
 if owner and owner.Name=="AdminPanel" then return end
 if scroll:GetAttribute("SoftEdges") then return end
 scroll:SetAttribute("SoftEdges",true)
 scroll.ClipsDescendants=true
 scroll.VerticalScrollBarInset=Enum.ScrollBarInset.ScrollBar
 local padding=scroll:FindFirstChildOfClass("UIPadding") or New("UIPadding",{Parent=scroll})
 for _,key in {"PaddingTop","PaddingBottom","PaddingLeft","PaddingRight"} do
  local value=(padding :: any)[key];(padding :: any)[key]=UDim.new(value.Scale,math.max(value.Offset,8))
 end
 -- No colour overlay at the edges: it never matched the ink panels behind lists and muddied the cards
 -- (ArmZ 2026-10-03). Rows clip cleanly inside the padded frame; the scrollbar shows there is more.
end
-- color nil = window colour; alpha = see-through ink panel; lip = 3D bottom edge;
-- studs = overlay transparency (1 = none); glyph = drawn symbol (close/delete/claimed).
local function st(color: Color3?, radius: number, stroke: number, studs: number, lip: boolean?, alpha: number?, glyph: string?)
 return {color=color,radius=radius,stroke=stroke,studs=studs,lip=lip,alpha=alpha,glyph=glyph}
end
local function fixed(s) s.fixed=true;return s end -- ignores the Fill attribute (lit nav tiles)
local GREEN,GOLD,RED=rgb(70,212,40),rgb(255,186,0),rgb(255,48,70)
local STYLE={
 window={wideWindow=st(nil,18,5,.8)},
 detail={detailPanel=st(INK,14,3,1,false,.5)},
 chrome={
  navNormal=st(rgb(0,150,255),14,4,.75,true),navGold=fixed(st(GOLD,14,4,.75,true)),navGreen=fixed(st(GOLD,14,4,.75,true)),
  tabNormal=st(INK,12,3,1,false,.45),tabGold=st(GOLD,12,3,.75,true),tabGreen=st(GOLD,12,3,.75,true), -- selected = gold everywhere (green vanished on green windows)
  headerPlaque=st(nil,14,4,.75,true),infoRow=st(INK,12,3,1,false,.5),currencyCapsule=st(INK,14,3,1,false,.35),
 },
 controls={
  buttonGreen=st(GREEN,12,3,.78,true),buttonGold=st(GOLD,12,3,.78,true),buttonRed=st(RED,12,3,.78,true),buttonDisabled=st(rgb(96,102,118),12,3,.78,true),
  close=st(rgb(255,40,60),12,4,.78,true),delete=st(RED,12,3,.78,true,nil,"🗑"),
  inert=st(INK,12,3,1,false,.45), -- Slate buttons: info rows and unavailable actions read as flat ink
  badgeReady=st(GREEN,10,3,.8),badgeClaimed=st(GREEN,10,3,.8,false,nil,"✓"),progressTrack=st(INK,10,3,1,false,.4),
 },
 cards={
  common=st(rgb(150,160,176),12,3,.7),rare=st(rgb(0,150,255),12,3,.7),epic=st(rgb(170,70,255),12,3,.7),legendary=st(rgb(255,176,0),12,3,.7),mythic=st(rgb(255,44,96),12,3,.7),
  unknown=st(rgb(52,56,74),12,3,.85),product=st(INK,12,3,1,false,.45),today=st(rgb(255,196,0),12,4,.7),selected=st(rgb(255,214,40),12,4,.7),
 },
}
local function ramp(c: Color3, lip: boolean?): ColorSequence
 local hi,lo=c:Lerp(Color3.new(1,1,1),.25),c:Lerp(Color3.new(),.1)
 if not lip then return ColorSequence.new(hi,lo) end
 local edge=c:Lerp(Color3.new(),.4)
 return ColorSequence.new({ColorSequenceKeypoint.new(0,hi),ColorSequenceKeypoint.new(.84,lo),ColorSequenceKeypoint.new(.85,edge),ColorSequenceKeypoint.new(1,edge)})
end
-- A surface for `parent`. Buttons/badges may set attribute Fill (Color3) to override the style colour.
function UIKit.Skin(parent: GuiObject, atlas: string, sprite: string): ImageLabel?
 local style=STYLE[atlas] and STYLE[atlas][sprite];if not style then return nil end
 local fill=(not style.fixed and parent:GetAttribute("Fill")) or style.color
 if not fill then
  local owner=parent:FindFirstAncestorWhichIsA("ScreenGui");local w=owner and UIKit.Windows[owner.Name] or DEFAULT
  fill=sprite=="headerPlaque" and w[2] or w[1]
 end
 local key=atlas.."/"..sprite.."#"..fill:ToHex()
 local old=parent:FindFirstChild("SurfaceArt")
 if old and old:GetAttribute("Sprite")==key then return old :: ImageLabel end
 if old then old:Destroy() end
 local alpha=style.alpha or 0;local tile=atlas=="window" and 88 or 56
 local image=New("ImageLabel",{Name="SurfaceArt",Active=false,ZIndex=2,Size=UDim2.fromScale(1,1),BackgroundColor3=alpha>0 and fill or Color3.new(1,1,1),BackgroundTransparency=alpha,BorderSizePixel=0,
  Image=style.studs<1 and STUDS or "",ImageTransparency=style.studs,ScaleType=Enum.ScaleType.Tile,TileSize=UDim2.fromOffset(tile,tile),Parent=parent},{
  UIKit.Corner(style.radius),
  New("UIStroke",{Thickness=style.stroke,Color=alpha>0 and INK or fill:Lerp(Color3.new(),.62),Transparency=alpha>0 and .25 or 0,ApplyStrokeMode=Enum.ApplyStrokeMode.Border,LineJoinMode=Enum.LineJoinMode.Round}),
 })
 if alpha==0 then New("UIGradient",{Rotation=90,Color=ramp(fill,style.lip),Parent=image}) end
 if atlas=="window" then New("ImageLabel",{Name="Vignette",Active=false,BackgroundTransparency=1,Size=UDim2.fromScale(1,1),Image=VIGNETTE,ImageTransparency=.72,ZIndex=1,Parent=image},{UIKit.Corner(style.radius)}) end
 if style.glyph then
  local centre=sprite=="delete"
  local g=New("TextLabel",{Name="Glyph",BackgroundTransparency=1,Text=style.glyph,TextScaled=true,FontFace=UIKit.Font,TextColor3=Color3.new(1,1,1),AnchorPoint=Vector2.new(centre and .5 or 0,.5),Position=centre and UDim2.fromScale(.5,.45) or UDim2.new(0,8,.5,0),Size=centre and UDim2.fromScale(.6,.6) or UDim2.new(0,24,.7,0),ZIndex=2,Parent=image},{UIKit.TextStroke(2)})
  g:SetAttribute("NoTranslate",true)
 end
 image:SetAttribute("Sprite",key)
 -- Keep the surface under the parent's own content in both ZIndex modes (skins are often made before
 -- the parent is in a ScreenGui): same level as the parent (Global draws it after its ancestors) and
 -- the parent's content shifted above it, keeping its relative order. Window sets its body itself.
 if atlas~="window" then
  image.ZIndex=parent.ZIndex
  local own={};local low=math.huge
  for _,d in parent:GetDescendants() do if d:IsA("GuiObject") and d~=image and not d:IsDescendantOf(image) then table.insert(own,d);low=math.min(low,d.ZIndex) end end
  local shift=image.ZIndex+1-low;if shift>0 then for _,d in own do d.ZIndex+=shift end end
 end
 parent.BackgroundTransparency=1
 local stroke=parent:FindFirstChildOfClass("UIStroke");if stroke then stroke.Enabled=false end
 local gradient=parent:FindFirstChildOfClass("UIGradient");if gradient then gradient.Enabled=false end
 local pad=parent:FindFirstChildOfClass("UIPadding")
 if pad then image.Position=UDim2.fromOffset(-pad.PaddingLeft.Offset,-pad.PaddingTop.Offset);image.Size=UDim2.new(1,pad.PaddingLeft.Offset+pad.PaddingRight.Offset,1,pad.PaddingTop.Offset+pad.PaddingBottom.Offset) end
 return image
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
	button:SetAttribute("Fill",color);UIKit.Skin(button,"controls",color==C.Slate and "inert" or "buttonGreen");base.Visible=false
	for _,l in button:GetDescendants() do if l:IsA("UIStroke") and l.Parent:IsA("TextLabel") then l.Thickness=math.max(2,(o.textSize or 17)/10) end end
	local pressed = false
	local hovered = false
	local focused = false
	local motionScale = New("UIScale", {Name="ButtonMotion", Parent=button})
	local scaleTween: Tween? = nil
	local moveTween: Tween? = nil
	local function animate()
		if scaleTween then scaleTween:Cancel() end
		if moveTween then moveTween:Cancel() end
		local reduced = game:GetService("GuiService").ReducedMotionEnabled
		local scale = if o.disabled then 1 else (if pressed then 0.96 else (if hovered or focused then 1.025 else 1))
		scaleTween = TweenService:Create(motionScale, TweenInfo.new(reduced and 0 or 0.18, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Scale=scale})
		moveTween = TweenService:Create(button, TweenInfo.new(reduced and 0 or 0.1), {Position=UDim2.fromOffset(0, pressed and shadow-1 or 0)})
		scaleTween:Play();moveTween:Play()
	end
	button.InputBegan:Connect(function(input)
		if o.disabled then return end
		if input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch then pressed=true;animate() end
	end)
	local function release()
		if pressed then
			pressed = false
			animate()
		end
	end
	button.InputEnded:Connect(function(input) if input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch then release() end end)
	button.MouseEnter:Connect(function() hovered=true;animate() end)
	button.MouseLeave:Connect(function() hovered=false;pressed=false;animate() end)
	button.SelectionGained:Connect(function() focused=true;animate() end)
	button.SelectionLost:Connect(function() focused=false;pressed=false;animate() end)
	button.Destroying:Connect(function() if scaleTween then scaleTween:Cancel() end;if moveTween then moveTween:Cancel() end end)
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
	button:SetAttribute("Fill",color)
	if not holder:GetAttribute("ArtCard") then UIKit.Skin(button,"controls",color==C.Slate and "inert" or "buttonGreen") end
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

-- Common window chrome and the icon atlas, shared by every system.
function UIKit.Icon(parent: Instance, id: string, props: Props?): ImageLabel?
 local atlas=require(game.ReplicatedStorage.Shared.Config.UIIcons)
 local r=atlas.Rects[id];if not r then return nil end
 local p: Props={Name="Art",BackgroundTransparency=1,Size=UDim2.fromOffset(64,64),ScaleType=Enum.ScaleType.Fit,Image="rbxassetid://"..(r[5] or atlas.AssetId),ImageRectOffset=Vector2.new(r[1],r[2]),ImageRectSize=Vector2.new(r[3],r[4]),Parent=parent}
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
-- Window: stud body in the system colour, big outlined title (optionally on a protruding colour plate) and red X.
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
  -- Padded windows keep the original Title row (content y 0..36) for the heading; their own rows start below it.
  local top=pad and 18 or nil;local h=top and 38 or 64
  UIKit.Symbol(panel,symbol or "book",{Name="TitleIcon",AnchorPoint=Vector2.new(0,.5),Position=top and UDim2.fromOffset(30-px,top) or UDim2.new(0,30-px,.105,-py-2),Size=UDim2.fromOffset(top and 42 or 78,top and 42 or 78),ZIndex=5})
  heading=UIKit.Label(title,46,{Name="WindowHeading",AnchorPoint=Vector2.new(0,.5),Position=top and UDim2.fromOffset(78-px,top) or UDim2.new(0,112-px,.105,-py-2),Size=UDim2.new(.62,-112,0,h),TextColor3=Heading,TextWrapped=false,TextTruncate=Enum.TextTruncate.AtEnd,ZIndex=5,Parent=panel})
  heading.TextScaled=true -- after TextWrapped=false (setting that clears TextScaled)
  -- Small windows: use the whole title strip up to the close button; shrink long/Thai titles instead of cutting them.
  local width=panel.Size.X.Offset;if width>0 and width<700 then heading.Size=UDim2.new(1,2*px-190,0,h) end
  New("UITextSizeConstraint",{MaxTextSize=46,MinTextSize=18,Parent=heading})
 end
 heading:FindFirstChildOfClass("UIStroke").Thickness=4
 if original then original:GetPropertyChangedSignal("Text"):Connect(function() heading.Text=original.Text end) end
 local close=UIKit.Button({text="X",textSize=38,color=C.Red,radius=10,stroke=4,size=UDim2.fromOffset(70,70),onClick=function() panel.Visible=false end});close.Name="WindowClose";close.AnchorPoint=Vector2.new(.5,.5);close.Position=UDim2.new(1,px-30,0,-py+18);close.ZIndex=6;close.Parent=panel
 local x=close.Button:FindFirstChildWhichIsA("TextLabel",true);x.Size=UDim2.new(1,0,.85,0);x:SetAttribute("NoTranslate",true)
 for _,v in close:GetDescendants() do if v:IsA("GuiObject") then v.ZIndex=6 end end
 close.Button.SurfaceArt.ZIndex=5 -- under the X
 return heading
end

-- Tab: ink (normal) / gold / green states, optional icon and live label.
function UIKit.Tab(o: Props): TextButton
 local tab=New("TextButton",{Name=o.name or "Tab",AutoButtonColor=false,Text="",BackgroundTransparency=1,Size=o.size or UDim2.fromOffset(200,54),Position=o.position or UDim2.new(),LayoutOrder=o.layoutOrder or 0,Parent=o.parent})
 local row=New("Frame",{Name="Content",BackgroundTransparency=1,Size=UDim2.new(1,0,1,-4),ZIndex=3,Parent=tab},{New("UIListLayout",{FillDirection=Enum.FillDirection.Horizontal,HorizontalAlignment=Enum.HorizontalAlignment.Center,VerticalAlignment=Enum.VerticalAlignment.Center,Padding=UDim.new(0,10),SortOrder=Enum.SortOrder.LayoutOrder})})
 if o.icon then UIKit.Symbol(row,o.icon,{Name="TabIcon",Size=UDim2.fromOffset(o.iconSize or 38,o.iconSize or 38),LayoutOrder=1,ZIndex=3}) end
 local base=o.textSize or 26
 local label=UIKit.Label(o.text,base,{Name="TabLabel",AutomaticSize=Enum.AutomaticSize.X,Size=UDim2.fromOffset(0,40),TextWrapped=false,LayoutOrder=2,ZIndex=3,Parent=row})
 label:FindFirstChildOfClass("UIStroke").Thickness=2.5
 -- Shrink long labels (Merchant, Thai) to the tab. Width is measured at the current size and scaled to base;
 -- the guard stops the resize re-firing this handler, and growing needs 2px so rounding cannot oscillate.
 local fitting=false
 local function fit()
  if fitting then return end
  local icon=row:FindFirstChild("TabIcon");local s=icon and icon.AbsoluteSize.X/(o.iconSize or 38) or 1
  local room=tab.AbsoluteSize.X-(icon and icon.AbsoluteSize.X+10*s or 0)-14*s
  if label.AbsoluteSize.X<=0 or room<=0 then return end
  local size=math.clamp(math.floor(base*room/(label.AbsoluteSize.X*base/label.TextSize)),12,base)
  if size<label.TextSize or size>=label.TextSize+2 or (size==base and label.TextSize~=base) then fitting=true;label.TextSize=size;fitting=false end
 end
 label:GetPropertyChangedSignal("AbsoluteSize"):Connect(fit);tab:GetPropertyChangedSignal("AbsoluteSize"):Connect(fit)
 tab.Activated:Connect(function() if o.onClick then o.onClick() end end)
 UIKit.SetTab(tab,o.state)
 return tab
end
function UIKit.SetTab(tab: GuiObject, state: string?)
 UIKit.Skin(tab,"chrome",state=="gold" and "tabGold" or state=="green" and "tabGreen" or "tabNormal")
 local label=tab:FindFirstChild("TabLabel",true);if label then label.TextColor3=state and Color3.new(1,1,1) or C.TextDim end
end

-- Ink strip for hints/stats; returns the frame and its live label.
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

-- List card: icon, short title, then a progress bar or one short line, an optional reward chip and a
-- status badge on the right. Built once per name and updated in place (lists refresh every second).
-- o={icon,iconColor?,title,sub?,progress?(0..1),count?,chip?={icon,text},badge?={text,kind},style?(cards sprite),dim?,onClick?}
-- A calm, illustrated empty state: one reason and one useful next step.
function UIKit.EmptyState(parent: Instance, name: string, o: Props): TextButton
 local r=parent:FindFirstChild(name) :: TextButton
 if not r then
  r=New("TextButton",{Name=name,Text="",Selectable=false,AutoButtonColor=false,BackgroundTransparency=1,Size=UDim2.new(1,-8,0,190),Parent=parent})
  UIKit.Icon(r,o.icon or "box",{Name="StateIcon",AnchorPoint=Vector2.new(.5,0),Position=UDim2.fromScale(.5,.06),Size=UDim2.fromOffset(68,68)})
  UIKit.Label("",22,{Name="Heading",Position=UDim2.fromScale(.05,.45),Size=UDim2.fromScale(.9,.22),TextXAlignment=Enum.TextXAlignment.Center,TextScaled=true,Parent=r})
  New("UITextSizeConstraint",{MaxTextSize=22,Parent=r.Heading})
  UIKit.Label("",17,{Name="Hint",FontFace=UIKit.FontBody,Position=UDim2.fromScale(.05,.68),Size=UDim2.fromScale(.9,.26),TextXAlignment=Enum.TextXAlignment.Center,TextScaled=true,Parent=r})
  New("UITextSizeConstraint",{MaxTextSize=17,Parent=r.Hint})
 end
 UIKit.Skin(r,"cards","product");r.Heading.Text=o.title;r.Hint.Text=o.sub or ""
 return r
end
local rowClick=setmetatable({},{__mode="k"})
function UIKit.Row(parent: Instance, name: string, o: Props): TextButton
 local r=parent:FindFirstChild(name) :: TextButton?
 if not r then
  r=New("TextButton",{Name=name,Text="",AutoButtonColor=false,BackgroundTransparency=1,Size=UDim2.new(1,-8,0,64),Parent=parent})
  local row=r :: TextButton
  row.Activated:Connect(function() local fn=rowClick[row];if fn then fn() end end)
  UIKit.Label("",20,{Name="Title",TextWrapped=false,ZIndex=4,Parent=row}).TextScaled=true
  New("UITextSizeConstraint",{MaxTextSize=20,MinTextSize=12,Parent=row.Title})
  UIKit.Label("",15,{Name="Sub",FontFace=UIKit.FontBody,TextColor3=Color3.fromRGB(235,240,250),TextWrapped=false,ZIndex=4,Parent=row}).TextScaled=true
  New("UITextSizeConstraint",{MaxTextSize=15,MinTextSize=10,Parent=row.Sub})
  local _,fill=UIKit.Progress(row,{Name="Bar",Size=UDim2.fromOffset(200,22),ZIndex=4});fill.ZIndex=5
  UIKit.Label("",15,{Name="Count",TextWrapped=false,TextXAlignment=Enum.TextXAlignment.Left,ZIndex=4,Parent=row})
  local chip=New("Frame",{Name="Chip",BackgroundTransparency=1,AnchorPoint=Vector2.new(1,.5),Size=UDim2.fromOffset(104,40),ZIndex=4,Parent=row})
  UIKit.Label("",20,{Name="ChipText",Position=UDim2.fromOffset(38,0),Size=UDim2.new(1,-38,1,0),TextWrapped=false,ZIndex=4,Parent=chip}).TextScaled=true
  New("UITextSizeConstraint",{MaxTextSize=21,MinTextSize=11,Parent=chip.ChipText})
  UIKit.Badge(row,"","gold",{Name="Status",AnchorPoint=Vector2.new(1,.5),Position=UDim2.new(1,-12,.5,0),Size=UDim2.fromOffset(120,40),ZIndex=4})
 end
 local row=r :: any
 rowClick[row]=o.onClick
 UIKit.Skin(row,"cards",o.style or "product")
 local h=o.height or 64;row.Size=UDim2.new(1,-8,0,h)
 -- Icon (rebuilt only when the symbol changes).
 local key=(o.icon or "").."#"..(o.iconColor and o.iconColor:ToHex() or "")
 if row:GetAttribute("IconKey")~=key then
  local old=row:FindFirstChild("RowIcon");if old then old:Destroy() end
  local art=o.icon and UIKit.Symbol(row,o.icon,{Name="RowIcon",AnchorPoint=Vector2.new(0,.5),Position=UDim2.new(0,12,.5,0),Size=UDim2.fromOffset(46,46),ZIndex=4})
  if art and o.iconColor then art.ImageColor3=o.iconColor end
  row:SetAttribute("IconKey",key)
 end
 local icon=row:FindFirstChild("RowIcon");local left=icon and 70 or 18
 -- Right side: badge, then chip.
 local right=12
 local badge=row.Status;badge.Visible=o.badge~=nil
 if o.badge then UIKit.SetBadge(badge,o.badge.text,o.badge.kind);badge.Size=UDim2.fromOffset(o.badge.width or 120,40);right+=badge.Size.X.Offset+10 end
 local chip=row.Chip;chip.Visible=o.chip~=nil
 if o.chip then
  chip.Size=UDim2.fromOffset(o.chip.width or 104,40);chip.Position=UDim2.new(1,-right,.5,0);chip.ChipText.Text=o.chip.text
  local cKey=o.chip.icon..(o.chip.color and o.chip.color:ToHex() or "")
  if chip:GetAttribute("IconKey")~=cKey then local old=chip:FindFirstChild("ChipIcon");if old then old:Destroy() end
   local a=UIKit.Symbol(chip,o.chip.icon,{Name="ChipIcon",AnchorPoint=Vector2.new(0,.5),Position=UDim2.new(0,0,.5,0),Size=UDim2.fromOffset(34,34),ZIndex=4});if a and o.chip.color then a.ImageColor3=o.chip.color end
   chip:SetAttribute("IconKey",cKey) end
  right+=chip.Size.X.Offset+8
 end
 -- Middle: title on top, then a bar (with count) or a short line; a lone title is centred.
 local title,sub,bar,count=row.Title,row.Sub,row.Bar,row.Count
 local lower=o.progress~=nil or (o.sub~=nil and o.sub~="")
 title.Text=o.title or "";title.Position=UDim2.fromOffset(left,lower and 7 or 0);title.Size=UDim2.new(1,-left-right,0,lower and 26 or h)
 bar.Visible=o.progress~=nil;count.Visible=o.progress~=nil and o.count~=nil
 if o.progress then
  local cw=o.count and 74 or 0
  bar.Position=UDim2.fromOffset(left,h-30);bar.Size=UDim2.new(1,-left-right-cw,0,22);UIKit.SetProgress(bar,o.progress,o.barColor)
  count.Text=o.count or "";count.Position=UDim2.new(1,-right-cw+8,0,h-30);count.Size=UDim2.fromOffset(cw-8,22)
 end
 sub.Visible=o.progress==nil and o.sub~=nil and o.sub~=""
 sub.Text=o.sub or "";sub.Position=UDim2.fromOffset(left,36);sub.Size=UDim2.new(1,-left-right,0,20)
 local fade=o.dim and .45 or 0
 title.TextTransparency=fade;sub.TextTransparency=fade;if icon then (icon :: any).ImageTransparency=fade end
 return row
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
