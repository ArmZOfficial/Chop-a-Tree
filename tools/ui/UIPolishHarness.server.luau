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
local Catalog=require(game.ReplicatedStorage.Shared.Config.WeaponCatalog)
local loot=require(game.ReplicatedStorage.Shared.Loot)
local inventory,index={},{}
for i=1,24 do local def=Catalog.List[i];inventory['qa_weapon_'..i]={id=def.id,il=1,stars=1,giant=false,rebirthDrop=0,roll=1,admin_spawned=true};if i<=3 then index[def.id]=true end end
D.Set(p,"Inventory.Weapons",inventory);D.Set(p,"Inventory.Equipped","qa_weapon_1");D.Set(p,"Index.weapons",index)
local chests={};for i,rarity in require(game.ReplicatedStorage.Shared.Config.Rarities).Order do table.insert(chests,{uid='qa_chest_'..i,rarity=rarity,level=i*2-1,zone=1,count=3,rebirthDrop=0,admin_spawned=true}) end
D.Set(p,"Inventory.Chests",chests)
for i,seed in require(game.ReplicatedStorage.Shared.Config.Seeds).List do G.GrantSeed(p,seed.id,1,0,3,true) end
for i,pet in require(game.ReplicatedStorage.Shared.Config.Pets).List do if i<=8 then P.GrantPet(p,pet.id,{admin=true}) end end
for i,egg in require(game.ReplicatedStorage.Shared.Config.Eggs).List do if i<=8 then P.GrantEgg(p,{id=egg.id,admin_spawned=true}) end end
G.Send(p);Q.Send(p,true)
script:SetAttribute("Ready",true)
while not script:GetAttribute("Finish") do task.wait(.1) end
F.Set("Leaderboard",false)
R.End(p,false);P.Dismount(p);D.ImportJSON(p,original);task.wait(.3)
D.Set(p,"Pets",game:GetService("HttpService"):JSONDecode(original).Pets)
for id,value in flags do F.Set(id,value) end
root.Anchored=anchored;P.Refresh(p);G.Send(p);Q.Send(p,true);R.Send(p)
Leader.State=boardState;Leader.Write=boardWrite;Leader.Refresh=boardRefresh
script:SetAttribute("Restored",true)

