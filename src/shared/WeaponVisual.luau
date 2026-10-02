-- Retro classic weapon builder (Plastic + Studs/Inlet, BrickColor palette, <=10 parts).
-- Tool contract "ForestWeapon": ForestAxe/WeaponId attributes, Handle part, giant x3 scale, preview Model.
-- Sword Pack defs carry swordShape/guardStyle/handleStyle; legacy defs fall back to name matching.
-- Each blade has a disabled "SwingTrail" (element colour) that ForestController enables during a swing.
local Rarities=require(script.Parent.Config.Rarities)
local Visual={}

local B=BrickColor.new
local ELEMENT_COLOR={ -- legacy-compatible Thai element keys
	["ไฟ"]=B("Bright orange").Color,["น้ำ"]=B("Bright bluish green").Color,["สายฟ้า"]=B("New Yeller").Color,
	["ลม"]=B("Pastel blue-green").Color,["เงา"]=B("Royal purple").Color,["แสง"]=B("Institutional white").Color,
	["ธรรมชาติ"]=B("Lime green").Color,["จักรวาล"]=B("Magenta").Color,
}
local HANDLE_COLOR={
	["Leather Grip"]=B("Reddish brown").Color,["Wire Grip"]=B("Medium stone grey").Color,["Crystal Grip"]=B("Pastel light blue").Color,
	["Dragon Grip"]=B("Crimson").Color,["Bone Grip"]=B("Brick yellow").Color,
}
local GUARD_COLOR={Common=B("Dark stone grey").Color,Rare=B("Medium stone grey").Color,Epic=B("Bright yellow").Color,Legendary=B("Gold").Color,Mythic=B("Gold").Color}
local STEEL=B("Light stone grey").Color
-- shape -> blade size, extra offset x, tilt (deg)
local BLADES={
	Longsword={Vector3.new(.5,3.4,.2),0,0},Shortsword={Vector3.new(.6,2.2,.2),0,0},Sabre={Vector3.new(.42,3,.2),.08,7},
	Katana={Vector3.new(.36,3.2,.16),.05,5},Greatsword={Vector3.new(.8,4.2,.24),0,0},Rapier={Vector3.new(.2,3.6,.14),0,0},
	Cleaver={Vector3.new(1.2,2.4,.22),.25,0},["Crystal Blade"]={Vector3.new(.62,3.2,.26),0,0},
}
Visual.ElementColor=ELEMENT_COLOR

function Visual.AccentColor(def)
	return def.element and ELEMENT_COLOR[def.element] or Rarities.Color[def.rarity]:Lerp(Color3.new(1,1,1),.35)
end

