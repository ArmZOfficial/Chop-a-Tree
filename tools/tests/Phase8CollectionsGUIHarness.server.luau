-- Set Finish=true and wait for Restored before stopping Play.
assert(game:GetService("RunService"):IsStudio())
local V=game.ServerScriptService.Server.Services;local S=game.ReplicatedStorage.Shared
local D=require(V.DataService);local R=require(V.RunService);local P=require(V.PetService)
local A=require(V.AchievementService);local Q=require(V.QuestService);local F=require(V.FeatureService)
local p=game.Players:GetPlayers()[1];assert(D.WaitForData(p,30))
local original=D.ExportJSON(p);script:SetAttribute("OriginalData",original)
local pivot=p.Character:GetPivot();local root=p.Character.HumanoidRootPart;local anchor=root.Anchored
local flags={};for _,id in {"Achievements","IndexBonuses","Rebirth","Story","Leaderboard"} do flags[id]=F.IsEnabled(id) end
R.End(p,false);P.Dismount(p);root.Anchored=true;F.Set("Leaderboard",false)
for _,id in {"Achievements","IndexBonuses","Rebirth","Story"} do F.Set(id,true) end
D.Set(p,"Achievements",{claimed={},equipped=""});D.Set(p,"Stats.TreesCut",100);D.SetCurrency(p,"Gems",0)
D.Set(p,"Progress.StoryChapter",9) -- isolate achievement Gems from automatic main-quest rewards
local idx={weapons={},pets={},seeds={},mutations={},done={seeds=true}}
for id in require(S.CollectionMath).Catalog.seeds do idx.seeds[id]=true end
D.Set(p,"Index",idx);D.Set(p,"Rebirth.skills",{});D.SetCurrency(p,"RebirthTokens",6)
p.Character:PivotTo(workspace.Map.Village.VillageSpawn.CFrame+Vector3.new(0,4,0));Q.Send(p,true)
script:SetAttribute("Ready",true)
while not script:GetAttribute("Finish") do
 script:SetAttribute("Gems",D.GetCurrency(p,"Gems"));script:SetAttribute("Claimed",D.Get(p,"Achievements.claimed.trees100")==true)
 script:SetAttribute("Equipped",D.Get(p,"Achievements.equipped"));script:SetAttribute("Title",p:GetAttribute("AchievementTitle"))
 script:SetAttribute("LuckRank",D.Get(p,"Rebirth.skills.Luck") or 0);task.wait(.1)
end
R.End(p,false);D.ImportJSON(p,original);for id,value in flags do F.Set(id,value) end
root.Anchored=anchor;p.Character:PivotTo(pivot);P.Refresh(p);require(V.GardenService).Send(p);Q.Send(p,true);R.Send(p);A.RefreshTitle(p)
script:SetAttribute("Restored",true)
