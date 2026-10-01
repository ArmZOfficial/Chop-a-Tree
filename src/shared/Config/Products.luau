-- Robux products (plan 17). IDs verified with MarketplaceService:GetProductInfo on 2026-10-02.
-- Never reuse or delete an ID that players have bought; retire by removing its effect only.
-- Prices live on Roblox (Creator Dashboard); the UI reads them with GetProductInfo.
local passes={
	{key="VIP",id=2001758981,name="VIP",desc="ฉายา VIP บนหัว • แท็กแชท • Daily +25 Gems"},
	{key="Wood2x",id=2001776992,name="×2 Wood",desc="Wood ×2 ถาวร (เท่าเพดานทางฟรี ไม่ซ้อน)"},
	{key="Coins2x",id=2002544956,name="×2 Coins",desc="Coins ×2 ถาวร (เท่าเพดานทางฟรี ไม่ซ้อน)"},
	{key="Lucky",id=2004062467,name="โชคดี",desc="โอกาส Epic+ ในหีบ +25% ถาวร"},
	{key="PetSlots",id=1999012110,name="ช่องสัตว์ +2",desc="พกสัตว์เพิ่ม 2 ตัว (สูงสุด 6)"},
	{key="HatchSpeed",id=2001663017,name="ฟักไว ×2",desc="ไข่ฟักเร็ว ×2 เท่าตู้ฟักเลเวลสูงสุด"},
	{key="GardenPlots",id=2001717045,name="แปลงสวน +10",desc="ช่องปลูก +10 (สูงสุด 30)"},
	{key="AutoSell",id=2003072801,name="ขายอัตโนมัติ",desc="เก็บผลแล้วขายทันทีทุกที่"},
	{key="Teleport",id=2002706984,name="วาร์ปทุกที่",desc="เปิดเมนูวาร์ปได้จากร้าน ไม่ต้องไปหินวาร์ป"},
	{key="OpenTen",id=2002598946,name="เปิดหีบรัว",desc="เปิดหีบ 10 ใบในครั้งเดียว"},
}
local products={
	{key="gems100",id=3715863360,name="100 Gems"},{key="gems550",id=3715863453,name="550 Gems"},
	{key="gems1200",id=3715863495,name="1,200 Gems"},{key="gems6500",id=3715864546,name="6,500 Gems"},
	{key="wood15",id=3715864683,name="Wood ×2 • 15 นาที"},{key="wood30",id=3715864726,name="Wood ×2 • 30 นาที"},
	{key="coins15",id=3715864787,name="Coins ×2 • 15 นาที"},{key="coins30",id=3715864824,name="Coins ×2 • 30 นาที"},
	{key="exp15",id=3715864866,name="EXP ×2 • 15 นาที"},{key="exp30",id=3715864911,name="EXP ×2 • 30 นาที"},
	{key="luck15",id=3715864960,name="Luck +25% • 15 นาที"},{key="luck30",id=3715865068,name="Luck +25% • 30 นาที"},
	{key="serverLuck",id=3715865119,name="Luck +25% ทั้งเซิร์ฟ • 15 นาที"},
	{key="instantHatch",id=3715865180,name="ฟักไข่ในตู้ทันที"},{key="instantGrow",id=3715865588,name="ต้นไม้ในสวนโตทันที"},
	{key="chestKey",id=3715865638,name="กุญแจหีบ • หีบ Legendary LEVEL 10"},{key="baseLock",id=3715865697,name="ล็อกฐานทันที"},
}
local passByKey,passById,productByKey,productById={},{},{},{}
for _,v in passes do passByKey[v.key]=v;passById[v.id]=v end
for _,v in products do productByKey[v.key]=v;productById[v.id]=v end
return table.freeze({Passes=passes,Products=products,PassByKey=passByKey,PassById=passById,ProductByKey=productByKey,ProductById=productById,
	-- Season Pass Premium (plan 17.4): sold from the Season panel, granted by SeasonService for the season on sale.
	SeasonPremium=table.freeze({key="seasonPremium",id=3715870274,name="Season Pass Premium"}),ServerLuckSeconds=900,ReceiptKeepSeconds=90*86400})
