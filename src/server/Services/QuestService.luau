-- Main story quest, daily/weekly quests and the Index (plan 4.11).
-- Counting steps read Stats deltas, so other systems only increment Stats.
local Players=game:GetService("Players")
local Http=game:GetService("HttpService")
local Shared=game.ReplicatedStorage.Shared
local Net=require(Shared.Net)
local Story=require(Shared.Config.Story)
local Zones=require(Shared.Config.Zones)
local Weapons=require(Shared.Config.Weapons)
local Pets=require(Shared.Config.Pets)
local Seeds=require(Shared.Config.Seeds)
local Mutations=require(Shared.Config.Mutations)
local Data=require(script.Parent.DataService)
local Features=require(script.Parent.FeatureService)
local Run=require(script.Parent.RunService)
local Quest={}
local talked,lastPacket={},{}
local dailyById={};for _,q in Story.Daily do dailyById[q.id]=q end
local totals={weapons=#Weapons.List,pets=#Pets.List,seeds=#Seeds.List,mutations=0}
local mutationIds={};for id in Mutations.Values do mutationIds[id]=true end;for id in Pets.Mutations do mutationIds[id]=true end
for _ in mutationIds do totals.mutations+=1 end
Quest.IndexTotals=totals

local function notify(p,text) Net.Event("Notify"):FireClient(p,{text=text}) end
local function stat(p,name) return Data.Get(p,"Stats."..name) or 0 end
function Quest.Step(p)
	local c=Story.Chapters[Data.Get(p,"Progress.StoryChapter")]
	return c and c.steps[Data.Get(p,"Quests.main.step")],c
end
local function startStep(p)
	local q=Data.Get(p,"Quests.main");local s=Quest.Step(p)
	q.base=s and s.kind=="stat" and stat(p,s.stat) or 0;talked[p]=nil;Data.Set(p,"Quests.main",q)
end
function Quest.Blocked(s) return s.zone~=nil and not Zones.List[s.zone].built end
function Quest.Progress(p,s)
	if s.kind=="stat" then return math.clamp(stat(p,s.stat)-Data.Get(p,"Quests.main.base"),0,s.count),s.count
	elseif s.kind=="talk" then return talked[p]==s.npc and 1 or 0,1
	elseif s.kind=="zone" then return (not Quest.Blocked(s) and Run.ZoneAt(p)==s.zone) and 1 or 0,1
	elseif s.kind=="boss" then return (Data.Get(p,"Progress.Bosses")[tostring(s.zone)] or 0)>0 and 1 or 0,1
	elseif s.kind=="shrine" then return Data.Get(p,"Progress.Shrines")[tostring(s.zone)] and 1 or 0,1 end
	return 0,1
end
function Quest.OnTalk(p,npc) talked[p]=npc;Quest.Check(p) end
-- Advance through every finished step; rewards are paid once per step.
function Quest.Check(p)
	if not Features.IsEnabled("Story") or not Data.IsLoaded(p) then return end
	for _=1,32 do
		local chapter=Data.Get(p,"Progress.StoryChapter");local c=Story.Chapters[chapter]
		if not c then return end
		local q=Data.Get(p,"Quests.main");local s=c.steps[q.step]
		if not s then
			Data.AddCurrency(p,"Gems",Story.ChapterGems*chapter)
			q.step=1;Data.Set(p,"Quests.main",q);Data.Set(p,"Progress.StoryChapter",chapter+1);startStep(p)
			local nextChapter=Story.Chapters[chapter+1]
			Net.Event("StoryShow"):FireClient(p,{kind="banner",title=c.title.." จบแล้ว!",sub=(nextChapter and nextChapter.title or "จบบทหลัก — วัฏจักรใหม่รอใน Rebirth").." • +"..Story.ChapterGems*chapter.." Gems"})
		else
			local have,need=Quest.Progress(p,s)
			if have<need then return end
			Data.AddCurrency(p,"Gems",Story.StepGems*chapter);q.step+=1;Data.Set(p,"Quests.main",q);startStep(p)
			notify(p,"เควสสำเร็จ: "..s.text.." +"..Story.StepGems*chapter.." Gems")
		end
	end
end
function Quest.ForceStep(p)
	local s=Quest.Step(p);if not s then return false end
	local q=Data.Get(p,"Quests.main")
	if s.kind=="stat" then q.base=stat(p,s.stat)-s.count;Data.Set(p,"Quests.main",q)
	elseif s.kind=="talk" then talked[p]=s.npc
	elseif s.kind=="boss" then local b=Data.Get(p,"Progress.Bosses");b[tostring(s.zone)]=math.max(1,b[tostring(s.zone)] or 0);Data.Set(p,"Progress.Bosses",b)
	elseif s.kind=="shrine" then local sh=Data.Get(p,"Progress.Shrines");sh[tostring(s.zone)]=true;Data.Set(p,"Progress.Shrines",sh)
	elseif s.kind=="zone" then q.step+=1;Data.Set(p,"Quests.main",q);startStep(p) end
	Quest.Check(p);return true
end
function Quest.ResetStory(p)
	Data.Set(p,"Progress.StoryChapter",1);Data.Set(p,"Progress.Bosses",{});Data.Set(p,"Progress.Shrines",{});Data.Set(p,"Progress.UnlockedZones",{1})
	Data.Set(p,"Quests.main",{step=1,base=0});talked[p]=nil
end

local function key(kind) local day=os.time()/86400;return kind=="daily" and math.floor(day) or math.floor((day+3)/7) end -- weeks start Monday UTC
-- Every player rolls the same quests for a UTC day/week.
function Quest.Side(p,kind)
	local d=Data.Get(p,"Quests."..kind);local k=key(kind)
	if d.key==k then return d end
	local random=Random.new((k*7919+(kind=="daily" and 11 or 29))%2147483647)
	local pool={};for i=1,#Story.Daily do pool[i]=i end
	local ids,base={},{}
	for i=1,(kind=="daily" and Story.DailyCount or Story.WeeklyCount) do
		local j=random:NextInteger(i,#pool);pool[i],pool[j]=pool[j],pool[i]
		local q=Story.Daily[pool[i]];table.insert(ids,q.id);base[q.id]=stat(p,q.stat)
	end
	d={key=k,ids=ids,base=base,claimed={}};Data.Set(p,"Quests."..kind,d);return d
end
local function sideRows(p,kind)
	local d=Quest.Side(p,kind);local rows={};local scale=kind=="weekly" and Story.WeeklyScale or 1
	for _,id in d.ids do local q=dailyById[id];local need=q.count*scale
		table.insert(rows,{id=id,text=kind=="weekly" and string.gsub(q.text,"%d+",tostring(need)) or q.text,have=math.clamp(stat(p,q.stat)-d.base[id],0,need),need=need,claimed=d.claimed[id]==true,gems=kind=="weekly" and Story.WeeklyGems or Story.DailyGems})
	end
	return rows,(d.key+1)*(kind=="daily" and 86400 or 604800)-(kind=="weekly" and 259200 or 0)
end
function Quest.Claim(p,kind,id)
	if not Features.IsEnabled("Story") then return false,"ระบบเควสยังไม่เปิด" end
	if kind~="daily" and kind~="weekly" then return false,"คำสั่งไม่ถูกต้อง" end
	local d=Quest.Side(p,kind)
	if not table.find(d.ids,id) then return false,"ไม่พบเควสนี้" end
	if d.claimed[id] then return false,"รับรางวัลไปแล้ว" end
	local q=dailyById[id];local need=q.count*(kind=="weekly" and Story.WeeklyScale or 1)
	if stat(p,q.stat)-d.base[id]<need then return false,"ยังทำเควสไม่ครบ" end
	local gems=kind=="weekly" and Story.WeeklyGems or Story.DailyGems
	d.claimed[id]=true;Data.Set(p,"Quests."..kind,d);Data.AddCurrency(p,"Gems",gems)
	return true,"รับรางวัลเควส +"..gems.." Gems"
end

-- Index records owned non-admin items; each new entry pays Gems once.
function Quest.ScanIndex(p)
	local idx=Data.Get(p,"Index");local gained=0
	local function add(cat,id) if id and not idx[cat][id] then idx[cat][id]=true;gained+=1 end end
	local inv=Data.Get(p,"Inventory")
	for _,w in inv.Weapons do if not w.admin_spawned and Weapons.ById[w.id] then add("weapons",w.id) end end
	for _,pet in inv.Pets do if not pet.admin_spawned and Pets.ById[pet.id] then add("pets",pet.id);if pet.mutation then add("mutations",pet.mutation) end end end
	for _,s in inv.Seeds do if not s.admin_spawned and Seeds.ById[s.id] then add("seeds",s.id) end end
	for _,plot in Data.Get(p,"Garden.plots") do if not plot.admin_spawned then add("seeds",plot.id);for m in plot.mutations or {} do if mutationIds[m] then add("mutations",m) end end end end
	for _,f in inv.Fruits do if not f.admin_spawned then for m in f.mutations or {} do if mutationIds[m] then add("mutations",m) end end end end
	if gained==0 then return 0 end
	local gems=gained*Story.IndexGem
	for cat,total in totals do
		local n=0;for _ in idx[cat] do n+=1 end
		if n>=total and not idx.done[cat] then idx.done[cat]=true;gems+=Story.IndexCompleteGems;notify(p,"Index หมวด "..cat.." ครบ! +"..Story.IndexCompleteGems.." Gems") end
	end
	Data.Set(p,"Index",idx);Data.AddCurrency(p,"Gems",gems)
	return gained
end
function Quest.IndexCounts(p)
	local idx=Data.Get(p,"Index");local out={}
	for cat,total in totals do local n=0;for _ in idx[cat] do n+=1 end;out[cat]={have=n,total=total} end
	return out
end

function Quest.Send(p,force)
	if not Data.IsLoaded(p) or not p.Parent then return end
	local s,c=Quest.Step(p);local current
	if s then local have,need=Quest.Progress(p,s);current={text=s.text,kind=s.kind,stat=s.stat,zone=s.zone or c.zone,npc=s.npc,have=have,need=need,blocked=Quest.Blocked(s)} end
	local steps={};if c then for i,step in c.steps do steps[i]={text=step.text,done=i<Data.Get(p,"Quests.main.step")} end end
	local daily,dailyEnds=sideRows(p,"daily");local weekly,weeklyEnds=sideRows(p,"weekly")
	local packet={enabled=Features.IsEnabled("Story"),chapter=Data.Get(p,"Progress.StoryChapter"),title=c and c.title or "จบบทหลักแล้ว",steps=steps,current=current,
		daily=daily,dailyEnds=dailyEnds,weekly=weekly,weeklyEnds=weeklyEnds,index=Quest.IndexCounts(p)}
	local json=Http:JSONEncode(packet)
	if force or lastPacket[p]~=json then lastPacket[p]=json;Net.Event("QuestState"):FireClient(p,packet) end
end

function Quest.Init()
	Data.PlayerLoaded:Connect(function(p) Quest.Side(p,"daily");Quest.Side(p,"weekly");Quest.ScanIndex(p);Quest.Check(p);Quest.Send(p,true) end)
	Data.Changed:Connect(function(p,path) if path=="" then talked[p]=nil;lastPacket[p]=nil end end)
	Players.PlayerRemoving:Connect(function(p) talked[p]=nil;lastPacket[p]=nil end)
end
function Quest.Start()
	task.spawn(function() local tick=0;while true do
		tick+=1
		for _,p in Players:GetPlayers() do if Data.IsLoaded(p) then
			Quest.Check(p);if tick%5==0 then Quest.ScanIndex(p) end;Quest.Send(p)
		end end
		task.wait(1)
	end end)
end
return Quest
