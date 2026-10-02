-- Phase 10 navigation reuses existing buttons/callbacks; server intents stay unchanged.
local Players=game:GetService("Players")
local S=game.ReplicatedStorage.Shared;local UI=require(S.UIKit)
local Atlas=require(S.Config.UIIcons)
local Net=require(S.Net)
local Phone=require(script.Parent.PhoneLayouts)
local Navigation={}
local Lighting=game:GetService("Lighting")
local GuiService=game:GetService("GuiService")
local UIS=game:GetService("UserInputService")
local specs={
	{"InventoryHUD","Toggle","Inventory","bag",true,960,650},
	{"PetHUD","Toggle","Pets","egg",true,960,650},
	{"GardenHUD","Toggle","Garden","leaf",true,960,650},
	{"ShopHUD","Toggle","Shop","shop",true,960,650},
	{"RewardsHUD","Open","Rewards","gift",true,960,650},
	{"StoryHUD","Toggle","Quests","book",false,780,570},
	{"SeasonHUD","Toggle","Season","season",false,760,540},
	{"RebirthHUD","Open","Rebirth","cycle",false,720,550},
	{"EmoteHUD","EmoteToggle","Emotes","face",false},
	{"EmoteHUD","PhotoToggle","Photo","camera",false},
	{"ForestHUD","InviteFriends","Invite Friends","friends",false},
}
-- Tight per-icon rectangles; labels remain live and readable.
local function icon(parent,id)
 local canvas=UI.New("Frame",{Name="Icon",BackgroundTransparency=1,Position=UDim2.new(.5,-34,0,4),Size=UDim2.fromOffset(68,64),Parent=parent})
 local rect=Atlas.Rects[id]
 if rect then UI.New("ImageLabel",{Name="Art",BackgroundTransparency=1,Size=UDim2.fromScale(1,1),ScaleType=Enum.ScaleType.Fit,Image="rbxassetid://"..Atlas.AssetId,ImageRectOffset=Vector2.new(rect[1],rect[2]),ImageRectSize=Vector2.new(rect[3],rect[4]),Parent=canvas})
 else for row=0,1 do for col=0,1 do UI.New("Frame",{Position=UDim2.fromOffset(16+col*21,11+row*21),Size=UDim2.fromOffset(16,16),BackgroundColor3=Color3.fromRGB(255,213,92),Parent=canvas},{UI.Corner(4),UI.Stroke(2)}) end end end
