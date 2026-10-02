-- Chapters 3–8 keepers. Add to the main place ServerScriptService in Edit, press Play, read workspace StoryKeepersResults, then delete it.
-- Always restores the real profile.
assert(game:GetService("RunService"):IsStudio())
local Collection=game:GetService("CollectionService")
local V=game.ServerScriptService.Server.Services
local D=require(V.DataService);local F=require(V.FeatureService);local St=require(V.StoryService);local R=require(V.RunService)
local Story=require(game.ReplicatedStorage.Shared.Config.Story)
local p=game.Players:GetPlayers()[1] or game.Players.PlayerAdded:Wait();assert(D.WaitForData(p,120));task.wait(2)
local original=D.ExportJSON(p);local pivot=p.Character:GetPivot();local flags={Story=F.IsEnabled("Story"),AutoSave=F.IsEnabled("AutoSave")}
local results={}
local function check(name,ok) assert(ok,name);table.insert(results,name) end
local function tagged(tag,attr,value) local found={} for _,x in Collection:GetTagged(tag) do if x:IsDescendantOf(workspace) and x:GetAttribute(attr)==value then table.insert(found,x) end end;return found end
local function at(model,offset) p.Character:PivotTo(model:GetPivot()*CFrame.new(0,0,offset));task.wait(.15) end
local function setQuest(chapter,step) D.Set(p,"Progress.StoryChapter",chapter);local q=table.clone(D.Get(p,"Quests.main"));q.step=step;q.base=0;D.Set(p,"Quests.main",q) end
local ok,err=xpcall(function()
	R.End(p,false);F.Set("Story",true);F.Set("AutoSave",false);D.Set(p,"Meta.AdminTouched",true);D.SetCurrency(p,"Gems",0);D.Set(p,"Progress.Bosses",{});D.Set(p,"Progress.Shrines",{})
	-- Map systems rescue players out of locked zones within a second; unlock the keepers' zones.
	D.Set(p,"Progress.UnlockedZones",{1,2,3,4,5,6,7,8})
	local valid=true
	for z=3,8 do
		local last=Story.Chapters[z].steps[5];local keeper=last and Story.Npcs[last.npc];local models=last and tagged("NPC","NpcId",last.npc) or {}
		local spawn=tagged("ZoneSpawn","Zone",z)[1]
		if not (last.kind=="talk" and keeper and keeper.zone==z and #keeper.intro>0 and #keeper.chapter[z]>0 and #models==1 and spawn and (models[1]:GetPivot().Position-spawn.Position).Magnitude<=20) then valid=false end
		if Story.Chapters[z].steps[4].kind~="shrine" then valid=false end
	end
	check("Chapters 3–8 append a keeper talk after the shrine; one keeper stands by each zone spawn",valid)
	local hana=tagged("NPC","NpcId","Hana")[1];local lumi=tagged("NPC","NpcId","Lumi")[1]
	setQuest(4,3);at(hana,60) -- boss step: cannot complete by standing in the zone
	check("Talking far from a keeper is rejected",not St.Talk(p,"Hana") and D.Get(p,"Quests.main.step")==3)
	at(hana,-6)
	check("Keeper intro does not advance an unrelated step",St.Talk(p,"Hana") and D.Get(p,"Quests.main.step")==3 and D.Get(p,"Progress.StoryChapter")==4)
	setQuest(5,5)
	check("Another zone's keeper does not complete the talk step",St.Talk(p,"Hana") and D.Get(p,"Quests.main.step")==5 and D.Get(p,"Progress.StoryChapter")==5)
	setQuest(4,5);local g=D.GetCurrency(p,"Gems")
	check("Reporting to the keeper finishes the chapter once",St.Talk(p,"Hana") and D.Get(p,"Progress.StoryChapter")==5 and D.Get(p,"Quests.main.step")==1 and D.GetCurrency(p,"Gems")==g+(Story.StepGems+Story.ChapterGems)*4)
	task.wait(.35);g=D.GetCurrency(p,"Gems")
	check("Talking again pays nothing",St.Talk(p,"Hana") and D.Get(p,"Progress.StoryChapter")==5 and D.GetCurrency(p,"Gems")==g)
	setQuest(8,5);at(lumi,-6);task.wait(.35)
	check("Lumi closes chapter 8 and the main story",St.Talk(p,"Lumi") and D.Get(p,"Progress.StoryChapter")==9)
end,debug.traceback)
for id,v in flags do F.Set(id,v) end
D.ImportJSON(p,original);p.Character:PivotTo(pivot);D.SaveNow(p)
local o=game.HttpService:JSONDecode(original)
local restored=D.Get(p,"Progress.StoryChapter")==o.Progress.StoryChapter and D.Get(p,"Quests.main.step")==o.Quests.main.step and D.GetCurrency(p,"Gems")==o.Currencies.Gems and D.Get(p,"Meta.AdminTouched")==o.Meta.AdminTouched
workspace:SetAttribute("StoryKeepersResults",game.HttpService:JSONEncode({passed=ok and restored,restored=restored,checks=results,error=not ok and err or nil}))
print("[StoryKeepersScenario]",ok and "passed" or err,#results,"restored",restored)
