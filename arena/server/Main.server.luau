-- Chop Arena reserved-server match loop. Studio runs FFA without teleports.
local Players=game:GetService("Players");local Teleport=game:GetService("TeleportService");local Teams=game:GetService("Teams")
local M=require(script.Parent.ArenaMatch)
local studio=game:GetService("RunService"):IsStudio()
Players.CharacterAutoLoads=false
local action=Instance.new("RemoteEvent");action.Name="ArenaAction";action.Parent=game.ReplicatedStorage
local function home(list,text)
	for _,p in list do M.Say(p,text) end
	if studio or #list==0 then return end
	task.wait(M.EndSeconds)
	local ok,err=pcall(Teleport.TeleportAsync,Teleport,M.LobbyPlaceId,list)
	if not ok then warn("[Arena] Return failed: "..tostring(err));for _,p in list do p:Kick("กลับหมู่บ้านไม่สำเร็จ กรุณาเข้าเกมใหม่") end end
end
if not studio and (game.PrivateServerId=="" or game.PrivateServerOwnerId~=0) then
	-- Public or VIP server: matches only exist in lobby-reserved servers.
	Players.PlayerAdded:Connect(function(p) task.wait(2);home({p},"เข้า Arena ผ่านพอร์ทัลในหมู่บ้าน") end)
	return
end
local mode,ranked
local function arrive(p)
	if not mode then local data=p:GetJoinData().TeleportData;mode=M.Mode(data) or (studio and "FFA") or "";ranked=type(data)=="table" and data.ranked==true end
	M.Say(p,"รอผู้เล่น…")
end
Players.PlayerAdded:Connect(arrive);for _,p in Players:GetPlayers() do arrive(p) end
repeat task.wait(.5) until #Players:GetPlayers()>0
local rules=M.Modes[mode]
if not rules then home(Players:GetPlayers(),"โหมดนี้ยังไม่เปิด");return end
local start=os.clock()
repeat task.wait(.5) until #Players:GetPlayers()>=rules.max or os.clock()-start>=M.WaitSeconds
local fighters=Players:GetPlayers()
if rules.teams and #fighters%2==1 then task.spawn(home,{table.remove(fighters)},"ทีมไม่เท่ากัน กลับหมู่บ้าน") end
if #fighters<rules.min then home(fighters,"ผู้เล่นไม่ครบ กลับหมู่บ้าน");return end
Players.PlayerAdded:Connect(function(p) task.defer(home,{p},"แมตช์เริ่มไปแล้ว") end)
local teamOf=rules.teams and M.Split(fighters) or {}
local alive,characters,charTeam,trees,scores={},{},{},{},{0,0}
local result,egg,carrier
local function dropEgg(at)
	carrier=nil;if not egg then return end
	for _,w in egg:GetChildren() do w:Destroy() end
	egg.Anchored=true;egg.Position=at or Vector3.new(0,3,0)
end
local function out(p) local i=table.find(alive,p);if i then table.remove(alive,i) end;if carrier==p then dropEgg() end end
Players.PlayerRemoving:Connect(out)
local function scoreboard() for _,q in Players:GetPlayers() do M.Say(q,M.Teams[1].name.." "..scores[1].." : "..scores[2].." "..M.Teams[2].name) end end
if rules.teams then
	for i,t in M.Teams do
		local team=Instance.new("Team");team.Name=t.name;team.TeamColor=t.color;team.AutoAssignable=false;team.Parent=Teams
		local pad=Instance.new("Part");pad.Name=t.name.." Base";pad.Anchored=true;pad.Size=Vector3.new(16,1,16);pad.Position=Vector3.new(t.x,.5,0);pad.BrickColor=t.color;pad.Parent=workspace
		pad.Touched:Connect(function(hit)
			local p=Players:GetPlayerFromCharacter(hit.Parent)
			if result~=nil or not p or p~=carrier or teamOf[p]~=i then return end
			scores[i]+=1;dropEgg();scoreboard()
		end)
		if mode=="TimberClash" then trees[i]=M.Tree(i) end
	end
	for p,i in teamOf do p.Team=Teams[M.Teams[i].name] end
