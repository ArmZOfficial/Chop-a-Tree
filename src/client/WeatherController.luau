local Lighting=game:GetService("Lighting")
local Run=game:GetService("RunService")
local Tween=game:GetService("TweenService")
local Debris=game:GetService("Debris")
local S=game.ReplicatedStorage.Shared
local UI=require(S.UIKit);local Net=require(S.Net);local Config=require(S.Config.Weather)
local Weather={}
function Weather.Start()
	local state=game.ReplicatedStorage:WaitForChild("WeatherState")
	local gui=UI.New("ScreenGui",{Name="WeatherHUD",ResetOnSpawn=false,DisplayOrder=4,Parent=game.Players.LocalPlayer:WaitForChild("PlayerGui")})
	local badge=UI.Label("",13,{Name="Forecast",AnchorPoint=Vector2.new(1,0),Position=UDim2.new(1,-16,0,120),Size=UDim2.fromOffset(230,60),BackgroundTransparency=.12,BackgroundColor3=UI.Colors.Panel,TextXAlignment=Enum.TextXAlignment.Center,Parent=gui});UI.Corner(10).Parent=badge
	local banner=UI.Label("",19,{Name="Banner",AnchorPoint=Vector2.new(.5,0),Position=UDim2.new(.5,0,0,175),Size=UDim2.new(.7,0,0,36),TextXAlignment=Enum.TextXAlignment.Center,Visible=false,Parent=gui})
	local function resize()
		local size=workspace.CurrentCamera.ViewportSize;local small=size.X<620
		badge.Position=UDim2.new(1,-16,0,small and 16 or 120)
		badge.Size=UDim2.fromOffset(small and math.max(120,size.X-220) or 230,small and 84 or 60);badge.TextSize=small and 12 or 13
	end
	workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(resize);resize()
	local original={Brightness=Lighting.Brightness,Ambient=Lighting.Ambient,OutdoorAmbient=Lighting.OutdoorAmbient,FogEnd=Lighting.FogEnd,FogColor=Lighting.FogColor,ClockTime=Lighting.ClockTime}
	local effects=Instance.new("Folder");effects.Name="LocalWeatherEffects";effects.Parent=workspace
	local emitterPart=Instance.new("Part");emitterPart.Name="SkyParticles";emitterPart.Size=Vector3.new(36,1,36);emitterPart.Anchored=true;emitterPart.CanCollide=false;emitterPart.CanQuery=false;emitterPart.CanTouch=false;emitterPart.Transparency=1;emitterPart.Parent=effects
	local emitter=Instance.new("ParticleEmitter");emitter.Texture="rbxasset://textures/particles/sparkles_main.dds";emitter.EmissionDirection=Enum.NormalId.Bottom;emitter.SpreadAngle=Vector2.new(12,12);emitter.Acceleration=Vector3.new(0,-15,0);emitter.Enabled=false;emitter.Parent=emitterPart
	local roofs=Instance.new("Folder");roofs.Name="SnowCovers";roofs.Parent=effects
	local function cover(part)
		if state:GetAttribute("id")=="Snow" and part:IsA("BasePart") and part.Name=="Roof" and not part:IsDescendantOf(effects) then
			local clone=Instance.new("Part");clone.Size=Vector3.new(part.Size.X+.1,.12,part.Size.Z+.1);clone.CFrame=part.CFrame*CFrame.new(0,part.Size.Y/2+.06,0);clone.Anchored=true;clone.CanCollide=false;clone.CanQuery=false;clone.CanTouch=false;clone.Color=Color3.fromRGB(239,247,255);clone.Material=Enum.Material.Snow;clone.Parent=roofs
		end
	end
	local current;local transition
	local function apply()
		local id=state:GetAttribute("id");if id==current then return end;current=id
		if transition then transition:Cancel() end
		local mood=table.clone(original)
		if id=="Rain" or id=="Storm" then mood.Brightness=id=="Storm" and .8 or 1.3;mood.OutdoorAmbient=Color3.fromRGB(109,125,150);mood.FogColor=Color3.fromRGB(139,153,170);mood.FogEnd=id=="Storm" and 450 or 750
		elseif id=="Snow" then mood.OutdoorAmbient=Color3.fromRGB(192,218,245);mood.FogColor=Color3.fromRGB(222,236,250);mood.FogEnd=750
		elseif id=="Golden" then mood.Brightness=3;mood.OutdoorAmbient=Color3.fromRGB(232,199,115);mood.Ambient=Color3.fromRGB(185,157,90) end
		local tint=({Fog=Color3.fromRGB(160,175,190),Wind=Color3.fromRGB(145,210,165),Sakura=Color3.fromRGB(255,170,200),Meteor=Color3.fromRGB(130,140,225),Aurora=Color3.fromRGB(85,230,180),Bloodmoon=Color3.fromRGB(170,40,65),Rainbow=Color3.fromRGB(215,165,255),RotInvasion=Color3.fromRGB(110,70,135)})[id]
		if tint then mood.OutdoorAmbient=tint;mood.FogColor=tint;mood.FogEnd=id=="Fog" and 180 or 750;mood.Brightness=(id=="Bloodmoon" or id=="RotInvasion") and .7 or 2 end
		if id=="Aurora" or id=="Bloodmoon" then mood.ClockTime=0 end
		transition=Tween:Create(Lighting,TweenInfo.new(2),mood);transition:Play()
		emitter.Enabled=id=="Rain" or id=="Storm" or id=="Snow"
		emitter.Rate=id=="Storm" and 140 or 80;emitter.Speed=NumberRange.new(id=="Snow" and 7 or 40);emitter.Lifetime=NumberRange.new(id=="Snow" and 3 or .8);emitter.Size=NumberSequence.new(id=="Snow" and .2 or .1);emitter.Color=ColorSequence.new(id=="Snow" and Color3.new(1,1,1) or Color3.fromRGB(163,206,240))
		if tint and id~="Fog" then emitter.Enabled=true;emitter.Color=ColorSequence.new(tint);emitter.Rate=45;emitter.Speed=NumberRange.new(id=="Meteor" and 55 or 8);emitter.Lifetime=NumberRange.new(3);emitter.Size=NumberSequence.new(.22);emitter.Acceleration=id=="Wind" and Vector3.new(20,-3,0) or Vector3.new(0,-8,0) else emitter.Acceleration=Vector3.new(0,-15,0) end
		roofs:ClearAllChildren();if id=="Snow" then for _,part in workspace.Map.Village:GetDescendants() do cover(part) end end
		banner.Text=Config.ById[id].name..(id=="Golden" and " • หีบ Level +5!" or "");banner.Visible=true
		local key=id;task.delay(4,function() if current==key then banner.Visible=false end end)
	end
	state:GetAttributeChangedSignal("id"):Connect(apply);workspace.DescendantAdded:Connect(cover);apply()
	state:GetAttributeChangedSignal("Message"):Connect(function() local message=state:GetAttribute("Message");if message and message~="" then banner.Text=message;banner.Visible=true;task.delay(5,function() banner.Visible=false end) end end)
	Run.RenderStepped:Connect(function() local camera=workspace.CurrentCamera;if camera then emitterPart.Position=camera.CFrame.Position+Vector3.new(0,20,0) end end)
	Net.Event("WeatherStrike").OnClientEvent:Connect(function(pos)
		local bolt=Instance.new("Part");bolt.Name="Lightning";bolt.Size=Vector3.new(.5,35,.5);bolt.Position=pos+Vector3.new(0,17.5,0);bolt.Anchored=true;bolt.CanCollide=false;bolt.CanQuery=false;bolt.Color=Color3.fromRGB(221,230,255);bolt.Material=Enum.Material.Neon;bolt.Parent=effects;Debris:AddItem(bolt,.25)
	end)
	task.spawn(function() while true do
		local id=state:GetAttribute("id");local seconds=math.max(0,(state:GetAttribute("endsAt") or os.time())-os.time());local nextId=state:GetAttribute("nextId") or "???";local nextName=Config.ById[nextId] and Config.ById[nextId].name or (nextId=="UTC" and "ตารางปกติ" or nextId)
		local note=({Rain="Wood ×1.25 • สวนโต ×1.5",Storm="ฟ้าผ่าให้รางวัล ×3",Snow="EXP ×1.5 • ต้นไม้แข็งขึ้น",Golden="หีบ Level +5",Clear="สวนโตได้แม้ออฟไลน์"})[id]
		local nextIn=math.max(0,(state:GetAttribute("nextAt") or os.time())-os.time())
		local fest=state:GetAttribute("Festival") or "";badge.Text=(fest~="" and "เทศกาล "..fest.." • " or "")..(state:GetAttribute("live") and "LIVE • " or "")..Config.ById[id].name.." • "..string.format("%d:%02d",seconds//60,seconds%60).."\n"..(note or Config.ById[id].note or "").."\nถัดไป: "..nextName.." • "..math.ceil(nextIn/60).." นาที"
		task.wait(1)
	end end)
end
return Weather
