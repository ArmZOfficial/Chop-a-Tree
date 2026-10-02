local Players=game:GetService("Players")
local Collection=game:GetService("CollectionService")
local S=game.ReplicatedStorage.Shared
local UI=require(S.UIKit);local Net=require(S.Net);local NF=require(S.NumberFormat)
local Config=require(S.Config.Rebirth);local Balance=require(S.Balance)
local Data=require(script.Parent.ClientData)
local Controller={}
function Controller.Start()
	local player=Players.LocalPlayer;local state;local busy=false;local token
	local gui=UI.New("ScreenGui",{Name="RebirthHUD",ResetOnSpawn=false,DisplayOrder=14,Parent=player:WaitForChild("PlayerGui")})
	local shade=UI.New("TextButton",{Name="Shade",Text="",Size=UDim2.fromScale(1,1),BackgroundColor3=Color3.new(),BackgroundTransparency=.45,AutoButtonColor=false,Visible=false,Parent=gui})
	local panel=UI.New("Frame",{Name="Panel",AnchorPoint=Vector2.new(.5,.5),Position=UDim2.fromScale(.5,.5),Size=UDim2.fromOffset(720,550),BackgroundColor3=UI.Colors.Panel,Visible=false,Parent=gui},{UI.Corner(18),UI.Stroke(4),UI.Padding(16)})
	local scale=UI.New("UIScale",{Parent=panel})
	UI.Label("New Cycle • REBIRTH",24,{Parent=panel})
	local status=UI.Label("",16,{Name="Status",Position=UDim2.fromOffset(0,40),Size=UDim2.new(1,0,0,58),Parent=panel})
	local message=UI.Label("",14,{Name="Message",Position=UDim2.fromOffset(0,102),Size=UDim2.new(1,0,0,34),TextColor3=UI.Colors.Accent,Parent=panel})
	local list=UI.New("ScrollingFrame",{Name="Skills",Position=UDim2.fromOffset(0,140),Size=UDim2.new(1,0,0,285),BackgroundTransparency=1,ScrollBarThickness=5,AutomaticCanvasSize=Enum.AutomaticSize.Y,CanvasSize=UDim2.new(),Parent=panel},{UI.List(Enum.FillDirection.Vertical,8)})
	local confirm=UI.New("Frame",{Name="Confirmation",Size=UDim2.fromScale(1,1),BackgroundColor3=UI.Colors.Panel,Visible=false,ZIndex=30,Parent=panel},{UI.Corner(16),UI.Padding(20)})
	UI.Label("Start a New Cycle?",25,{Parent=confirm})
	UI.Label("Resets Coins, Wood, zones/story, base upgrades and uncollected pen income\n\nKeeps weapons, pets, eggs, chests, Gems, Index, garden trees and permanent skills\nTrees beyond starting slots still bear fruit. Buy back slots before replanting",19,{Position=UDim2.fromOffset(0,65),Size=UDim2.new(1,0,0,235),Parent=confirm})
	local render;local rows={}
	local function button(name,text,color,parent,pos,size,callback)
		local b=UI.Button({text=text,color=color,size=size,onClick=callback});b.Name=name;b.Position=pos;b.Parent=parent;return b
	end
	local function call(action,arg)
		if busy then return end;busy=true
		task.spawn(function()
			local ok,success,msg,packet,nextToken=pcall(function() return Net.Function("RebirthAction"):InvokeServer(action,arg) end)
			if ok and packet then state=packet end
			message.Text=ok and (msg or "") or "Could not reach the server. Try again"
			if action=="Prepare" and ok and success then token=nextToken;confirm.Visible=true end
			if action=="Confirm" then token=nil;confirm.Visible=false end
			task.wait(.3);busy=false;render()
		end)
	end
	local function text(b,value) b.Button:FindFirstChildWhichIsA("TextLabel",true).Text=value end
	for _,def in Config.Skills do
		local d=def
		local row=UI.New("Frame",{Name=d.id,Size=UDim2.new(1,-8,0,80),BackgroundColor3=UI.Colors.Card,Parent=list},{UI.Corner(10)})
		local label=UI.Label(d.name,16,{Name="Description",Position=UDim2.fromOffset(10,6),Size=UDim2.new(1,-185,1,-12),Parent=row})
		local buy=button("Buy","Upgrade",UI.Colors.Green,row,UDim2.new(1,-166,0,14),UDim2.fromOffset(150,52),function() if state then call("Buy",{id=d.id,rank=state.skills[d.id]}) end end)
		rows[d.id]={label=label,buy=buy}
	end
	local rebirth=button("Prepare","Start New Cycle",UI.Colors.Purple,panel,UDim2.new(0,0,1,-72),UDim2.fromOffset(430,55),function() call("Prepare") end)
	local function close() panel.Visible=false;shade.Visible=false;confirm.Visible=false;token=nil end
	button("Close","Close",UI.Colors.Slate,panel,UDim2.new(1,-155,1,-72),UDim2.fromOffset(155,55),close)
	button("Confirm","Confirm Rebirth",UI.Colors.Red,confirm,UDim2.new(0,0,1,-90),UDim2.fromOffset(310,60),function() call("Confirm",token) end)
	button("Cancel","Cancel",UI.Colors.Slate,confirm,UDim2.new(1,-270,1,-90),UDim2.fromOffset(250,60),function() token=nil;confirm.Visible=false end)
	-- Confirmation is above the panel; its content must also be above its background.
	for _,object in confirm:GetDescendants() do if object:IsA("GuiObject") then object.ZIndex=31 end end
	local open=button("Open","REBIRTH",UI.Colors.Purple,gui,UDim2.new(1,-190,0,12),UDim2.fromOffset(174,48),function() panel.Visible=true;shade.Visible=true;confirm.Visible=false;token=nil;call("Sync") end)
	shade.Activated:Connect(close)
	render=function()
		if not state then return end
		status.Text="Cycle "..state.rebirth.." • Permanent Power ×"..NF.Short(Balance.Get("RebirthPower")^state.rebirth).." • Rot ×"..NF.Short(Balance.Rot(state.rebirth)).."\n"..NF.Short(state.tokens).." Token • Defeat the boss in zone "..state.requiredZone.." + "..NF.Short(state.cost).." Coins • Earned "..state.tokensAward.." Token"
		for _,d in Config.Skills do local r=state.skills[d.id];local row=rows[d.id];row.label.Text=d.name.."  "..r.."/"..d.max.."\n"..d.description
			text(row.buy,r>=d.max and "Max tier" or ("Buy • "..d.baseCost*(r+1).." Token"));UI.SetButtonColor(row.buy,r>=d.max and UI.Colors.Slate or UI.Colors.Green)
		end
		text(rebirth,state.ready and "Start New Cycle" or state.reason);UI.SetButtonColor(rebirth,state.ready and UI.Colors.Purple or UI.Colors.Slate)
	end
	local originals=setmetatable({},{__mode="k"})
	local function tint(tree)
		local rb=Data.Get("Progress.Rebirth") or 0;local amount=math.min(.45,rb*.04)
		for _,part in tree:GetDescendants() do if part:IsA("BasePart") then originals[part]=originals[part] or part.Color;part.Color=originals[part]:Lerp(Color3.fromRGB(130,55,175),amount) end end
	end
	Collection:GetInstanceAddedSignal("Tree"):Connect(function(tree) task.defer(tint,tree) end)
	Data.Changed:Connect(function(path)
		if path=="" or path=="Progress.Rebirth" then for _,tree in Collection:GetTagged("Tree") do tint(tree) end end
		if panel.Visible and (path=="" or path:match("^Progress") or path:match("^Currencies") or path:match("^Rebirth") or path=="Run") then task.defer(function() if not busy then call("Sync") end end) end
	end)
	local flags=game.ReplicatedStorage:WaitForChild("FeatureFlags")
	local function feature() open.Visible=flags:GetAttribute("Rebirth")==true;if not open.Visible then close() end end
	flags:GetAttributeChangedSignal("Rebirth"):Connect(feature);feature()
	local function resize() local v=workspace.CurrentCamera.ViewportSize;scale.Scale=math.min(1,(v.X-24)/720,(v.Y-40)/550) end
	workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(resize);resize()
	if Data.IsReady() then for _,tree in Collection:GetTagged("Tree") do tint(tree) end end
end
return Controller
