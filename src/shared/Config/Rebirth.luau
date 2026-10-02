-- Initial economy inputs; tune in Phase 10. Each purchase costs baseCost × next rank.
local skills={
	{id="AutoCut",name="Skilled Lumberjack",description="Auto Cut penalty reduced by 5% per tier (minimum penalty 25%)",max=4,baseCost=1},
	{id="PetSlots",name="Companion",description="Carry +1 pet per tier (max 6 pets)",max=3,baseCost=2},
	{id="ChestLevel",name="Cycle Chest",description="Run chests gain +1 level per tier",max=5,baseCost=1},
	{id="Wood",name="Thriving Forest",description="Wood Add 50% per tier (max ×2)",max=2,baseCost=2},
	{id="Coins",name="Forest Wealth",description="Forest Coins +50% per tier (max ×2)",max=2,baseCost=2},
	{id="Luck",name="Collector's Luck",description="Epic+ chest chance +12.5% per tier (with Index max +25%)",max=2,baseCost=2},
}
local byId={};for _,s in skills do byId[s.id]=s end
return table.freeze({CoinBase=1e9,FirstBossZone=4,MaxRebirth=280,ConfirmSeconds=30,Skills=skills,ById=byId})
