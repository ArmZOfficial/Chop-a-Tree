local S=game.ReplicatedStorage.Shared
local Eggs=require(S.Config.Eggs)
local Pets=require(S.Config.Pets)
local Math=require(S.PetMath)
local Data=require(game.ServerScriptService.Server.Services.DataService)
return function(Admin,Pet,Steal)
	Admin.Register({id="eggs.all",tab="pets",label="Grant All Eggs ×1",color="Pink",usesTarget=true,marksTarget=true,run=function(ctx)
		for _,p in ctx.targets do for _,e in Eggs.List do Pet.GrantEgg(p,{id=e.id,admin_spawned=true}) end;Pet.Send(p) end
		return true,"Test eggs granted. Place at your base incubator"
	end})
	Admin.Register({id="eggs.hatchnow",tab="pets",label="Instant Incubator Hatch",color="Green",usesTarget=true,marksTarget=true,run=function(ctx)
		for _,p in ctx.targets do local d=Data.Get(p,"Pets")
			if d then for _,egg in d.incubator do if not egg.carriedBy then egg.progress=Eggs.ById[egg.id].hatch;egg.done=true;egg.admin_spawned=true end end;Pet.Send(p) end
		end
		return true,"Incubator eggs ready to hatch"
	end})
	Admin.Register({id="eggs.five",tab="pets",label="Incubator eggs: 5 sec remaining",color="Blue",usesTarget=true,marksTarget=true,run=function(ctx)
		for _,p in ctx.targets do local d=Data.Get(p,"Pets")
			if d then local speed=Math.HatchSpeed(d.upgrades.incubator)
				for _,egg in d.incubator do if not egg.done then egg.progress=math.max(egg.progress,Eggs.ById[egg.id].hatch-5*speed);egg.admin_spawned=true end end;Pet.Send(p) end
		end
		return true,"Set Hatch Time to 5 sec"
	end})
	for _,rarity in Pets.Order do local r=rarity
		Admin.Register({id="pets."..r,tab="pets",label="Grant Pets "..r,color=r=="Secret" and "Slate" or "Purple",usesTarget=true,marksTarget=true,run=function(ctx)
			for _,p in ctx.targets do for _,def in Pets.List do if def.rarity==r then Pet.GrantPet(p,def.id,{admin=true}) end end;Pet.Send(p) end
			return true,"Grant Pets "..r.." done"
		end})
	end
	for id in Pets.Mutations do local m=id
		Admin.Register({id="pets.mut."..m,tab="pets",label="Fox ×3 Mutation "..m,sub="Test Fuse/Income",color="Orange",usesTarget=true,marksTarget=true,run=function(ctx)
			for _,p in ctx.targets do for _=1,3 do Pet.GrantPet(p,"pet_fox",{admin=true,mutation=m}) end;Pet.Send(p) end
			return true,"Grant Ember Fox "..m.." ×3"
		end})
	end
	Admin.Register({id="pets.mount",tab="pets",label="Spawn and Mount Meadow Wolf",color="Teal",usesTarget=true,marksTarget=true,run=function(ctx)
		for _,p in ctx.targets do local ok,uid=Pet.GrantPet(p,"pet_wolf",{admin=true});if ok then Pet.Mount(p,uid) end;Pet.Send(p) end
		return true,"Wolf mounted"
	end})
	Admin.Register({id="steal.botthief",tab="pets",label="Bot Steals Our Egg",sub="Chase and press E to reclaim",color="Red",run=function(ctx) return Steal.SpawnBotThief(ctx.admin) end})
	Admin.Register({id="steal.botbase",tab="pets",label="Create Bot Base to Steal From",sub="Eggs 3 eggs (third egg is over 75% hatched)",color="Orange",run=function()
		local ok,id=Steal.CreateBot();return ok,ok and "Bot base at slot "..id or "No free bases"
	end})
	Admin.Register({id="steal.botdefence",tab="pets",label="Bot Base: Max Traps & Guards",sub="Click again to close",color="Purple",run=function()
		local on=not (Steal.Bot() and Steal.Bot().defence.trap);local ok=Steal.SetBotDefence(on and 3 or nil,on and 3 or nil)
		return ok,ok and ("Bot base traps/guards: "..(on and "Lv 3" or "Close")) or "Create a bot base first"
	end})
	Admin.Register({id="steal.removebot",tab="pets",label="Remove Bot Base",color="Slate",run=function() return Steal.RemoveBot(),"Bot base removed" end})
	for _,mode in {"on","off"} do local m=mode
		Admin.Register({id="steal.shield"..m,tab="pets",label=m=="on" and "Force Shield On" or "Force Shield Off",sub="New Player / AFK Shield",color=m=="on" and "Blue" or "Red",usesTarget=true,run=function(ctx)
			for _,p in ctx.targets do p:SetAttribute("ShieldOverride",m) end;return true,"Shield: "..m
		end})
	end
	Admin.Register({id="steal.shieldauto",tab="pets",label="Standard Shield Rules",color="Green",usesTarget=true,run=function(ctx)
		for _,p in ctx.targets do p:SetAttribute("ShieldOverride",nil) end;return true,"Standard Shield (new: 30 min / AFK: 10 min)"
	end})
	Admin.Register({id="steal.resetlock",tab="pets",label="Reset Base Lock/Theft Cooldown",color="Teal",usesTarget=true,run=function(ctx)
		for _,p in ctx.targets do Steal.ResetLock(p) end;return true,"Base lock reset"
	end})
end
