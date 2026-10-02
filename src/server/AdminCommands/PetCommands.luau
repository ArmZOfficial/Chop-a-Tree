local S=game.ReplicatedStorage.Shared
local Eggs=require(S.Config.Eggs)
local Pets=require(S.Config.Pets)
local Math=require(S.PetMath)
local Data=require(game.ServerScriptService.Server.Services.DataService)
return function(Admin,Pet,Steal)
	Admin.Register({id="eggs.all",tab="pets",label="ให้ไข่ทุกชนิด ×1",color="Pink",usesTarget=true,marksTarget=true,run=function(ctx)
		for _,p in ctx.targets do for _,e in Eggs.List do Pet.GrantEgg(p,{id=e.id,admin_spawned=true}) end;Pet.Send(p) end
		return true,"ให้ไข่ทดสอบแล้ว — วางที่ตู้ฟักในฐาน"
	end})
	Admin.Register({id="eggs.hatchnow",tab="pets",label="ไข่ในตู้ฟักเสร็จทันที",color="Green",usesTarget=true,marksTarget=true,run=function(ctx)
		for _,p in ctx.targets do local d=Data.Get(p,"Pets")
			if d then for _,egg in d.incubator do if not egg.carriedBy then egg.progress=Eggs.ById[egg.id].hatch;egg.done=true;egg.admin_spawned=true end end;Pet.Send(p) end
		end
		return true,"ไข่ในตู้ฟักพร้อมฟักแล้ว"
	end})
	Admin.Register({id="eggs.five",tab="pets",label="ไข่ในตู้ฟักเหลือ 5 วิ",color="Blue",usesTarget=true,marksTarget=true,run=function(ctx)
		for _,p in ctx.targets do local d=Data.Get(p,"Pets")
			if d then local speed=Math.HatchSpeed(d.upgrades.incubator)
				for _,egg in d.incubator do if not egg.done then egg.progress=math.max(egg.progress,Eggs.ById[egg.id].hatch-5*speed);egg.admin_spawned=true end end;Pet.Send(p) end
		end
		return true,"ตั้งเวลาฟักเหลือ 5 วินาที"
	end})
	for _,rarity in Pets.Order do local r=rarity
		Admin.Register({id="pets."..r,tab="pets",label="ให้สัตว์ "..r,color=r=="Secret" and "Slate" or "Purple",usesTarget=true,marksTarget=true,run=function(ctx)
			for _,p in ctx.targets do for _,def in Pets.List do if def.rarity==r then Pet.GrantPet(p,def.id,{admin=true}) end end;Pet.Send(p) end
			return true,"ให้สัตว์ "..r.." แล้ว"
		end})
	end
	for id in Pets.Mutations do local m=id
		Admin.Register({id="pets.mut."..m,tab="pets",label="Fox ×3 Mutation "..m,sub="ทดสอบหลอม/รายได้",color="Orange",usesTarget=true,marksTarget=true,run=function(ctx)
			for _,p in ctx.targets do for _=1,3 do Pet.GrantPet(p,"pet_fox",{admin=true,mutation=m}) end;Pet.Send(p) end
			return true,"ให้ Ember Fox "..m.." ×3"
		end})
	end
	Admin.Register({id="pets.mount",tab="pets",label="เสก Meadow Wolf แล้วขี่ทันที",color="Teal",usesTarget=true,marksTarget=true,run=function(ctx)
		for _,p in ctx.targets do local ok,uid=Pet.GrantPet(p,"pet_wolf",{admin=true});if ok then Pet.Mount(p,uid) end;Pet.Send(p) end
		return true,"ขี่หมาป่าแล้ว"
	end})
	Admin.Register({id="steal.botthief",tab="pets",label="บอทขโมยไข่ฐานเรา",sub="ตามไปกด E ทวงคืน",color="Red",run=function(ctx) return Steal.SpawnBotThief(ctx.admin) end})
	Admin.Register({id="steal.botbase",tab="pets",label="สร้างฐานบอทให้ขโมย",sub="ไข่ 3 ใบ (ใบที่ 3 ฟักเกิน 75%)",color="Orange",run=function()
		local ok,id=Steal.CreateBot();return ok,ok and "ฐานบอทอยู่ที่ฐาน "..id or "ไม่มีฐานว่าง"
	end})
	Admin.Register({id="steal.botdefence",tab="pets",label="ฐานบอท: กับดัก+สัตว์เฝ้าสูงสุด",sub="กดอีกครั้งเพื่อปิด",color="Purple",run=function()
		local on=not (Steal.Bot() and Steal.Bot().defence.trap);local ok=Steal.SetBotDefence(on and 3 or nil,on and 3 or nil)
		return ok,ok and ("กับดัก/สัตว์เฝ้าฐานบอท: "..(on and "Lv 3" or "ปิด")) or "สร้างฐานบอทก่อน"
	end})
	Admin.Register({id="steal.removebot",tab="pets",label="ลบฐานบอท",color="Slate",run=function() return Steal.RemoveBot(),"ลบฐานบอทแล้ว" end})
	for _,mode in {"on","off"} do local m=mode
		Admin.Register({id="steal.shield"..m,tab="pets",label=m=="on" and "บังคับเปิดโล่" or "บังคับปิดโล่",sub="โล่ผู้เล่นใหม่/AFK",color=m=="on" and "Blue" or "Red",usesTarget=true,run=function(ctx)
			for _,p in ctx.targets do p:SetAttribute("ShieldOverride",m) end;return true,"โล่: "..m
		end})
	end
	Admin.Register({id="steal.shieldauto",tab="pets",label="โล่ตามกติกาปกติ",color="Green",usesTarget=true,run=function(ctx)
		for _,p in ctx.targets do p:SetAttribute("ShieldOverride",nil) end;return true,"โล่ตามกติกา (ใหม่ 30 นาที / AFK 10 นาที)"
	end})
	Admin.Register({id="steal.resetlock",tab="pets",label="รีเซ็ตล็อกฐาน/คูลดาวน์ขโมย",color="Teal",usesTarget=true,run=function(ctx)
		for _,p in ctx.targets do Steal.ResetLock(p) end;return true,"รีเซ็ตล็อกฐานแล้ว"
	end})
end
