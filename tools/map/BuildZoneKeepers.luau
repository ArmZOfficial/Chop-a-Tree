-- Places the zone 3–8 keeper NPCs (Config.Story keepers) beside each ZoneSpawn, opposite the warp stone.
-- Run in Studio Edit with MCP execute_luau; safe to rerun. Run again after a MapBuilder rebuild.
local Collection=game:GetService("CollectionService")
local keepers={[3]={"Myco","Aunt Myco",Color3.fromRGB(110,90,200)},[4]={"Hana","Hana, Sakura Keeper",Color3.fromRGB(240,150,190)},[5]={"Raiko","Raiko, Thunder Panda",Color3.fromRGB(250,220,80)},
	[6]={"Borin","Borin, Ice Hunter",Color3.fromRGB(150,210,250)},[7]={"Quartz","Quartz, Crystal Golem",Color3.fromRGB(170,240,230)},[8]={"Lumi","Lumi, Spirit of Lumora",Color3.fromRGB(255,250,200)}}
local function tagged(tag,zone) for _,x in Collection:GetTagged(tag) do if x:IsDescendantOf(workspace) and x:GetAttribute("Zone")==zone then return x end end end
local placed=0
for zone,k in keepers do
	local spawn=tagged("ZoneSpawn",zone);if not spawn then continue end
	local root=spawn.Parent.Parent;local old=root:FindFirstChild("Keeper_"..k[1]);if old then old:Destroy() end
	local sp=spawn.Position;local nearest,best=nil,math.huge
	for _,w in Collection:GetTagged("WarpStone") do local d=(w:GetPivot().Position-sp).Magnitude;if d<best then nearest,best=w,d end end
	local away=nearest and best<40 and Vector3.new(sp.X-nearest:GetPivot().Position.X,0,sp.Z-nearest:GetPivot().Position.Z).Unit or Vector3.xAxis
	local ground=sp.Y-.5;local pos=Vector3.new(sp.X,ground,sp.Z)+away*14
	local cf=CFrame.lookAt(pos,Vector3.new(sp.X,ground,sp.Z))
	local m=Instance.new("Model");m.Name="Keeper_"..k[1]
	local function part(name,size,offset,color,shape)
		local p=Instance.new("Part");p.Name=name;p.Anchored=true;p.Size=size;p.CFrame=cf*offset;p.Color=color;p.TopSurface=Enum.SurfaceType.Smooth;p.BottomSurface=Enum.SurfaceType.Smooth
		if shape then p.Shape=shape end;p.Parent=m;return p
	end
	local body=part("Body",Vector3.new(4,5,2.5),CFrame.new(0,3.1,0),k[3])
	part("Head",Vector3.new(3,3,3),CFrame.new(0,7.1,0),Color3.fromRGB(240,205,170),Enum.PartType.Ball)
	part("Hat",Vector3.new(3.6,1,3.6),CFrame.new(0,8.9,0),k[3]:Lerp(Color3.new(0,0,0),.35))
	local bill=Instance.new("BillboardGui");bill.Name="NameTag";bill.Size=UDim2.fromOffset(220,34);bill.StudsOffset=Vector3.new(0,8.5,0);bill.MaxDistance=90;bill.Parent=body
	local label=Instance.new("TextLabel");label.Size=UDim2.fromScale(1,1);label.BackgroundTransparency=1;label.Text=k[2];label.TextScaled=true;label.Font=Enum.Font.GothamBold
	label.TextColor3=Color3.fromRGB(253,230,138);label.TextStrokeTransparency=0;label.Parent=bill
	m.PrimaryPart=body;m:SetAttribute("NpcId",k[1]);Collection:AddTag(m,"NPC");m.Parent=root;placed+=1
end
return placed
