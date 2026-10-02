local Players=game:GetService("Players");local S=game.ReplicatedStorage.Shared
local UI=require(S.UIKit);local Net=require(S.Net);local NF=require(S.NumberFormat)
local Daily=require(S.Config.Daily);local Boards=require(S.Config.Leaderboards)
local Controller={}
function Controller.Start()
	local player=Players.LocalPlayer;local dailyState,boardState;local tab="Daily";local scope="Server";local metric="TreesCut";local busy=false
	local gui=UI.New("ScreenGui",{Name="RewardsHUD",ResetOnSpawn=false,DisplayOrder=15,Parent=player:WaitForChild("PlayerGui")})
	local shade=UI.New("TextButton",{Name="Shade",Text="",Size=UDim2.fromScale(1,1),BackgroundColor3=Color3.new(),BackgroundTransparency=.45,Visible=false,ZIndex=0,Parent=gui})
	local panel=UI.New("Frame",{Name="Panel",AnchorPoint=Vector2.new(.5,.5),Position=UDim2.fromScale(.5,.5),Size=UDim2.fromOffset(960,650),BackgroundColor3=UI.Colors.Panel,Visible=false,Parent=gui},{UI.Corner(16),UI.Stroke(4),UI.Padding(16)})
	local scale=UI.New("UIScale",{Parent=panel})
	UI.Label("Rewards & Leaderboards",24,{Parent=panel})
	local message=UI.Label("",14,{Name="Message",Position=UDim2.new(0,0,1,-52),Size=UDim2.new(1,-130,0,44),TextColor3=UI.Colors.Accent,Parent=panel})
	local render
	local function button(name,text,parent,pos,size,fn,color)
		local b=UI.Button({text=text,textSize=16,size=size,onClick=fn,color=color or UI.Colors.Green});b.Name=name;b.Position=pos;b.Parent=parent;return b
	end
	local function request(remote,arg)
		if busy then return end;busy=true
		task.spawn(function()
			local ok,success,msg,packet=pcall(function() return Net.Function(remote):InvokeServer(arg) end)
			message.Text=ok and (msg or "") or "Could not reach the server. Try again"
			if ok and packet then if remote=="DailyAction" then dailyState=packet elseif remote=="LeaderboardRequest" then boardState=packet end end
			task.wait(remote=="CodeAction" and 1 or .4);busy=false;render()
		end)
	end
	local daily=UI.New("Frame",{Name="Daily",Position=UDim2.fromOffset(0,100),Size=UDim2.new(1,0,0,470),BackgroundTransparency=1,Parent=panel})
	local summary=UI.Label("",15,{Name="Summary",Size=UDim2.new(1,0,0,40),Parent=daily})
	local list=UI.New("ScrollingFrame",{Position=UDim2.fromOffset(0,44),Size=UDim2.new(1,0,1,-106),BackgroundTransparency=1,ScrollBarThickness=5,AutomaticCanvasSize=Enum.AutomaticSize.Y,CanvasSize=UDim2.new(),Parent=daily},{UI.Grid(4,174,12)})
	local rows,cards={},{};for i,r in Daily.Rewards do
        local card=UI.New("Frame",{Name="Day"..i,BackgroundTransparency=1,LayoutOrder=i,Parent=list});cards[i]=card;UI.Skin(card,"cards","product")
        UI.Label("DAY "..i,20,{Position=UDim2.fromOffset(8,6),Size=UDim2.new(1,-16,0,25),TextXAlignment=Enum.TextXAlignment.Center,Parent=card})
        UI.Art(card,"rewards",r.chest and (r.chest.rarity=="Epic" and "epicChest" or "rareChest") or r.boost and "woodBoost" or "gemsSmall",{Position=UDim2.fromOffset(24,33),Size=UDim2.new(1,-48,0,85)})
        rows[i]=UI.Label(r.label,15,{Position=UDim2.fromOffset(10,122),Size=UDim2.new(1,-20,0,44),TextXAlignment=Enum.TextXAlignment.Center,Parent=card})
    end
	button("Claim","Claim Today's Reward",daily,UDim2.new(1,-280,1,-56),UDim2.fromOffset(280,54),function() request("DailyAction","Claim") end)
	UI.Label("Resets at 00:00 UTC\n\nMissing a day resets your streak\nThe cycle repeats after day 7",14,{Position=UDim2.new(0,0,1,-54),Size=UDim2.new(1,-300,0,54),Parent=daily})
	local codes=UI.New("Frame",{Name="Codes",Position=UDim2.fromOffset(0,110),Size=UDim2.new(1,0,0,345),BackgroundTransparency=1,Parent=panel})
	UI.Label("Enter a code for Gems, chests or boosts\nEach code can be redeemed once and has an expiry date",18,{Size=UDim2.new(1,0,0,75),Parent=codes})
	local input=UI.New("TextBox",{Name="Input",Position=UDim2.fromOffset(0,105),Size=UDim2.new(1,-180,0,56),Text="",PlaceholderText="Enter Code",ClearTextOnFocus=false,TextSize=22,Font=Enum.Font.GothamBold,TextColor3=UI.Colors.Text,BackgroundColor3=UI.Colors.Card,Parent=codes},{UI.Corner(10),UI.Padding(10)})
	button("Redeem","Redeem Code",codes,UDim2.new(1,-168,0,105),UDim2.fromOffset(168,56),function() request("CodeAction",input.Text) end)
	local boost=UI.Label("",15,{Name="Boosts",Position=UDim2.fromOffset(0,200),Size=UDim2.new(1,0,0,90),Parent=codes})
	local board=UI.New("Frame",{Name="Boards",Position=UDim2.fromOffset(0,108),Size=UDim2.new(1,0,0,350),BackgroundTransparency=1,Parent=panel})
	local mode=UI.Label("",14,{Name="Status",Position=UDim2.fromOffset(0,44),Size=UDim2.new(1,0,0,40),Parent=board})
	for i,def in Boards.Metrics do local d=def;button(d.id,d.name,board,UDim2.fromOffset((i-1)*177,0),UDim2.fromOffset(169,40),function() metric=d.id;render() end,UI.Colors.Slate) end
	button("Server","This server",board,UDim2.fromOffset(0,88),UDim2.fromOffset(170,40),function() scope="Server";render() end,UI.Colors.Slate)
	button("Global","Global",board,UDim2.fromOffset(182,88),UDim2.fromOffset(170,40),function() scope="Global";render() end,UI.Colors.Purple)
	button("Refresh","Refresh",board,UDim2.new(1,-160,0,88),UDim2.fromOffset(160,40),function() request("LeaderboardRequest") end)
	local ranks=UI.New("ScrollingFrame",{Name="Ranks",Position=UDim2.fromOffset(0,138),Size=UDim2.new(1,0,1,-138),BackgroundTransparency=1,ScrollBarThickness=5,AutomaticCanvasSize=Enum.AutomaticSize.Y,CanvasSize=UDim2.new(),Parent=board},{UI.List(Enum.FillDirection.Vertical,3)})
	local rankRows={};for i=1,Boards.Top do rankRows[i]=UI.Label("",17,{Name="Rank"..i,Size=UDim2.new(1,-12,0,28),Parent=ranks}) end
	local flags=game.ReplicatedStorage:WaitForChild("FeatureFlags");local tabButtons={}
	local function sync() if tab=="Daily" then request("DailyAction","Sync") elseif tab=="Boards" then request("LeaderboardRequest") end end
	for i,name in {"Daily","Codes","Boards"} do local key=name
		tabButtons[key]=button("Tab"..key,key=="Boards" and "Leaderboard" or key,panel,UDim2.fromOffset((i-1)*235,48),UDim2.fromOffset(225,44),function() tab=key;render();sync() end,UI.Colors.Slate)
	end
	local function close() panel.Visible=false;shade.Visible=false end
	button("Close","Close",panel,UDim2.new(1,-120,1,-52),UDim2.fromOffset(120,44),close,UI.Colors.Slate);shade.Activated:Connect(close)
	local function open(which) tab=which or "Daily";panel.Visible=true;shade.Visible=true;render();sync() end
	local openButton=button("Open","Rewards / Leaderboard",gui,UDim2.new(1,-374,0,12),UDim2.fromOffset(174,48),function() open() end,UI.Colors.Green)
	Net.Event("LeaderboardShow").OnClientEvent:Connect(function() open("Boards") end)
	render=function()
		daily.Visible=tab=="Daily";codes.Visible=tab=="Codes";board.Visible=tab=="Boards"
		for key,b in tabButtons do UI.SetButtonColor(b,tab==key and UI.Colors.Purple or UI.Colors.Slate) end
		if dailyState then
			summary.Text="Login streak "..dailyState.streak.." days • Today: day "..dailyState.day.."/7 • "..(dailyState.claimed and "Claimed" or "Ready to Claim")
			for i,r in Daily.Rewards do rows[i].Text=r.label..(i==dailyState.day and (dailyState.claimed and " • Claimed" or " • TODAY") or "");UI.Skin(cards[i],"cards",i==dailyState.day and "today" or "product") end
		end
		if boardState then
			mode.Text="Season "..boardState.season.." • "..(scope=="Server" and "This server • Actual values" or "Global ≈ • "..boardState.status)..(boardState.studio and " • Studio uses a separate store" or "")
			local data=(scope=="Server" and boardState.localBoards or boardState.globalBoards)[metric] or {}
			for i,row in rankRows do local entry=data[i];row.Visible=entry~=nil;row.Text=entry and (i..". "..entry.name.."  "..(scope=="Global" and "≈ " or "")..NF.Short(entry.value)) or "" end
			if #data==0 then rankRows[1].Visible=true;rankRows[1].Text="No eligible rankings yet" end
		end
		local Data=require(script.Parent.ClientData);local now=os.time();local active={}
		for kind,expires in Data.Get("Boosts") or {} do if expires>now then table.insert(active,kind.." ×2 Left "..math.ceil((expires-now)/60).." min") end end
		boost.Text=#active>0 and table.concat(active,"\n") or "No active timed boosts"
	end
	local function feature() openButton.Visible=flags:GetAttribute("Daily") or flags:GetAttribute("Codes") or flags:GetAttribute("Leaderboard");if not openButton.Visible then close() end end
	for _,key in {"Daily","Codes","Leaderboard"} do flags:GetAttributeChangedSignal(key):Connect(feature) end;feature()
	local function resize() local v=workspace.CurrentCamera.ViewportSize;scale.Scale=math.min(1,(v.X-24)/740,(v.Y-40)/560) end
	workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(resize);resize()
	task.spawn(function() while true do task.wait(1);if panel.Visible then render();if tab=="Daily" and dailyState and os.time()>=dailyState.nextAt then sync() end end end end)
end
return Controller
