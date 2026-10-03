-- Studio-only visual fixture. Never deploy; set Finish=true and wait for Restored before Stop.
assert(game:GetService("RunService"):IsStudio())
local V=game.ServerScriptService.Server.Services
assert(V.DataService:GetAttribute("MapUseMockProfiles")==true,"UI QA requires mock profiles")
local D=require(V.DataService);local F=require(V.FeatureService);local R=require(V.RunService)
local Q=require(V.QuestService);local P=require(V.PetService);local G=require(V.GardenService)
local p=game.Players:GetPlayers()[1] or game.Players.PlayerAdded:Wait()
assert(D.WaitForData(p,30))
local original=D.ExportJSON(p);script:SetAttribute("OriginalData",original)
local root=p.Character:WaitForChild("HumanoidRootPart");local anchored=root.Anchored
local flags=game.ReplicatedStorage.FeatureFlags:GetAttributes()
F.Set("AutoSave",false);F.Set("Leaderboard",false);R.End(p,false);P.Dismount(p);root.Anchored=true
D.Set(p,"Meta.AdminTouched",true)
D.Set(p,"Progress.Rebirth",0);Q.ResetStory(p);D.Set(p,"Progress.Bosses",{["4"]=1})
D.Set(p,"Rebirth.skills",{});D.SetCurrency(p,"RebirthTokens",100);D.SetCurrency(p,"Coins",1e9)
local season=require(game.ReplicatedStorage.Shared.Config.Season).Seasons[1]
D.Set(p,"Season",{id=season.id,xp=4000,premium=false,free={},prem={},pendingFor=""})
local daily=Q.Side(p,"daily")
for _,id in daily.ids do daily.base[id]=-100000 end
D.Set(p,"Quests.daily",daily);Q.Send(p,true)
-- Synthetic boards exercise the client without any OrderedDataStore access.
local Leader=require(V.LeaderboardService)
local boardState,boardWrite,boardRefresh=Leader.State,Leader.Write,Leader.Refresh
Leader.Write=function() return true end
Leader.Refresh=function() return false end
Leader.State=function()
	local localBoards,globalBoards={},{}
	for _,metric in require(game.ReplicatedStorage.Shared.Config.Leaderboards).Metrics do
		localBoards[metric.id]={{name="UI QA Player",value=12345},{name="Second Player",value=2345},{name="Third Player",value=345}}
		globalBoards[metric.id]={{name="Global QA Player",value=98765}}
	end
	return {localBoards=localBoards,globalBoards=globalBoards,enabled=true,status="ready",studio=true}
end
F.Set("Leaderboard",true)
local function language() D.Set(p,"Settings.Language",script:GetAttribute("Language") or "en") end
language();script:GetAttributeChangedSignal("Language"):Connect(language)
script:GetAttributeChangedSignal("Premium"):Connect(function() D.Set(p,"Season.premium",script:GetAttribute("Premium")==true) end)
script:SetAttribute("Ready",true)
while not script:GetAttribute("Finish") do task.wait(.1) end
F.Set("Leaderboard",false)
R.End(p,false);P.Dismount(p);D.ImportJSON(p,original);task.wait(.3)
D.Set(p,"Pets",game:GetService("HttpService"):JSONDecode(original).Pets)
for id,value in flags do F.Set(id,value) end
root.Anchored=anchored;P.Refresh(p);G.Send(p);Q.Send(p,true);R.Send(p)
Leader.State=boardState;Leader.Write=boardWrite;Leader.Refresh=boardRefresh
script:SetAttribute("Restored",true)
