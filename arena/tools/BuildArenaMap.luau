-- Rebuilds workspace.ArenaMap in the Chop Arena place (run in Studio Edit). Gameplay assumes: floor top at y=0,
-- team bases at x=±60/z=0, trees at x=±15, egg at the centre, FFA spawns on a 30-stud ring. Keep those spots clear.
local old=workspace:FindFirstChild("ArenaMap");if old then old:Destroy() end
local base=workspace:FindFirstChild("Baseplate");if base then base:Destroy() end
local map=Instance.new("Model");map.Name="ArenaMap"
local function part(name,size,cf,color,material,shape)
	local p=Instance.new("Part");p.Name=name;p.Anchored=true;p.Size=size;p.CFrame=cf;p.Color=color;p.Material=material
	p.TopSurface=Enum.SurfaceType.Smooth;p.BottomSurface=Enum.SurfaceType.Smooth;if shape then p.Shape=shape end;p.Parent=map;return p
end
local grass,stone,wood,leaf=Color3.fromRGB(96,150,72),Color3.fromRGB(120,118,128),Color3.fromRGB(104,72,48),Color3.fromRGB(70,128,60)
part("Floor",Vector3.new(4,260,260),CFrame.new(0,-2,0)*CFrame.Angles(0,0,math.rad(90)),grass,Enum.Material.Grass,Enum.PartType.Cylinder)
part("CentreRing",Vector3.new(.2,40,40),CFrame.new(0,.05,0)*CFrame.Angles(0,0,math.rad(90)),Color3.fromRGB(150,140,120),Enum.Material.Cobblestone,Enum.PartType.Cylinder)
for i=0,35 do -- ring wall
	local a=i/36*math.pi*2
	part("Wall",Vector3.new(18,14,4),CFrame.new(math.cos(a)*100,7,math.sin(a)*100)*CFrame.Angles(0,-a+math.pi/2,0),stone,Enum.Material.Slate)
end
for _,deg in {45,135,225,315} do -- cover rocks between the lanes
	local a=math.rad(deg)
	part("Rock",Vector3.new(10,7,8),CFrame.new(math.cos(a)*42,3,math.sin(a)*42)*CFrame.Angles(0,a,math.rad(8)),stone,Enum.Material.Slate)
end
for _,z in {-38,38} do -- logs flanking the team lanes
	for _,x in {-36,36} do part("Log",Vector3.new(12,3,3),CFrame.new(x,1.5,z)*CFrame.Angles(0,math.rad(90),0),wood,Enum.Material.Wood) end
end
for i=0,11 do -- forest beyond the wall
	local a=(i+.5)/12*math.pi*2;local r=114
	part("Trunk",Vector3.new(4,26,4),CFrame.new(math.cos(a)*r,13,math.sin(a)*r),wood,Enum.Material.Wood)
	part("Leaves",Vector3.new(18,18,18),CFrame.new(math.cos(a)*r,28,math.sin(a)*r),leaf,Enum.Material.Grass,Enum.PartType.Ball)
end
map.Parent=workspace
local spawn=workspace:FindFirstChildOfClass("SpawnLocation");if spawn then spawn.CFrame=CFrame.new(0,.6,0);spawn.Transparency=1;spawn.CanCollide=false;local decal=spawn:FindFirstChildOfClass("Decal");if decal then decal:Destroy() end end
return #map:GetChildren()
