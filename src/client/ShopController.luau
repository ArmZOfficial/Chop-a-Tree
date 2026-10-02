-- Robux shop window (concept: assets/ui/elements-v1/concepts/shop.png). The server validates and opens every purchase prompt.
local Players=game:GetService("Players")
local MS=game:GetService("MarketplaceService")
local TextChat=game:GetService("TextChatService")
local S=game.ReplicatedStorage.Shared
local Net=require(S.Net);local UI=require(S.UIKit)
local C=require(S.Config.Products)
local Data=require(script.Parent.ClientData)
local Shop={}
-- Illustrations from the UI atlases; unmapped items use their uploaded product icon.
local ART={gems100="rewards/gemsSmall",gems550="rewards/gemsMedium",gems1200="rewards/gemsLarge",gems6500="rewards/gemsLarge",
	wood15="rewards/woodBoost",wood30="rewards/woodBoost",luck15="rewards/luckBoost",luck30="rewards/luckBoost",serverLuck="rewards/luckBoost",
	chestKey="rewards/chestKey",instantHatch="incubation/eggReady",instantGrow="garden/plotReady",
	Wood2x="rewards/woodBoost",Lucky="rewards/luckBoost",PetSlots="pets/pet_fox",HatchSpeed="incubation/cradleReady",GardenPlots="garden/plotGrowing",AutoSell="garden/fruit",OpenTen="rewards/epicChest"}
local SYMBOL={VIP="trophy",Coins2x="gift",Teleport="arena",baseLock="shop",coins15="gift",coins30="gift",exp15="book",exp30="book"}
local function describe(p)
	local minutes=p.name:match("(%d+) min")
	local k=p.key
	if k:find("^gems") then return "Gems for your adventures."
	elseif k=="serverLuck" then return "Chest luck for the whole server\nfor "..minutes.." minutes."
	elseif k:find("^wood") then return "Double Wood\nfor "..minutes.." minutes."
	elseif k:find("^coins") then return "Double Coins\nfor "..minutes.." minutes."
	elseif k:find("^exp") then return "Double EXP\nfor "..minutes.." minutes."
	elseif k:find("^luck") then return "Improve chest luck\nfor "..minutes.." minutes."
	elseif k=="instantHatch" then return "Finish the eggs in\nyour incubator now."
	elseif k=="instantGrow" then return "Finish growing your\ngarden trees now."
	elseif k=="chestKey" then return "Legendary Chest\nLevel 10"
	elseif k=="baseLock" then return "Lock your base\nright away." end
	return ""
