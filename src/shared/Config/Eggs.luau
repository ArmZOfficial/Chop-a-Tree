-- Eggs for built zones 1–2. price is zone 1 Coins and scales with the egg's zone.
-- belt = conveyor weight (0 = nest/chest only); nestType matches the map Nest EggType.
local list={
	{id="egg_meadow",name="Meadow Egg",thai="ไข่ทุ่งหญ้า",zone=1,nestType="MeadowEgg",hatch=60,price=500,belt=60,color=Color3.fromRGB(170,230,120),
		pets={{"pet_bunny",45},{"pet_fox",35},{"pet_bee",15},{"pet_deer",4.5},{"pet_wolf",.5}}},
	{id="egg_leaf",name="Leaf Egg",thai="ไข่ใบไม้",zone=2,nestType="LeafEgg",hatch=300,price=2500,belt=30,color=Color3.fromRGB(240,150,70),
		pets={{"pet_squirrel",45},{"pet_owl",35},{"pet_boar",15},{"pet_stag",4.5},{"pet_phoenix",.5}}},
	{id="egg_sunburst",name="Sunburst Egg",thai="ไข่แสงตะวัน",zone=1,hatch=600,price=5000,belt=8,color=Color3.fromRGB(255,214,90),
		pets={{"pet_fox",30},{"pet_bee",40},{"pet_deer",22},{"pet_wolf",7},{"pet_drake",1}}},
	{id="egg_starlit",name="Starlit Egg",thai="ไข่แสงดาว",zone=1,hatch=3600,price=50000,belt=2,color=Color3.fromRGB(190,170,255),
		pets={{"pet_deer",40},{"pet_wolf",40},{"pet_drake",19},{"pet_lumikit",1}}},
}
local byId,byNest={},{};for _,v in list do byId[v.id]=v;if v.nestType then byNest[v.nestType]=v end end
return table.freeze({List=list,ById=byId,ByNest=byNest})
