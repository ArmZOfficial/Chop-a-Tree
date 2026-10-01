-- Festival windows (plan 4.12.4/4.12.6). UTC dates set ahead of time; add new rows per season.
-- During a festival the UTC schedule's Clear/common weather becomes `weather`
-- (night-only rows apply 18:00–06:00 UTC). Rare weather and RotInvasion stay untouched.
-- `mutation`/`chance` replace that weather's garden mutation while the festival runs.
local function utc(y,m,d) return DateTime.fromUniversalTime(y,m,d).UnixTimestamp end
local list={
	{id="halloween",name="ฮาโลวีน",startsAt=utc(2026,10,25),endsAt=utc(2026,11,2),weather="Bloodmoon",nightOnly=true},
	-- Loy Krathong follows the lunar calendar; check the date each year.
	{id="loykrathong",name="ลอยกระทง",startsAt=utc(2026,11,23),endsAt=utc(2026,11,26),weather="Aurora",nightOnly=true},
	{id="winter",name="คริสต์มาส/ปีใหม่",startsAt=utc(2026,12,20),endsAt=utc(2027,1,3),weather="Snow"},
	{id="songkran",name="สงกรานต์",startsAt=utc(2027,4,12),endsAt=utc(2027,4,17),weather="Rain",mutation="Splash",chance=.25},
}
local byId={};for _,v in list do byId[v.id]=v end
return table.freeze({List=list,ById=byId,PreviewSeconds=600})
