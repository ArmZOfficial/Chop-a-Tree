-- Procedural low-poly pets and eggs; final art replaces this in Phase 10.
local Pets=require(script.Parent.Config.Pets)
local Visual={}
local function part(m,name,size,cf,color,shape)
	local p=Instance.new("Part");p.Name=name;p.Size=size;p.CFrame=cf;p.Color=color;p.Anchored=true;p.CanCollide=false;p.CanQuery=false;p.CanTouch=false;p.CastShadow=false
	p.Material=Enum.Material.SmoothPlastic;if shape then p.Shape=shape end;p.Parent=m;return p
end
-- Returns an anchored model centred on its Body at the origin, facing -Z.
function Visual.Pet(id,scale)
	local def=Pets.ById[id];scale=scale or 1
	local m=Instance.new("Model");m.Name=id
	local c,a=def.color,def.accent;local s=def.shape
	local function v(x,y,z) return CFrame.new(x*scale,y*scale,z*scale) end
	local body=part(m,"Body",Vector3.new(1.6,1.3,2)*scale,v(0,0,0),c,s=="bird" and Enum.PartType.Ball or nil)
	part(m,"Head",Vector3.new(1.1,1.1,1.1)*scale,v(0,.7,-1.1),c,Enum.PartType.Ball)
	for i=-1,1,2 do part(m,"Eye",Vector3.new(.18,.18,.18)*scale,v(i*.25,.85,-1.62),Color3.new(.05,.05,.08),Enum.PartType.Ball) end
	if s=="bunny" then for i=-1,1,2 do part(m,"Ear",Vector3.new(.25,1,.35)*scale,v(i*.25,1.5,-1),a) end
	elseif s=="fox" or s=="wolf" or s=="kit" then for i=-1,1,2 do part(m,"Ear",Vector3.new(.3,.5,.3)*scale,v(i*.3,1.35,-1.05),a) end;part(m,"Tail",Vector3.new(.5,.5,1.4)*scale,v(0,.3,1.4),a)
	elseif s=="bird" then for i=-1,1,2 do part(m,"Wing",Vector3.new(.2,.9,1.2)*scale,v(i*.9,.1,0),a) end
	elseif s=="deer" then for i=-1,1,2 do part(m,"Antler",Vector3.new(.15,1,.15)*scale,v(i*.3,1.6,-1),a) end
	elseif s=="boar" then for i=-1,1,2 do part(m,"Tusk",Vector3.new(.15,.15,.5)*scale,v(i*.3,.45,-1.75),a) end
	elseif s=="drake" then for i=-1,1,2 do part(m,"Wing",Vector3.new(1.4,.15,1)*scale,v(i*1.3,.6,.2),a) end;part(m,"Horn",Vector3.new(.2,.6,.2)*scale,v(0,1.4,-1),a) end
	if s~="bird" then for _,x in {-.5,.5} do for _,z in {-.6,.6} do part(m,"Leg",Vector3.new(.35,.7,.35)*scale,v(x,-.85,z),c) end end end
	m.PrimaryPart=body;return m
end
function Visual.Egg(color,scale)
	local m=Instance.new("Model");m.Name="Egg";scale=scale or 1
	local shell=part(m,"Shell",Vector3.new(1.4,1.8,1.4)*scale,CFrame.new(),color,Enum.PartType.Ball)
	part(m,"Spot",Vector3.new(.5,.5,.5)*scale,CFrame.new(.45*scale,.3*scale,-.45*scale),Color3.new(1,1,1),Enum.PartType.Ball)
	m.PrimaryPart=shell;return m
end
return Visual
