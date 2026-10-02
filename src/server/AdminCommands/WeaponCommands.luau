local Weapons=require(game.ReplicatedStorage.Shared.Config.WeaponCatalog)
local Net=require(game.ReplicatedStorage.Shared.Net)
local ORDER={"Common","Rare","Epic","Legendary","Mythic"}
-- Fake result for the opening preview: never saved, never granted.
local function fake(rarity,giant)
	local pool={};for _,w in Weapons.List do if w.rarity==rarity then table.insert(pool,w) end end
	local def=pool[math.random(1,math.max(1,#pool))] or Weapons.List[1]
	return {uid="preview",item={id=def.id,il=1,stars=1,giant=giant,rebirthDrop=0,roll=1},new=math.random()<.5,chest=rarity}
end
return function(Admin,Weapon)
	-- Chest opening QA (track J): `chest preview <rarity|giant|1-5> [multi]`; only the admin sees it.
	for i,kind in {"Common","Rare","Epic","Legendary","Mythic","Giant"} do
		for _,multi in {false,true} do
			local rarity=kind=="Giant" and "Legendary" or kind
			Admin.Register({id="chest.preview."..string.lower(kind)..(multi and ".multi" or ""),tab="chests",label="Preview Opening "..kind..(multi and " ×10" or ""),color="Blue",minLevel="Tester",hidden=multi,order=100+i,run=function(ctx)
				local results={fake(rarity,kind=="Giant")}
				if multi then for _=2,10 do table.insert(results,fake(ORDER[math.random(1,math.min(i,5))],false)) end end
				Net.Event("ChestPreview"):FireClient(ctx.admin,results)
				return true,"Preview only — nothing saved"
			end})
		end
	end
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
