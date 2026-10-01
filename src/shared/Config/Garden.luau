return table.freeze({
	InitialSlots=6,MaxSlots=30,UpgradeStep=6,UpgradeWood=500,
	PlotRange=18,BaseRange=65,ShopRange=26,RestockSeconds=300,
	TreeSeedChance=.12,ChestSeedChance=.2,CutSeedChance=.08,
	WaterGrowth=1.1,MaxExpBuff=.25,MaxFruitStacks=300,
	-- Zone ambient (plan 4.12.1 item 7): plots grown from that source zone roll the
	-- zone's mild mutation once per fruit cycle while the owner is online.
	Ambient={[3]={mutation="Misty",chance=.05},[5]={mutation="Wet",chance=.05},[6]={mutation="Chilled",chance=.05}},
	-- Daily full-price sales per UTC day, keyed by the fruit's best capped mutation (plan 4.12.5 item 4).
	SellCaps={Cosmic=5,Celestial=10,Rainbow=10,Aurora=15,Electrified=15},OverCapMult=.1,
})
