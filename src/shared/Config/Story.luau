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
-- Each zone 3–8 has a keeper NPC near its spawn. New steps are only appended so saved step indexes stay valid.
local keepers={
	[3]={id="Myco",name="ป้า Myco",
		intro={"โอ๊ะ เด็กจากหมู่บ้าน! ป้าคือ Myco ดูแลบึงเห็ดนี้มาสามร้อยปีแล้ว","เห็ดเรืองแสงพวกนี้กินราเน่าได้ แต่ Sporemother กินเห็ดของป้าไปหมด","ฟันต้นที่ติดราให้เยอะๆ แล้วไปเคาะประตูบ้านมันซะ"},
		outro={"ศาลเจ้าบึงสว่างแล้ว! เห็ดของป้าร้องเพลงได้อีกครั้ง","ข้างบนเนินมีกลิ่นซากุระ... แต่ก็มีกลิ่นดาบด้วย ระวังตัวนะ"},
		idle={"เห็ดสีฟ้ากินได้ สีม่วงอย่าแตะ สีเขียว... ลองดูเองสิ","ป้าไม่ได้แก่นะ ป้าแค่ผ่านฤดูฝนมาเยอะ"}},
	[4]={id="Hana",name="Hana ผู้เฝ้าซากุระ",
		intro={"เจ้าคือคนที่ลบราเน่าในบึงสินะ ข้าชื่อ Hana","Blossom Ronin เคยเป็นศิษย์ร่วมสำนักของข้า ราเน่ากลืนใจเขาไปแล้ว","ช่วยปลดปล่อยเขาด้วยขวานของเจ้า"},
		outro={"กลีบซากุระกลับมาเป็นสีชมพูแล้ว ขอบใจเจ้ามาก","ป่าไผ่ข้างหน้าฟ้าผ่าทุกนาที เอาร่มไปด้วยก็ไม่ช่วยหรอก"},
		idle={"ดาบที่ดีที่สุดคือดาบที่ไม่ต้องชัก... แต่ขวานต้องเหวี่ยงนะ","ซากุระบานแค่ครู่เดียว เลยต้องตั้งใจดู"}},
	[5]={id="Raiko",name="Raiko แพนด้าสายฟ้า",
		intro={"ปึ้ง! ขนข้าชี้ตั้งเพราะไฟฟ้าสถิต ไม่ได้ตกใจนะ","Stormstalk ดูดฟ้าผ่าจากไผ่ทุกต้นไปเลี้ยงราเน่า","ฟันไผ่ที่ติดราให้หมด มันจะอ่อนแรงลง"},
		outro={"ฟ้าผ่ากลับมาเป็นจังหวะสวยงามแล้ว ดูสิ เต้นได้เลย","ทางเหนือหนาวมาก เอาผ้าพันคอข้าไปไหม? ...มีแต่ขนนะ"},
		idle={"ไผ่อร่อยที่สุดตอนโดนฟ้าผ่านิดๆ","ข้าไม่ได้ขี้เกียจ ข้ากำลังชาร์จไฟอยู่"}},
	[6]={id="Borin",name="Borin นักล่าน้ำแข็ง",
		intro={"หยุด! ...อ้อ คนนี่เอง นึกว่ามนุษย์หิมะ","Frost Warden แช่แข็งศาลเจ้าไว้ใต้ธารน้ำแข็ง","ฟันต้นสนที่ติดราแล้วตัวเจ้าจะอุ่นขึ้น เชื่อข้า"},
		outro={"น้ำแข็งละลายแล้ว ศาลเจ้าหายใจได้อีกครั้ง","สันเขาคริสตัลข้างหน้าแสงแยงตามาก หรี่ตาไว้"},
		idle={"ข้าเคยจับปลาด้วยมือเปล่า ปลามันหนาวจนไม่หนี","อย่าเลียเสาน้ำแข็ง ข้าเตือนแล้ว"}},
	[7]={id="Quartz",name="Quartz โกเลมคริสตัล",
		intro={"...ตรวจพบผู้มาเยือน ระดับภัยคุกคามต่อราเน่า: สูง","Prism Titan หักเหแสงของศาลเจ้าทั้งเจ็ดไปที่เกาะ Lumora","หยุดมัน แล้วทางขึ้นฟ้าจะเปิด"},
		outro={"แสงคริสตัลกลับสู่ทิศทางเดิม ระบบ: พอใจ","เกาะลอยฟ้าข้างบนคือที่มาของราเน่า... และของต้นไม้ทั้งหมด"},
		idle={"ข้าไม่มีหัวใจ แต่มีแร่ควอตซ์ ใกล้เคียงกัน","บันทึก: มนุษย์ชอบกดปุ่มคุยซ้ำ"}},
	[8]={id="Lumi",name="Lumi วิญญาณ Lumora",
		intro={"เจ้ามาถึงจนได้... ข้าคือ Lumi เสียงสุดท้ายของต้นไม้แม่ Lumora","ราเน่าคือความเจ็บปวดของข้าที่รั่วลงไปถึงป่าเบื้องล่าง","Rotbound Lumora คือร่างที่ติดเชื้อของข้า ปลดปล่อยข้าเถิด"},
		outro={"รากของข้าหยุดเจ็บแล้ว ป่าทั้งแปดกำลังหายใจพร้อมกัน","The Withering จบลงแล้ว... ในวัฏจักรนี้","เมื่อเจ้าพร้อม จงเกิดใหม่ (Rebirth) แล้วปกป้องป่าอีกครั้งด้วยพลังที่แข็งแกร่งกว่าเดิม"},
		idle={"ทุกใบไม้ที่ร่วงจะกลับมาเป็นเมล็ด","ขอบใจที่ฟังเสียงต้นไม้"}},
}
for z=3,8 do
	local zone=Zones.List[z];local keeper=keepers[z]
	table.insert(chapters,{zone=z,title="บทที่ "..z.." • "..zone.thai,steps={
		{kind="zone",zone=z,text="เข้าสู่"..zone.thai},
		{kind="stat",stat="TreesCut",count=40,text="ฟันต้นไม้ใน"..zone.thai},
		{kind="boss",zone=z,text="ล้ม "..zone.boss},
		{kind="shrine",zone=z,text="จุดศาลเจ้า"..zone.thai},
		{kind="talk",npc=keeper.id,text="เล่าให้ "..keeper.name.." ฟัง"},
	}})