end
local function title(p) return p.key=="chestKey" and "Chest Key" or p.name end
function Shop.Start()
	local player=Players.LocalPlayer
	local flags=game.ReplicatedStorage.FeatureFlags
	local gui=UI.New("ScreenGui",{Name="ShopHUD",ResetOnSpawn=false,ZIndexBehavior=Enum.ZIndexBehavior.Sibling,DisplayOrder=12,Parent=player:WaitForChild("PlayerGui")})
	local panel=UI.New("Frame",{Name="Panel",AnchorPoint=Vector2.new(.5,.5),Position=UDim2.fromScale(.5,.5),Size=UDim2.fromOffset(960,650),Visible=false,BackgroundTransparency=1,Parent=gui})
	UI.Window(panel,"Shop","shop",{plaque=330,center=true})
	local message=UI.Label("",14,{Name="Message",Visible=false,Parent=panel})
	local list=UI.New("ScrollingFrame",{Name="Items",Position=UDim2.fromOffset(40,188),Size=UDim2.fromOffset(880,384),BackgroundTransparency=1,ScrollBarThickness=6,ScrollBarImageColor3=Color3.fromRGB(240,180,90),AutomaticCanvasSize=Enum.AutomaticSize.Y,CanvasSize=UDim2.new(),Parent=panel},{UI.List(Enum.FillDirection.Vertical,10),UI.Padding(4)})
	local featured=UI.New("Frame",{Name="Featured",BackgroundTransparency=1,Size=UDim2.new(1,-10,0,0),AutomaticSize=Enum.AutomaticSize.Y,LayoutOrder=1,Parent=list},{UI.Grid(3,244,12)})
	local others=UI.New("Frame",{Name="Others",BackgroundTransparency=1,Size=UDim2.new(1,-10,0,0),AutomaticSize=Enum.AutomaticSize.Y,LayoutOrder=2,Parent=list},{UI.Grid(3,122,12)})
	local footer=UI.New("Frame",{Name="Footer",BackgroundTransparency=1,AnchorPoint=Vector2.new(.5,0),Position=UDim2.new(.5,0,0,580),Size=UDim2.fromOffset(330,44),Parent=panel})
	UI.Skin(footer,"chrome","infoRow")
	local footerLabel=UI.Label("",20,{Size=UDim2.fromScale(1,1),TextXAlignment=Enum.TextXAlignment.Center,TextWrapped=false,TextColor3=Color3.fromRGB(255,220,120),ZIndex=3,Parent=footer})
	local tab,prices,icons,render="Products",{},{},nil
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
			message.Text=ok and (msg or "") or "Could not reach the server"
			if message.Text~="" then UI.Toast(gui,message.Text,ok and success and UI.Colors.Accent or UI.Colors.Red) end
		end)
	end
	local function art(card,key,product,props)
		local spec=ART[key];local a
		if spec then local atlas,sprite=spec:match("^(%w+)/([%w_]+)$");a=UI.Art(card,atlas,sprite,props)
		else
			local imageId=product and icons[product.id]
			if imageId and imageId>0 then a=UI.New("ImageLabel",{BackgroundTransparency=1,ScaleType=Enum.ScaleType.Fit,Image="rbxassetid://"..imageId,Parent=card});for k,v in props do (a::any)[k]=v end
			else a=UI.Icon(card,SYMBOL[key] or "gift",props) end
		end
		if a then a.Name="Art" end
	end
	-- Large card: illustration on top, name, short description, price.
	local function big(product,key,desc,buy,color,onClick,order)
		local card=UI.New("Frame",{Name=(tab=="Passes" and "Pass_" or "Product_")..key,BackgroundTransparency=1,LayoutOrder=order,Parent=featured});UI.Skin(card,"cards","product")
		art(card,key,product,{Position=UDim2.fromOffset(20,12),Size=UDim2.new(1,-40,0,112)})
		UI.Label(title(product),32,{Name="Title",Position=UDim2.fromOffset(12,122),Size=UDim2.new(1,-24,0,38),TextXAlignment=Enum.TextXAlignment.Center,TextScaled=true,Parent=card})
		UI.Label((desc:gsub("%s+"," ")),17,{Name="Desc",FontFace=UI.FontBold,Position=UDim2.fromOffset(14,160),Size=UDim2.new(1,-28,0,22),TextXAlignment=Enum.TextXAlignment.Center,TextYAlignment=Enum.TextYAlignment.Top,TextColor3=UI.Colors.TextDim,TextScaled=true,Parent=card})
		local b=UI.Button({text=buy,textSize=28,color=color,size=UDim2.new(1,-28,0,58),onClick=onClick});b.Name="Purchase";b.Position=UDim2.new(0,14,1,-64);b.Parent=card
	end
	-- Small card: illustration left, text and price right.
	local function small(product,key,desc,buy,color,onClick,order)
		local card=UI.New("Frame",{Name=(tab=="Passes" and "Pass_" or "Product_")..key,BackgroundTransparency=1,LayoutOrder=order,Parent=others});UI.Skin(card,"cards","product")
		art(card,key,product,{Position=UDim2.fromOffset(12,11),Size=UDim2.fromOffset(100,100)})
		UI.Label(title(product),21,{Name="Title",Position=UDim2.fromOffset(118,10),Size=UDim2.new(1,-130,0,28),TextXAlignment=Enum.TextXAlignment.Center,TextScaled=true,Parent=card})
		-- Description fills the gap between title and button (the button used to cover its second line).
		UI.Label(desc,14,{Name="Desc",FontFace=UI.FontBold,Position=UDim2.fromOffset(120,36),Size=UDim2.new(1,-134,1,-88),TextXAlignment=Enum.TextXAlignment.Center,TextYAlignment=Enum.TextYAlignment.Top,TextColor3=UI.Colors.TextDim,TextScaled=true,Parent=card})
		local b=UI.Button({text=buy,textSize=22,color=color,size=UDim2.new(1,-128,0,46),onClick=onClick});b.Name="Purchase";b.Position=UDim2.new(0,118,1,-50);b.Parent=card
	end
	local tabs={}
	render=function()
		if not panel.Visible then return end
		for key,t in tabs do UI.SetTab(t,tab==key and "gold" or nil) end
		for _,frame in {featured,others} do for _,v in frame:GetChildren() do if v:IsA("GuiObject") then v:Destroy() end end end
		local owned=Data.Get("Purchases.passes") or {}
		if tab=="Passes" then
			footerLabel.Text="Permanent upgrades"
			for i,pass in C.Passes do local key=pass.key;local text=price(pass.id,Enum.InfoType.GamePass);local color=UI.Colors.Green;local fn=function() request("Prompt",key) end
				if owned[key] and key=="Teleport" then text="Open Warp";fn=function() request("Warp") end
				elseif owned[key] then text="✓ Owned";color=UI.Colors.Slate;fn=function() end end
				;(i<=3 and big or small)(pass,key,pass.desc,text,color,fn,i)
			end
		else
			footerLabel.Text="Repeatable purchases"
			for i,p in C.Products do local key=p.key
				;(i<=3 and big or small)(p,key,describe(p),price(p.id,Enum.InfoType.Product),UI.Colors.Green,function() request("Prompt",key) end,i)
			end
		end
	end
	for i,t in {{"Passes","Gamepasses"},{"Products","Products"}} do local id=t[1]
		tabs[id]=UI.Tab({name="Tab"..id,text=t[2],size=UDim2.fromOffset(270,58),position=UDim2.new(.5,(i-2)*278+4,0,118),parent=panel,textSize=28,onClick=function() tab=id;render() end})
	end
	local toggle=UI.Button({text="Robux Shop",color=UI.Colors.Orange,size=UDim2.fromOffset(130,48),onClick=function()
		panel.Visible=not panel.Visible;message.Text="";render()
	end});toggle.Name="Toggle";toggle.Position=UDim2.fromOffset(200,365);toggle.Parent=gui
	panel:GetPropertyChangedSignal("Visible"):Connect(function() if panel.Visible then render() end end)
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
