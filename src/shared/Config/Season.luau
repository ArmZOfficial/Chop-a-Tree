-- Season Pass (plan 17.4). One row per season; the active one is the row whose UTC window contains now.
-- Premium is bound to the season id it was bought for and never carries into the next season.
-- Rewards use RewardService shapes (gems/chest/boost); Premium adds more of the same, no stronger chest tier (no P2W). Exclusive cosmetics wait for the cosmetic system (plan 17.5).
local function rewards(free,premium)
	local out={}
	for level=1,#free do out[level]={free=free[level],premium=premium[level]} end
	return out
end
local G=function(n) return {gems=n,label=n.." Gems"} end
local B=function(kind,min) return {boost={kind=kind,seconds=min*60},label=kind.." ×2 • "..min.." min"} end
local CH=function(rarity,level) return {chest={rarity=rarity,level=level,count=1},label="Chests "..rarity.." Lv."..level} end
local levels=rewards({
	G(10),B("Wood",15),G(15),CH("Rare",5),G(20),B("Coins",15),G(25),CH("Rare",8),G(30),CH("Epic",10),
	G(30),B("Exp",15),G(35),CH("Rare",10),G(40),B("Luck",15),G(45),CH("Epic",15),G(50),CH("Epic",20),
	G(50),B("Wood",30),G(60),CH("Epic",25),G(70),B("Coins",30),G(80),CH("Legendary",10),G(90),CH("Legendary",15),
},{
	G(40),B("Exp",30),G(50),CH("Epic",10),G(60),B("Luck",30),G(70),CH("Epic",15),G(80),CH("Legendary",10),
	G(90),B("Wood",30),G(100),CH("Epic",20),G(110),B("Coins",30),G(120),CH("Legendary",15),G(150),CH("Legendary",20),
	G(150),B("Luck",30),G(175),CH("Legendary",25),G(200),B("Exp",30),G(250),CH("Legendary",20),G(300),CH("Legendary",25),
})
return table.freeze({
	Seasons={
		{id="s1_2026_10",name="Season 1 • First Bloom",startsAt=1790812800,endsAt=1793491200}, -- 2026-10-01 → 2026-11-01 UTC
		{id="s2_2026_11",name="Season 2 • Moonlit Forest",startsAt=1793491200,endsAt=1796083200}, -- 2026-11-01 → 2026-12-01 UTC
		{id="s3_2026_12",name="Season 3 • Silver Snow Forest",startsAt=1796083200,endsAt=1798761600}, -- 2026-12-01 → 2027-01-01 UTC
		{id="s4_2027_01",name="Season 4 • Lantern Grove",startsAt=1798761600,endsAt=1801440000}, -- 2027-01-01 → 2027-02-01 UTC
		{id="s5_2027_02",name="Season 5 • Heartwood Orchard",startsAt=1801440000,endsAt=1803859200}, -- 2027-02-01 → 2027-03-01 UTC
	},
	XpPerLevel=1000,
	Levels=levels,
	-- Pass XP per Stats increment. Auto Cut trees earn less than manual cuts (plan 17.4.3).
	Xp={TreesCut=10,AutoTreesCut=5,SeedsPlanted=15,Harvests=15,EggsHatched=40,ChestsOpened=10,BossKills=150,WorldBossKills=150},
	-- Paid when a Premium receipt cannot unlock its season (already owned or the season ended): ≈ Gems value of 499 Robux.
	PremiumFallbackGems=4500,
})