end
function Navigation.Start()
	local pg=Players.LocalPlayer.PlayerGui
	local gui=UI.New("ScreenGui",{Name="NavigationHUD",ResetOnSpawn=false,DisplayOrder=20,Parent=pg})
	local rail=UI.New("Frame",{Name="MainMenus",BackgroundTransparency=1,AnchorPoint=Vector2.new(0,.5),Position=UDim2.new(0,12,.46,0),Size=UDim2.fromOffset(200,324),Parent=gui},{UI.Grid(2,100,12)})
	-- Concept rail: while a primary window is open its menu tiles stack beside the window.
	local side=UI.New("Frame",{Name="SideRail",BackgroundTransparency=1,AnchorPoint=Vector2.new(1,.5),Size=UDim2.fromOffset(104,630),Visible=false,Parent=gui},{UI.List(Enum.FillDirection.Vertical,6,Enum.HorizontalAlignment.Center)})
	local sideScale=UI.New("UIScale",{Parent=side})
	local RAIL=104
	local drawer=UI.New("Frame",{Name="MoreMenus",AnchorPoint=Vector2.new(.5,.5),Position=UDim2.fromScale(.5,.5),Size=UDim2.fromOffset(490,400),BackgroundColor3=UI.Colors.Panel,Visible=false,Parent=gui},{UI.Corner(18),UI.Stroke(4),UI.Padding(16)})
	UI.Label("Choose a Menu",24,{Parent=drawer})
	local grid=UI.New("ScrollingFrame",{Name="Menus",BackgroundTransparency=1,Position=UDim2.fromOffset(0,45),Size=UDim2.new(1,0,1,-45),CanvasSize=UDim2.new(),AutomaticCanvasSize=Enum.AutomaticSize.Y,ScrollBarThickness=4,Parent=drawer},{UI.Grid(4,100,12)})
	local records,panels={},{};local compact=false;local layout;local hidBackpack=false
    local blur=UI.New("BlurEffect",{Name="MenuBlur",Size=0,Parent=Lighting})
    UI.Window(drawer,"Choose a Menu","book")
	local more=UI.Button({text="More",color=UI.Colors.Orange,size=UDim2.fromOffset(94,100),onClick=function()
		local open=false;for _,r in panels do if r.panel.Visible then open=true;r.panel.Visible=false end end
		drawer.Visible=open or not drawer.Visible
	end});more.Name="More";more.LayoutOrder=99;more.Parent=rail
	local mobile=UI.Button({text="Menu",color=UI.Colors.Orange,size=UDim2.fromOffset(72,80),onClick=function() drawer.Visible=not drawer.Visible end});mobile.Name="Menu";mobile.Position=UDim2.fromOffset(10,65);mobile.Parent=gui
	local function dress(holder,label,id)
		local b=holder:FindFirstChild("Button");if not b then return end
		b.BackgroundColor3=Color3.fromRGB(164,98,49)
        local border=b:FindFirstChildOfClass("UIStroke");if border then border.Thickness=4;border.Color=Color3.fromRGB(31,23,16) end
        local corner=b:FindFirstChildOfClass("UICorner");if corner then corner.CornerRadius=UDim.new(0,12) end
        UI.Skin(b,"chrome","navNormal");holder:SetAttribute("ArtCard",true)
        local t=b:FindFirstChildWhichIsA("TextLabel",true);t.Text=label;t.TextSize=20;t.TextScaled=true;UI.New("UITextSizeConstraint",{MaxTextSize=20,MinTextSize=11,Parent=t});t.TextColor3=Color3.new(1,1,1);t.Position=UDim2.new(0,-5,1,-29);t.Size=UDim2.new(1,10,0,28);UI.TextStroke(3).Parent=t
		icon(b,id);b.Activated:Connect(function() if holder~=more and holder~=mobile then drawer.Visible=false end end)
	end
	dress(more,"More","menu");dress(mobile,"Menu","menu");mobile:FindFirstChild("Button").Icon.Size=UDim2.fromOffset(42,35);mobile.Button.Icon.Position=UDim2.new(.5,-21,0,3)
	-- Phone layouts: {Position,Size} per named child (false = hidden); desktop values are restored
	-- when the screen is no longer compact.
	-- Re-applied whenever the window is shown or gains children: controllers build parts lazily.
	local function reflow(panel,spec,on)
		if not on and not panel:GetAttribute("PhoneLayout") then return end
		panel:SetAttribute("PhoneLayout",on)
		for path,r in spec do
			local o=panel;for part in path:gmatch("[^.]+") do o=o and o:FindFirstChild(part) end
			if o then
				-- Desktop values live in attributes (a weak table keyed by Instance loses entries).
				if o:GetAttribute("DeskVisible")==nil then o:SetAttribute("DeskPosition",o.Position);o:SetAttribute("DeskSize",o.Size);o:SetAttribute("DeskVisible",o.Visible) end
				if r==false then o.Visible=not on and o:GetAttribute("DeskVisible")
				else o.Position=on and r[1] or o:GetAttribute("DeskPosition");o.Size=on and r[2] or o:GetAttribute("DeskSize") end
			end
		end
	end
	local function fit(panel,w,h,primary)
		local v=workspace.CurrentCamera.ViewportSize;local scale=panel:FindFirstChildOfClass("UIScale") or UI.New("UIScale",{Parent=panel})
		local owner=panel:FindFirstAncestorWhichIsA("ScreenGui")
		local spec=owner and Phone[owner.Name.."."..panel.Name];local pad=40
		if spec then if panel.Visible or not compact then reflow(panel,spec,compact) end;if compact then local sz=spec._size;w,h,pad=sz and sz[1] or Phone.W,sz and sz[2] or Phone.H,16 end end
		if compact and owner and (primary or panel.Name=="Panel" or panel.Name=="Settings") then
			-- Phone: use the full screen height (the window may cover the topbar strip) and stay right of
			-- Roblox's top-left buttons; +40 keeps the corner close button on screen.
			local inset=GuiService:GetGuiInset().Y;local area=Vector2.new(v.X,v.Y-inset) -- not owner.AbsoluteSize: it lags a viewport change
			local ok,bar=pcall(function() return GuiService.TopbarInset end);local left=ok and bar and math.max(0,bar.Min.X) or 0
			local beside=math.min(1,(area.X-left-12)/(w+pad),(area.Y+inset-8)/(h+pad))
			local below=math.min(1,(area.X-12)/(w+pad),(area.Y-8)/(h+pad)) -- narrow phones: under the topbar instead
			local s=math.max(beside,below)
			panel.Size=UDim2.fromOffset(w,h);scale.Scale=s;panel.AnchorPoint=Vector2.new(.5,.5)
			panel.Position=beside>=below and UDim2.new(0,left+(area.X-left)/2,.5,-inset/2+6*s) or UDim2.new(.5,0,.5,6*s)
			return s
		end
		local rail=primary and not compact and RAIL or 0
		panel.Size=UDim2.fromOffset(w,h);scale.Scale=math.min(1,(v.X-24-rail)/w,(v.Y-68)/h)
		if primary then panel.AnchorPoint=Vector2.new(.5,.5);panel.Position=UDim2.new(.5,rail/2*scale.Scale,.5,8*scale.Scale)
		elseif panel.Name=="Panel" or panel.Name=="Settings" then panel.AnchorPoint=Vector2.new(.5,.5);panel.Position=UDim2.fromScale(.5,.5) end -- undo the phone placement
		return scale.Scale
	end
	local function bindPanel(panel,owner,w,h,primary)
        local titles={InventoryHUD={"Inventory","bag"},PetHUD={"Pets","egg"},GardenHUD={"Garden","leaf"},ShopHUD={"Shop","shop"},RewardsHUD={"Rewards","gift"},StoryHUD={"Quests & Index","book"},SeasonHUD={"Season Pass","season"},RebirthHUD={"Rebirth","cycle"},ArenaHUD={"Chop Arena","arena"},NavigationHUD={"Settings","gear"}}
        local title=titles[owner.Name]
        if panel.Name=="Panel" or panel.Name=="Settings" then UI.Window(panel,title and title[1],title and title[2]) else UI.Window(panel) end
		local shade=panel.Name=="Panel" and owner:FindFirstChild("Shade")
		if not shade then shade=UI.New("TextButton",{Name="NavigationShade_"..panel.Name,Text="",AutoButtonColor=false,Size=UDim2.fromScale(1,1),BackgroundColor3=UI.Colors.Outline,BackgroundTransparency=.45,Visible=false,Parent=owner});shade.ZIndex=0;shade.Activated:Connect(function() panel.Visible=false end) end
		-- Clicks on empty window areas must not fall through to the shade (which closes the window).
		UI.New("TextButton",{Name="ClickBlocker",Text="",AutoButtonColor=false,Selectable=false,BackgroundTransparency=1,Size=UDim2.fromScale(1,1),ZIndex=0,Parent=panel})
		if shade:IsA("GuiButton") then shade.Selectable=false end
		if owner:GetAttribute("BaseDisplayOrder")==nil then owner:SetAttribute("BaseDisplayOrder",owner.DisplayOrder) end
		table.insert(panels,{panel=panel,owner=owner,w=w,h=h,shade=shade,primary=primary});panel:SetAttribute("NavigationPanel",true)
		panel:GetPropertyChangedSignal("Visible"):Connect(function()
			-- Owner ScreenGuis respect the top-bar inset (0 until the top bar loads, so read it on open);
			-- stretch the shade over it so the dim covers the full screen.
			local inset=GuiService:GetGuiInset().Y;shade.Position=UDim2.fromOffset(0,-inset);shade.Size=UDim2.new(1,0,1,inset)
			shade.Visible=panel.Visible
			if panel.Visible then for _,r in panels do if r.panel~=panel then r.panel.Visible=false;r.shade.Visible=false end end;drawer.Visible=false end
			if layout then layout() end
		end)
		local spec,pending=Phone[owner.Name.."."..panel.Name],false
		if spec then panel.DescendantAdded:Connect(function()
			if compact and panel.Visible and not pending then pending=true;task.defer(function() pending=false;reflow(panel,spec,compact) end) end
		end) end
		local correcting=false
		panel:GetPropertyChangedSignal("Size"):Connect(function() if not correcting then correcting=true;fit(panel,w,h,primary);correcting=false end end)
		fit(panel,w,h,primary)
	end
	for index,spec in specs do
		local owner=pg:FindFirstChild(spec[1]);local holder=owner and owner:FindFirstChild(spec[2])
		if holder then
			dress(holder,spec[3],spec[4]);holder.LayoutOrder=index;holder.AnchorPoint=Vector2.zero
			table.insert(records,{holder=holder,owner=owner,primary=spec[5]})
			owner:GetPropertyChangedSignal("Enabled"):Connect(function() holder.Visible=owner.Enabled;if layout then layout() end end)
			if spec[6] and owner:FindFirstChild("Panel") then bindPanel(owner.Panel,owner,spec[6],spec[7],spec[5]) end
		end
	end
	for _,spec in {{"ArenaHUD","Panel",500,440},{"InventoryHUD","Result",380,365},{"ForestHUD","Summary",360,250},{"EmoteHUD","Wheel",330,330},{"StoryHUD","Dialog",620,150}} do
		local owner=pg:FindFirstChild(spec[1]);local panel=owner and owner:FindFirstChild(spec[2]);if panel then bindPanel(panel,owner,spec[3],spec[4]) end
	end
	local settings=UI.New("Frame",{Name="Settings",AnchorPoint=Vector2.new(.5,.5),Position=UDim2.fromScale(.5,.5),Size=UDim2.fromOffset(450,478),BackgroundColor3=UI.Colors.Panel,Visible=false,Parent=gui},{UI.Corner(18),UI.Stroke(4),UI.Padding(18)})
	UI.Label("Settings",24,{Parent=settings})
    UI.Label("E: Chop  •  Shift: Sprint  •  G: Emotes  •  P: Photo",15,{Name="Keys",Position=UDim2.fromOffset(12,396),Size=UDim2.new(1,-24,0,34),Parent=settings})
    local muteState={Music=false,SFX=false};local volumes={}
    local function category(s)
        local group=s.SoundGroup;local name=string.lower(s.Name)
        return (s:GetAttribute("SoundCategory")=="Music" or (group and group.Name=="Music") or name:find("music") or name:find("ambience")) and "Music" or "SFX"
    end
    local function sound(s)
        if not s:IsA("Sound") then return end
        if muteState[category(s)] then
            if volumes[s]==nil then volumes[s]=s.Volume;s.Destroying:Once(function() volumes[s]=nil end) end
            s.Volume=0
        elseif volumes[s]~=nil then s.Volume=volumes[s];volumes[s]=nil end
    end
    -- NavigationHUD uses Global ZIndex: lift toggles (and their skin art) above the row background.
    local function lift(t) for _,d in t:GetDescendants() do if d:IsA("GuiObject") then d.ZIndex+=2 end end end
    for i,key in {"Music","SFX"} do
        local row=UI.New("Frame",{Name=key,Position=UDim2.fromOffset(0,50+(i-1)*66),Size=UDim2.new(1,0,0,58),BackgroundColor3=UI.Colors.PanelDark,Parent=settings},{UI.Corner(12),UI.Stroke(2,UI.Colors.Rail)})
        UI.Label(key,26,{Position=UDim2.fromOffset(12,8),Size=UDim2.new(1,-120,1,-16),Parent=row})
        local toggle
        toggle=UI.Button({text="ON",textSize=24,color=UI.Colors.Green,size=UDim2.fromOffset(88,52),onClick=function()
            muteState[key]=not muteState[key];for _,s in game:GetDescendants() do sound(s) end
            toggle.Button:FindFirstChildWhichIsA("TextLabel",true).Text=muteState[key] and "OFF" or "ON";UI.SetButtonColor(toggle,muteState[key] and UI.Colors.Red or UI.Colors.Green)
        end});toggle.Name="Toggle";toggle.Position=UDim2.new(1,-98,0,3);toggle.Parent=row;lift(toggle)
    end
    game.DescendantAdded:Connect(function(s) task.defer(sound,s) end)
    do -- Sprint mode (Hold / Toggle); saved in Settings.SprintMode by the server
        local Sprint=require(script.Parent.SprintController)
        local row=UI.New("Frame",{Name="Sprint",Position=UDim2.fromOffset(0,182),Size=UDim2.new(1,0,0,58),BackgroundColor3=UI.Colors.PanelDark,Parent=settings},{UI.Corner(12),UI.Stroke(2,UI.Colors.Rail)})
        UI.Label("Sprint",26,{Position=UDim2.fromOffset(12,8),Size=UDim2.new(1,-170,1,-16),Parent=row})
        local toggle
        local function refresh() local t=toggle.Button:FindFirstChildWhichIsA("TextLabel",true);if t then t.Text=string.upper(Sprint.Mode()) end end
        toggle=UI.Button({text="HOLD",textSize=22,color=UI.Colors.Blue,size=UDim2.fromOffset(138,52),onClick=function() Sprint.SetMode(Sprint.Mode()=="Toggle" and "Hold" or "Toggle") end})
        toggle.Name="Toggle";toggle.Position=UDim2.new(1,-148,0,3);toggle.Parent=row;lift(toggle)
        refresh();require(script.Parent.ClientData).Changed:Connect(function(path) if path=="" or path=="Settings.SprintMode" or path=="Settings" then refresh() end end)
    end
    do -- Language: AUTO (Roblox locale) / ENGLISH / ไทย; saved in Settings.Language by the server
        local LocaleController=require(script.Parent.LocaleController)
        local row=UI.New("Frame",{Name="Language",Position=UDim2.fromOffset(0,248),Size=UDim2.new(1,0,0,58),BackgroundColor3=UI.Colors.PanelDark,Parent=settings},{UI.Corner(12),UI.Stroke(2,UI.Colors.Rail)})
        UI.Label("Language",26,{Position=UDim2.fromOffset(12,8),Size=UDim2.new(1,-170,1,-16),Parent=row})
        local toggle
        local function refresh() local t=toggle.Button:FindFirstChildWhichIsA("TextLabel",true);if t then t.Text=LocaleController.Label() end end
        toggle=UI.Button({text="AUTO",textSize=22,color=UI.Colors.Blue,size=UDim2.fromOffset(138,52),onClick=function() LocaleController.Cycle() end})
        toggle.Name="Toggle";toggle.Position=UDim2.new(1,-148,0,3);toggle.Parent=row;lift(toggle)
        refresh();require(script.Parent.ClientData).Changed:Connect(function(path) if path=="" or path=="Settings.Language" or path=="Settings" then refresh() end end)
    end
    do -- Chest opening animation: FULL / FAST / OFF; saved in Settings.ChestAnimation by the server
        local Opening=require(script.Parent.ChestOpening)
        local NEXT,LABEL={Full="Fast",Fast="Off",Off="Full"},{Full="FULL",Fast="FAST",Off="OFF"}
        local row=UI.New("Frame",{Name="ChestAnimation",Position=UDim2.fromOffset(0,314),Size=UDim2.new(1,0,0,58),BackgroundColor3=UI.Colors.PanelDark,Parent=settings},{UI.Corner(12),UI.Stroke(2,UI.Colors.Rail)})
        UI.Label("Chest Animation",26,{Position=UDim2.fromOffset(12,8),Size=UDim2.new(1,-170,1,-16),TextScaled=true,Parent=row})
        local toggle
        local function refresh() local t=toggle.Button:FindFirstChildWhichIsA("TextLabel",true);if t then t.Text=LABEL[Opening.Mode()] end end
        toggle=UI.Button({text="FULL",textSize=22,color=UI.Colors.Blue,size=UDim2.fromOffset(138,52),onClick=function() Net.Event("SettingIntent"):FireServer("ChestAnimation",NEXT[Opening.Mode()]) end})
        toggle.Name="Toggle";toggle.Position=UDim2.new(1,-148,0,3);toggle.Parent=row;lift(toggle)
        refresh();require(script.Parent.ClientData).Changed:Connect(function(path) if path=="" or path=="Settings.ChestAnimation" or path=="Settings" then refresh() end end)
    end
	local settingButton=UI.Button({text="Settings",color=UI.Colors.Blue,onClick=function() settings.Visible=true end});settingButton.Name="SettingsMenu";settingButton.LayoutOrder=98;dress(settingButton,"Settings","gear");table.insert(records,{holder=settingButton,owner=gui,primary=false})
	bindPanel(settings,gui,450,478)
	layout=function()
		local v=workspace.CurrentCamera.ViewportSize;compact=v.X<700 or v.Y<500
		local modal,active=false,nil;for _,r in panels do local s=fit(r.panel,r.w,r.h,r.primary);if r.panel.Visible and r.owner.Enabled then modal=true;if r.primary and not compact then active=r;sideScale.Scale=s end end end
		rail.Visible=not compact and not modal;mobile.Visible=compact and not modal;drawer.Visible=drawer.Visible and not modal
		side.Visible=active~=nil
		if active then local s=sideScale.Scale;side.Position=UDim2.new(.5,RAIL/2*s-active.w*s/2+16*s,.5,8*s) end
		fit(drawer,490,400)
        local obscured=modal or drawer.Visible
        blur.Size=obscured and 18 or 0
        -- Lift the open window's ScreenGui above every HUD (compass 22, event/zone banners 5...) so its
        -- shade covers them; Blur only affects the 3D view, never GUI.
        local raised={};for _,r in panels do if r.panel.Visible and r.owner.Enabled then raised[r.owner]=true end end
        for _,r in panels do r.owner.DisplayOrder=raised[r.owner] and 30 or r.owner:GetAttribute("BaseDisplayOrder") end
        -- The tool hotbar would sit on top of window footers: StarterGui.ToolHotbar when installed
        -- (it turns Roblox's backpack bar off for good), Roblox's own bar otherwise.
        local hotbar=pg:FindFirstChild("ToolHotbar")
        if hotbar then hotbar.Enabled=not obscured elseif obscured~=hidBackpack then hidBackpack=obscured;pcall(game:GetService("StarterGui").SetCoreGuiEnabled,game:GetService("StarterGui"),Enum.CoreGuiType.Backpack,not obscured) end
		local currencies=pg:FindFirstChild("HUD") and pg.HUD:FindFirstChild("Currencies")
		if currencies then currencies.Visible=not obscured end
		local weather=pg:FindFirstChild("WeatherHUD");if weather and weather:FindFirstChild("Forecast") then weather.Forecast.Visible=not obscured end
        -- The event banner sits above the hint line (desktop) or in its place (phones), never over PLAY.
        local event=pg:FindFirstChild("WorldEventHUD") and pg.WorldEventHUD:FindFirstChild("Event");if event then event.Position=UDim2.new(.5,0,1,compact and -150 or -196) end
        -- The compass (MapHUD, DisplayOrder 22 for the boat ride) would draw over open windows: drop it below them.
        local map=pg:FindFirstChild("MapHUD");if map then map.DisplayOrder=obscured and 7 or 22 end
        -- Floating world HUD (compass, zone/event banners) would still show through the dim: hide it while a menu is open.
        if map then for _,c in map:GetChildren() do if c:IsA("GuiObject") and c.Name~="BoatSkip" then c.Visible=not obscured end end end
        for _,name in {"ZoneHUD","WorldEventHUD"} do local g=pg:FindFirstChild(name);if g then g.Enabled=not obscured end end
        local forest=pg:FindFirstChild("ForestHUD");if forest and forest:FindFirstChild("RunPanel") then
            if forest:FindFirstChild("Play") then forest.Play.Visible=not obscured and not forest.RunPanel.Visible end
            if forest:FindFirstChild("Hint") then forest.Hint.Visible=not obscured and not compact and not forest.RunPanel.Visible end
        end
        for _,r in records do
            local here=active and r.primary;r.holder.Parent=here and side or ((compact or not r.primary) and grid or rail);r.holder.Size=here and UDim2.fromOffset(100,100) or UDim2.fromOffset(94,100)
            local lit=active and active.owner==r.owner
            UI.Skin(r.holder.Button,"chrome",lit and ((r.owner.Name=="PetHUD" or r.owner.Name=="GardenHUD") and "navGreen" or "navGold") or "navNormal")
        end
        more.Parent=active and side or rail;more.Size=active and UDim2.fromOffset(100,100) or UDim2.fromOffset(94,100)
		local tracker=pg:FindFirstChild("StoryHUD") and pg.StoryHUD:FindFirstChild("Tracker")
		if tracker then tracker.Visible=not obscured;tracker.AnchorPoint=Vector2.new(1,0);tracker.Position=UDim2.new(1,-12,0,92);tracker.Size=UDim2.fromOffset(compact and 190 or 240,90) end
	end
	drawer:GetPropertyChangedSignal("Visible"):Connect(function() if layout then layout() end end)
	-- Gamepad: Select (Roblox default) enters UI navigation; B closes the open window/menu;
	-- opening a window moves the selection into it. Gold outline marks the selected control.
	local highlight=UI.New("Frame",{Name="GamepadSelection",BackgroundTransparency=1,Size=UDim2.fromScale(1,1)},{UI.Corner(12),UI.New("UIStroke",{Thickness=4,Color=Color3.fromRGB(255,213,92),ApplyStrokeMode=Enum.ApplyStrokeMode.Border})})
	pg.SelectionImageObject=highlight
	local function gamepad() local v=UIS:GetLastInputType().Value;return v>=Enum.UserInputType.Gamepad1.Value and v<=Enum.UserInputType.Gamepad8.Value end
	local function first(frame) -- top-left visible control, never the close button or full-size click catchers
		local best,by,bx
		for _,d in frame:GetDescendants() do
			if d:IsA("GuiButton") and d.Selectable and d.Visible and d.AbsoluteSize.X>4 and not d:FindFirstAncestor("WindowClose") then
				local ok,p=true,d.Parent;while p and p~=frame do if p:IsA("GuiObject") and not p.Visible then ok=false;break end;p=p.Parent end
				local a=d.AbsolutePosition
				if ok and (not best or a.Y<by-4 or (math.abs(a.Y-by)<=4 and a.X<bx)) then best,by,bx=d,a.Y,a.X end
			end
		end
		return best
	end
	local function focus(frame) if gamepad() then task.defer(function() if frame.Visible then local b=first(frame);if b then GuiService.SelectedObject=b else GuiService:Select(frame) end end end) end end
	for _,r in panels do r.panel:GetPropertyChangedSignal("Visible"):Connect(function() if r.panel.Visible then focus(r.panel) end end) end
	drawer:GetPropertyChangedSignal("Visible"):Connect(function() if drawer.Visible then focus(drawer) end end)
	UIS.InputBegan:Connect(function(input)
		if input.KeyCode~=Enum.KeyCode.ButtonB then return end
		for _,r in panels do if r.panel.Visible and r.owner.Enabled then r.panel.Visible=false;GuiService.SelectedObject=nil;return end end
		if drawer.Visible then drawer.Visible=false;GuiService.SelectedObject=nil end
	end)
	workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(layout);layout()
end
return Navigation
