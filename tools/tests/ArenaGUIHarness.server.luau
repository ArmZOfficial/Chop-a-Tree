-- Studio only. No queue transport or profile writes. Invoke Finish before Stop.
assert(game.RunService:IsStudio())
local V=game.ServerScriptService.Server.Services;local Net=require(game.ReplicatedStorage.Shared.Net)
local F=require(V.FeatureService);local D=require(V.DataService);local A=require(V.ArenaService)
local p=game.Players:GetPlayers()[1];assert(D.WaitForData(p,30))
local flags={PvP=F.IsEnabled("PvP"),AutoSave=F.IsEnabled("AutoSave"),Leaderboard=F.IsEnabled("Leaderboard")}
local pivot=p.Character:GetPivot();local root=p.Character.HumanoidRootPart;local anchor=root.Anchored
local portals=game.CollectionService:GetTagged("ArenaPortal");assert(#portals>0)
F.Set("AutoSave",false);F.Set("Leaderboard",false);F.Set("PvP",true)
root.Anchored=true;p.Character:PivotTo(portals[1]:GetPivot()+Vector3.new(0,-5,0))
assert(not A.Join(p,"Duel",true),"Unconfigured Arena must reject join")
Net.Event("ArenaShow"):FireClient(p)
local finish=Instance.new("BindableFunction");finish.Name="Finish";finish.Parent=script
finish.OnInvoke=function()
	A.Leave(p);for k,v in flags do F.Set(k,v) end
	root.Anchored=anchor;p.Character:PivotTo(pivot);script:SetAttribute("Restored",true);return true
end
script:SetAttribute("Ready",true)
