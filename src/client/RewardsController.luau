-- Rewards window (concept: assets/ui/elements-v1/concepts/rewards.png). Server intents unchanged.
local Players=game:GetService("Players");local S=game.ReplicatedStorage.Shared
local UI=require(S.UIKit);local Net=require(S.Net);local NF=require(S.NumberFormat)
local Daily=require(S.Config.Daily);local Boards=require(S.Config.Leaderboards)
local Controller={}
-- Leaderboard metric tabs: icon + one short word.
local METRIC={TreesCut={"tree","Trees"},HighestHit={"sword","Damage"},Rebirth={"cycle","Rebirth"},Income={"coin","Income"},Likes={"heart","Likes"}}
local function rewardArt(r)
	if r.chest then return r.chest.rarity=="Epic" and "epicChest" or "rareChest" end
	if r.boost then return r.boost.kind=="Wood" and "woodBoost" or "luckBoost" end
	return (r.gems or 0)>=75 and "gemsMedium" or "gemsSmall"
end
function Controller.Start()
	local player=Players.LocalPlayer;local dailyState,boardState;local tab="Daily";local scope="Server";local metric="TreesCut";local busy=false
	local gui=UI.New("ScreenGui",{Name="RewardsHUD",ResetOnSpawn=false,ZIndexBehavior=Enum.ZIndexBehavior.Sibling,DisplayOrder=15,Parent=player:WaitForChild("PlayerGui")})
	local shade=UI.New("TextButton",{Name="Shade",Text="",Size=UDim2.fromScale(1,1),BackgroundColor3=Color3.new(),BackgroundTransparency=.45,Visible=false,ZIndex=0,Parent=gui})
	local panel=UI.New("Frame",{Name="Panel",AnchorPoint=Vector2.new(.5,.5),Position=UDim2.fromScale(.5,.5),Size=UDim2.fromOffset(960,650),BackgroundTransparency=1,Visible=false,Parent=gui})
	UI.Window(panel,"Rewards","rewards/gift",{plaque=370})
	local streakBox=UI.New("Frame",{Name="Streak",BackgroundTransparency=1,AnchorPoint=Vector2.new(1,.5),Position=UDim2.new(1,-92,.105,-2),Size=UDim2.fromOffset(320,56),Parent=panel});UI.Skin(streakBox,"chrome","infoRow")
	local streak=UI.Label("",24,{Name="StreakText",RichText=true,Size=UDim2.fromScale(1,1),TextXAlignment=Enum.TextXAlignment.Center,TextWrapped=false,ZIndex=3,Parent=streakBox})
	streak.TextScaled=true;UI.New("UITextSizeConstraint",{MaxTextSize=24,MinTextSize=12,Parent=streak}) -- narrow box on phones / long Thai
	local message=UI.Label("",14,{Name="Message",Visible=false,Parent=panel})
	local render
	local function button(name,text,parent,pos,size,fn,color,textSize)
		local b=UI.Button({text=text,textSize=textSize or 18,size=size,onClick=fn,color=color or UI.Colors.Green});b.Name=name;b.Position=pos;b.Parent=parent;return b
	end
	local function request(remote,arg)
		if busy then return end;busy=true
		task.spawn(function()
			local ok,success,msg,packet=pcall(function() return Net.Function(remote):InvokeServer(arg) end)
			message.Text=ok and (msg or "") or "Could not reach the server. Try again"
			if message.Text~="" and (remote~="DailyAction" or arg~="Sync") and remote~="LeaderboardRequest" then UI.Toast(gui,message.Text,ok and success and UI.Colors.Accent or UI.Colors.Red) end
			if ok and packet then if remote=="DailyAction" then dailyState=packet elseif remote=="LeaderboardRequest" then boardState=packet end end
			task.wait(remote=="CodeAction" and 1 or .4);busy=false;render()
		end)
	end
	-- Daily: 4 + 3 calendar.
	local daily=UI.New("Frame",{Name="Daily",Position=UDim2.fromOffset(0,0),Size=UDim2.fromScale(1,1),BackgroundTransparency=1,Parent=panel})
	local cards,labels,badges={},{},{}
	for i,r in Daily.Rewards do
		local top=i<=4;local w=top and 208 or 270;local x=top and 44+(i-1)*220 or 480+(i-6)*282-w/2
		local card=UI.New("Frame",{Name="Day"..i,BackgroundTransparency=1,Position=UDim2.fromOffset(x,top and 188 or 380),Size=UDim2.fromOffset(w,top and 182 or 160),Parent=daily});cards[i]=card;UI.Skin(card,"cards","product")
		UI.Label("Day "..i,26,{Name="DayLabel",Position=UDim2.fromOffset(8,8),Size=UDim2.new(1,-16,0,30),TextXAlignment=Enum.TextXAlignment.Center,Parent=card}):FindFirstChildOfClass("UIStroke").Thickness=3
		UI.Art(card,"rewards",rewardArt(r),{Position=UDim2.fromOffset(30,38),Size=UDim2.new(1,-60,1,top and -110 or -88)})
		labels[i]=UI.Label((r.label:gsub("Chests (%a+) Lv","%1 Chest Lv")),20,{Name="Reward",Position=UDim2.new(0,8,1,top and -72 or -46),Size=UDim2.new(1,-16,0,30),TextXAlignment=Enum.TextXAlignment.Center,TextScaled=true,Parent=card})
		UI.New("UITextSizeConstraint",{MaxTextSize=21,Parent=labels[i]})
		badges[i]=UI.Badge(card,"Claimed","claimed",{Name="Status",AnchorPoint=Vector2.new(.5,1),Position=UDim2.new(.5,0,1,-6),Size=UDim2.fromOffset(150,38),Visible=false,ZIndex=5})
	end
	UI.InfoBar(daily,"Daily reset: 00:00 UTC • Missing a day resets your streak",{Name="Reset",Position=UDim2.fromOffset(44,556),Size=UDim2.fromOffset(560,54)},"book")
	local claim=button("Claim","Claim Today",daily,UDim2.fromOffset(620,546),UDim2.fromOffset(300,68),function() request("DailyAction","Claim") end,UI.Colors.Green,34)
	-- Codes
	local codes=UI.New("Frame",{Name="Codes",Position=UDim2.fromOffset(44,190),Size=UDim2.fromOffset(872,420),BackgroundTransparency=1,Parent=panel})
	UI.Icon(codes,"season",{AnchorPoint=Vector2.new(.5,0),Position=UDim2.new(.5,0,0,0),Size=UDim2.fromOffset(120,96)})
	UI.Label("Enter a code for Gems, chests or boosts\nEach code can be redeemed once and has an expiry date",20,{Position=UDim2.fromOffset(0,100),Size=UDim2.new(1,0,0,60),TextXAlignment=Enum.TextXAlignment.Center,Parent=codes})
	local inputBox=UI.New("Frame",{Name="InputBox",BackgroundTransparency=1,Position=UDim2.fromOffset(110,176),Size=UDim2.fromOffset(440,64),Parent=codes});UI.Skin(inputBox,"chrome","infoRow")
	local input=UI.New("TextBox",{Name="Input",BackgroundTransparency=1,Position=UDim2.fromOffset(20,0),Size=UDim2.new(1,-40,1,0),Text="",PlaceholderText="Enter Code",PlaceholderColor3=Color3.fromRGB(190,160,130),ClearTextOnFocus=false,TextSize=26,FontFace=UI.Font,TextColor3=UI.Colors.Text,ZIndex=4,Parent=inputBox})
	button("Redeem","Redeem",codes,UDim2.fromOffset(566,174),UDim2.fromOffset(196,68),function() request("CodeAction",input.Text) end,UI.Colors.Green,28)
	local boost=UI.Label("",18,{Name="Boosts",Position=UDim2.fromOffset(110,262),Size=UDim2.fromOffset(652,120),TextXAlignment=Enum.TextXAlignment.Center,TextYAlignment=Enum.TextYAlignment.Top,Parent=codes})
	-- Leaderboard
	local board=UI.New("Frame",{Name="Boards",Position=UDim2.fromOffset(44,188),Size=UDim2.fromOffset(872,424),BackgroundTransparency=1,Parent=panel})
	-- One row of metric tabs plus a Server/Global toggle; boards refresh by themselves while open.
	local metricTabs={}
	for i,def in Boards.Metrics do local d=def;local m=METRIC[d.id] or {"trophy",d.name}
		metricTabs[d.id]=UI.Tab({name=d.id,text=m[2],icon=m[1],iconSize=30,size=UDim2.fromOffset(136,52),position=UDim2.fromOffset((i-1)*144,0),parent=board,textSize=18,onClick=function() metric=d.id;render() end})
	end
	local scopeTab=UI.Tab({name="Scope",text="Server",icon="home",iconSize=30,size=UDim2.fromOffset(144,52),position=UDim2.new(1,-144,0,0),parent=board,textSize=18,state="green",onClick=function() scope=scope=="Server" and "Global" or "Server";render() end})
	local ranks=UI.New("ScrollingFrame",{Name="Ranks",Position=UDim2.fromOffset(0,64),Size=UDim2.new(1,0,1,-64),BackgroundTransparency=1,ScrollBarThickness=6,ScrollBarImageColor3=Color3.fromRGB(240,180,90),AutomaticCanvasSize=Enum.AutomaticSize.Y,CanvasSize=UDim2.new(),Parent=board},{UI.List(Enum.FillDirection.Vertical,6)})
	local MEDAL={Color3.new(1,1,1),Color3.fromRGB(205,215,230),Color3.fromRGB(235,150,95)}
	local flags=game.ReplicatedStorage:WaitForChild("FeatureFlags");local tabButtons={}
	local function sync() if tab=="Daily" then request("DailyAction","Sync") elseif tab=="Boards" then request("LeaderboardRequest") end end
	for i,t in {{"Daily","Daily","gift"},{"Codes","Codes","season"},{"Boards","Leaderboard","trophy"}} do local key=t[1]
		tabButtons[key]=UI.Tab({name="Tab"..key,text=t[2],icon=t[3],size=UDim2.fromOffset(282,60),position=UDim2.fromOffset(44+(i-1)*295,120),parent=panel,textSize=28,onClick=function() tab=key;render();sync() end})
	end
	local function close() panel.Visible=false;shade.Visible=false end
	shade.Activated:Connect(close)
	local function open(which) tab=which or "Daily";panel.Visible=true;shade.Visible=true;render();sync() end
	local openButton=button("Open","Rewards / Leaderboard",gui,UDim2.new(1,-374,0,12),UDim2.fromOffset(174,48),function() open() end,UI.Colors.Green)
	Net.Event("LeaderboardShow").OnClientEvent:Connect(function() open("Boards") end)
	render=function()
		daily.Visible=tab=="Daily";codes.Visible=tab=="Codes";board.Visible=tab=="Boards"
		for key,b in tabButtons do UI.SetTab(b,tab==key and "gold" or nil) end
		for key,b in metricTabs do UI.SetTab(b,metric==key and "gold" or nil) end
		local scopeLabel=scopeTab:FindFirstChild("TabLabel",true);if scopeLabel then scopeLabel.Text=scope=="Server" and "Server" or "Global" end
		if dailyState then
			streak.Text="Login Streak: <font color='#FFD24A'>"..dailyState.streak.." day"..(dailyState.streak==1 and "" or "s").."</font>"
			for i in Daily.Rewards do
				local done=i<dailyState.day or (i==dailyState.day and dailyState.claimed)
				UI.Skin(cards[i],"cards",i==dailyState.day and "today" or "product")
				badges[i].Visible=done or i==dailyState.day
				if done then UI.SetBadge(badges[i],"Claimed","claimed") elseif i==dailyState.day then UI.SetBadge(badges[i],"Today","gold") end
				labels[i].Position=UDim2.new(0,8,1,badges[i].Visible and (i<=4 and -72 or -76) or -46)
			end
			local label=claim.Button:FindFirstChildWhichIsA("TextLabel",true);label.Text=dailyState.claimed and "Claimed" or "Claim Today"
			UI.SetButtonColor(claim,dailyState.claimed and UI.Colors.Slate or UI.Colors.Green)
		end
		if boardState then
			local data=(scope=="Server" and boardState.localBoards or boardState.globalBoards)[metric] or {};local icon=(METRIC[metric] or {"trophy"})[1]
			for i=1,Boards.Top do local entry=data[i];local name="Rank"..i
				if entry then UI.Row(ranks,name,{icon=i<=3 and "medal" or nil,iconColor=MEDAL[i],title=(i>3 and i..".  " or "")..entry.name,chip={icon=icon,text=(scope=="Global" and "≈" or "")..NF.Short(entry.value),width=150},style=i==1 and "today" or "product"}).LayoutOrder=i
				elseif ranks:FindFirstChild(name) then ranks[name]:Destroy() end
			end
			local empty=ranks:FindFirstChild("Empty")
			if #data==0 then UI.Row(ranks,"Empty",{icon="trophy",title="No eligible rankings yet"}) elseif empty then empty:Destroy() end
		end
		local Data=require(script.Parent.ClientData);local now=os.time();local active={}
		for kind,expires in Data.Get("Boosts") or {} do if expires>now then table.insert(active,kind.." ×2 • "..math.ceil((expires-now)/60).." min left") end end
		boost.Text=#active>0 and ("Active boosts\n"..table.concat(active,"\n")) or "No active timed boosts"
	end
	local function feature() openButton.Visible=flags:GetAttribute("Daily") or flags:GetAttribute("Codes") or flags:GetAttribute("Leaderboard");if not openButton.Visible then close() end end
	for _,key in {"Daily","Codes","Leaderboard"} do flags:GetAttributeChangedSignal(key):Connect(feature) end;feature()
	task.spawn(function() local last=0;while true do task.wait(1);if panel.Visible then render()
		if tab=="Daily" and dailyState and os.time()>=dailyState.nextAt then sync() end
		if tab=="Boards" and os.clock()-last>=Boards.RefreshSeconds then last=os.clock();sync() end end end end)
end
return Controller
