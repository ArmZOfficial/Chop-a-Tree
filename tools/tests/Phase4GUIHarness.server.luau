-- Test-only setup for real mouse input. Set workspace.Phase4GUICommand to finish.
assert(game:GetService("RunService"):IsStudio())
local Services=game.ServerScriptService.Server.Services
local D=require(Services.DataService);local G=require(Services.GardenService);local W=require(Services.WeatherService);local R=require(Services.RunService)
local p=game.Players:GetPlayers()[1];assert(D.WaitForData(p,30))
local original=D.ExportJSON(p);script:SetAttribute("OriginalData",original)
local pos=p.Character:GetPivot();local weather=W.GetOverride()
R.End(p,false);W.Force("Clear",3600)
D.Set(p,"Garden",{slots=6,plots={},starterGiven=true,shopEpoch=0,bought={}});D.Set(p,"Inventory.Seeds",{});D.Set(p,"Inventory.Fruits",{})
D.SetCurrency(p,"Coins",100000);D.SetCurrency(p,"Wood",100000)
local _,uid=G.GrantSeed(p,"seed_sunapple",1,0,3,false);workspace:SetAttribute("Phase4GUISeed",uid)
p.Character:PivotTo(G.Base(p).GardenSlots.Slot1.CFrame+Vector3.new(0,4,0));G.Send(p)
local function status()
	local plot=D.Get(p,"Garden.plots")["1"];local fruit=0;for _,f in D.Get(p,"Inventory.Fruits") do fruit+=f.count end
	workspace:SetAttribute("Phase4GUIPlot",plot~=nil);workspace:SetAttribute("Phase4GUIWatered",plot and plot.watered or false)
	workspace:SetAttribute("Phase4GUIFruit",fruit);workspace:SetAttribute("Phase4GUISlots",D.Get(p,"Garden.slots"))
	workspace:SetAttribute("Phase4GUICoins",D.GetCurrency(p,"Coins"))
end
local connection
connection=workspace:GetAttributeChangedSignal("Phase4GUICommand"):Connect(function()
	local command=workspace:GetAttribute("Phase4GUICommand")
	if command=="Mature" then G.MatureAll(p)
	elseif command=="Shop" then for _,m in game:GetService("CollectionService"):GetTagged("Shop") do if m:GetAttribute("ShopType")=="SeedShop" then p.Character:PivotTo(m.PrimaryPart.CFrame+Vector3.new(0,5,0)) end end
	elseif command=="Base" then p.Character:PivotTo(G.Base(p).GardenSlots.Slot1.CFrame+Vector3.new(0,4,0))
	elseif command=="Finish" then
		connection:Disconnect();D.ImportJSON(p,original);p.Character:PivotTo(pos)
		if weather then W.Force(weather.id,math.max(1,weather.endsAt-os.time())) else W.Force(nil) end
		G.Send(p);R.Send(p);workspace:SetAttribute("Phase4GUIRestored",true);return
	elseif command=="Rain" or command=="Snow" or command=="Golden" or command=="Storm" then W.Force(command,300) end
	status()
end)
D.Changed:Connect(function(target,path) if target==p and path~="" then status() end end)
status();workspace:SetAttribute("Phase4GUIReady",true)
