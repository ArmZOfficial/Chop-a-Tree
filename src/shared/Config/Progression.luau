-- Initial free-path values; permanent Wood/Coins share a x2 ceiling with Rebirth.
local achievements={
	{id="trees100",name="New Lumberjack",stat="TreesCut",need=100,gems=20,title="Apprentice Lumberjack"},
	{id="trees1000",name="One Thousand Trees",stat="TreesCut",need=1000,gems=100,title="Forest Guardian"},
	{id="trees10000",name="Lumberjack Legend",stat="TreesCut",need=10000,gems=250,title="Forest Legend"},
	{id="chests25",name="Chest Hunter",stat="ChestsOpened",need=25,gems=50,title="Treasure Hunter"},
	{id="harvest50",name="Thriving Garden",stat="Harvests",need=50,gems=50,title="Garden Keeper"},
	{id="hatch20",name="Pet Friend",stat="EggsHatched",need=20,gems=50,title="Forest Friend"},
	{id="boss8",name="Guardian Cleanser",stat="BossKills",need=8,gems=100,title="Rot Cleanser"},
	{id="rebirth1",name="New Cycle",kind="Rebirth",need=1,gems=100,title="Cycle Starter"},
	{id="index4",name="Complete Collection",kind="Index",need=4,gems=250,title="Rootfall Collector"},
}
local byId={};for _,a in achievements do byId[a.id]=a end
return table.freeze({Index={
	weapons={kind="Power",bonus=.1,text="Power +10% (combined Power bonus max ×4)"},
	pets={kind="Coins",bonus=.25,text="Coins Permanent +25% (with Rebirth max ×2)"},
	seeds={kind="Wood",bonus=.25,text="Wood Permanent +25% (with Rebirth max ×2)"},
	mutations={kind="Luck",bonus=.25,text="Epic+ chest chance +25% (max 100%)"},
},PermanentCap=2,LuckCap=.25,TempLuck=.25,LuckMax=.5,Achievements=achievements,ById=byId})
