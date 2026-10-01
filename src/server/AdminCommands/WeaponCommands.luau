local Weapons=require(game.ReplicatedStorage.Shared.Config.Weapons)
return function(Admin,Weapon)
	for _,rarity in {"Common","Rare","Epic","Legendary","Mythic"} do
		Admin.Register({id="chests."..rarity,tab="chests",label="ให้หีบ "..rarity.." ×3",color="Orange",usesTarget=true,marksTarget=true,run=function(ctx)
			for _,p in ctx.targets do Weapon.GrantChest(p,rarity,20,1,3,true) end
			return true,"ให้หีบทดสอบแล้ว — เปิดที่แท่นหมู่บ้าน"
		end})
	end
	Admin.Register({id="weapons.fusedemo",tab="weapons",label="ให้ของซ้ำ 3 ชิ้นทดสอบ Fuse",color="Green",usesTarget=true,marksTarget=true,run=function(ctx)
		for _,p in ctx.targets do for _=1,3 do Weapon.Grant(p,Weapons.List[1].id,1,false) end end
		return true,"ให้ของซ้ำแล้ว (ต้องมี Wood และอยู่ที่แท่น)"
	end})
	Admin.Register({id="weapons.giant",tab="weapons",label="ให้ Giant Mythic",color="Red",usesTarget=true,marksTarget=true,run=function(ctx)
		local id;for _,w in Weapons.List do if w.rarity=="Mythic" then id=w.id;break end end
		for _,p in ctx.targets do Weapon.Grant(p,id,1,true) end
		return true,"ให้ Giant Mythic ทดสอบแล้ว"
	end})
end
