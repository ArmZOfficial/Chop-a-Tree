-- Initial free-path values; permanent Wood/Coins share a x2 ceiling with Rebirth.
local achievements={
	{id="trees100",name="คนตัดไม้หน้าใหม่",stat="TreesCut",need=100,gems=20,title="คนตัดไม้ฝึกหัด"},
	{id="trees1000",name="หนึ่งพันต้น",stat="TreesCut",need=1000,gems=100,title="ผู้พิทักษ์ป่า"},
	{id="trees10000",name="ตำนานคนตัดไม้",stat="TreesCut",need=10000,gems=250,title="ตำนานแห่งป่า"},
	{id="chests25",name="นักล่าหีบ",stat="ChestsOpened",need=25,gems=50,title="นักล่าขุมทรัพย์"},
	{id="harvest50",name="สวนอุดมสมบูรณ์",stat="Harvests",need=50,gems=50,title="เจ้าสวน"},
	{id="hatch20",name="เพื่อนสัตว์",stat="EggsHatched",need=20,gems=50,title="เพื่อนสัตว์ป่า"},
	{id="boss8",name="ผู้ชำระผู้พิทักษ์",stat="BossKills",need=8,gems=100,title="ผู้ชำระราเน่า"},
	{id="rebirth1",name="วัฏจักรใหม่",kind="Rebirth",need=1,gems=100,title="ผู้เริ่มวัฏจักร"},
	{id="index4",name="สมุดสะสมสมบูรณ์",kind="Index",need=4,gems=250,title="นักสะสมแห่ง Rootfall"},
}
local byId={};for _,a in achievements do byId[a.id]=a end
return table.freeze({Index={
	weapons={kind="Power",bonus=.1,text="Power +10% (รวมบัฟ Power สูงสุด ×4)"},
	pets={kind="Coins",bonus=.25,text="Coins ถาวร +25% (รวม Rebirth สูงสุด ×2)"},
	seeds={kind="Wood",bonus=.25,text="Wood ถาวร +25% (รวม Rebirth สูงสุด ×2)"},
	mutations={kind="Luck",bonus=.25,text="โอกาส Epic+ ในหีบ +25% (สูงสุด 100%)"},
},PermanentCap=2,LuckCap=.25,Achievements=achievements,ById=byId})
