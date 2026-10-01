-- Light per-zone ambience (plan 4.12.1 item 7): particles around the camera while the
-- local player stands in a zone. Visual only — no mutations and no Lighting changes,
-- so it never fights WeatherController.
local Players=game:GetService("Players")
local Zones=require(game.ReplicatedStorage.Shared.Config.Zones)
local Ambience={}

local function seq(c) return ColorSequence.new(c) end
local PRESETS={
	[3]={name="Fireflies",color=seq(Color3.fromRGB(150,255,190)),rate=14,size=NumberSequence.new(.25),speed=NumberRange.new(.5,1.5),life=NumberRange.new(4,7),light=1,accel=Vector3.new(0,.4,0)},
	[4]={name="Petals",color=seq(Color3.fromRGB(255,190,215)),rate=22,size=NumberSequence.new(.35),speed=NumberRange.new(2,4),life=NumberRange.new(5,8),accel=Vector3.new(1.5,-2,0),rot=true},
	[5]={name="Drizzle",color=seq(Color3.fromRGB(190,210,230)),rate=60,size=NumberSequence.new(.08),speed=NumberRange.new(30,40),life=NumberRange.new(.8,1.2),accel=Vector3.new(0,-40,0),squash=true},
	[6]={name="LightSnow",color=seq(Color3.fromRGB(255,255,255)),rate=30,size=NumberSequence.new(.22),speed=NumberRange.new(2,4),life=NumberRange.new(5,8),accel=Vector3.new(.5,-3,0)},
	[7]={name="Sparkles",color=ColorSequence.new(Color3.fromRGB(170,230,255),Color3.fromRGB(255,170,250)),rate=16,size=NumberSequence.new(.3),speed=NumberRange.new(.5,1),life=NumberRange.new(2,4),light=1,accel=Vector3.zero},
	[8]={name="GoldMotes",color=seq(Color3.fromRGB(255,232,150)),rate=18,size=NumberSequence.new(.3),speed=NumberRange.new(.5,1.5),life=NumberRange.new(4,7),light=1,accel=Vector3.new(0,.6,0)},
}

-- Same zone footprint as RunService.ZoneAt.
function Ambience.ZoneAt(pos)
	for _,z in Zones.List do
		local x,zpos=(z.col-1.5)*Zones.GridStep,(z.row-.5)*Zones.GridStep
		local depth=z.id==8 and z.halfSize or Zones.GroundHalfDepth
		if math.abs(pos.X-x)<=z.halfSize and math.abs(pos.Z-zpos)<=depth and math.abs(pos.Y-z.y)<18 then return z.id end
	end
	return nil
end

function Ambience.Start()
	local player=Players.LocalPlayer
	local anchor=Instance.new("Part");anchor.Name="ZoneAmbience";anchor.Anchored=true;anchor.CanCollide=false;anchor.CanQuery=false;anchor.CanTouch=false
	anchor.Transparency=1;anchor.Size=Vector3.new(60,1,60);anchor.Parent=workspace
	local emitter=Instance.new("ParticleEmitter");emitter.Enabled=false;emitter.EmissionDirection=Enum.NormalId.Bottom;emitter.SpreadAngle=Vector2.new(30,30);emitter.Parent=anchor
	local current
	task.spawn(function() while true do
		local hr=player.Character and player.Character:FindFirstChild("HumanoidRootPart")
		local zone=hr and Ambience.ZoneAt(hr.Position)
		local preset=zone and PRESETS[zone]
		if preset~=current then
			current=preset;emitter.Enabled=preset~=nil;emitter:Clear()
			if preset then
				emitter.Name=preset.name;emitter.Color=preset.color;emitter.Rate=preset.rate;emitter.Size=preset.size;emitter.Speed=preset.speed
				emitter.Lifetime=preset.life;emitter.LightEmission=preset.light or 0;emitter.Acceleration=preset.accel
				emitter.RotSpeed=preset.rot and NumberRange.new(-90,90) or NumberRange.new(0)
				emitter.Squash=preset.squash and NumberSequence.new(2.5) or NumberSequence.new(0)
				emitter.EmissionDirection=(zone==3 or zone==7 or zone==8) and Enum.NormalId.Top or Enum.NormalId.Bottom
			end
		end
		if hr and preset then
			local low=zone==3 or zone==7 or zone==8
			anchor.CFrame=CFrame.new(hr.Position+Vector3.new(0,low and -2 or 22,0))
		end
		task.wait(.2)
	end end)
end
return Ambience
