-- UTC login streak; rewards are fixed in zone 1 and use the player's current Rot.
return table.freeze({Rewards={
	{gems=20,label="20 Gems"},
	{gems=30,label="30 Gems"},
	{chest={rarity="Rare",level=5,count=1},label="Chests Rare Lv.5"},
	{gems=50,label="50 Gems"},
	{boost={kind="Wood",seconds=900},label="Wood ×2 • 15 min"},
	{gems=75,label="75 Gems"},
	{gems=100,chest={rarity="Epic",level=20,count=1},label="100 Gems + Chests Epic Lv.20"},
},VipGems=25}) -- VIP pass: extra Gems on every claim
