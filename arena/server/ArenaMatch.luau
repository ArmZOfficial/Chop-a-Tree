-- Chop Arena match rules (Phase 9b/9c). TeleportData is only a mode hint; nothing here writes profiles or rewards.
local M={LobbyPlaceId=93479990217075,Damage=10,Range=8,Cooldown=.5,Health=100,Speed=16,WaitSeconds=20,MatchSeconds=180,EndSeconds=8}
M.Modes={Duel={min=2,max=2},FFA={min=2,max=7},TimberClash={min=4,max=6,teams=true},EggHeist={min=4,max=6,teams=true}}
M.Respawn=5;M.TreeHealth=300;M.EggGoal=3
M.Teams={{name="ทีมแดง",color=BrickColor.new("Bright red"),x=-60},{name="ทีมน้ำเงิน",color=BrickColor.new("Bright blue"),x=60}}
local ready={}
function M.Mode(data) return type(data)=="table" and type(data.mode)=="string" and M.Modes[data.mode] and data.mode or nil end
function M.Split(list) local t={};for i,p in list do t[p]=(i-1)%2+1 end;return t end
-- Ranked and Casual both use equal stats until Casual caps exist.
function M.Equip(character)
	local h=character:FindFirstChildOfClass("Humanoid")
	h.MaxHealth=M.Health;h.Health=M.Health;h.WalkSpeed=M.Speed;h.UseJumpPower=true;h.JumpPower=50
end
-- Server-side swing: nearest living target in front of the attacker within Range; teamOf (model -> team) blocks friendly hits.
function M.Attack(attacker,targets,now,teamOf)
	local root=attacker:FindFirstChild("HumanoidRootPart");local h=attacker:FindFirstChildOfClass("Humanoid")
	if not root or not h or h.Health<=0 or (ready[attacker] or 0)>now then return nil end
	ready[attacker]=now+M.Cooldown
	local best,dist
	for _,t in targets do
		local tr=t:FindFirstChild("HumanoidRootPart");local th=t:FindFirstChildOfClass("Humanoid")
		if t~=attacker and tr and th and th.Health>0 and not (teamOf and teamOf[t] and teamOf[t]==teamOf[attacker]) then
			local off=tr.Position-root.Position;local d=off.Magnitude
			if d<=M.Range and (d<.1 or root.CFrame.LookVector:Dot(off.Unit)>.3) and (not dist or d<dist) then best,dist=t,d end
		end
	end
	if best then best:FindFirstChildOfClass("Humanoid"):TakeDamage(M.Damage) end
	return best
end
-- Timber Clash tree: a Humanoid model so swings reuse Attack; the low root keeps it in melee range.
function M.Tree(i)
	local team=M.Teams[i];local m=Instance.new("Model");m.Name=team.name.." Tree"
	local root=Instance.new("Part");root.Name="HumanoidRootPart";root.Anchored=true;root.Size=Vector3.new(6,6,6);root.Position=Vector3.new(team.x/4,3,0);root.BrickColor=team.color;root.Parent=m
	local trunk=Instance.new("Part");trunk.Name="Trunk";trunk.Anchored=true;trunk.CanCollide=false;trunk.Size=Vector3.new(5,30,5);trunk.Position=root.Position+Vector3.new(0,18,0);trunk.BrickColor=BrickColor.new("Reddish brown");trunk.Parent=m
	local h=Instance.new("Humanoid");h.RequiresNeck=false;h.BreakJointsOnDeath=false;h.MaxHealth=M.TreeHealth;h.Health=M.TreeHealth;h.Parent=m
	m.PrimaryPart=root;m.Parent=workspace;return m
end
-- nil = keep fighting, false = draw, player = winner.
function M.Outcome(alive) if #alive==1 then return alive[1] elseif #alive==0 then return false end;return nil end
function M.Say(p,text)
	local gui=p:FindFirstChildOfClass("PlayerGui");if not gui then return end
	local screen=gui:FindFirstChild("ArenaStatus")
	if not screen then
		screen=Instance.new("ScreenGui");screen.Name="ArenaStatus";screen.ResetOnSpawn=false
		local l=Instance.new("TextLabel");l.Name="Text";l.Size=UDim2.new(1,0,0,48);l.Position=UDim2.fromOffset(0,60);l.BackgroundTransparency=1
		l.TextColor3=Color3.new(1,1,1);l.TextStrokeTransparency=0;l.TextSize=28;l.Font=Enum.Font.GothamBold;l.Parent=screen;screen.Parent=gui
	end
	screen.Text.Text=text
end
return M
