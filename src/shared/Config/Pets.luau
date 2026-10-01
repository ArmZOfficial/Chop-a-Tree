-- Initial pet roster for built zones 1–2; zones 3–8 add rows in Phase 7.
-- buff: Power/Wood/Exp multiply forest results, Speed multiplies WalkSpeed.
local list={
	{id="pet_bunny",name="Clover Bunny",thai="กระต่ายโคลเวอร์",rarity="Common",zone=1,buff="Speed",shape="bunny",color=Color3.fromRGB(245,240,230),accent=Color3.fromRGB(120,200,110)},
	{id="pet_fox",name="Ember Fox",thai="จิ้งจอกถ่านแดง",rarity="Common",zone=1,buff="Power",shape="fox",color=Color3.fromRGB(240,128,60),accent=Color3.fromRGB(255,240,220)},
	{id="pet_bee",name="Honey Bee",thai="ผึ้งน้ำผึ้ง",rarity="Rare",zone=1,buff="Wood",shape="bird",color=Color3.fromRGB(250,204,21),accent=Color3.fromRGB(40,30,20)},
	{id="pet_deer",name="Sun Deer",thai="กวางตะวัน",rarity="Epic",zone=1,buff="Exp",shape="deer",rideable=true,color=Color3.fromRGB(214,160,96),accent=Color3.fromRGB(255,236,150)},
	{id="pet_wolf",name="Meadow Wolf",thai="หมาป่าทุ่งหญ้า",rarity="Legendary",zone=1,buff="Power",shape="wolf",rideable=true,color=Color3.fromRGB(170,180,196),accent=Color3.fromRGB(110,220,140)},
	{id="pet_drake",name="Little Sun Drake",thai="มังกรน้อยสุริยา",rarity="Mythic",zone=1,buff="Power",shape="drake",rideable=true,color=Color3.fromRGB(255,120,60),accent=Color3.fromRGB(255,220,90)},
	{id="pet_lumikit",name="Lumora Kit",thai="ลูกแมวลูมอรา",rarity="Secret",zone=1,buff="Exp",shape="kit",color=Color3.fromRGB(255,244,190),accent=Color3.fromRGB(130,255,190)},
	{id="pet_squirrel",name="Acorn Squirrel",thai="กระรอกลูกโอ๊ก",rarity="Common",zone=2,buff="Wood",shape="bunny",color=Color3.fromRGB(176,98,50),accent=Color3.fromRGB(240,200,150)},
	{id="pet_owl",name="Maple Owl",thai="นกฮูกเมเปิล",rarity="Rare",zone=2,buff="Exp",shape="bird",color=Color3.fromRGB(196,90,48),accent=Color3.fromRGB(255,214,140)},
	{id="pet_boar",name="Amber Boar",thai="หมูป่าอำพัน",rarity="Epic",zone=2,buff="Power",shape="boar",rideable=true,color=Color3.fromRGB(150,92,52),accent=Color3.fromRGB(250,180,70)},
	{id="pet_stag",name="Autumn Stag",thai="กวางใบไม้ร่วง",rarity="Legendary",zone=2,buff="Speed",shape="deer",rideable=true,color=Color3.fromRGB(190,96,40),accent=Color3.fromRGB(255,150,60)},
	{id="pet_phoenix",name="Leaf Phoenix",thai="ฟีนิกซ์ใบไม้",rarity="Mythic",zone=2,buff="Power",shape="drake",rideable=true,color=Color3.fromRGB(230,80,40),accent=Color3.fromRGB(255,190,60)},
}
local byId={};for _,v in list do byId[v.id]=v end
return table.freeze({
	List=list,ById=byId,
	Order={"Common","Rare","Epic","Legendary","Mythic","Secret"},
	-- Coins per second in the pen for a zone 1, tier 1, unmutated pet.
	Income={Common=2,Rare=6,Epic=20,Legendary=60,Mythic=200,Secret=600},
	-- Additive buff while following; scaled ×1.2 per source zone (plan 14.2).
	Bonus={Common=.05,Rare=.1,Epic=.2,Legendary=.35,Mythic=.6,Secret=1},
	Colors={Common=Color3.fromRGB(75,85,99),Rare=Color3.fromRGB(29,78,216),Epic=Color3.fromRGB(126,34,206),Legendary=Color3.fromRGB(180,83,9),Mythic=Color3.fromRGB(185,28,28),Secret=Color3.fromRGB(15,15,15)},
	ZoneBonus=1.2,TierIncome=.5,TierBuff=.25,MaxTier=5,
	MaxBuff=4,MaxSpeed=1.5,SpeedScale=.5, -- plan 17.1.6 caps combined boosts at ×4
	-- Hatch mutations raise pen income only; one mutation per pet.
	Mutations={Shocked={mult=3,weather="Storm"},Frozen={mult=4,weather="Snow"},Golden={mult=5,weather="Golden"}},
	HatchMutationChance=.35,
})
