-- Temporary Play Script. Set Finish=true and wait for Restored before stopping Play.
assert(game:GetService("RunService"):IsStudio())
local Services=game.ServerScriptService.Server.Services
local D=require(Services.DataService);local R=require(Services.RunService);local Q=require(Services.QuestService)
local P=require(Services.PetService);local G=require(Services.GardenService);local F=require(Services.FeatureService)
local p=game.Players:GetPlayers()[1];assert(D.WaitForData(p,30))
local original=D.ExportJSON(p);script:SetAttribute("OriginalData",original)
local pivot=p.Character:GetPivot();local root=p.Character.HumanoidRootPart;local anchored=root.Anchored;local flag=F.IsEnabled("Rebirth")
R.End(p,false);P.Dismount(p);root.Anchored=true;F.Set("Rebirth",true)
D.Set(p,"Progress.Rebirth",0);Q.ResetStory(p);D.Set(p,"Progress.Bosses",{["4"]=1})
D.Set(p,"Rebirth.skills",{});D.SetCurrency(p,"RebirthTokens",100);D.SetCurrency(p,"Coins",1e9);D.SetCurrency(p,"Wood",123)
p.Character:PivotTo(workspace.Map.Village.VillageSpawn.CFrame+Vector3.new(0,4,0))
script:SetAttribute("Ready",true)
while not script:GetAttribute("Finish") do task.wait(.1) end
R.End(p,false);D.ImportJSON(p,original);F.Set("Rebirth",flag);root.Anchored=anchored;p.Character:PivotTo(pivot)
P.Refresh(p);G.Send(p);Q.Send(p,true);R.Send(p);script:SetAttribute("Restored",true)
