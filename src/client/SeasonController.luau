-- Season Pass panel (plan 17.4). Reads the replicated Season profile; the server validates every claim and purchase.
local Players=game:GetService("Players")
local MS=game:GetService("MarketplaceService")
local S=game.ReplicatedStorage.Shared
local Net=require(S.Net);local UI=require(S.UIKit)
local C=require(S.Config.Season);local Products=require(S.Config.Products)
local Data=require(script.Parent.ClientData)
local Controller={}
function Controller.Start()
	local player=Players.LocalPlayer
	local flags=game.ReplicatedStorage.FeatureFlags
	local gui=UI.New("ScreenGui",{Name="SeasonHUD",ResetOnSpawn=false,DisplayOrder=13,Parent=player:WaitForChild("PlayerGui")})
	local panel=UI.New("Frame",{Name="Panel",AnchorPoint=Vector2.new(.5,.5),Position=UDim2.fromScale(.5,.5),Size=UDim2.fromOffset(760,540),Visible=false,BackgroundColor3=UI.Colors.Panel,Parent=gui},{UI.Corner(16),UI.Stroke(4),UI.Padding(14)})
	local title=UI.Label("Season Pass",22,{Name="Title",Parent=panel})
	local info=UI.Label("",15,{Name="Info",Position=UDim2.fromOffset(0,32),Size=UDim2.new(1,0,0,44),Parent=panel})
	local message=UI.Label("",14,{Name="Message",Position=UDim2.new(0,0,1,-104),Size=UDim2.new(1,0,0,40),TextColor3=UI.Colors.Accent,Parent=panel})
	local list=UI.New("ScrollingFrame",{Name="Levels",Position=UDim2.fromOffset(0,140),Size=UDim2.new(1,0,1,-250),BackgroundTransparency=1,ScrollBarThickness=5,AutomaticCanvasSize=Enum.AutomaticSize.Y,CanvasSize=UDim2.new(),Parent=panel},{UI.List(Enum.FillDirection.Vertical,6)})
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
		local b=UI.Button({text=text,textSize=15,color=color,size=size,onClick=fn});b.Name=name;b.Position=pos;b.Parent=parent;return b
	end
	button("ClaimAll","Claim All",panel,UDim2.fromOffset(0,84),UDim2.fromOffset(200,48),UI.Colors.Green,function() request("SeasonAction","ClaimAll") end)
	local buy=button("BuyPremium","Premium",panel,UDim2.fromOffset(212,84),UDim2.fromOffset(300,48),UI.Colors.Purple,function() request("ShopAction","Prompt","seasonPremium") end)
	local buyLabel=buy:FindFirstChildWhichIsA("TextLabel",true)
	render=function()
		if not panel.Visible then return end
		local season=active();local d=Data.Get("Season") or {}
		local current=season and d.id==season.id
		local xp=current and d.xp or 0;local level=math.min(#C.Levels,math.floor(xp/C.XpPerLevel))
		local premium=current and d.premium==true;local free=current and d.free or {};local prem=current and d.prem or {}
		if not season then title.Text="Season Pass";info.Text="No active season. Wait for the next season"
		else
			local days=math.max(0,math.ceil((season.endsAt-workspace:GetServerTimeNow())/86400))
			title.Text="Season Pass • "..season.name
			info.Text=string.format("Level %d/%d • XP %d/%d • %d days left\nEarn XP by chopping (Auto Cut earns half), planting, harvesting, hatching, opening chests and defeating bosses",
				level,#C.Levels,level>=#C.Levels and C.XpPerLevel or xp%C.XpPerLevel,C.XpPerLevel,days)
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
		for _,v in list:GetChildren() do if v:IsA("GuiObject") then v:Destroy() end end
		for i,row in C.Levels do
			local frame=UI.New("Frame",{Name="Level"..i,Size=UDim2.new(1,-8,0,52),BackgroundTransparency=1,LayoutOrder=i,Parent=list})
			UI.Label("Lv."..i,18,{Size=UDim2.new(0,64,1,0),TextColor3=i<=level and UI.Colors.Accent or UI.Colors.TextDim,Parent=frame})
			local key=tostring(i)
			local function cell(name,track,reward,claimed,locked,x)
				local text,color=reward.label,UI.Colors.Slate
				if claimed then text="✓ "..text elseif locked then text="🔒 "..text elseif i<=level then text="Claim • "..text;color=track=="premium" and UI.Colors.Purple or UI.Colors.Green end
				button(name,text,frame,UDim2.new(x,x==0 and 70 or 35,0,0),UDim2.new(.5,-39,1,0),color,function()
					if not claimed and not locked and i<=level then request("SeasonAction","Claim",track,i) end
				end)
			end
			cell("Free","free",row.free,free[key]==true,false,0)
			cell("Premium","premium",row.premium,prem[key]==true,not premium,.5)
		end
	end
	local close=UI.Button({text="Close",color=UI.Colors.Slate,size=UDim2.new(1,0,0,50),onClick=function() panel.Visible=false end});close.Name="Close";close.Position=UDim2.new(0,0,1,-50);close.Parent=panel
	local toggle=UI.Button({text="Season Pass",color=UI.Colors.Purple,size=UDim2.fromOffset(130,48),onClick=function()
		panel.Visible=not panel.Visible;message.Text="";render()
	end});toggle.Name="Toggle";toggle.Position=UDim2.fromOffset(200,425);toggle.Parent=gui
	local function resize() local size=workspace.CurrentCamera.ViewportSize;panel.Size=UDim2.fromOffset(math.min(760,size.X-28),math.min(540,size.Y-60)) end
	workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(resize);resize()
	local function flag() gui.Enabled=flags:GetAttribute("SeasonPass")==true end
	flags:GetAttributeChangedSignal("SeasonPass"):Connect(flag);flag()
	Data.Changed:Connect(function(path) if path=="" or string.sub(path,1,6)=="Season" then render() end end)
end
return Controller
