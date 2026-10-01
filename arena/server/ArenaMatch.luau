-- Chop Arena match rules (Phase 9b). TeleportData is only a mode hint; nothing here writes profiles or rewards.
local M={LobbyPlaceId=93479990217075,Damage=10,Range=8,Cooldown=.5,Health=100,Speed=16,WaitSeconds=20,MatchSeconds=180,EndSeconds=8}
M.Modes={Duel={min=2,max=2},FFA={min=2,max=7}} -- team modes wait for Timber Clash / Egg Heist rules
local ready={}
function M.Mode(data) return type(data)=="table" and type(data.mode)=="string" and M.Modes[data.mode] and data.mode or nil end
-- Ranked and Casual both use equal stats until Casual caps exist.
function M.Equip(character)
	local h=character:FindFirstChildOfClass("Humanoid")
	h.MaxHealth=M.Health;h.Health=M.Health;h.WalkSpeed=M.Speed;h.UseJumpPower=true;h.JumpPower=50
end
-- Server-side swing: nearest living target in front of the attacker within Range.
function M.Attack(attacker,targets,now)
	local root=attacker:FindFirstChild("HumanoidRootPart");local h=attacker:FindFirstChildOfClass("Humanoid")
	if not root or not h or h.Health<=0 or (ready[attacker] or 0)>now then return nil end
	ready[attacker]=now+M.Cooldown
	local best,dist
	for _,t in targets do
		local tr=t:FindFirstChild("HumanoidRootPart");local th=t:FindFirstChildOfClass("Humanoid")
		if t~=attacker and tr and th and th.Health>0 then
			local off=tr.Position-root.Position;local d=off.Magnitude
			if d<=M.Range and (d<.1 or root.CFrame.LookVector:Dot(off.Unit)>.3) and (not dist or d<dist) then best,dist=t,d end
		end
	end
	if best then best:FindFirstChildOfClass("Humanoid"):TakeDamage(M.Damage) end
	return best
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
