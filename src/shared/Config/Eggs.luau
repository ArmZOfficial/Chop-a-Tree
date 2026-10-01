-- Eggs per zone. price is zone 1 Coins and scales with the egg's zone.
-- belt = conveyor weight (0 = nest/chest only); nestType matches the map Nest EggType.
-- Zone 3–8 eggs (Phase 7) come from nests and chests only, so the shared belt never
-- shows eggs a new player cannot buy.
local list={
	{id="egg_meadow",name="Meadow Egg",thai="ไข่ทุ่งหญ้า",zone=1,nestType="MeadowEgg",hatch=60,price=500,belt=60,color=Color3.fromRGB(170,230,120),
		pets={{"pet_bunny",45},{"pet_fox",35},{"pet_bee",15},{"pet_deer",4.5},{"pet_wolf",.5}}},
	{id="egg_leaf",name="Leaf Egg",thai="ไข่ใบไม้",zone=2,nestType="LeafEgg",hatch=300,price=2500,belt=30,color=Color3.fromRGB(240,150,70),
		pets={{"pet_squirrel",45},{"pet_owl",35},{"pet_boar",15},{"pet_stag",4.5},{"pet_phoenix",.5}}},
	{id="egg_sunburst",name="Sunburst Egg",thai="ไข่แสงตะวัน",zone=1,hatch=600,price=5000,belt=8,color=Color3.fromRGB(255,214,90),
		pets={{"pet_fox",30},{"pet_bee",40},{"pet_deer",22},{"pet_wolf",7},{"pet_drake",1}}},
	{id="egg_starlit",name="Starlit Egg",thai="ไข่แสงดาว",zone=1,hatch=3600,price=50000,belt=2,color=Color3.fromRGB(190,170,255),
		pets={{"pet_deer",40},{"pet_wolf",40},{"pet_drake",19},{"pet_lumikit",1}}},
	{id="egg_spore",name="Spore Egg",thai="ไข่สปอร์",zone=3,nestType="SporeEgg",hatch=600,price=2500,belt=0,color=Color3.fromRGB(120,230,200),
		pets={{"pet_sporetoad",45},{"pet_glowmoth",35},{"pet_fungalfox",15},{"pet_mireboar",4.5},{"pet_sporedrake",0.5}}},
	{id="egg_petal",name="Petal Egg",thai="ไข่กลีบซากุระ",zone=4,nestType="PetalEgg",hatch=900,price=2500,belt=0,color=Color3.fromRGB(255,183,213),
		pets={{"pet_petalbunny",45},{"pet_blossomcrane",35},{"pet_roninfox",15},{"pet_sakurastag",4.5},{"pet_cherrydragon",0.5}}},
	{id="egg_thunder",name="Thunder Egg",thai="ไข่สายฟ้า",zone=5,nestType="ThunderEgg",hatch=1200,price=2500,belt=0,color=Color3.fromRGB(255,235,80),
		pets={{"pet_voltsquirrel",45},{"pet_stormcrow",35},{"pet_thunderwolf",15},{"pet_bambooboar",4.5},{"pet_raijudrake",0.5}}},
	{id="egg_frost",name="Frost Egg",thai="ไข่น้ำแข็ง",zone=6,nestType="FrostEgg",hatch=1800,price=2500,belt=0,color=Color3.fromRGB(170,225,255),
		pets={{"pet_snowhare",45},{"pet_frostowl",35},{"pet_icewolf",15},{"pet_aurorastag",4.5},{"pet_glacierwyrm",0.5}}},
	{id="egg_crystal",name="Crystal Egg",thai="ไข่คริสตัล",zone=7,nestType="CrystalEgg",hatch=2400,price=2500,belt=0,color=Color3.fromRGB(200,170,255),
		pets={{"pet_gembunny",45},{"pet_prismbird",35},{"pet_shardfox",15},{"pet_quartzboar",4.5},{"pet_prismdrake",0.5}}},
	{id="egg_celestial",name="Celestial Egg",thai="ไข่สวรรค์",zone=8,nestType="CelestialEgg",hatch=3600,price=2500,belt=0,color=Color3.fromRGB(255,236,170),
		pets={{"pet_cloudkit",45},{"pet_halodove",35},{"pet_starwolf",15},{"pet_celestialstag",4.5},{"pet_lumorawyrm",0.5}}},
}
local byId,byNest={},{};for _,v in list do byId[v.id]=v;if v.nestType then byNest[v.nestType]=v end end
return table.freeze({List=list,ById=byId,ByNest=byNest})
