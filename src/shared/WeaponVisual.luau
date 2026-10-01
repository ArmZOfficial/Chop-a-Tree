-- Procedural gameplay silhouettes; final art is refined in Phase 10.
local Rarities=require(script.Parent.Config.Rarities)
local Visual={}
function Visual.Build(def,item,preview)
	local model=Instance.new(preview and "Model" or "Tool")
	model.Name=preview and def.name or "ForestWeapon"
	local scale=item.giant and 3 or 1
	local color=Rarities.Color[def.rarity]:Lerp(Color3.new(1,1,1),0.3)
	local handle
	local function part(name,size,pos,c,shape)
		local p=Instance.new("Part");p.Name=name;p.Size=size*scale;p.CFrame=CFrame.new(pos*scale)
		p.Color=c or color;p.Material=Enum.Material.SmoothPlastic;p.CanCollide=false;p.CanQuery=false;p.Massless=true;p.Anchored=preview==true
		if shape then p.Shape=shape end
		p.Parent=model
		if handle and not preview then local weld=Instance.new("WeldConstraint");weld.Part0=handle;weld.Part1=p;weld.Parent=p end
		return p
	end
	handle=part("Handle",Vector3.new(.3,2.8,.3),Vector3.zero,Color3.fromRGB(94,65,45))
	local n=string.lower(def.name)
	if n:find("orb") or n:find("bell") or n:find("lantern") then
		part("Core",Vector3.new(1.4,1.4,1.4),Vector3.new(0,1.9,0),nil,Enum.PartType.Ball)
	elseif n:find("grimoire") or n:find("guitar") or n:find("banner") or n:find("fan") or n:find("umbrella") then
		part("Body",Vector3.new(1.6,1.8,.3),Vector3.new(0,1.8,0))
		part("Emblem",Vector3.new(.6,.6,.4),Vector3.new(0,1.8,0),Color3.fromRGB(255,224,100))
	elseif n:find("bow") or n:find("chakram") or n:find("boomerang") then
		for _,x in {-1,1} do part("Arm",Vector3.new(.25,3,.35),Vector3.new(x*.7,1.3,0)) end
		part("Crossbar",Vector3.new(1.6,.25,.35),Vector3.new(0,2.7,0))
	elseif n:find("hammer") or n:find("mace") or n:find("club") or n:find("gauntlet") or n:find("lollipop") then
		part("Head",Vector3.new(1.8,1,.8),Vector3.new(0,1.9,0))
	elseif n:find("axe") or n:find("ono") or n:find("halberd") or n:find("scythe") or n:find("anchor") then
		part("Blade",Vector3.new(1.6,1.1,.3),Vector3.new(.65,1.8,0))
		part("Edge",Vector3.new(.18,1.3,.4),Vector3.new(1.4,1.8,0),Color3.fromRGB(225,239,255))
	elseif n:find("trident") or n:find("lance") or n:find("hoko") then
		for _,x in {-1,0,1} do part("Tip",Vector3.new(.18,1.4,.18),Vector3.new(x*.4,2.5,0)) end
		part("Guard",Vector3.new(1,.2,.3),Vector3.new(0,1.8,0))
	else
		part("Blade",Vector3.new(.65,3,.2),Vector3.new(0,2.4,0),Color3.fromRGB(218,235,255))
		part("Guard",Vector3.new(1.3,.2,.4),Vector3.new(0,1.1,0))
	end
	if preview then model.PrimaryPart=handle else
		model.CanBeDropped=false;model.ToolTip=def.thai;model:SetAttribute("ForestAxe",true);model:SetAttribute("WeaponId",def.id)
		model.Grip=CFrame.Angles(0,0,math.rad(-15))
	end
	return model
end
return Visual
