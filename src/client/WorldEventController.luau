local Players=game:GetService("Players")
local Run=game:GetService("RunService")
local S=game.ReplicatedStorage.Shared
local UI=require(S.UIKit)
local Locale=require(S.Locale)
local C=require(S.Config.WorldEvents)
local Zones=require(S.Config.Zones)
local Controller={}
local connections,gui,beam={},nil,nil
function Controller.Start()
	local player=Players.LocalPlayer;local state=game.ReplicatedStorage:WaitForChild("WorldEventState")
	gui=UI.New("ScreenGui",{Name="WorldEventHUD",ResetOnSpawn=false,DisplayOrder=5,Parent=player:WaitForChild("PlayerGui")})
	local banner=UI.Label("",16,{Name="Event",AnchorPoint=Vector2.new(.5,1),Position=UDim2.new(.5,0,1,-115),Size=UDim2.new(.6,0,0,32),TextXAlignment=Enum.TextXAlignment.Center,BackgroundColor3=UI.Colors.PanelDark,BackgroundTransparency=.1,Visible=false,Parent=gui})
	local function update()
		local def=C.ById[state:GetAttribute("id")];local zone=Zones.List[state:GetAttribute("zone")]
		banner.Visible=def~=nil
		if def then banner.Text=Locale.T("{1} • {2}",{Locale.T(def.name),zone and Locale.T(zone.name) or ""}) end
		if beam then beam:Destroy();beam=nil end
		local position=state:GetAttribute("position")
		if position then
			beam=Instance.new("Part");beam.Name="EventBeacon";beam.Anchored=true;beam.CanCollide=false;beam.CanQuery=false;beam.CanTouch=false
			beam.Size=Vector3.new(2,55,2);beam.Position=position+Vector3.new(0,27,0);beam.Color=Color3.fromRGB(255,215,70);beam.Material=Enum.Material.Neon;beam.Transparency=.4;beam.Parent=workspace
		end
	end
	for _,key in {"id","zone","position"} do table.insert(connections,state:GetAttributeChangedSignal(key):Connect(update)) end
	table.insert(connections,Locale.Changed:Connect(update));update()
	local elapsed=0;table.insert(connections,Run.Heartbeat:Connect(function(dt)
		elapsed+=dt;if elapsed<.3 then return end;elapsed=0
		local root=player.Character and player.Character:FindFirstChild("HumanoidRootPart")
		local position=state:GetAttribute("position");local def=C.ById[state:GetAttribute("id")]
		if position and root and def then banner.Text=Locale.T("{1} • {2} studs",{Locale.T(def.name),math.floor((position-root.Position).Magnitude)}) end
	end))
end
function Controller.Destroy() for _,c in connections do c:Disconnect() end;table.clear(connections);if beam then beam:Destroy();beam=nil end;if gui then gui:Destroy();gui=nil end end
return Controller
