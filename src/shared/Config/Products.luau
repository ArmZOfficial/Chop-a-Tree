-- Robux products (plan 17). IDs verified with MarketplaceService:GetProductInfo on 2026-10-02.
-- Never reuse or delete an ID that players have bought; retire by removing its effect only.
-- Prices live on Roblox (Creator Dashboard); the UI reads them with GetProductInfo.
local passes={
	{key="VIP",id=2001758981,name="VIP",desc="VIP overhead title • Chat tag • Daily +25 Gems"},
	{key="Wood2x",id=2001776992,name="×2 Wood",desc="Wood ×2 Permanent (same free cap; does not stack)"},
	{key="Coins2x",id=2002544956,name="×2 Coins",desc="Coins ×2 Permanent (same free cap; does not stack)"},
	{key="Lucky",id=2004062467,name="Lucky",desc="Epic+ chest chance +25% Permanent"},
	{key="PetSlots",id=1999012110,name="Pet Slots +2",desc="Carry +2 pets (max 6)"},
	{key="HatchSpeed",id=2001663017,name="Hatch Speed ×2",desc="Hatch speed ×2, matching a max-level incubator"},
	{key="GardenPlots",id=2001717045,name="Garden Slots +10",desc="Garden Slots +10 (max 30)"},
	{key="AutoSell",id=2003072801,name="Auto Sell",desc="Harvest and sell instantly anywhere"},
	{key="Teleport",id=2002706984,name="Teleport Anywhere",desc="Open Warp from the shop without visiting a warp stone"},
	{key="OpenTen",id=2002598946,name="Open Ten",desc="Open Chest 10 chests at once"},
}
local products={
	{key="gems100",id=3715863360,name="100 Gems"},{key="gems550",id=3715863453,name="550 Gems"},
	{key="gems1200",id=3715863495,name="1,200 Gems"},{key="gems6500",id=3715864546,name="6,500 Gems"},
	{key="wood15",id=3715864683,name="Wood ×2 • 15 min"},{key="wood30",id=3715864726,name="Wood ×2 • 30 min"},
	{key="coins15",id=3715864787,name="Coins ×2 • 15 min"},{key="coins30",id=3715864824,name="Coins ×2 • 30 min"},
	{key="exp15",id=3715864866,name="EXP ×2 • 15 min"},{key="exp30",id=3715864911,name="EXP ×2 • 30 min"},
	{key="luck15",id=3715864960,name="Luck +25% • 15 min"},{key="luck30",id=3715865068,name="Luck +25% • 30 min"},
	{key="serverLuck",id=3715865119,name="Server Luck +25% • 15 min"},
	{key="instantHatch",id=3715865180,name="Instant Incubator Hatch"},{key="instantGrow",id=3715865588,name="Instant Garden Growth"},
	{key="chestKey",id=3715865638,name="Chest Key • Legendary Chest Level 10"},{key="baseLock",id=3715865697,name="Instant Base Lock"},
}
local passByKey,passById,productByKey,productById={},{},{},{}
for _,v in passes do passByKey[v.key]=v;passById[v.id]=v end
for _,v in products do productByKey[v.key]=v;productById[v.id]=v end
return table.freeze({Passes=passes,Products=products,PassByKey=passByKey,PassById=passById,ProductByKey=productByKey,ProductById=productById,
	-- Season Pass Premium (plan 17.4): sold from the Season panel, granted by SeasonService for the season on sale.
	SeasonPremium=table.freeze({key="seasonPremium",id=3715870274,name="Season Pass Premium"}),ServerLuckSeconds=900,ReceiptKeepSeconds=90*86400})
