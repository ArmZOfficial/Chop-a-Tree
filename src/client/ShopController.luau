-- Robux shop panel (plan 17). The server validates and opens every purchase prompt.
local Players=game:GetService("Players")
local MS=game:GetService("MarketplaceService")
local TextChat=game:GetService("TextChatService")
local S=game.ReplicatedStorage.Shared
local Net=require(S.Net);local UI=require(S.UIKit)
local C=require(S.Config.Products)
local Data=require(script.Parent.ClientData)
local Shop={}
function Shop.Start()
	local player=Players.LocalPlayer
	local flags=game.ReplicatedStorage.FeatureFlags
	local gui=UI.New("ScreenGui",{Name="ShopHUD",ResetOnSpawn=false,DisplayOrder=12,Parent=player:WaitForChild("PlayerGui")})
	local panel=UI.New("Frame",{Name="Panel",AnchorPoint=Vector2.new(.5,.5),Position=UDim2.fromScale(.5,.5),Size=UDim2.fromOffset(700,520),Visible=false,BackgroundColor3=UI.Colors.Panel,Parent=gui},{UI.Corner(16),UI.Stroke(4),UI.Padding(14)})
	UI.Label("Robux Shop • Free players can reach the same goals",20,{Parent=panel})
	local message=UI.Label("",14,{Name="Message",Position=UDim2.fromOffset(0,30),Size=UDim2.new(1,0,0,24),TextColor3=UI.Colors.Accent,Parent=panel})
	local list=UI.New("ScrollingFrame",{Name="Items",Position=UDim2.fromOffset(0,112),Size=UDim2.new(1,0,1,-170),BackgroundTransparency=1,ScrollBarThickness=5,AutomaticCanvasSize=Enum.AutomaticSize.Y,CanvasSize=UDim2.new(),Parent=panel},{UI.List(Enum.FillDirection.Vertical,6)})
	local tab,prices,render="Passes",{},nil
	local function price(id,kind)
		if prices[id]==nil then prices[id]=false
			task.spawn(function()
				local ok,info=pcall(MS.GetProductInfo,MS,id,kind);prices[id]=ok and info.PriceInRobux or false;render()
			end)
		end
		return prices[id] and ("R$ "..prices[id]) or "R$ …"
	end
	local function request(action,key)
		task.spawn(function()
			local ok,success,msg=pcall(function() return Net.Function("ShopAction"):InvokeServer(action,key) end)
			message.Text=ok and (msg or "") or "Could not reach the server";message.TextColor3=ok and success and UI.Colors.Accent or UI.Colors.Red
		end)
	end
	local function row(name,text,color,callback)
		local b=UI.Button({text=text,color=color,size=UDim2.new(1,-8,0,58),onClick=callback});b.Name=name;b.Parent=list
	end
	render=function()
		if not panel.Visible then return end
		for _,v in list:GetChildren() do if v:IsA("GuiObject") then v:Destroy() end end
		local owned=Data.Get("Purchases.passes") or {}
		if tab=="Passes" then
			for _,pass in C.Passes do local key=pass.key
				if owned[key] and key=="Teleport" then row("Pass_"..key,pass.name.." ✓ • Click to open Warp\n"..pass.desc,UI.Colors.Green,function() request("Warp") end)
				elseif owned[key] then row("Pass_"..key,pass.name.." ✓ Owned\n"..pass.desc,UI.Colors.Slate,function() end)
				else row("Pass_"..key,pass.name.." • "..price(pass.id,Enum.InfoType.GamePass).."\n"..pass.desc,UI.Colors.Purple,function() request("Prompt",key) end) end
			end
		else
			for _,p in C.Products do local key=p.key
				row("Product_"..key,p.name.." • "..price(p.id,Enum.InfoType.Product),UI.Colors.Orange,function() request("Prompt",key) end)
			end
		end
	end
	for i,t in {{"Passes","Game Pass (Permanent)"},{"Products","Repeatable Products"}} do local id=t[1]
		local b=UI.Button({text=t[2],color=UI.Colors.Teal,size=UDim2.new(.5,-8,0,42),onClick=function() tab=id;render() end})
		b.Name="Tab"..id;b.Position=UDim2.new((i-1)/2,0,0,62);b.Parent=panel
	end
	local close=UI.Button({text="Close",color=UI.Colors.Slate,size=UDim2.new(1,0,0,44),onClick=function() panel.Visible=false end});close.Name="Close";close.Position=UDim2.new(0,0,1,-48);close.Parent=panel
	local toggle=UI.Button({text="Robux Shop",color=UI.Colors.Orange,size=UDim2.fromOffset(130,48),onClick=function()
		panel.Visible=not panel.Visible;message.Text="";render()
	end});toggle.Name="Toggle";toggle.Position=UDim2.fromOffset(200,365);toggle.Parent=gui
	local function resize() local size=workspace.CurrentCamera.ViewportSize;panel.Size=UDim2.fromOffset(math.min(700,size.X-28),math.min(520,size.Y-60)) end
	workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(resize);resize()
	local function flag() gui.Enabled=flags:GetAttribute("Shop")==true end
	flags:GetAttributeChangedSignal("Shop"):Connect(flag);flag()
	Data.Changed:Connect(function() render() end)
	-- VIP chat tag (attribute set by the server from the profile).
	TextChat.OnIncomingMessage=function(msg)
		local props=Instance.new("TextChatMessageProperties")
		local src=msg.TextSource and Players:GetPlayerByUserId(msg.TextSource.UserId)
		if src and src:GetAttribute("VIP") then props.PrefixText="<font color='#FACC15'>[VIP]</font> "..msg.PrefixText end
		return props
	end
end
return Shop
