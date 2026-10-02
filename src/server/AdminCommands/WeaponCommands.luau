local Weapons=require(game.ReplicatedStorage.Shared.Config.WeaponCatalog)
return function(Admin,Weapon)
	for _,rarity in {"Common","Rare","Epic","Legendary","Mythic"} do
		Admin.Register({id="chests."..rarity,tab="chests",label="Grant Chests "..rarity.." ×3",color="Orange",usesTarget=true,marksTarget=true,run=function(ctx)
			for _,p in ctx.targets do Weapon.GrantChest(p,rarity,20,1,3,true) end
			return true,"Test chests granted. Open at the village station"
		end})
	end
	Admin.Register({id="weapons.fusedemo",tab="weapons",label="Grant 3 Duplicates for Fuse Test",color="Green",usesTarget=true,marksTarget=true,run=function(ctx)
		for _,p in ctx.targets do for _=1,3 do Weapon.Grant(p,Weapons.List[1].id,1,false) end end
		return true,"Duplicates granted (requires Wood and station)"
	end})
	Admin.Register({id="weapons.giant",tab="weapons",label="Grant Giant Mythic",color="Red",usesTarget=true,marksTarget=true,run=function(ctx)
		local id;for _,w in Weapons.List do if w.rarity=="Mythic" then id=w.id;break end end
		for _,p in ctx.targets do Weapon.Grant(p,id,1,true) end
		return true,"Giant Mythic test item granted"
	end})
end
