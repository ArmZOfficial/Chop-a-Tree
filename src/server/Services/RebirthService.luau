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
	if not Data.IsLoaded(p) or not Features.IsEnabled("Rebirth") then return false,"ระบบ Rebirth ยังไม่เปิด" end
	local d=Data.GetData(p);local rebirth=d.Progress.Rebirth
	if rebirth>=Config.MaxRebirth then return false,"ถึงขีดจำกัดวัฏจักรแล้ว" end
	if d.Run.Active then return false,"กด End Run ก่อนเริ่มวัฏจักรใหม่" end
	if p:GetAttribute("CarryingEgg") then return false,"ส่งหรือคืนไข่ที่ถือก่อน" end
	for _,egg in d.Pets.incubator do if egg.carriedBy then return false,"มีไข่กำลังถูกขโมย — จัดการให้เสร็จก่อน" end end
	local hum=p.Character and p.Character:FindFirstChildOfClass("Humanoid")
	if not hum or hum.Health<=0 then return false,"รอตัวละครเกิดก่อน" end
	if not force then
		local zone=Math.RequiredZone(rebirth)
		if (d.Progress.Bosses[tostring(zone)] or 0)<1 then return false,"ล้มบอสโซน "..zone.." ในวัฏจักรนี้ก่อน" end
		if Data.GetCurrency(p,"Coins")<Math.Cost(rebirth) then return false,"Coins ยังไม่พอ" end
	end
	return true,"พร้อมเริ่มวัฏจักรใหม่"
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
	if expected~=rb then return false,"วัฏจักรเปลี่ยนแล้ว กรุณายืนยันใหม่" end
	-- Preserve the inventory and crops; reset banked Coins and paid base capacity/upgrades.
	Pet.Advance(p,os.time(),true);Pet.Dismount(p);Steal.ResetLock(p)
	Data.SetCurrency(p,"Coins",0);Data.SetCurrency(p,"Wood",0)
	Data.AddCurrency(p,"RebirthTokens",Math.Tokens(rb));Data.Set(p,"Progress.Rebirth",rb+1)
	Data.Set(p,"Progress.Zone",1);Quest.ResetStory(p)
	Data.Set(p,"Garden.slots",6);Data.Set(p,"Pets.upgrades",{lock=0,incubator=0,pen=0})
	Data.Set(p,"Pets.bank",0);Data.Set(p,"Pets.bankAt",os.time())
	confirmations[p]=nil
	local spawn=workspace.Map.Village:FindFirstChild("VillageSpawn")
	if spawn then p.Character:PivotTo(spawn.CFrame+Vector3.new(0,4,0)) end
	Rebirth.Refresh(p)
	return true,"เริ่มวัฏจักรที่ "..(rb+1).." แล้ว! +"..Math.Tokens(rb).." Rebirth Token"
end
function Rebirth.Prepare(p)
	local ok,msg=Rebirth.Check(p);if not ok then return false,msg end
	local token=Http:GenerateGUID(false)
	confirmations[p]={token=token,rebirth=Data.Get(p,"Progress.Rebirth"),expires=os.clock()+Config.ConfirmSeconds}
	return true,"ยืนยันการรีเซ็ต Coins, Wood, โซนและอัปเกรดฐาน",token
end
function Rebirth.Confirm(p,token)
	local c=confirmations[p]
	if type(token)~="string" or not c or c.token~=token then return false,"กรุณากดยืนยันใหม่" end
	confirmations[p]=nil
	if os.clock()>c.expires then return false,"การยืนยันหมดเวลาแล้ว" end
	return Rebirth.Perform(p,c.rebirth,false)
end
function Rebirth.Buy(p,id,expectedRank)
	if not Data.IsLoaded(p) or not Features.IsEnabled("Rebirth") or type(id)~="string" or not Config.ById[id] then return false,"ไม่พบทักษะหรือระบบยังไม่เปิด" end
	local rank=Math.Rank(Data.GetData(p),id,true);local cost=Math.SkillCost(id,rank)
	if expectedRank~=rank then return false,"ขั้นทักษะเปลี่ยนแล้ว กรุณาอัปเดต" end
	if not cost then return false,"ทักษะขั้นสูงสุดแล้ว" end
	if Data.GetCurrency(p,"RebirthTokens")<cost then return false,"Rebirth Token ไม่พอ" end
	Data.AddCurrency(p,"RebirthTokens",-cost)
	local skills=table.clone(Data.Get(p,"Rebirth.skills"));skills[id]=rank+1;Data.Set(p,"Rebirth.skills",skills)
	Rebirth.Refresh(p);return true,"อัปเกรด "..Config.ById[id].name.." เป็นขั้น "..(rank+1)
end
function Rebirth.SetSkills(p,all)
	local skills={};if all then for _,s in Config.Skills do skills[s.id]=s.max end end
	Data.Set(p,"Rebirth.skills",skills);confirmations[p]=nil;Rebirth.Refresh(p)
end
function Rebirth.Init()
	Net.Function("RebirthAction").OnServerInvoke=function(p,action,arg)
		if not Data.IsLoaded(p) then return false,"ข้อมูลยังไม่พร้อม" end
		local now=os.clock();if now-(lastAction[p] or -math.huge)<.25 then return false,"รอสักครู่" end;lastAction[p]=now
		local ok,msg,value
		if action=="Sync" then ok,msg=true,"พร้อมแล้ว"
		elseif action=="Prepare" then ok,msg,value=Rebirth.Prepare(p)
		elseif action=="Confirm" then ok,msg=Rebirth.Confirm(p,arg)
		elseif action=="Buy" and type(arg)=="table" then ok,msg=Rebirth.Buy(p,arg.id,arg.rank)
		else ok,msg=false,"คำสั่งไม่ถูกต้อง" end
		return ok,msg,Rebirth.State(p),value
	end
	Players.PlayerRemoving:Connect(function(p) confirmations[p]=nil;lastAction[p]=nil end)
	game.ReplicatedStorage.FeatureFlags:GetAttributeChangedSignal("Rebirth"):Connect(function()
		for _,p in Players:GetPlayers() do if Data.IsLoaded(p) then confirmations[p]=nil;Rebirth.Refresh(p) end end
	end)
end
function Rebirth.Start() end
return Rebirth
