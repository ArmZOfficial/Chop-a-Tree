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
	UI.Label("Shop",30,{Parent=panel})
	local message=UI.Label("",14,{Name="Message",Position=UDim2.fromOffset(0,30),Size=UDim2.new(1,0,0,24),TextColor3=UI.Colors.Accent,Parent=panel})
	local list=UI.New("ScrollingFrame",{Name="Items",Position=UDim2.fromOffset(0,112),Size=UDim2.new(1,0,1,-170),BackgroundTransparency=1,ScrollBarThickness=5,AutomaticCanvasSize=Enum.AutomaticSize.Y,CanvasSize=UDim2.new(),Parent=panel},{UI.Grid(2,186,12)})
	local tab,prices,icons,render="Passes",{},{},nil
	local function price(id,kind)
		if prices[id]==nil then prices[id]=false
			task.spawn(function()
				local ok,info=pcall(MS.GetProductInfo,MS,id,kind);prices[id]=ok and info.PriceInRobux or false;icons[id]=ok and info.IconImageAssetId or nil;render()
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
        local parts=string.split(text,"\n");local heading=parts[1];local description=parts[2] or "";local key=name:gsub("^Pass_",""):gsub("^Product_","")
        local symbols={VIP="trophy",Wood2x="leaf",Coins2x="gift",Lucky="season",PetSlots="egg",HatchSpeed="egg",GardenPlots="leaf",AutoSell="shop",Teleport="arena",OpenTen="gift"}
        local symbol=symbols[key] or (key:find("gems") and "season") or (key:find("Hatch") and "egg") or (key:find("Grow") and "leaf") or "gift"
        local card=UI.New("Frame",{Name=name,BackgroundColor3=UI.Colors.Card,Parent=list},{UI.Corner(12),UI.Stroke(3,UI.Colors.Outline),UI.Padding(10)})
        UI.New("UIGradient",{Rotation=90,Color=ColorSequence.new(Color3.new(1,1,1),Color3.fromRGB(188,161,135)),Parent=card})
        local art=UI.Icon(card,symbol,{Position=UDim2.fromOffset(6,27),Size=UDim2.fromOffset(82,82)})
        local product=C.PassByKey[key] or C.ProductByKey[key];local imageId=product and icons[product.id]
        if art and imageId and imageId>0 then art.Image="rbxassetid://"..imageId;art.ImageRectOffset=Vector2.zero;art.ImageRectSize=Vector2.zero end
        UI.Label((C.PassByKey[key] or C.ProductByKey[key] or {}).name or heading,21,{Position=UDim2.fromOffset(0,0),Size=UDim2.new(1,0,0,30),Parent=card})
        UI.Label(description~="" and description or "Repeatable purchase",14,{Position=UDim2.fromOffset(98,38),Size=UDim2.new(1,-102,0,66),Parent=card})
        local purchase=UI.Button({text=heading:match("R%$.*$") or (heading:find("Owned") and "Owned") or (heading:find("Warp") and "Open Warp") or "View",textSize=24,color=color==UI.Colors.Slate and color or UI.Colors.Green,size=UDim2.new(1,0,0,46),onClick=callback});purchase.Name="Purchase";purchase.Position=UDim2.new(0,0,1,-48);purchase.Parent=card
    end
	render=function()
		if not panel.Visible then return end
		for _,v in list:GetChildren() do if v:IsA("GuiObject") then v:Destroy() end end
		local owned=Data.Get("Purchases.passes") or {}
		if tab=="Passes" then
			for _,pass in C.Passes do local key=pass.key;price(pass.id,Enum.InfoType.GamePass)
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
