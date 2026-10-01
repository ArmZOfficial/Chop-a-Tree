-- Test-only setup for real input. Set workspace.Phase6GUICommand = "Finish" to restore.
assert(game:GetService("RunService"):IsStudio())
local Collection=game:GetService("CollectionService")
local Services=game.ServerScriptService.Server.Services
local D=require(Services.DataService);local Q=require(Services.QuestService);local R=require(Services.RunService);local Bo=require(Services.BossService)
local p=game.Players:GetPlayers()[1];assert(D.WaitForData(p,30))
local original=D.ExportJSON(p);script:SetAttribute("OriginalData",original)
local pos=p.Character:GetPivot()
local function tagged(tag,attr,value) for _,x in Collection:GetTagged(tag) do if x:IsDescendantOf(workspace) and x:GetAttribute(attr)==value then return x end end end
R.End(p,false);Q.ResetStory(p);D.SetCurrency(p,"Gems",0);Q.Send(p,true)
local function status()
	workspace:SetAttribute("Phase6GUIStep",D.Get(p,"Quests.main.step"));workspace:SetAttribute("Phase6GUIGems",D.GetCurrency(p,"Gems"))
	workspace:SetAttribute("Phase6GUIRun",D.Get(p,"Run.Active"));workspace:SetAttribute("Phase6GUIZone",R.ZoneAt(p) or 0)
end
local connection
connection=workspace:GetAttributeChangedSignal("Phase6GUICommand"):Connect(function()
	local command=workspace:GetAttribute("Phase6GUICommand")
	if command=="Bram" then p.Character:PivotTo(tagged("NPC","NpcId","Bram"):GetPivot()*CFrame.new(0,0,-7))
	elseif command=="Daily" then local d=Q.Side(p,"daily");for id in d.base do d.base[id]=-1e6 end;D.Set(p,"Quests.daily",d);Q.Send(p,true)
	elseif command=="Stone" then p.Character:PivotTo(workspace.Map.Village.Services.WarpStone:GetPivot()*CFrame.new(0,0,7))
	elseif command=="Boss" then p.Character:PivotTo(CFrame.new(Bo.Get(1).center+Vector3.new(-22,4,0),Bo.Get(1).center))
	elseif command=="Finish" then
		connection:Disconnect();R.End(p,false);D.ImportJSON(p,original);p.Character:PivotTo(pos);Q.Send(p,true);R.Send(p)
		workspace:SetAttribute("Phase6GUIRestored",true);return
	end
	status()
end)
task.spawn(function() while connection.Connected do status();task.wait(.5) end end)
status();workspace:SetAttribute("Phase6GUIReady",true)
