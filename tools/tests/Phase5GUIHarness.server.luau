-- Test-only setup for real mouse input. Set workspace.Phase5GUICommand = "Finish" to restore.
assert(game:GetService("RunService"):IsStudio())
local Services=game.ServerScriptService.Server.Services
local D=require(Services.DataService);local P=require(Services.PetService);local St=require(Services.StealService)
local G=require(Services.GardenService);local W=require(Services.WeatherService);local R=require(Services.RunService)
local p=game.Players:GetPlayers()[1];assert(D.WaitForData(p,30))
local original=D.ExportJSON(p);script:SetAttribute("OriginalData",original)
local pos=p.Character:GetPivot();local weather=W.GetOverride()
R.End(p,false);W.Force("Clear",3600);St.ResetLock(p)
D.Set(p,"Pets",{incubator={},bank=0,bankAt=0,beltBought={},upgrades={lock=0,incubator=0,pen=0},equipSlots=3})
D.Set(p,"Inventory.Eggs",{});D.Set(p,"Inventory.Pets",{});D.SetCurrency(p,"Wood",100000)
P.GrantEgg(p,{id="egg_meadow",admin_spawned=true})
p.Character:PivotTo(G.Base(p).Incubator:GetPivot()*CFrame.new(6,3,0));P.Refresh(p);P.Send(p)
local function status()
	local inc=D.Get(p,"Pets.incubator")["1"];local pets=0;local equipped=0
	for _,pet in D.Get(p,"Inventory.Pets") do pets+=1;if pet.place=="equip" then equipped+=1 end end
	local eggs=0;for _ in D.Get(p,"Inventory.Eggs") do eggs+=1 end
	workspace:SetAttribute("Phase5GUIIncubator",inc~=nil);workspace:SetAttribute("Phase5GUIEggs",eggs)
	workspace:SetAttribute("Phase5GUIPets",pets);workspace:SetAttribute("Phase5GUIEquipped",equipped)
	workspace:SetAttribute("Phase5GUILocked",St.Locked(G.BaseIndex(p)));workspace:SetAttribute("Phase5GUIPenLevel",D.Get(p,"Pets.upgrades").pen)
end
local connection
connection=workspace:GetAttributeChangedSignal("Phase5GUICommand"):Connect(function()
	local command=workspace:GetAttribute("Phase5GUICommand")
	if command=="Ready" then local inc=D.Get(p,"Pets.incubator")["1"];if inc then inc.progress=60;inc.done=true end;P.Send(p)
	elseif command=="Base" then p.Character:PivotTo(G.Base(p).PrimaryPart.CFrame*CFrame.new(0,4,0))
	elseif command=="Finish" then
		connection:Disconnect();St.ResetLock(p);P.Dismount(p);D.ImportJSON(p,original);p.Character:PivotTo(pos)
		if weather then W.Force(weather.id,math.max(1,weather.endsAt-os.time())) else W.Force(nil) end
		P.Refresh(p);P.Send(p);R.Send(p);workspace:SetAttribute("Phase5GUIRestored",true);return
	end
	status()
end)
D.Changed:Connect(function(target,path) if target==p and path~="" then status() end end)
task.spawn(function() while connection.Connected do status();task.wait(.5) end end)
status();workspace:SetAttribute("Phase5GUIReady",true)