end
local npcs={Bram={name="ปู่ Bram",
	chapter={
		[1]={"อ้าว! หน้าใหม่นี่นา ยินดีต้อนรับสู่หมู่บ้าน Rootfall","ราเน่าสีม่วงไหลลงมาจากราก Lumora กินป่าเราทีละต้น","เอาขวานนี่ไป เดินผ่านประตูป่าแล้วฟันต้นที่ติดราเน่าซะ","สมัยปู่ยังหนุ่มนะ ปู่ตัดต้นไม้ด้วยช้อน... ไม่เชื่อก็ช่างเถอะ"},
		[2]={"เจ้าล้ม Old Oakheart ได้จริงด้วย! ศาลเจ้าทุ่งหญ้าสว่างแล้ว","ประตูราเน่าไปป่าเมเปิลเปิดให้เจ้าแล้ว","ระวังนะ ใบเมเปิลร่วงตลอด เหมือนผมปู่เลย ฮ่าๆ"},
	},
	idle={"ต้นไม้บอกปู่ว่ามันอยากโดนตัด... ล้อเล่น มันบอกว่าอยากโตต่างหาก","รู้ไหมทำไมต้นไม้ไม่เล่นไพ่? เพราะกลัวโดนตัด!","ปลูกต้นไม้ไว้ในฐานด้วยนะ ป่าจะได้กลับมา","ไข่ในตู้ฟักอย่าทิ้งไว้โดยไม่ล็อกฐานล่ะ"},
}}
-- Keepers: intro while their chapter is active, outro on the closing talk step, idle otherwise.
for z,k in keepers do npcs[k.id]={name=k.name,zone=z,intro=k.intro,chapter={[z]=k.outro},idle=k.idle} end
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
	Npcs=npcs,
	ShrineLines={"แสงสีเขียวพุ่งขึ้นจากศาลเจ้า ราเน่าถอยออกไป","ทางไปโซนถัดไปเปิดแล้ว!"},
})
