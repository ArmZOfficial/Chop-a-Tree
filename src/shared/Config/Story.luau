-- Main story chapters, NPC lines, side quests and boss rules (plan 1, 4.11, 14.4).
-- Step kinds: talk (npc), stat (Stats counter since the step began), zone (stand in zone),
-- boss (defeat zone guardian once), shrine (light the zone shrine).
local Zones=require(script.Parent.Zones)
local chapters={
	{zone=1,title="บทที่ 1 • ทุ่งหญ้าแสงแดด",steps={
		{kind="talk",npc="Bram",text="คุยกับปู่ Bram ที่หมู่บ้าน"},
		{kind="stat",stat="TreesCut",count=10,text="ฟันต้นไม้ในป่า"},
		{kind="stat",stat="ChestsOpened",count=1,text="เปิดหีบที่แท่นในหมู่บ้าน"},
		{kind="stat",stat="SeedsPlanted",count=1,text="ปลูกเมล็ดในสวนของคุณ"},
		{kind="stat",stat="EggsHatched",count=1,text="ฟักไข่ที่ตู้ฟักในฐาน"},
		{kind="boss",zone=1,text="ล้ม Old Oakheart ที่ลานบอส"},
		{kind="shrine",zone=1,text="จุดศาลเจ้าทุ่งหญ้า"},
	}},
	{zone=2,title="บทที่ 2 • ป่าเมเปิล",steps={
		{kind="talk",npc="Bram",text="กลับไปเล่าให้ปู่ Bram ฟัง"},
		{kind="zone",zone=2,text="ผ่านประตูราเน่าเข้าป่าเมเปิล"},
		{kind="stat",stat="TreesCut",count=25,text="ฟันต้นไม้ในป่าเมเปิล"},
		{kind="stat",stat="ChestsOpened",count=3,text="เปิดหีบที่แท่นในหมู่บ้าน"},
		{kind="boss",zone=2,text="ล้ม Maple Colossus"},
		{kind="shrine",zone=2,text="จุดศาลเจ้าป่าเมเปิล"},
	}},
}
-- Chapters 3–8 share one template; their zones become playable in Phase 7.
for z=3,8 do
	local zone=Zones.List[z]
	table.insert(chapters,{zone=z,title="บทที่ "..z.." • "..zone.thai,steps={
		{kind="zone",zone=z,text="เข้าสู่"..zone.thai},
		{kind="stat",stat="TreesCut",count=40,text="ฟันต้นไม้ใน"..zone.thai},
		{kind="boss",zone=z,text="ล้ม "..zone.boss},
		{kind="shrine",zone=z,text="จุดศาลเจ้า"..zone.thai},
	}})
end
local daily={
	{id="trees",stat="TreesCut",count=60,text="ฟันต้นไม้ 60 ต้น"},
	{id="chests",stat="ChestsOpened",count=5,text="เปิดหีบ 5 ใบ"},
	{id="plant",stat="SeedsPlanted",count=3,text="ปลูกเมล็ด 3 ครั้ง"},
	{id="harvest",stat="Harvests",count=8,text="เก็บผลไม้ 8 ครั้ง"},
	{id="hatch",stat="EggsHatched",count=2,text="ฟักไข่ 2 ใบ"},
	{id="boss",stat="BossKills",count=1,text="ล้มบอสโซน 1 ครั้ง"},
}
return table.freeze({
	Chapters=chapters,
	StepGems=5,ChapterGems=25, -- × chapter number
	Daily=daily,DailyCount=3,DailyGems=5,
	WeeklyCount=3,WeeklyScale=6,WeeklyGems=20,
	IndexGem=1,IndexCompleteGems=50,
	BossRange=26,BossRespawn=60,BossShare=.02,BossWindow=30,BossGems=25,
	TalkRange=16,ShrineRange=18,WarpRange=16,
	Npcs={Bram={name="ปู่ Bram",
		chapter={
			[1]={"อ้าว! หน้าใหม่นี่นา ยินดีต้อนรับสู่หมู่บ้าน Rootfall","ราเน่าสีม่วงไหลลงมาจากราก Lumora กินป่าเราทีละต้น","เอาขวานนี่ไป เดินผ่านประตูป่าแล้วฟันต้นที่ติดราเน่าซะ","สมัยปู่ยังหนุ่มนะ ปู่ตัดต้นไม้ด้วยช้อน... ไม่เชื่อก็ช่างเถอะ"},
			[2]={"เจ้าล้ม Old Oakheart ได้จริงด้วย! ศาลเจ้าทุ่งหญ้าสว่างแล้ว","ประตูราเน่าไปป่าเมเปิลเปิดให้เจ้าแล้ว","ระวังนะ ใบเมเปิลร่วงตลอด เหมือนผมปู่เลย ฮ่าๆ"},
		},
		idle={"ต้นไม้บอกปู่ว่ามันอยากโดนตัด... ล้อเล่น มันบอกว่าอยากโตต่างหาก","รู้ไหมทำไมต้นไม้ไม่เล่นไพ่? เพราะกลัวโดนตัด!","ปลูกต้นไม้ไว้ในฐานด้วยนะ ป่าจะได้กลับมา","ไข่ในตู้ฟักอย่าทิ้งไว้โดยไม่ล็อกฐานล่ะ"},
	}},
	ShrineLines={"แสงสีเขียวพุ่งขึ้นจากศาลเจ้า ราเน่าถอยออกไป","ทางไปโซนถัดไปเปิดแล้ว!"},
})
