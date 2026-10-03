-- Season Pass panel (plan 17.4). Reads the replicated Season profile; the server validates every claim and purchase.
local Players=game:GetService("Players")
local MS=game:GetService("MarketplaceService")
local S=game.ReplicatedStorage.Shared
local Net=require(S.Net);local UI=require(S.UIKit)
local C=require(S.Config.Season);local Products=require(S.Config.Products);local Rarities=require(S.Config.Rarities)
-- Reward cell: icon + short amount (gems "10", boost "×2 • 15 min", chest tinted by rarity "Lv.5").
local BOOST_ICON={Wood="wood",Coins="coin",Exp="star",Luck="clover"}
local function look(r)
	if r.gems then return "gem",nil,tostring(r.gems) end
	if r.boost then return BOOST_ICON[r.boost.kind] or "boost",nil,"×2 • "..math.floor(r.boost.seconds/60).." min" end
	if r.chest then return "chest",Rarities.Color[r.chest.rarity],"Lv."..r.chest.level end
	return "gift",nil,r.label
end
local Data=require(script.Parent.ClientData)
local Controller={}
function Controller.Start()
	local player=Players.LocalPlayer
	local flags=game.ReplicatedStorage.FeatureFlags
	local gui=UI.New("ScreenGui",{Name="SeasonHUD",ResetOnSpawn=false,DisplayOrder=13,Parent=player:WaitForChild("PlayerGui")})
	local panel=UI.New("Frame",{Name="Panel",AnchorPoint=Vector2.new(.5,.5),Position=UDim2.fromScale(.5,.5),Size=UDim2.fromOffset(760,540),Visible=false,BackgroundColor3=UI.Colors.Panel,Parent=gui},{UI.Corner(16),UI.Stroke(4),UI.Padding(14)})
	local title=UI.Label("Season Pass",22,{Name="Title",Parent=panel})
	local info=UI.Label("",20,{Name="Info",Position=UDim2.fromOffset(0,38),Size=UDim2.new(1,-80,0,26),TextWrapped=false,Parent=panel})
	local xpBar=UI.Progress(panel,{Name="Xp",Position=UDim2.fromOffset(0,66),Size=UDim2.new(1,0,0,26)})
	local xpText=UI.Label("",15,{Name="XpText",Size=UDim2.fromScale(1,1),TextXAlignment=Enum.TextXAlignment.Center,ZIndex=6,Parent=xpBar})
	local message=UI.Label("",14,{Name="Message",Position=UDim2.new(0,0,1,-24),Size=UDim2.new(1,0,0,24),TextColor3=UI.Colors.Accent,Parent=panel})
	for i,h in {{"Free","gift"},{"Premium","crown"}} do -- column headers
		local head=UI.New("Frame",{Name="Head"..h[1],BackgroundTransparency=1,Position=UDim2.new((i-1)*.5,i==1 and 70 or 4,0,156),Size=UDim2.new(.5,i==1 and -74 or -12,0,30),Parent=panel})
		UI.Icon(head,h[2],{Size=UDim2.fromOffset(30,30)});UI.Label(h[1],20,{Position=UDim2.fromOffset(38,0),Size=UDim2.new(1,-38,1,0),TextWrapped=false,Parent=head})
	end
	local list=UI.New("ScrollingFrame",{Name="Levels",Position=UDim2.fromOffset(0,190),Size=UDim2.new(1,0,1,-218),BackgroundTransparency=1,ScrollBarThickness=5,AutomaticCanvasSize=Enum.AutomaticSize.Y,CanvasSize=UDim2.new(),Parent=panel},{UI.List(Enum.FillDirection.Vertical,6)})
	local price,busy,render=nil,false,nil
	local function show(ok,success,msg)
		message.Text=ok and (msg or "") or "Could not reach the server";message.TextColor3=ok and success and UI.Colors.Accent or UI.Colors.Red
	end
	local function request(remote,...)
		if busy then return end;busy=true;local args={...}
		task.spawn(function()
			local ok,success,msg=pcall(function() return Net.Function(remote):InvokeServer(table.unpack(args)) end)
			show(ok,success,msg);task.wait(.35);busy=false;render()
		end)
	end
	local function active()
		local now=workspace:GetServerTimeNow()
		for _,s in C.Seasons do if now>=s.startsAt and now<s.endsAt then return s end end
	end
	local function button(name,text,parent,pos,size,color,fn)
		local b=UI.Button({text=text,textSize=19,color=color,size=size,onClick=fn});b.Name=name;b.Position=pos;b.Parent=parent;return b
	end
	button("ClaimAll","Claim All",panel,UDim2.fromOffset(0,102),UDim2.new(.36,-6,0,48),UI.Colors.Green,function() request("SeasonAction","ClaimAll") end)
	local buy=button("BuyPremium","Premium",panel,UDim2.new(.36,6,0,102),UDim2.new(.64,-6,0,48),UI.Colors.Purple,function() request("ShopAction","Prompt","seasonPremium") end)
	local buyLabel=buy:FindFirstChildWhichIsA("TextLabel",true)
	render=function()
		if not panel.Visible then return end
		local season=active();local d=Data.Get("Season") or {}
		local current=season and d.id==season.id
		local xp=current and d.xp or 0;local level=math.min(#C.Levels,math.floor(xp/C.XpPerLevel))
		local premium=current and d.premium==true;local free=current and d.free or {};local prem=current and d.prem or {}
		local into=level>=#C.Levels and C.XpPerLevel or xp%C.XpPerLevel
		UI.SetProgress(xpBar,into/C.XpPerLevel);xpText.Text="XP "..into.."/"..C.XpPerLevel
		if not season then title.Text="Season Pass";info.Text="No active season. Wait for the next season"
		else
			local days=math.max(0,math.ceil((season.endsAt-workspace:GetServerTimeNow())/86400))
			title.Text="Season Pass • "..season.name
			info.Text="Level "..level.."/"..#C.Levels.." • "..days.." days left"
		end
		if buyLabel then
			if premium then buyLabel.Text="Premium ✓ Unlocked"
			else
				if price==nil then price=false
					task.spawn(function() local ok,i=pcall(MS.GetProductInfo,MS,Products.SeasonPremium.id,Enum.InfoType.Product);price=ok and i.PriceInRobux or false;render() end)
				end
				buyLabel.Text="Buy Premium • "..(price and ("R$ "..price) or "R$ …")
			end
		end
		-- Rows are updated in place (no rebuild on every data change).
		for i,row in C.Levels do
			local frame=list:FindFirstChild("Level"..i) or UI.New("Frame",{Name="Level"..i,Size=UDim2.new(1,-8,0,64),BackgroundTransparency=1,LayoutOrder=i,Parent=list})
			local lv=frame:FindFirstChild("Lv") or UI.Badge(frame,"",nil,{Name="Lv",AnchorPoint=Vector2.new(0,.5),Position=UDim2.new(0,0,.5,0),Size=UDim2.fromOffset(62,44)})
			UI.SetBadge(lv,tostring(i),i<=level and "gold" or nil)
			local key=tostring(i)
			local function cell(name,track,reward,claimed,locked,x)
				local icon,tint,amount=look(reward);local ready=not claimed and not locked and i<=level
				local c=UI.Row(frame,name,{icon=icon,iconColor=tint,title=amount,dim=claimed or locked,style=ready and (track=="premium" and "epic" or "today") or "product",
					chip=locked and {icon="lock",text="",width=40} or nil,badge=claimed and {text="",kind="claimed",width=48} or ready and {text="Claim",kind="ready",width=100} or nil,
					onClick=function() if ready then request("SeasonAction","Claim",track,i) end end})
				c.Position=UDim2.new(x,x==0 and 70 or 4,0,0);c.Size=UDim2.new(.5,x==0 and -74 or -12,1,0)
			end
			cell("Free","free",row.free,free[key]==true,false,0)
			cell("Premium","premium",row.premium,prem[key]==true,not premium,.5)
		end
	end
	local toggle=UI.Button({text="Season Pass",color=UI.Colors.Purple,size=UDim2.fromOffset(130,48),onClick=function()
		panel.Visible=not panel.Visible
	end});toggle.Name="Toggle";toggle.Position=UDim2.fromOffset(200,425);toggle.Parent=gui
	-- Render on every open (menu tile, gamepad, other windows), not only from this toggle.
	panel:GetPropertyChangedSignal("Visible"):Connect(function() if panel.Visible then message.Text="";render() end end)
	local function resize() local size=workspace.CurrentCamera.ViewportSize;panel.Size=UDim2.fromOffset(math.min(760,size.X-28),math.min(540,size.Y-60)) end
	workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(resize);resize()
	local function flag() gui.Enabled=flags:GetAttribute("SeasonPass")==true end
	flags:GetAttributeChangedSignal("SeasonPass"):Connect(flag);flag()
	Data.Changed:Connect(function(path) if path=="" or string.sub(path,1,6)=="Season" then render() end end)
end
return Controller