end
if mode=="EggHeist" then
	egg=Instance.new("Part");egg.Name="ArenaEgg";egg.Shape=Enum.PartType.Ball;egg.Size=Vector3.new(3,3,3);egg.BrickColor=BrickColor.new("Gold")
	egg.CanCollide=false;egg.Massless=true;egg.Anchored=true;egg.Position=Vector3.new(0,3,0);egg.Parent=workspace
	egg.Touched:Connect(function(hit) -- server owns pickup; only a living fighter's current character can carry
		local p=Players:GetPlayerFromCharacter(hit.Parent);local h=p and hit.Parent:FindFirstChildOfClass("Humanoid")
		local root=hit.Parent:FindFirstChild("HumanoidRootPart")
		if result~=nil or carrier or not p or not teamOf[p] or not h or h.Health<=0 or not root or characters[p]~=hit.Parent then return end
		carrier=p;egg.Anchored=false;egg.CFrame=root.CFrame*CFrame.new(0,4,0)
		local w=Instance.new("WeldConstraint");w.Part0=egg;w.Part1=root;w.Parent=egg
	end)
end
local function spawn(i,p)
	if p.Parent~=Players or result~=nil then return end
	p:LoadCharacter();local c=p.Character;if not c then return end;M.Equip(c)
	local team=teamOf[p];local angle=i/#fighters*math.pi*2
	local at=team and Vector3.new(M.Teams[team].x,5,(i%3-1)*6) or Vector3.new(math.cos(angle)*30,5,math.sin(angle)*30)
	c:PivotTo(CFrame.lookAt(at,Vector3.new(0,5,0)))
	characters[p]=c;charTeam[c]=team
	if not table.find(alive,p) then table.insert(alive,p) end
	c:FindFirstChildOfClass("Humanoid").Died:Connect(function()
		if carrier==p then dropEgg(c:GetPivot().Position) end
		if team then task.delay(M.Respawn,spawn,i,p) else out(p) end
	end)
	local tool=Instance.new("Tool");tool.Name="ขวาน";tool.CanBeDropped=false
	local handle=Instance.new("Part");handle.Name="Handle";handle.Size=Vector3.new(.4,3,.4);handle.Parent=tool
	local pressed
	tool.Activated:Connect(function() pressed=os.clock() end) -- Activated/Deactivated replicate; the server times the charge and decides the hit
	tool.Deactivated:Connect(function()
		local heavy=pressed~=nil and os.clock()-pressed>=M.Heavy.charge;pressed=nil
		local targets={};if team and trees[team] then table.insert(targets,trees[team]) end -- each team fells its own tree
		for _,q in alive do table.insert(targets,characters[q]) end
		if tool.Parent==c then M.Attack(c,targets,os.clock(),charTeam,heavy) end
	end)
	tool.Parent=p.Backpack
end
for i,p in fighters do spawn(i,p) end
action.OnServerEvent:Connect(function(p,kind,on)
	if kind=="Block" and type(on)=="boolean" and characters[p] and characters[p]==p.Character then M.SetBlock(p.Character,on) end
end)
for _,p in fighters do M.Say(p,"สู้! คลิกฟัน • กดค้างฟันหนัก • Q Dash • F บล็อก") end
-- Team result: a side with nobody left loses; otherwise the first to finish its goal wins, and at time-out the side further along wins.
local function teamResult(final)
	local present={0,0};for _,p in alive do present[teamOf[p]]+=1 end
	if present[1]==0 or present[2]==0 then return present[1]>0 and 1 or present[2]>0 and 2 or false end
	local progress={}
	for i=1,2 do
		progress[i]=mode=="TimberClash" and 1-trees[i].Humanoid.Health/M.TreeHealth or scores[i]/M.EggGoal
		if progress[i]>=1 then return i end
	end
	if final then return progress[1]>progress[2] and 1 or progress[2]>progress[1] and 2 or false end
	return nil
end
local deadline=os.clock()+M.MatchSeconds
repeat
	task.wait(.25)
	if rules.teams then result=teamResult(os.clock()>=deadline) else result=M.Outcome(alive) end
until result~=nil or os.clock()>=deadline
result=result or false
M.Record(game.JobId~="" and game.JobId or "studio-"..os.time(),ranked,M.Results(fighters,teamOf,result,function(p) return p.Parent==Players end))
home(Players:GetPlayers(),type(result)=="number" and M.Teams[result].name.." ชนะ!" or result and result.DisplayName.." ชนะ!" or "เสมอ")
