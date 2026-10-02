-- Chop Arena input: Q/ButtonB dashes (client-owned movement), F/ButtonL1 holds block, E/ButtonX weapon skill (server applies both).
local CAS=game:GetService("ContextActionService")
local player=game:GetService("Players").LocalPlayer
local remote=game:GetService("ReplicatedStorage"):WaitForChild("ArenaAction")
local DASH_COOLDOWN,DASH_SPEED,DASH_TIME=3,60,.18
local nextDash=0
CAS:BindAction("ArenaDash",function(_,state)
	if state~=Enum.UserInputState.Begin then return Enum.ContextActionResult.Pass end
	local root=player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	if not root or os.clock()<nextDash or player.Character:GetAttribute("Blocking") then return Enum.ContextActionResult.Sink end
	nextDash=os.clock()+DASH_COOLDOWN
	local att=Instance.new("Attachment");att.Parent=root
	local push=Instance.new("LinearVelocity");push.Attachment0=att;push.MaxForce=math.huge;push.VectorVelocity=root.CFrame.LookVector*DASH_SPEED;push.Parent=root
	task.delay(DASH_TIME,function() push:Destroy();att:Destroy() end)
	return Enum.ContextActionResult.Sink
end,true,Enum.KeyCode.Q,Enum.KeyCode.ButtonB)
CAS:BindAction("ArenaBlock",function(_,state)
	if state==Enum.UserInputState.Begin then remote:FireServer("Block",true) elseif state==Enum.UserInputState.End then remote:FireServer("Block",false) end
	return Enum.ContextActionResult.Sink
end,true,Enum.KeyCode.F,Enum.KeyCode.ButtonL1)
CAS:BindAction("ArenaSkill",function(_,state)
	if state==Enum.UserInputState.Begin then remote:FireServer("Skill") end
	return Enum.ContextActionResult.Sink
end,true,Enum.KeyCode.E,Enum.KeyCode.ButtonX)
CAS:SetTitle("ArenaDash","Dash");CAS:SetTitle("ArenaBlock","Block")
local function skillTitle() CAS:SetTitle("ArenaSkill",player:GetAttribute("ArenaSkill") or "Skill") end
player:GetAttributeChangedSignal("ArenaSkill"):Connect(skillTitle);skillTitle()
