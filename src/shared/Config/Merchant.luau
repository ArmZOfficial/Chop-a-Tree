-- Squirrel merchant (plan 4.12.4): visits every UTC hour for 10 minutes.
-- Window starts at minute 30 so it never overlaps a RotInvasion block (minutes 0–10).
-- Offer ids are stable; add rows, never reuse an id.
-- kind: seed (Coins × seed price at shop zone), egg (Coins × egg price), chest (Gems).
local offers={
	{id="m_seed_sakuragem",kind="seed",item="seed_sakuragem",mult=1.5,limit=2,weight=30},
	{id="m_seed_crystalpine",kind="seed",item="seed_crystalpine",mult=1.5,limit=2,weight=25},
	{id="m_seed_thunderroot",kind="seed",item="seed_thunderroot",mult=1.5,limit=1,weight=15},
	{id="m_seed_lumora",kind="seed",item="seed_lumora",mult=2,limit=1,weight=6},
	{id="m_egg_sunburst",kind="egg",item="egg_sunburst",mult=1.2,limit=2,weight=25},
	{id="m_egg_starlit",kind="egg",item="egg_starlit",mult=1.2,limit=1,weight=12},
	{id="m_egg_mist",kind="egg",item="egg_mist",mult=1.5,limit=1,weight=6},
	{id="m_chest_epic",kind="chest",item="Epic",gems=40,level=10,limit=1,weight=20},
	{id="m_chest_legendary",kind="chest",item="Legendary",gems=120,level=10,limit=1,weight=6},
}
local byId={};for _,v in offers do byId[v.id]=v end
return table.freeze({Offers=offers,ById=byId,Seed=40261003,Period=3600,Offset=1800,Duration=600,Slots=4,
	Range=16,Position=Vector3.new(-712,0,284),SummonSeconds=600,KeepSeconds=2*86400})
