-- Main story chapters, NPC lines, side quests and boss rules (plan 1, 4.11, 14.4).
-- Step kinds: talk (npc), stat (Stats counter since the step began), zone (stand in zone),
-- boss (defeat zone guardian once), shrine (light the zone shrine).
local Zones=require(script.Parent.Zones)
local chapters={
	{zone=1,title="Chapter 1 • Sunlit Meadow",steps={
		{kind="talk",npc="Bram",text="Talk to Grandpa Bram in the village"},
		{kind="stat",stat="TreesCut",count=10,text="Chop trees in the forest"},
		{kind="stat",stat="ChestsOpened",count=1,text="Open chests at the village station"},
		{kind="stat",stat="SeedsPlanted",count=1,text="Plant a seed in your garden"},
		{kind="stat",stat="EggsHatched",count=1,text="Hatch an egg at your base incubator"},
		{kind="boss",zone=1,text="Defeat Old Oakheart in the boss clearing"},
		{kind="shrine",zone=1,text="Light the Meadow shrine"},
	}},
	{zone=2,title="Chapter 2 • Maple Forest",steps={
		{kind="talk",npc="Bram",text="Report back to Grandpa Bram"},
		{kind="zone",zone=2,text="Enter Maple Forest through the Rot gate"},
		{kind="stat",stat="TreesCut",count=25,text="Chop trees in Maple Forest"},
		{kind="stat",stat="ChestsOpened",count=3,text="Open chests at the village station"},
		{kind="boss",zone=2,text="Defeat Maple Colossus"},
		{kind="shrine",zone=2,text="Light the Maple shrine"},
	}},
}
-- Each zone 3–8 has a keeper NPC near its spawn. New steps are only appended so saved step indexes stay valid.
local keepers={
	[3]={id="Myco",name="Aunt Myco",
		intro={"A visitor from the village! I am Myco. I have tended this marsh for three hundred years.","These glowing mushrooms eat Rot, but Sporemother has eaten all my mushrooms.","Chop the infected trees, then go knock on her door!"},
		outro={"The marsh shrine shines again! My mushrooms can sing once more.","The hill smells of cherry blossoms... and sharp blades. Be careful."},
		idle={"Blue mushrooms are edible. Avoid the purple ones. Green ones... find out yourself!","I am not old. I have simply seen many rainy seasons."}},
	[4]={id="Hana",name="Hana, Sakura Keeper",
		intro={"You cleansed the marsh, did you? I am Hana.","Blossom Ronin trained alongside me. The Rot has consumed his heart.","Please free him with your axe."},
		outro={"The blossoms are pink again. Thank you.","Lightning strikes the bamboo forest every minute. An umbrella will not help."},
		idle={"The best sword is one never drawn... but an axe must swing.","Cherry blossoms last only a moment. Take time to admire them."}},
	[5]={id="Raiko",name="Raiko, Thunder Panda",
		intro={"Zap! My fur stands up from static electricity. I am not scared!","Stormstalk drains lightning from every bamboo stalk to feed the Rot.","Chop the infected bamboo to weaken it."},
		outro={"The lightning has its rhythm back. Look, you can dance to it!","The north is freezing. Want my scarf? ...It is mostly fur."},
		idle={"Bamboo tastes best with a little lightning.","I am not lazy. I am recharging."}},
	[6]={id="Borin",name="Borin, Ice Hunter",
		intro={"Halt! ...Oh, a person. I thought you were a snowman.","Frost Warden froze the shrine beneath the glacier.","Chopping infected pines will warm you up. Trust me."},
		outro={"The ice has melted. The shrine can breathe again.","The crystal ridge ahead is dazzling. Keep your eyes narrowed."},
		idle={"I once caught fish with my bare hands. They were too cold to flee.","Do not lick the ice pillars. You have been warned."}},
	[7]={id="Quartz",name="Quartz, Crystal Golem",
		intro={"...Visitor detected. Threat level to Rot: high.","Prism Titan bends the light of seven shrines toward Lumora Island.","Stop it, and the path to the sky will open."},
		outro={"Crystal light restored. System status: satisfied.","The floating island is the source of the Rot... and of all trees."},
		idle={"I have no heart, but I have quartz. Close enough.","Log: Humans enjoy pressing the talk button repeatedly."}},
	[8]={id="Lumi",name="Lumi, Spirit of Lumora",
		intro={"You finally made it... I am Lumi, the last voice of the mother tree Lumora.","The Rot is my pain spilling into the forests below.","Rotbound Lumora is my infected form. Please set me free."},
		outro={"My roots no longer hurt. All eight forests breathe together.","The Withering has ended... for this cycle.","When you are ready, Rebirth and protect the forest again with greater strength."},
		idle={"Every fallen leaf will return as a seed.","Thank you for listening to the trees."}},
}
for z=3,8 do
	local zone=Zones.List[z];local keeper=keepers[z]
	table.insert(chapters,{zone=z,title="Chapter "..z.." • "..zone.name,steps={
		{kind="zone",zone=z,text="Enter "..zone.name},
		{kind="stat",stat="TreesCut",count=40,text="Chop trees in "..zone.name},
		{kind="boss",zone=z,text="Defeat "..zone.boss},
		{kind="shrine",zone=z,text="Light the shrine in "..zone.name},
		{kind="talk",npc=keeper.id,text="Report to "..keeper.name},
	}})
end
local npcs={Bram={name="Grandpa Bram",
	chapter={
		[1]={"A new face! Welcome to Rootfall Village.","Purple Rot flows from Lumora roots, consuming our forest one tree at a time.","Take this axe. Enter the forest gate and chop infected trees.","When I was young, I chopped trees with a spoon... Believe what you like."},
		[2]={"You defeated Old Oakheart! The Meadow shrine shines again.","The Rot gate to Maple Forest is now open to you.","Watch out! Maple leaves keep falling, just like my hair. Ha!"},
	},
	idle={"The trees told me they wanted chopping... Kidding! They want to grow.","Why do trees avoid card games? They are afraid of getting cut!","Plant trees at your base so the forest can return.","Do not leave incubator eggs unprotected. Lock your base!"},
}}
-- Keepers: intro while their chapter is active, outro on the closing talk step, idle otherwise.
for z,k in keepers do npcs[k.id]={name=k.name,zone=z,intro=k.intro,chapter={[z]=k.outro},idle=k.idle} end
local daily={
	{id="trees",stat="TreesCut",count=60,text="Chop 60 trees"},
	{id="chests",stat="ChestsOpened",count=5,text="Open 5 chests"},
	{id="plant",stat="SeedsPlanted",count=3,text="Plant 3 seeds"},
	{id="harvest",stat="Harvests",count=8,text="Harvest fruit 8 times"},
	{id="hatch",stat="EggsHatched",count=2,text="Hatch 2 eggs"},
	{id="boss",stat="BossKills",count=1,text="Defeat a zone boss once"},
}
return table.freeze({
	Chapters=chapters,
	StepGems=5,ChapterGems=25, -- × chapter number
	Daily=daily,DailyCount=3,DailyGems=5,
	WeeklyCount=3,WeeklyScale=6,WeeklyGems=20,
	IndexGem=1,IndexCompleteGems=50,
	BossRange=26,BossRespawn=60,BossShare=.02,BossWindow=30,BossGems=25,
	TalkRange=16,ShrineRange=18,WarpRange=16,
	Npcs=npcs,
	ShrineLines={"Green light rises from the shrine. The Rot retreats.","The next zone is now open!"},
})
