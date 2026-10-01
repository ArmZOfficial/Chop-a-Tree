-- Finish=true restores the profile before Stop Play.
assert(game:GetService("RunService"):IsStudio())
local Services=game.ServerScriptService.Server.Services;local D=require(Services.DataService)
local Daily=require(Services.DailyService);local F=require(Services.FeatureService);local R=require(Services.RunService)
local P=require(Services.PetService);local L=require(Services.LeaderboardService)
local p=game.Players:GetPlayers()[1];assert(D.WaitForData(p,30));local original=D.ExportJSON(p);script:SetAttribute("OriginalData",original)
local root=p.Character.HumanoidRootPart;local anchored=root.Anchored;local pivot=p.Character:GetPivot();script:SetAttribute("OriginalPivot",pivot);script:SetAttribute("OriginalAnchor",anchored)
R.End(p,false);P.Dismount(p);root.Anchored=true;Daily.Reset(p);D.Set(p,"Codes.redeemed",{});D.SetCurrency(p,"Gems",0);D.Set(p,"Inventory.Chests",{});D.Set(p,"Boosts",{Wood=0,Coins=0})
script:SetAttribute("Ready",true)
while not script:GetAttribute("Finish") do task.wait(.1) end
D.ImportJSON(p,original);root.Anchored=anchored;p.Character:PivotTo(pivot);P.Refresh(p);require(Services.GardenService).Send(p);require(Services.QuestService).Send(p,true);R.Send(p);L.Snapshot(p);L.Render();script:SetAttribute("Restored",true)