function Visual.Build(def,item,preview)
	local model=Instance.new(preview and "Model" or "Tool")
	model.Name=preview and def.name or "ForestWeapon"
	local scale=item.giant and 3 or 1
	local color=Rarities.Color[def.rarity]:Lerp(Color3.new(1,1,1),.3)
	local accent=Visual.AccentColor(def)
	local handle
	local function part(name,size,pos,c,opts)
		local p=Instance.new("Part");p.Name=name;p.Size=size*scale;p.CFrame=CFrame.new(pos*scale)*(opts and opts.rot or CFrame.identity)
		p.Color=c or color;p.Material=opts and opts.neon and Enum.Material.Neon or Enum.Material.Plastic
		p.TopSurface=Enum.SurfaceType.Studs;p.BottomSurface=Enum.SurfaceType.Inlet
		p.CanCollide=false;p.CanQuery=false;p.CanTouch=preview~=true and name=="Handle";p.Massless=true;p.Anchored=preview==true
		if opts and opts.shape then p.Shape=opts.shape end
		p.Parent=model
		if handle and not preview then local weld=Instance.new("WeldConstraint");weld.Part0=handle;weld.Part1=p;weld.Parent=p end
		return p
	end
	local tipY=2.6
	if def.swordShape then
		local blade=BLADES[def.swordShape] or BLADES.Longsword
		local size,offset,tilt=blade[1],blade[2],blade[3]
		local rot=CFrame.Angles(0,0,math.rad(-tilt))
		handle=part("Handle",Vector3.new(.32,1.6,.32),Vector3.zero,HANDLE_COLOR[def.handleStyle] or HANDLE_COLOR["Leather Grip"])
		part("Pommel",Vector3.new(.45,.4,.45),Vector3.new(0,-.95,0),GUARD_COLOR[def.rarity])
		local gc=GUARD_COLOR[def.rarity];local gs=def.guardStyle
		if gs=="Disc Guard" then part("Guard",Vector3.new(1,.24,1),Vector3.new(0,.9,0),gc)
		elseif gs=="Basket Guard" then part("Guard",Vector3.new(1.1,.24,.5),Vector3.new(0,.9,0),gc);part("Basket",Vector3.new(.9,.7,.18),Vector3.new(0,.5,.26),gc)
		elseif gs=="Wing Guard" then part("Guard",Vector3.new(1,.24,.4),Vector3.new(0,.9,0),gc);for _,x in {-1,1} do part("Wing",Vector3.new(.5,.24,.3),Vector3.new(x*.72,1.1,0),gc,{rot=CFrame.Angles(0,0,math.rad(x*35))}) end
		elseif gs=="Claw Guard" then part("Guard",Vector3.new(1.1,.24,.4),Vector3.new(0,.9,0),gc);for _,x in {-1,1} do part("Claw",Vector3.new(.2,.6,.2),Vector3.new(x*.5,1.25,0),gc) end
		elseif gs=="Swept Guard" then part("Guard",Vector3.new(1.3,.24,.36),Vector3.new(0,.9,0),gc,{rot=CFrame.Angles(0,0,math.rad(8))})
		else part("Guard",Vector3.new(1.5,.26,.4),Vector3.new(0,.9,0),gc) end
		local bladeColor=def.swordShape=="Crystal Blade" and accent:Lerp(Color3.new(1,1,1),.35) or STEEL
		local by=1.02+size.Y/2
		part("Blade",size,Vector3.new(offset,by,0),bladeColor,{rot=rot})
		part("Tip",Vector3.new(size.X*.62,.45,size.Z),Vector3.new(offset,by+size.Y/2+.2,0),bladeColor,{rot=rot})
		if def.rarity~="Common" then part("Gem",Vector3.new(.3,.3,.5),Vector3.new(0,.9,0),accent,{neon=true}) end
		if def.rarity=="Legendary" or def.rarity=="Mythic" then part("Rune",Vector3.new(size.X*.3,size.Y*.7,size.Z+.04),Vector3.new(offset,by,0),accent,{neon=true,rot=rot}) end
		tipY=by+size.Y/2+.4
	else
		handle=part("Handle",Vector3.new(.3,2.8,.3),Vector3.zero,HANDLE_COLOR["Leather Grip"])
		local n=string.lower(def.name)
		if n:find("orb") or n:find("bell") or n:find("lantern") then part("Core",Vector3.new(1.4,1.4,1.4),Vector3.new(0,1.9,0),nil,{shape=Enum.PartType.Ball})
		elseif n:find("grimoire") or n:find("guitar") or n:find("banner") or n:find("fan") or n:find("umbrella") then part("Body",Vector3.new(1.6,1.8,.3),Vector3.new(0,1.8,0));part("Emblem",Vector3.new(.6,.6,.4),Vector3.new(0,1.8,0),accent,{neon=true})
		elseif n:find("bow") or n:find("chakram") or n:find("boomerang") then for _,x in {-1,1} do part("Arm",Vector3.new(.25,3,.35),Vector3.new(x*.7,1.3,0)) end;part("Crossbar",Vector3.new(1.6,.25,.35),Vector3.new(0,2.7,0))
		elseif n:find("hammer") or n:find("mace") or n:find("club") or n:find("gauntlet") or n:find("lollipop") then part("Head",Vector3.new(1.8,1,.8),Vector3.new(0,1.9,0))
		elseif n:find("axe") or n:find("ono") or n:find("halberd") or n:find("scythe") or n:find("anchor") then part("Blade",Vector3.new(1.6,1.1,.3),Vector3.new(.65,1.8,0));part("Edge",Vector3.new(.18,1.3,.4),Vector3.new(1.4,1.8,0),STEEL)
		elseif n:find("trident") or n:find("lance") or n:find("hoko") then for _,x in {-1,0,1} do part("Tip",Vector3.new(.18,1.4,.18),Vector3.new(x*.4,2.5,0)) end;part("Guard",Vector3.new(1,.2,.3),Vector3.new(0,1.8,0))
		else part("Blade",Vector3.new(.65,3,.2),Vector3.new(0,2.4,0),STEEL);part("Guard",Vector3.new(1.3,.2,.4),Vector3.new(0,1.1,0)) end
		tipY=3.2
	end
	if preview then model.PrimaryPart=handle else
		-- Swing trail (off until ForestController swings): base just above the guard, tip at the blade end.
		local a0=Instance.new("Attachment");a0.Name="TrailBase";a0.Position=Vector3.new(0,1.1*scale,0);a0.Parent=handle
		local a1=Instance.new("Attachment");a1.Name="TrailTip";a1.Position=Vector3.new(0,tipY*scale,0);a1.Parent=handle
		local trail=Instance.new("Trail");trail.Name="SwingTrail";trail.Attachment0=a0;trail.Attachment1=a1;trail.Enabled=false
		trail.Lifetime=.18;trail.LightEmission=.6;trail.FaceCamera=true;trail.Color=ColorSequence.new(accent)
		trail.Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,.2),NumberSequenceKeypoint.new(1,1)});trail.Parent=handle
		model.CanBeDropped=false;model.ToolTip=def.name;model:SetAttribute("ForestAxe",true);model:SetAttribute("WeaponId",def.id)
		model.Grip=CFrame.Angles(0,0,math.rad(-15))
	end
	return model
end
return Visual
