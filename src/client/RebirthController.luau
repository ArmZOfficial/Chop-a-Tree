local Players=game:GetService("Players")
local Collection=game:GetService("CollectionService")
local S=game.ReplicatedStorage.Shared
local UI=require(S.UIKit);local Net=require(S.Net);local NF=require(S.NumberFormat)
local Config=require(S.Config.Rebirth);local Balance=require(S.Balance)
local Data=require(script.Parent.ClientData)
local Controller={}
-- Skill rows: icon + name + one short effect line (the full description lives in Config.Rebirth).
local SKILL={AutoCut={"axe","Auto Cut penalty −5%"},PetSlots={"friends","+1 pet carried"},ChestLevel={"chest","Run chests +1 level"},Wood={"wood","+50% Wood"},Coins={"coin","+50% Coins"},Luck={"clover","+12.5% Epic+ chest chance"}}
function Controller.Start()
	local player=Players.LocalPlayer;local state;local busy=false;local token
	local gui=UI.New("ScreenGui",{Name="RebirthHUD",ResetOnSpawn=false,DisplayOrder=14,Parent=player:WaitForChild("PlayerGui")})
	local shade=UI.New("TextButton",{Name="Shade",Text="",Size=UDim2.fromScale(1,1),BackgroundColor3=Color3.new(),BackgroundTransparency=.45,AutoButtonColor=false,Visible=false,ZIndex=0,Parent=gui}) -- under the window (Global ZIndex)
	local panel=UI.New("Frame",{Name="Panel",AnchorPoint=Vector2.new(.5,.5),Position=UDim2.fromScale(.5,.5),Size=UDim2.fromOffset(720,550),BackgroundColor3=UI.Colors.Panel,Visible=false,Parent=gui},{UI.Corner(18),UI.Stroke(4),UI.Padding(16)})
	local scale=UI.New("UIScale",{Parent=panel})
	UI.Label("New Cycle • REBIRTH",24,{Parent=panel})
	local caps={}
	for i,c in {{"cycle","Cycle"},{"power","Power"},{"token","Tokens"}} do
		local _,value=UI.Capsule(panel,c[1],c[2],{Name="Stat"..c[2],Position=UDim2.new((i-1)/3,i==1 and 0 or 5,0,42),Size=UDim2.new(1/3,-10,0,58)});caps[i]=value
	end
	local message=UI.Label("",14,{Name="Message",Position=UDim2.fromOffset(0,170),Size=UDim2.new(1,0,0,20),TextColor3=UI.Colors.Accent,Parent=panel})
	local list=UI.New("ScrollingFrame",{Name="Skills",Position=UDim2.fromOffset(0,192),Size=UDim2.new(1,0,1,-262),BackgroundTransparency=1,ScrollBarThickness=5,AutomaticCanvasSize=Enum.AutomaticSize.Y,CanvasSize=UDim2.new(),Parent=panel},{UI.List(Enum.FillDirection.Vertical,8)})
	local confirm=UI.New("Frame",{Name="Confirmation",Size=UDim2.fromScale(1,1),BackgroundColor3=UI.Colors.Panel,Visible=false,ZIndex=30,Parent=panel},{UI.Corner(16),UI.Padding(20)})
	UI.Label("Start a New Cycle?",25,{Name="Heading",Parent=confirm})
	UI.Label("Resets: Coins, Wood, zones, story, base upgrades\n\nKeeps: weapons, pets, eggs, chests, Gems, Index, garden, skills",22,{Name="Body",Position=UDim2.fromOffset(0,65),Size=UDim2.new(1,0,0,235),Parent=confirm})
	local render
	local function button(name,text,color,parent,pos,size,callback)
		local b=UI.Button({text=text,textSize=size.Y.Offset>=58 and 22 or nil,color=color,size=size,onClick=callback});b.Name=name;b.Position=pos;b.Parent=parent;return b
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
	local rebirth=button("Prepare","Start New Cycle",UI.Colors.Purple,panel,UDim2.new(0,0,1,-62),UDim2.new(1,0,0,58),function() call("Prepare") end)
	local function close() panel.Visible=false;shade.Visible=false;confirm.Visible=false;token=nil end
	button("Confirm","Confirm Rebirth",UI.Colors.Red,confirm,UDim2.new(0,0,1,-90),UDim2.fromOffset(310,60),function() call("Confirm",token) end)
	button("Cancel","Cancel",UI.Colors.Slate,confirm,UDim2.new(1,-270,1,-90),UDim2.fromOffset(250,60),function() token=nil;confirm.Visible=false end)
	-- Confirmation is above the panel; its content must also be above its background.
	for _,object in confirm:GetDescendants() do if object:IsA("GuiObject") then object.ZIndex=object:IsA("TextLabel") and 32 or 31 end end
	local open=button("Open","REBIRTH",UI.Colors.Purple,gui,UDim2.new(1,-190,0,12),UDim2.fromOffset(174,48),function() panel.Visible=true;shade.Visible=true;confirm.Visible=false;token=nil;call("Sync") end)
	shade.Activated:Connect(close)
	render=function()
		if not state then return end
		caps[1].Text=tostring(state.rebirth);caps[2].Text="×"..NF.Short(Balance.Get("RebirthPower")^state.rebirth).."  Rot ×"..NF.Short(Balance.Rot(state.rebirth));caps[3].Text=NF.Short(state.tokens).." (+"..state.tokensAward..")"
		local need=UI.Row(panel,"Requirement",{icon="boss",title="Beat the Zone "..state.requiredZone.." boss",chip={icon="coin",text=NF.Short(state.cost)},badge=state.ready and {text="Ready",kind="ready"} or nil,style=state.ready and "today" or "product"})
		need.Position=UDim2.fromOffset(0,panel:GetAttribute("PhoneLayout") and 58 or 106);need.Size=UDim2.new(1,0,0,58)
		for i,d in Config.Skills do local id,r=d.id,state.skills[d.id];local max=r>=d.max;local cost=d.baseCost*(r+1)
			UI.Row(list,id,{icon=SKILL[id] and SKILL[id][1] or "star",title=d.name.."  "..r.."/"..d.max,sub=SKILL[id] and SKILL[id][2] or d.description,chip=not max and {icon="token",text=tostring(cost),width=80} or nil,
				badge=max and {text="Max",kind="gold"} or {text="Buy",kind=state.tokens>=cost and "ready" or nil,width=90},
				onClick=function() if state and not max then call("Buy",{id=id,rank=state.skills[id]}) end end}).LayoutOrder=i
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
