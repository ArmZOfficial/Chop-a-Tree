-- Rebirth and permanent skill purchases are server-owned, with no yields in transfers.
local Players=game:GetService("Players")
local Http=game:GetService("HttpService")
local S=game.ReplicatedStorage.Shared
local Net=require(S.Net);local Config=require(S.Config.Rebirth);local Math=require(S.RebirthMath)
local Data=require(script.Parent.DataService);local Features=require(script.Parent.FeatureService)
local Run=require(script.Parent.RunService);local Pet=require(script.Parent.PetService)
local Garden=require(script.Parent.GardenService);local Steal=require(script.Parent.StealService)
local Quest=require(script.Parent.QuestService)
local Rebirth={};local confirmations,lastAction={},{}

function Rebirth.Check(p,force)
	if not Data.IsLoaded(p) or not Features.IsEnabled("Rebirth") then return false,"Rebirth unavailable" end
	local d=Data.GetData(p);local rebirth=d.Progress.Rebirth
	if rebirth>=Config.MaxRebirth then return false,"Cycle limit reached" end
	if d.Run.Active then return false,"End your run before starting a new cycle" end
	if p:GetAttribute("CarryingEgg") then return false,"Deliver or return the egg you are carrying first" end
	for _,egg in d.Pets.incubator do if egg.carriedBy then return false,"Egg theft in progress. Resolve it first" end end
	local hum=p.Character and p.Character:FindFirstChildOfClass("Humanoid")
	if not hum or hum.Health<=0 then return false,"Wait for your character to spawn" end
	if not force then
		local zone=Math.RequiredZone(rebirth)
		if (d.Progress.Bosses[tostring(zone)] or 0)<1 then return false,"Defeat boss in zone "..zone.." in this cycle first" end
		if Data.GetCurrency(p,"Coins")<Math.Cost(rebirth) then return false,"Coins Not enough" end
	end
	return true,"Ready for a New Cycle"
end
function Rebirth.State(p)
	local d=Data.GetData(p);if not d then return nil end
	local ok,msg=Rebirth.Check(p);local rb=d.Progress.Rebirth;local ranks={}
	for _,s in Config.Skills do ranks[s.id]=Math.Rank(d,s.id,true) end
	return {rebirth=rb,requiredZone=Math.RequiredZone(rb),cost=Math.Cost(rb),tokensAward=Math.Tokens(rb),
		tokens=d.Currencies.RebirthTokens,coins=d.Currencies.Coins,ready=ok,reason=msg,skills=ranks,enabled=Features.IsEnabled("Rebirth")}
end
function Rebirth.Refresh(p)
	Pet.Trim(p);Pet.Refresh(p);Pet.Send(p);Garden.Send(p);Quest.Send(p,true);Run.Send(p)
end
function Rebirth.Perform(p,expected,force)
	local ok,msg=Rebirth.Check(p,force);if not ok then return false,msg end
	local rb=Data.Get(p,"Progress.Rebirth")
	if expected~=rb then return false,"Cycle changed. Please confirm again" end
	-- Preserve the inventory and crops; reset banked Coins and paid base capacity/upgrades.
	Pet.Advance(p,os.time(),true);Pet.Dismount(p);Steal.ResetLock(p)
	Data.SetCurrency(p,"Coins",0);Data.SetCurrency(p,"Wood",0)
	Data.AddCurrency(p,"RebirthTokens",Math.Tokens(rb));Data.Set(p,"Progress.Rebirth",rb+1)
	Data.Set(p,"Progress.Zone",1);Quest.ResetStory(p)
	Data.Set(p,"Garden.slots",6);Data.Set(p,"Pets.upgrades",{lock=0,incubator=0,pen=0,trap=0,guard=0})
	Data.Set(p,"Pets.bank",0);Data.Set(p,"Pets.bankAt",os.time())
	confirmations[p]=nil
	local spawn=workspace.Map.Village:FindFirstChild("VillageSpawn")
	if spawn then p.Character:PivotTo(spawn.CFrame+Vector3.new(0,4,0)) end
	Rebirth.Refresh(p)
	return true,"Starting cycle "..(rb+1).." done! +"..Math.Tokens(rb).." Rebirth Token"
end
function Rebirth.Prepare(p)
	local ok,msg=Rebirth.Check(p);if not ok then return false,msg end
	local token=Http:GenerateGUID(false)
	confirmations[p]={token=token,rebirth=Data.Get(p,"Progress.Rebirth"),expires=os.clock()+Config.ConfirmSeconds}
	return true,"Confirm resetting Coins, Wood, zones and base upgrades",token
end
function Rebirth.Confirm(p,token)
	local c=confirmations[p]
	if type(token)~="string" or not c or c.token~=token then return false,"Please confirm again" end
	confirmations[p]=nil
	if os.clock()>c.expires then return false,"Confirmation expired" end
	return Rebirth.Perform(p,c.rebirth,false)
end
function Rebirth.Buy(p,id,expectedRank)
	if not Data.IsLoaded(p) or not Features.IsEnabled("Rebirth") or type(id)~="string" or not Config.ById[id] then return false,"Skill not found or system disabled" end
	local rank=Math.Rank(Data.GetData(p),id,true);local cost=Math.SkillCost(id,rank)
	if expectedRank~=rank then return false,"Skill tier changed. Please refresh" end
	if not cost then return false,"Skill already maxed" end
	if Data.GetCurrency(p,"RebirthTokens")<cost then return false,"Rebirth Token Not enough" end
	Data.AddCurrency(p,"RebirthTokens",-cost)
	local skills=table.clone(Data.Get(p,"Rebirth.skills"));skills[id]=rank+1;Data.Set(p,"Rebirth.skills",skills)
	Rebirth.Refresh(p);return true,"Upgrade "..Config.ById[id].name.." to tier "..(rank+1)
end
function Rebirth.SetSkills(p,all)
	local skills={};if all then for _,s in Config.Skills do skills[s.id]=s.max end end
	Data.Set(p,"Rebirth.skills",skills);confirmations[p]=nil;Rebirth.Refresh(p)
end
function Rebirth.Init()
	Net.Function("RebirthAction").OnServerInvoke=function(p,action,arg)
		if not Data.IsLoaded(p) then return false,"Data not ready" end
		local now=os.clock();if now-(lastAction[p] or -math.huge)<.25 then return false,"Please wait" end;lastAction[p]=now
		local ok,msg,value
		if action=="Sync" then ok,msg=true,"Ready"
		elseif action=="Prepare" then ok,msg,value=Rebirth.Prepare(p)
		elseif action=="Confirm" then ok,msg=Rebirth.Confirm(p,arg)
		elseif action=="Buy" and type(arg)=="table" then ok,msg=Rebirth.Buy(p,arg.id,arg.rank)
		else ok,msg=false,"Invalid command" end
		return ok,msg,Rebirth.State(p),value
	end
	Players.PlayerRemoving:Connect(function(p) confirmations[p]=nil;lastAction[p]=nil end)
	game.ReplicatedStorage.FeatureFlags:GetAttributeChangedSignal("Rebirth"):Connect(function()
		for _,p in Players:GetPlayers() do if Data.IsLoaded(p) then confirmations[p]=nil;Rebirth.Refresh(p) end end
	end)
end
function Rebirth.Start() end
return Rebirth
