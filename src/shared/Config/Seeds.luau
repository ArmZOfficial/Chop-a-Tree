-- Initial garden economy; source zone/Rot scale prices and harvests via Balance.
local list={
	{id="seed_sunapple",name="Sunapple",thai="แอปเปิลแสงอาทิตย์",rarity="Common",tier=1,grow=300,fruitTime=60,yield=3,price=100,value=100,wood=300,stockChance=1,stockMin=4,stockMax=8,color=Color3.fromRGB(255,112,72)},
	{id="seed_maplesap",name="Maple Sap",thai="เมเปิลน้ำผึ้ง",rarity="Common",tier=2,grow=600,fruitTime=90,yield=2,price=250,value=250,wood=700,stockChance=.9,stockMin=3,stockMax=6,color=Color3.fromRGB(244,176,67)},
	{id="seed_moonbamboo",name="Moon Bamboo",thai="ไผ่จันทรา",rarity="Rare",tier=3,grow=1800,fruitTime=180,yield=3,price=1250,value=500,wood=3000,stockChance=.5,stockMin=1,stockMax=3,color=Color3.fromRGB(119,234,210)},
	{id="seed_frostpear",name="Frost Pear",thai="ลูกแพร์น้ำค้าง",rarity="Rare",tier=3,grow=3600,fruitTime=300,yield=3,price=2500,value=1000,wood=6000,stockChance=.4,stockMin=1,stockMax=2,color=Color3.fromRGB(164,221,255)},
	{id="seed_sakuragem",name="Sakura Gem",thai="ซากุระแก้ว",rarity="Epic",tier=4,grow=7200,fruitTime=600,yield=3,price=6000,value=3000,wood=14000,stockChance=.2,stockMin=1,stockMax=2,color=Color3.fromRGB(251,149,210)},
	{id="seed_crystalpine",name="Crystal Pine",thai="สนคริสตัล",rarity="Epic",tier=4,grow=14400,fruitTime=900,yield=2,price=12000,value=7000,wood=30000,stockChance=.15,stockMin=1,stockMax=1,color=Color3.fromRGB(182,151,255)},
	{id="seed_thunderroot",name="Thunderroot",thai="รากสายฟ้า",rarity="Legendary",tier=5,grow=43200,fruitTime=1800,yield=3,price=30000,value=15000,wood=75000,stockChance=.07,stockMin=1,stockMax=1,color=Color3.fromRGB(252,243,115)},
	{id="seed_lumora",name="Lumora",thai="ลูมอรา",rarity="Mythic",tier=6,grow=86400,fruitTime=3600,yield=3,price=60000,value=40000,wood=150000,stockChance=.025,stockMin=1,stockMax=1,expBuff=.05,color=Color3.fromRGB(255,232,149)},
}
local byId={};for _,v in list do byId[v.id]=v end
return table.freeze({List=list,ById=byId})
