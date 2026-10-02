local S=game.ReplicatedStorage.Shared
local UI=require(S.UIKit);local Net=require(S.Net);local C=require(S.Config.Arena);local Data=require(script.Parent.ClientData)
local A={}
function A.Start()
	local gui=UI.New("ScreenGui",{Name="ArenaHUD",ResetOnSpawn=false,DisplayOrder=14,Parent=game.Players.LocalPlayer:WaitForChild("PlayerGui")})
	local panel=UI.New("Frame",{Name="Panel",Size=UDim2.fromOffset(500,420),AnchorPoint=Vector2.new(.5,.5),Position=UDim2.fromScale(.5,.5),BackgroundColor3=UI.Colors.Panel,Visible=false,Parent=gui},{UI.Corner(16),UI.Padding(16)})
	local title=UI.Label("Chop Arena",24,{Parent=panel})
	local function rank() -- display only; the server resets the season on load
		local d=Data.Get("Arena") or {};local rp=d.rp or 0;local name=C.Ranks[1].name
		for _,r in C.Ranks do if rp>=r.rp then name=r.name end end
		title.Text="Chop Arena • "..name.." "..rp.." RP • "..(Data.Get("Currencies.ArenaTokens") or 0).." Tokens"
	end
	Data.Changed:Connect(function(path) if path=="" or string.sub(path,1,5)=="Arena" or path=="Currencies.ArenaTokens" or path=="Currencies" then rank() end end)
	local info=UI.Label("",15,{Name="Info",Position=UDim2.fromOffset(0,36),Size=UDim2.new(1,0,0,48),Parent=panel})
	local ranked=true;local busy=false;local lastStatus;local labels={}
	local function button(name,text,y,color,fn)
		local b=UI.Button({text=text,textSize=16,color=color,size=UDim2.new(1,0,0,42),onClick=fn});b.Name=name;b.Position=UDim2.fromOffset(0,y);b.Parent=panel;return b
	end
	local function render(s)
		local status=s.transferring and "Joining arena…" or s.mode and ("Queued for "..s.mode.." • Waiting for players") or s.ready and "Choose a mode and wait at the portal" or "Arena unavailable"
		if status~=lastStatus then info.Text=status;lastStatus=status end
		for _,m in C.Modes do labels[m.id].Text=m.name.." • "..(s.counts[m.id] or 0).." players" end
	end
	local function request(action,id)
		if busy then return end;busy=true
		task.spawn(function()
			local ok,success,msg,s=pcall(function() return Net.Function("ArenaAction"):InvokeServer(action,id,ranked) end)
			if s then render(s) end
			if not ok or not success then info.Text=ok and msg or "Could not reach the server" end
			task.wait(.4);busy=false
		end)
	end
	local toggle
	toggle=button("Ranked","Ranked • Equal stats",92,UI.Colors.Purple,function()
		ranked=not ranked;toggle:FindFirstChildWhichIsA("TextLabel",true).Text=ranked and "Ranked • Equal stats" or "Casual • Power capped"
	end)
	for i,m in C.Modes do local b=button("Join"..m.id,m.name,140+(i-1)*48,UI.Colors.Blue,function() request("Join",m.id) end);labels[m.id]=b:FindFirstChildWhichIsA("TextLabel",true) end
	button("Leave","Leave Queue",336,UI.Colors.Red,function() request("Leave") end)
	local close=UI.Button({text="×",color=UI.Colors.Slate,size=UDim2.fromOffset(40,36),onClick=function() panel.Visible=false end});close.Name="Close";close.Position=UDim2.new(1,-40,0,0);close.Parent=panel
	Net.Event("ArenaShow").OnClientEvent:Connect(function() lastStatus=nil;rank();panel.Visible=true;request("State") end)
	Net.Event("ArenaState").OnClientEvent:Connect(render)
	game.ReplicatedStorage.FeatureFlags:GetAttributeChangedSignal("PvP"):Connect(function() if not game.ReplicatedStorage.FeatureFlags:GetAttribute("PvP") then panel.Visible=false end end)
	local function resize() local v=workspace.CurrentCamera.ViewportSize;panel.Size=UDim2.fromOffset(math.min(500,v.X-24),420);local scale=panel:FindFirstChildOfClass("UIScale");scale.Scale=math.min(1,(v.Y-24)/420) end
	UI.New("UIScale",{Parent=panel});workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(resize);resize()
end
return A
