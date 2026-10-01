-- Phase 9b arena rules. Add to the Chop Arena place ServerScriptService in Edit, press Play, read workspace ArenaMatchResults, then delete it.
assert(game:GetService("RunService"):IsStudio())
local M=require(game.ServerScriptService.Arena.ArenaMatch)
local results={}
local function check(name,ok) assert(ok,name);table.insert(results,name) end
local rigs={}
local function rig(at,look)
	local m=game.Players:CreateHumanoidModelFromDescription(Instance.new("HumanoidDescription"),Enum.HumanoidRigType.R15)
	m.Parent=workspace;m.HumanoidRootPart.Anchored=true;m:PivotTo(CFrame.lookAt(at,look or at+Vector3.zAxis));table.insert(rigs,m);return m
end
local function hp(m) return m:FindFirstChildOfClass("Humanoid").Health end
local ok,err=xpcall(function()
	check("Known mode hints accepted",M.Mode({mode="Duel"})=="Duel" and M.Mode({mode="FFA",ranked=true})=="FFA")
	check("Bad or unfinished mode hints rejected",not M.Mode({mode="TimberClash"}) and not M.Mode("Duel") and not M.Mode({mode=1}) and not M.Mode(nil))
	local a=rig(Vector3.new(0,50,0),Vector3.new(0,50,10));local front=rig(Vector3.new(0,50,5));local behind=rig(Vector3.new(0,50,-5));local far=rig(Vector3.new(0,50,30))
	for _,m in {a,front,behind,far} do m:FindFirstChildOfClass("Humanoid").MaxHealth=500;m:FindFirstChildOfClass("Humanoid").Health=500;M.Equip(m) end
	check("Equip sets equal stats",hp(a)==M.Health and a.Humanoid.MaxHealth==M.Health and a.Humanoid.WalkSpeed==M.Speed)
	local all={a,front,behind,far}
	check("Swing hits the target in front",M.Attack(a,all,100)==front and hp(front)==M.Health-M.Damage and hp(behind)==M.Health and hp(far)==M.Health)
	check("Cooldown blocks a fast second swing",M.Attack(a,all,100+M.Cooldown/2)==nil and hp(front)==M.Health-M.Damage)
	check("Swing never hits self, behind or out of range",M.Attack(a,{a,behind,far},101)==nil and hp(a)==M.Health and hp(behind)==M.Health)
	front.Humanoid.Health=0;check("Dead targets are skipped",M.Attack(a,all,102)==nil)
	a.Humanoid.Health=0;check("Dead attackers cannot swing",M.Attack(a,{behind},103)==nil and hp(behind)==M.Health)
	local p={}
	check("Outcome: last fighter wins, none is a draw, two keep fighting",M.Outcome({p})==p and M.Outcome({})==false and M.Outcome({p,{}})==nil)
	local me=game.Players:GetPlayers()[1] or game.Players.PlayerAdded:Wait()
	local deadline=os.clock()+M.WaitSeconds+5
	repeat task.wait(.5) until os.clock()>deadline or (me.PlayerGui:FindFirstChild("ArenaStatus") and me.PlayerGui.ArenaStatus.Text.Text~="รอผู้เล่น…")
	check("Solo Studio server refuses to start a match",me.PlayerGui.ArenaStatus.Text.Text=="ผู้เล่นไม่ครบ กลับหมู่บ้าน" and me.Character==nil)
end,debug.traceback)
for _,m in rigs do m:Destroy() end
workspace:SetAttribute("ArenaMatchResults",game.HttpService:JSONEncode({passed=ok,checks=results,error=not ok and err or nil}))
print("[ArenaMatchSelfTest]",ok and "passed" or err,#results)
