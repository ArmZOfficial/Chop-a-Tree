-- Chop Arena reserved-server match loop. Studio runs FFA without teleports.
local Players=game:GetService("Players");local Teleport=game:GetService("TeleportService")
local M=require(script.Parent.ArenaMatch)
local studio=game:GetService("RunService"):IsStudio()
Players.CharacterAutoLoads=false
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
local mode
local function arrive(p) mode=mode or M.Mode(p:GetJoinData().TeleportData) or (studio and "FFA") or "";M.Say(p,"รอผู้เล่น…") end
Players.PlayerAdded:Connect(arrive);for _,p in Players:GetPlayers() do arrive(p) end
repeat task.wait(.5) until #Players:GetPlayers()>0
local rules=M.Modes[mode]
if not rules then home(Players:GetPlayers(),"โหมดนี้ยังไม่เปิด");return end
local start=os.clock()
repeat task.wait(.5) until #Players:GetPlayers()>=rules.max or os.clock()-start>=M.WaitSeconds
local fighters=Players:GetPlayers()
if #fighters<rules.min then home(fighters,"ผู้เล่นไม่ครบ กลับหมู่บ้าน");return end
Players.PlayerAdded:Connect(function(p) task.defer(home,{p},"แมตช์เริ่มไปแล้ว") end)
local alive,characters={},{}
local function out(p) local i=table.find(alive,p);if i then table.remove(alive,i) end end
Players.PlayerRemoving:Connect(out)
for i,p in fighters do
	if p.Parent~=Players then continue end
	p:LoadCharacter();local c=p.Character;if not c then continue end;M.Equip(c)
	local angle=i/#fighters*math.pi*2;local at=Vector3.new(math.cos(angle),0,math.sin(angle))*30+Vector3.new(0,5,0)
	c:PivotTo(CFrame.lookAt(at,Vector3.new(0,5,0)))
	table.insert(alive,p);characters[p]=c
	c:FindFirstChildOfClass("Humanoid").Died:Connect(function() out(p) end)
	local tool=Instance.new("Tool");tool.Name="ขวาน";tool.CanBeDropped=false
	local handle=Instance.new("Part");handle.Name="Handle";handle.Size=Vector3.new(.4,3,.4);handle.Parent=tool
	tool.Activated:Connect(function() -- Activated replicates; the server decides the hit
		local targets={};for _,q in alive do table.insert(targets,characters[q]) end
		if tool.Parent==c then M.Attack(c,targets,os.clock()) end
	end)
	tool.Parent=p.Backpack
end
for _,p in fighters do M.Say(p,"สู้!") end
local deadline=os.clock()+M.MatchSeconds
local result
repeat task.wait(.25);result=M.Outcome(alive) until result~=nil or os.clock()>=deadline
home(Players:GetPlayers(),result and (result.DisplayName.." ชนะ!") or "เสมอ")
