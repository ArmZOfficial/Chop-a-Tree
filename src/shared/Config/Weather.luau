local list={
	{id="Clear",name="Clear",duration=0,weight=0,growth=1,wood=1,exp=1,hp=1},
	{id="Rain",name="Rain",duration=300,weight=50,growth=1.5,wood=1.25,exp=1,hp=1,mutation="Wet",chance=.25},
	{id="Storm",name="Thunderstorm",duration=240,weight=20,growth=1,wood=1,exp=1,hp=1,mutation="Shocked",chance=.03},
	{id="Snow",name="Snow",duration=300,weight=25,growth=1,wood=1,exp=1.5,hp=1.25,mutation="Chilled",chance=.2},
	{id="Golden",name="Golden",duration=240,weight=5,growth=1,wood=1,exp=1,hp=1,mutation="Golden",chance=.01,rare=true,chestLevel=5},
	{id="Fog",name="Dense Fog",duration=360,weight=15,growth=1,wood=1,exp=1,hp=1,mutation="Misty",chance=.12,note="Mutation Misty • Dense Fog"},
	{id="Wind",name="Gusts",duration=180,weight=35,growth=1,wood=1,exp=1,hp=1,mutation="Windswept",chance=.2,area=1.5,note="Weapon Area ×1.5"},
	{id="Sakura",name="Blossom Rain",duration=300,weight=4,growth=1,wood=1,exp=1,hp=1,mutation="Blossom",chance=.025,rare=true,crit=15,note="Critical ×15 • Blossom"},
	{id="Meteor",name="Meteor Shower",duration=240,weight=1,growth=1,wood=1,exp=1,hp=1,mutation="Celestial",chance=.005,rare=true,note="Mutation Celestial • Meteor Shower"},
	{id="Aurora",name="Aurora",duration=360,weight=3,growth=1,wood=1.5,coins=1.5,exp=1,hp=1,mutation="Aurora",chance=.015,rare=true,nightOnly=true,note="Wood/Coins ×1.5 • Aurora"},
	{id="Bloodmoon",name="Blood Moon",duration=480,weight=1,growth=1,wood=1,exp=1,hp=2,mutation="Bloodlit",chance=.01,rare=true,nightOnly=true,reward=4,note="HP Trees ×2 • Rewards ×4"},
	{id="Rainbow",name="Rainbow",duration=120,weight=0,growth=1,wood=1,exp=1,hp=1,mutation="Rainbow",chance=.01,rare=true,note="Mutation Rainbow • Special colors"},
	-- Fixed UTC encounter every two hours; excluded from random weather rolls.
	{id="RotInvasion",name="Rot Invasion",duration=600,weight=0,growth=.75,wood=1,exp=1,hp=1,mutation="Rotten",chance=.1,rare=true,note="Zone 1 World Boss • Slower garden growth"},
}
local byId={};for _,v in list do byId[v.id]=v end
return table.freeze({List=list,ById=byId,Seed=40261001,ClearMin=300,ClearMax=480,LightningSeconds=15,LightningReward=3,RainbowChance=.1,WeekendRareMult=2})
