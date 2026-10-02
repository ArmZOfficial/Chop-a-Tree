-- Base traps and guard pets. Add to the main place ServerScriptService in Edit, press Play, read workspace BaseDefenceResults, then delete it.
-- Uses the admin bot base as the victim and always restores the real profile.
assert(game:GetService("RunService"):IsStudio())
local V=game.ServerScriptService.Server.Services;local S=game.ReplicatedStorage.Shared
local D=require(V.DataService);local F=require(V.FeatureService);local P=require(V.PetService);local St=require(V.StealService);local G=require(V.GardenService);local R=require(V.RunService)
local M=require(S.PetMath);local Config=require(S.Config.Base)
local p=game.Players:GetPlayers()[1] or game.Players.PlayerAdded:Wait();assert(D.WaitForData(p,120));task.wait(2)
local original=D.ExportJSON(p);local pivot=p.Character:GetPivot();local flags={Eggs=F.IsEnabled("Eggs"),Stealing=F.IsEnabled("Stealing"),AutoSave=F.IsEnabled("AutoSave")}
local results={}
local function check(name,ok) assert(ok,name);table.insert(results,name) end
local function at(cf) p.Character:PivotTo(cf);task.wait(.2) end
local ok,err=xpcall(function()
	R.End(p,false);F.Set("Eggs",true);F.Set("Stealing",true);F.Set("AutoSave",false);p:SetAttribute("ShieldOverride","off");St.ResetLock(p)
	D.Set(p,"Meta.AdminTouched",true);D.Set(p,"Pets",{incubator={},bank=0,bankAt=0,beltBought={},weatherBought={},upgrades={lock=0,incubator=0,pen=0,trap=0,guard=0},equipSlots=3});D.Set(p,"Inventory.Eggs",{});P.Refresh(p)
	check("Trap slows thieves 10% per level from the base 25%",M.TrapSlow(0)==Config.StealSlow and math.abs(M.TrapSlow(3)-Config.StealSlow*.7)<1e-9 and M.MaxLevel("trap")==3)
	check("Guard chance is 15% per level, max 45%",M.GuardChance(0)==0 and math.abs(M.GuardChance(3)-.45)<1e-9 and M.MaxLevel("guard")==3)
	local base=G.Base(p);at(base.PrimaryPart.CFrame*CFrame.new(0,4,0));D.SetCurrency(p,"Wood",1e9);local wood=D.GetCurrency(p,"Wood")
	check("Trap and guard upgrades cost Wood at the base",P.Upgrade(p,"trap") and P.Upgrade(p,"guard") and D.GetCurrency(p,"Wood")==wood-M.UpgradeCost("trap",0)-M.UpgradeCost("guard",0) and D.Get(p,"Pets.upgrades").trap==1 and D.Get(p,"Pets.upgrades").guard==1)
	for _=1,3 do P.Upgrade(p,"trap") end;check("Trap caps at level 3",D.Get(p,"Pets.upgrades").trap==3 and not P.Upgrade(p,"trap"))
	local okBot,botId=St.CreateBot();local botBase=G.BaseById(botId);at(botBase.Incubator:GetPivot()*CFrame.new(5,3,0))
	St.SetBotDefence(nil,nil)
	check("No defence keeps the normal 25% slow",St.Try(p,botId) and math.abs(p:GetAttribute("CarryMult")-Config.StealSlow)<1e-9);St.Return(p,"test");St.ResetLock(p)
	St.SetBotDefence(3,nil)
	check("Level 3 trap slows the thief to 52.5%",St.Try(p,botId) and math.abs(p:GetAttribute("CarryMult")-M.TrapSlow(3))<1e-9 and math.abs(p.Character.Humanoid.WalkSpeed-16*M.TrapSlow(3))<1e-3);St.Return(p,"test");St.ResetLock(p)
	St.SetBotDefence(nil,7) -- chance above 1: the guard always wins, so the roll is deterministic
	local okTry,msg=St.Try(p,botId)
	check("Guard chases the thief off before the egg moves",not okTry and string.find(msg,"Guard chased you away")~=nil and not p:GetAttribute("CarryingEgg") and St.Bot().incubator["1"].carriedBy==nil)
	check("Being chased off still starts the base cooldown",not St.Try(p,botId))
	St.RemoveBot()
end,debug.traceback)
pcall(St.Return,p);pcall(St.RemoveBot);St.ResetLock(p)
for id,v in flags do F.Set(id,v) end;p:SetAttribute("ShieldOverride",nil)
D.ImportJSON(p,original);p.Character:PivotTo(pivot);P.Refresh(p);D.SaveNow(p)
local o=game.HttpService:JSONDecode(original)
local restored=D.GetCurrency(p,"Wood")==o.Currencies.Wood and D.Get(p,"Pets.upgrades").lock==o.Pets.upgrades.lock and D.Get(p,"Meta.AdminTouched")==o.Meta.AdminTouched and (D.Get(p,"Pets.upgrades").trap or 0)==(o.Pets.upgrades.trap or 0)
workspace:SetAttribute("BaseDefenceResults",game.HttpService:JSONEncode({passed=ok and restored,restored=restored,checks=results,error=not ok and err or nil}))
print("[BaseDefenceScenario]",ok and "passed" or err,#results,"restored",restored)
