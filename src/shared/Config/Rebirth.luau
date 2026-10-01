-- Initial economy inputs; tune in Phase 10. Each purchase costs baseCost × next rank.
local skills={
	{id="AutoCut",name="คนตัดไม้ชำนาญ",description="Auto Cut หักน้อยลง 5% ต่อขั้น (สูงสุดเหลือ −25%)",max=4,baseCost=1},
	{id="PetSlots",name="เพื่อนร่วมทาง",description="พกสัตว์เพิ่ม 1 ตัวต่อขั้น (สูงสุด 6 ตัว)",max=3,baseCost=2},
	{id="ChestLevel",name="หีบแห่งวัฏจักร",description="หีบที่เก็บใน Run เลเวลเพิ่ม 1 ต่อขั้น",max=5,baseCost=1},
	{id="Wood",name="ป่าอุดมสมบูรณ์",description="Wood เพิ่ม 50% ต่อขั้น (สูงสุด ×2)",max=2,baseCost=2},
	{id="Coins",name="ทรัพย์แห่งป่า",description="Coins จากป่าเพิ่ม 50% ต่อขั้น (สูงสุด ×2)",max=2,baseCost=2},
	{id="Luck",name="โชคของนักสะสม",description="โอกาส Epic+ ในหีบ +12.5% ต่อขั้น (รวม Index สูงสุด +25%)",max=2,baseCost=2},
}
local byId={};for _,s in skills do byId[s.id]=s end
return table.freeze({CoinBase=1e9,FirstBossZone=4,MaxRebirth=280,ConfirmSeconds=30,Skills=skills,ById=byId})
