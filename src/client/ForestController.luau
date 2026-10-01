local Players=game:GetService("Players")
local UIS=game:GetService("UserInputService")
local RS=game:GetService("RunService")
local Collection=game:GetService("CollectionService")
local Tween=game:GetService("TweenService")
local Debris=game:GetService("Debris")
local Shared=game.ReplicatedStorage:WaitForChild("Shared")
local Net=require(Shared.Net)
local UI=require(Shared.UIKit)
local NF=require(Shared.NumberFormat)
local Balance=require(Shared.Balance)
local Config=require(Shared.Config.Forest)
local Data=require(script.Parent.ClientData)
local Forest={}
local player=Players.LocalPlayer
local state={active=false,autoAttack=false,autoCut=false,power=0}
local bars={}

function Forest.Start()
	local gui=UI.New("ScreenGui",{Name="ForestHUD",ResetOnSpawn=false,DisplayOrder=3,Parent=player:WaitForChild("PlayerGui")})
	local panel=UI.New("ScrollingFrame",{Name="RunPanel",AnchorPoint=Vector2.new(1,0.5),Position=UDim2.new(1,-14,0.5,0),Size=UDim2.fromOffset(226,460),CanvasSize=UDim2.new(),AutomaticCanvasSize=Enum.AutomaticSize.Y,ScrollBarThickness=4,BackgroundColor3=UI.Colors.Panel,Visible=false,Parent=gui},{UI.Corner(16),UI.Stroke(3),UI.Padding(12),UI.List(Enum.FillDirection.Vertical,8)})
	UI.Label("FOREST RUN",22,{LayoutOrder=0,TextXAlignment=Enum.TextXAlignment.Center,Parent=panel})
	local attackHolder,attack=UI.Button({text="Auto Attack: OFF",color=UI.Colors.Green,size=UDim2.new(1,0,0,48),layoutOrder=1,onClick=function() Net.Event("ForestAction"):FireServer("AutoAttack",not state.autoAttack) end})
	attackHolder.Name="AutoAttack"; attackHolder.Parent=panel
	local cutHolder,cut=UI.Button({text="Auto Cut: OFF",sub="EXP / Wood / Coins −45%",color=UI.Colors.Blue,size=UDim2.new(1,0,0,62),layoutOrder=2,onClick=function() Net.Event("ForestAction"):FireServer("AutoCut",not state.autoCut) end})
	cutHolder.Name="AutoCut"; cutHolder.Parent=panel
	local endHolder=UI.Button({text="End Run",color=UI.Colors.Red,size=UDim2.new(1,0,0,48),layoutOrder=3,onClick=function() Net.Event("ForestAction"):FireServer("End") end})
	endHolder.Name="EndRun"; endHolder.Parent=panel
	UI.Label("CHESTS • MAX 50",15,{LayoutOrder=4,Parent=panel})
	local chests=UI.New("ScrollingFrame",{Name="Chests",BackgroundTransparency=1,Size=UDim2.new(1,0,0,95),AutomaticCanvasSize=Enum.AutomaticSize.Y,CanvasSize=UDim2.new(),ScrollBarThickness=4,LayoutOrder=5,Parent=panel},{UI.List(Enum.FillDirection.Vertical,6)})
	local top=UI.New("Frame",{Name="RunStats",AnchorPoint=Vector2.new(0.5,0),Position=UDim2.new(0.5,0,0,10),Size=UDim2.fromOffset(390,92),BackgroundColor3=UI.Colors.Panel,Visible=false,Parent=gui},{UI.Corner(14),UI.Stroke(3)})
	local stats=UI.Label("",18,{Position=UDim2.fromOffset(12,7),Size=UDim2.new(1,-24,0,28),TextXAlignment=Enum.TextXAlignment.Center,Parent=top})
	local earnings=UI.Label("",14,{Position=UDim2.fromOffset(12,36),Size=UDim2.new(1,-24,0,22),TextXAlignment=Enum.TextXAlignment.Center,Parent=top})
	local expBack=UI.New("Frame",{Position=UDim2.fromOffset(12,66),Size=UDim2.new(1,-24,0,13),BackgroundColor3=UI.Colors.PanelDark,ClipsDescendants=true,Parent=top},{UI.Corner(6)})
	local expFill=UI.New("Frame",{Size=UDim2.fromScale(0,1),BackgroundColor3=UI.Colors.Green,Parent=expBack},{UI.Corner(6)})
	local summary=UI.New("Frame",{Name="Summary",AnchorPoint=Vector2.new(0.5,0.5),Position=UDim2.fromScale(0.5,0.5),Size=UDim2.fromOffset(360,250),BackgroundColor3=UI.Colors.Panel,Visible=false,Parent=gui},{UI.Corner(18),UI.Stroke(4),UI.Padding(18)})
	UI.Label("RUN COMPLETE!",25,{TextXAlignment=Enum.TextXAlignment.Center,Parent=summary})
	local summaryText=UI.Label("",17,{Name="Rewards",Position=UDim2.fromOffset(0,44),Size=UDim2.new(1,0,0,115),TextXAlignment=Enum.TextXAlignment.Center,Parent=summary})
	local close=UI.Button({text="กลับไปเล่น",color=UI.Colors.Green,size=UDim2.new(1,0,0,48),onClick=function() summary.Visible=false end})
	close.Position=UDim2.new(0,0,1,-48); close.Parent=summary
	local function hitNearest()
		if not state.active then return end
		local hr=player.Character and player.Character:FindFirstChild("HumanoidRootPart")
		if not hr then return end
		local best,dist=nil,Config.AttackRange
		for _,m in Collection:GetTagged("Tree") do
			if m:IsA("Model") and m.PrimaryPart and m:GetAttribute("Alive")~=false then
				local p=m.PrimaryPart.Position
				local d=Vector3.new(p.X-hr.Position.X,0,p.Z-hr.Position.Z).Magnitude
				if d<dist then best,dist=m,d end
			end
		end
		if best then Net.Event("ForestAction"):FireServer("Hit",best) end
	end
	local chop=UI.Button({text="CHOP 🪓",color=UI.Colors.Orange,size=UDim2.fromOffset(150,52),onClick=hitNearest})
	chop.Name="Chop"; chop.AnchorPoint=Vector2.new(0.5,1); chop.Position=UDim2.new(0.5,0,1,-105); chop.Visible=false; chop.Parent=gui
	local hint=UI.Label("เดินผ่านประตูสู่ป่าเพื่อเริ่ม Run",18,{Name="Hint",AnchorPoint=Vector2.new(0.5,1),Position=UDim2.new(0.5,0,1,-20),Size=UDim2.fromOffset(390,32),TextXAlignment=Enum.TextXAlignment.Center,Parent=gui})
	UI.TextStroke(2).Parent=hint
	local invite=UI.Button({text="ชวนเพื่อน +10%",color=UI.Colors.Teal,size=UDim2.fromOffset(178,48),onClick=function()
		pcall(function() game:GetService("SocialService"):PromptGameInvite(player) end)
	end})
	invite.Name="InviteFriends"; invite.Position=UDim2.fromOffset(16,185); invite.Parent=gui
	local function hookTool(tool)
		if tool:IsA("Tool") and tool:GetAttribute("ForestAxe") and not tool:GetAttribute("ForestHooked") then
			tool:SetAttribute("ForestHooked",true); tool.Activated:Connect(hitNearest)
		end
	end
	local function characterAdded(char)
		for _,child in char:GetChildren() do hookTool(child) end
		char.ChildAdded:Connect(hookTool)
	end
	if player.Character then characterAdded(player.Character) end
	player.CharacterAdded:Connect(characterAdded)
	UIS.InputBegan:Connect(function(input,processed) if not processed and input.KeyCode==Enum.KeyCode.E then hitNearest() end end)
	local function cancelAuto()
		if state.autoCut then Net.Event("ForestAction"):FireServer("AutoCut",false); state.autoCut=false end
	end
	UIS.JumpRequest:Connect(cancelAuto)
	local controls
	local module=player.PlayerScripts:FindFirstChild("PlayerModule")
	if module then local ok,result=pcall(require,module); if ok and result.GetControls then controls=result:GetControls() end end
	UIS.InputBegan:Connect(function(input,processed)
		if not processed and table.find({Enum.KeyCode.W,Enum.KeyCode.A,Enum.KeyCode.S,Enum.KeyCode.D,Enum.KeyCode.Up,Enum.KeyCode.Down,Enum.KeyCode.Left,Enum.KeyCode.Right},input.KeyCode) then cancelAuto() end
	end)
	UIS.InputChanged:Connect(function(input)
		if input.KeyCode==Enum.KeyCode.Thumbstick1 and input.Position.Magnitude>0.1 then cancelAuto() end
	end)
	UIS.TouchMoved:Connect(function(input)
		local size=workspace.CurrentCamera.ViewportSize
		if input.Position.X<size.X*0.35 and input.Position.Y>size.Y*0.5 then cancelAuto() end
	end)
	RS.RenderStepped:Connect(function()
		if state.autoCut and controls and controls:GetMoveVector().Magnitude>0.05 then cancelAuto() end
	end)
	local function buttonText(button,text)
		local label=button:FindFirstChildWhichIsA("TextLabel",true)
		if label then label.Text=text end
	end
	Net.Event("RunState").OnClientEvent:Connect(function(nextState)
		state=nextState
		panel.Visible=state.active; top.Visible=state.active; chop.Visible=state.active; hint.Visible=not state.active and not state.summary
		buttonText(attack,"Auto Attack: "..(state.autoAttack and "ON" or "OFF"))
		buttonText(cut,"Auto Cut: "..(state.autoCut and "ON" or "OFF"))
		stats.Text="LEVEL "..state.level.."  •  ×"..string.format("%.2f",state.multiplier).."  •  Power "..NF.Short(state.power)
		earnings.Text="Wood +"..NF.Short(state.wood).."  Coins +"..NF.Short(state.coins).."  Friends +"..math.floor((state.friendBoost-1)*100+0.5).."%"
		expFill.Size=UDim2.fromScale(math.clamp(state.exp/state.nextExp,0,1),1)
		for _,child in chests:GetChildren() do if child:IsA("TextLabel") then child:Destroy() end end
		if #state.chests==0 then UI.Label("เคลียร์ต้นไม้รอบจุดหีบ",14,{TextColor3=UI.Colors.TextDim,Parent=chests}) end
		for i,c in state.chests do UI.Label(c.rarity.." • LEVEL "..c.level.."  ×"..c.count,15,{LayoutOrder=i,Parent=chests}) end
		if state.summary then
			local s=state.summary; local count=0; for _,c in s.chests do count+=c.count end
			summaryText.Text="LEVEL "..s.level.." • "..s.trees.." trees\nWood +"..NF.Short(s.wood).."\nCoins +"..NF.Short(s.coins).."\nChests: "..count.." (เก็บในกระเป๋าแล้ว)"
			summary.Visible=true
		end
	end)
	local function resize()
		local camera=workspace.CurrentCamera
		if not camera then return end
		local width,height=camera.ViewportSize.X,camera.ViewportSize.Y
		local scale=math.min(1,height/480,width/980)
		panel.Size=UDim2.fromOffset(math.clamp(width*0.23,180,226),math.min(460,height-35))
		for _,frame in {top,summary} do
			local s=frame:FindFirstChildOfClass("UIScale") or Instance.new("UIScale")
			s.Scale=math.max(0.8,scale); s.Parent=frame
		end
		chop.Size=UDim2.fromOffset(150,52) -- keep the touch target comfortably sized
	end
	resize(); workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(resize)
	Net.Event("TreeHit").OnClientEvent:Connect(function(hit)
		local hr=player.Character and player.Character:FindFirstChild("HumanoidRootPart")
		if not hr or (hr.Position-hit.position).Magnitude>100 then return end
		if hit.player==player.UserId and player.Character then
			local tool=player.Character:FindFirstChildOfClass("Tool")
			if tool then
				local original=tool.Grip
				Tween:Create(tool,TweenInfo.new(0.12),{Grip=original*CFrame.Angles(math.rad(-65),0,0)}):Play()
				task.delay(0.14,function() if tool.Parent then Tween:Create(tool,TweenInfo.new(0.18),{Grip=original}):Play() end end)
			end
		end
		local anchor=Instance.new("Part"); anchor.Anchored=true; anchor.Transparency=1; anchor.CanCollide=false; anchor.CanQuery=false; anchor.Size=Vector3.one; anchor.Position=hit.position+Vector3.new(0,5,0); anchor.Parent=workspace
		local bill=Instance.new("BillboardGui"); bill.Size=UDim2.fromOffset(150,45); bill.AlwaysOnTop=true; bill.Parent=anchor
		local label=UI.Label(NF.Short(hit.damage)..(hit.crit and " CRIT!" or ""),hit.crit and 26 or 21,{Size=UDim2.fromScale(1,1),TextColor3=hit.crit and UI.Colors.Accent or Color3.new(1,1,1),TextXAlignment=Enum.TextXAlignment.Center,Parent=bill})
		UI.TextStroke(2).Parent=label
		Tween:Create(anchor,TweenInfo.new(0.7),{Position=anchor.Position+Vector3.new(0,4,0)}):Play()
		Tween:Create(label,TweenInfo.new(0.7),{TextTransparency=1}):Play(); Debris:AddItem(anchor,0.8)
		if hit.dead and hit.tier==6 then
			local light=Instance.new("PointLight"); light.Color=Color3.fromRGB(100,255,140); light.Brightness=8; light.Range=25; light.Parent=anchor
			Tween:Create(light,TweenInfo.new(0.7),{Brightness=0}):Play()
		end
	end)
	task.spawn(function()
		while true do
			local hr=player.Character and player.Character:FindFirstChild("HumanoidRootPart")
			for _,m in Collection:GetTagged("Tree") do
				if m:IsA("Model") and m.PrimaryPart then
					local near=hr and (hr.Position-m.PrimaryPart.Position).Magnitude<65
					local alive=m:GetAttribute("Alive")~=false
					if near and alive then
						if not bars[m] then
							local bill=Instance.new("BillboardGui"); bill.Name="TreeHealth"; bill.Size=UDim2.fromOffset(180,44); bill.StudsOffset=Vector3.new(0,6,0); bill.AlwaysOnTop=true; bill.Adornee=m.PrimaryPart; bill.Parent=gui
							local label=UI.Label("",14,{Size=UDim2.fromScale(1,1),TextXAlignment=Enum.TextXAlignment.Center,Parent=bill}); UI.TextStroke(2).Parent=label
							label.Size=UDim2.new(1,0,0,28)
							local back=UI.New("Frame",{Position=UDim2.new(0,10,0,31),Size=UDim2.new(1,-20,0,8),BackgroundColor3=UI.Colors.PanelDark,ClipsDescendants=true,Parent=bill},{UI.Corner(4)})
							local fill=UI.New("Frame",{Size=UDim2.fromScale(1,1),BackgroundColor3=UI.Colors.Green,Parent=back},{UI.Corner(4)})
							bars[m]={gui=bill,label=label,fill=fill}
						end
						local zone,tier=m:GetAttribute("Zone"),m:GetAttribute("Tier")
						local rb=Data.Get("Progress.Rebirth") or 0
						local req=Balance.TreeRequiredPower(zone,tier,rb)
						local hp=Balance.TreeHP(zone,tier,rb)
						bars[m].label.Text=state.power<req and ("🔒 Power "..NF.Short(req)) or ("T"..tier.."  "..NF.Short(hp*(m:GetAttribute("HealthRatio") or 1)).." / "..NF.Short(hp))
						bars[m].label.TextColor3=state.power<req and UI.Colors.Red or UI.Colors.Text
						bars[m].fill.Size=UDim2.fromScale(math.clamp(m:GetAttribute("HealthRatio") or 1,0,1),1)
						bars[m].fill.BackgroundColor3=state.power<req and UI.Colors.Red or UI.Colors.Green
					elseif bars[m] then bars[m].gui:Destroy(); bars[m]=nil end
				end
			end
			for m,bar in bars do if not m:IsDescendantOf(workspace) then bar.gui:Destroy(); bars[m]=nil end end
			task.wait(0.3)
		end
	end)
	task.spawn(function() while not Data.IsReady() do task.wait(0.1) end; Net.Function("RunRequest"):InvokeServer() end)
end

return Forest
