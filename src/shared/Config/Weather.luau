local list={
	{id="Clear",name="ฟ้าใส",duration=0,weight=0,growth=1,wood=1,exp=1,hp=1},
	{id="Rain",name="ฝนตก",duration=300,weight=50,growth=1.5,wood=1.25,exp=1,hp=1,mutation="Wet",chance=.25},
	{id="Storm",name="พายุฟ้าผ่า",duration=240,weight=20,growth=1,wood=1,exp=1,hp=1,mutation="Shocked",chance=.03},
	{id="Snow",name="หิมะตก",duration=300,weight=25,growth=1,wood=1,exp=1.5,hp=1.25,mutation="Chilled",chance=.2},
	{id="Golden",name="แสงทอง",duration=240,weight=5,growth=1,wood=1,exp=1,hp=1,mutation="Golden",chance=.01,rare=true,chestLevel=5},
	{id="Fog",name="หมอกหนา",duration=360,weight=15,growth=1,wood=1,exp=1,hp=1,mutation="Misty",chance=.12,note="Mutation Misty • หมอกหนา"},
	{id="Wind",name="ลมกรรโชก",duration=180,weight=35,growth=1,wood=1,exp=1,hp=1,mutation="Windswept",chance=.2,area=1.5,note="ระยะ Area อาวุธ ×1.5"},
	{id="Sakura",name="ฝนซากุระ",duration=300,weight=4,growth=1,wood=1,exp=1,hp=1,mutation="Blossom",chance=.025,rare=true,crit=15,note="Critical ×15 • Blossom"},
	{id="Meteor",name="ฝนดาวตก",duration=240,weight=1,growth=1,wood=1,exp=1,hp=1,mutation="Celestial",chance=.005,rare=true,note="Mutation Celestial • ฝนดาวตก"},
	{id="Aurora",name="ออโรรา",duration=360,weight=3,growth=1,wood=1.5,coins=1.5,exp=1,hp=1,mutation="Aurora",chance=.015,rare=true,nightOnly=true,note="Wood/Coins ×1.5 • Aurora"},
	{id="Bloodmoon",name="พระจันทร์สีเลือด",duration=480,weight=1,growth=1,wood=1,exp=1,hp=2,mutation="Bloodlit",chance=.01,rare=true,nightOnly=true,reward=4,note="HP ต้นไม้ ×2 • รางวัล ×4"},
	{id="Rainbow",name="รุ้งหลังฝน",duration=120,weight=0,growth=1,wood=1,exp=1,hp=1,mutation="Rainbow",chance=.01,rare=true,note="Mutation Rainbow • สีพิเศษ"},
	-- Fixed UTC encounter every two hours; excluded from random weather rolls.
	{id="RotInvasion",name="ราเน่าบุก",duration=600,weight=0,growth=.75,wood=1,exp=1,hp=1,mutation="Rotten",chance=.1,rare=true,note="บอสโลกโซน 1 • สวนโตช้าลง"},
}
local byId={};for _,v in list do byId[v.id]=v end
return table.freeze({List=list,ById=byId,Seed=40261001,ClearMin=300,ClearMax=480,LightningSeconds=15,LightningReward=3,RainbowChance=.1,WeekendRareMult=2})
