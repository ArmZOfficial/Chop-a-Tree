-- Chop Arena match rules (Phase 9b/9c). TeleportData is only a mode hint; nothing here writes profiles or rewards.
local M={LobbyPlaceId=93479990217075,Damage=10,Range=8,Cooldown=.5,Health=100,Speed=16,WaitSeconds=20,MatchSeconds=180,EndSeconds=8}
M.Modes={Duel={min=2,max=2},FFA={min=2,max=7},TimberClash={min=4,max=6,teams=true},EggHeist={min=4,max=6,teams=true}}
M.Respawn=5;M.TreeHealth=300;M.EggGoal=3
-- Hold the swing to charge a heavy hit; it breaks blocks. Blocking from the front cuts light hits and slows the blocker.
M.Heavy={damage=25,range=9,cooldown=1.5,charge=.8};M.BlockFactor=.3;M.BlockSpeed=8
-- Weapon skill (E): the element picks the shape only; every shape has a similar budget so Ranked stays equal.
M.Skill={cooldown=8,Burst={radius=8,damage=15},Cone={range=12,dot=.5,damage=20},Pierce={range=16,width=2.5,damage=25}}
local shapeOf={["ไฟ"]="Cone",["ลม"]="Cone",["แสง"]="Cone",["สายฟ้า"]="Pierce",["เงา"]="Pierce"}
function M.SkillShape(element) return shapeOf[element] or "Burst" end
M.Teams={{name="ทีมแดง",color=BrickColor.new("Bright red"),x=-60},{name="ทีมน้ำเงิน",color=BrickColor.new("Bright blue"),x=60}}
local ready,skillReady={},{}
function M.Mode(data) return type(data)=="table" and type(data.mode)=="string" and M.Modes[data.mode] and data.mode or nil end
function M.Split(list) local t={};for i,p in list do t[p]=(i-1)%2+1 end;return t end
-- Ranked and Casual both use equal stats until Casual caps exist.
function M.Equip(character)
	local h=character:FindFirstChildOfClass("Humanoid")
	h.MaxHealth=M.Health;h.Health=M.Health;h.WalkSpeed=M.Speed;h.UseJumpPower=true;h.JumpPower=50
end
function M.SetBlock(character,on)
	local h=character:FindFirstChildOfClass("Humanoid");if not h or h.Health<=0 then return end
	character:SetAttribute("Blocking",on or nil);h.WalkSpeed=on and M.BlockSpeed or M.Speed
end
-- Server-side swing: nearest living target in front of the attacker within range; teamOf (model -> team) blocks friendly hits.
function M.Attack(attacker,targets,now,teamOf,heavy)
	local root=attacker:FindFirstChild("HumanoidRootPart");local h=attacker:FindFirstChildOfClass("Humanoid")
	if not root or not h or h.Health<=0 or attacker:GetAttribute("Blocking") or (ready[attacker] or 0)>now then return nil end
	ready[attacker]=now+(heavy and M.Heavy.cooldown or M.Cooldown)
	local range=heavy and M.Heavy.range or M.Range
	local best,dist
	for _,t in targets do
		local tr=t:FindFirstChild("HumanoidRootPart");local th=t:FindFirstChildOfClass("Humanoid")
		if t~=attacker and tr and th and th.Health>0 and not (teamOf and teamOf[t] and teamOf[t]==teamOf[attacker]) then
			local off=tr.Position-root.Position;local d=off.Magnitude
			if d<=range and (d<.1 or root.CFrame.LookVector:Dot(off.Unit)>.3) and (not dist or d<dist) then best,dist=t,d end
		end
	end
	if best then M.Hit(root,best,heavy and M.Heavy.damage or M.Damage,heavy) end
	return best
end
-- Applies damage; a front block cuts it unless the hit breaks blocks.
function M.Hit(root,target,damage,breaks)
	local tr=target:FindFirstChild("HumanoidRootPart")
	if not breaks and target:GetAttribute("Blocking") and tr.CFrame.LookVector:Dot((root.Position-tr.Position).Unit)>.3 then damage*=M.BlockFactor end
	target:FindFirstChildOfClass("Humanoid"):TakeDamage(damage)
end
function M.UseSkill(attacker,targets,now,teamOf,shape)
	local root=attacker:FindFirstChild("HumanoidRootPart");local h=attacker:FindFirstChildOfClass("Humanoid");local s=M.Skill[shape]
	if not s or not root or not h or h.Health<=0 or attacker:GetAttribute("Blocking") or (skillReady[attacker] or 0)>now then return nil end
	skillReady[attacker]=now+M.Skill.cooldown
	local look=root.CFrame.LookVector;local hits={}
	for _,t in targets do
		local tr=t:FindFirstChild("HumanoidRootPart");local th=t:FindFirstChildOfClass("Humanoid")
		if t~=attacker and tr and th and th.Health>0 and not (teamOf and teamOf[t] and teamOf[t]==teamOf[attacker]) then
			local off=tr.Position-root.Position;local d=off.Magnitude;local along=look:Dot(off)
			local inside=shape=="Burst" and d<=s.radius or shape=="Cone" and d<=s.range and (d<.1 or look:Dot(off.Unit)>=s.dot)
				or shape=="Pierce" and along>=0 and along<=s.range and (off-look*along).Magnitude<=s.width
			if inside then M.Hit(root,t,s.damage,false);table.insert(hits,t) end
		end
	end
	return hits
end
-- Timber Clash tree: a Humanoid model so swings reuse Attack; the low root keeps it in melee range.
function M.Tree(i)
	local team=M.Teams[i];local m=Instance.new("Model");m.Name=team.name.." Tree"
	local root=Instance.new("Part");root.Name="HumanoidRootPart";root.Anchored=true;root.Size=Vector3.new(6,6,6);root.Position=Vector3.new(team.x/4,3,0);root.BrickColor=team.color;root.Parent=m
	local trunk=Instance.new("Part");trunk.Name="Trunk";trunk.Anchored=true;trunk.CanCollide=false;trunk.Size=Vector3.new(5,30,5);trunk.Position=root.Position+Vector3.new(0,18,0);trunk.BrickColor=BrickColor.new("Reddish brown");trunk.Parent=m
	local h=Instance.new("Humanoid");h.RequiresNeck=false;h.BreakJointsOnDeath=false;h.MaxHealth=M.TreeHealth;h.Health=M.TreeHealth;h.Parent=m
	m.PrimaryPart=root;m.Parent=workspace;return m
end
-- Per-player result for the lobby ledger: winner is a player, a team index, or false for a draw. Leavers always get "left".
function M.Results(fighters,teamOf,winner,present)
	local out={}
	for _,p in fighters do
		out[p.UserId]=not present(p) and "left" or winner==false and "draw" or (winner==p or (teamOf[p]~=nil and teamOf[p]==winner)) and "win" or "loss"
	end
	return out
end
local ledger
pcall(function() ledger=game:GetService("DataStoreService"):GetDataStore("ArenaPending_v1"..(game:GetService("RunService"):IsStudio() and "_Studio" or "")) end)
-- The lobby's ArenaRewardService pays each matchId once when the player is back; this server never touches profiles.
function M.Record(matchId,ranked,results)
	if not ledger then return end
	for userId,result in results do
		for _=1,3 do
			local ok,err=pcall(ledger.UpdateAsync,ledger,tostring(userId),function(old)
				old=type(old)=="table" and old or {};old[matchId]={result=result,ranked=ranked==true,at=os.time()};return old
			end)
			if ok then break end;warn("[Arena] Record failed: "..tostring(err));task.wait(1)
		end
	end
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
