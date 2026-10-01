local list={
	{id="Clear",name="ฟ้าใส",duration=0,weight=0,growth=1,wood=1,exp=1,hp=1},
	{id="Rain",name="ฝนตก",duration=300,weight=50,growth=1.5,wood=1.25,exp=1,hp=1,mutation="Wet",chance=.25},
	{id="Storm",name="พายุฟ้าผ่า",duration=240,weight=20,growth=1,wood=1,exp=1,hp=1,mutation="Shocked",chance=.03},
	{id="Snow",name="หิมะตก",duration=300,weight=25,growth=1,wood=1,exp=1.5,hp=1.25,mutation="Chilled",chance=.2},
	{id="Golden",name="แสงทอง",duration=240,weight=5,growth=1,wood=1,exp=1,hp=1,mutation="Golden",chance=.01,rare=true,chestLevel=5},
}
local byId={};for _,v in list do byId[v.id]=v end
return table.freeze({List=list,ById=byId,Seed=40261001,ClearMin=300,ClearMax=480,LightningSeconds=15,LightningReward=3})
