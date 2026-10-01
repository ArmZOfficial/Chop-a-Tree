-- Initial drop tables; Common level 1 preserves the planned 70/25/5 split.
return table.freeze({
	Weights = {
		Common = {70,25,5,0,0}, Rare = {25,55,18,2,0}, Epic = {0,20,60,18,2},
		Legendary = {0,0,25,65,10}, Mythic = {0,0,10,30,60},
	},
	SpotWeights = {75,20,4,0.9,0.1},
	LevelStep = 20, MaxLevelBoost = 4, GiantLevelBonus = 0.01, MaxGiantChance = 0.25,
	MaxWeapons = 300, MaxStars = 5, FuseBaseWood = 100,
	AltarRange = 24, FreeChestSeconds = 900,
})
