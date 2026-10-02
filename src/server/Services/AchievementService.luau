local Players=game:GetService("Players")
local S=game.ReplicatedStorage.Shared;local Net=require(S.Net);local Config=require(S.Config.Progression);local Math=require(S.CollectionMath)
local Data=require(script.Parent.DataService);local Features=require(script.Parent.FeatureService)
local Achievement={};local last={}
function Achievement.State(p)
	local d=Data.GetData(p);local rows={}
	for _,def in Config.Achievements do table.insert(rows,{id=def.id,name=def.name,title=def.title,gems=def.gems,have=Math.AchievementProgress(d,def),need=def.need,claimed=d.Achievements.claimed[def.id]==true}) end
	return {rows=rows,equipped=d.Achievements.equipped,enabled=Features.IsEnabled("Achievements")}
end
function Achievement.RefreshTitle(p)
	if not Data.IsLoaded(p) then return end
	local a=Data.Get(p,"Achievements");local def=Config.ById[a.equipped]
	local title=Features.IsEnabled("Achievements") and def and a.claimed[def.id]==true and def.title or ""
	if (Data.Get(p,"Purchases.passes") or {}).VIP then title=title=="" and "VIP" or "VIP • "..title end
	p:SetAttribute("AchievementTitle",title)
	local head=p.Character and p.Character:FindFirstChild("Head");if not head then return end
	local gui=head:FindFirstChild("AchievementTitle")
	if title=="" then if gui then gui:Destroy() end;return end
	if not gui then
		gui=Instance.new("BillboardGui");gui.Name="AchievementTitle";gui.Size=UDim2.fromOffset(260,30);gui.StudsOffsetWorldSpace=Vector3.new(0,2.5,0);gui.MaxDistance=80;gui.Parent=head
		local label=Instance.new("TextLabel");label.Size=UDim2.fromScale(1,1);label.BackgroundTransparency=1;label.TextSize=16;label.Font=Enum.Font.GothamBold;label.TextColor3=Color3.fromRGB(255,226,139);label.TextStrokeTransparency=.3;label.Parent=gui
	end
	gui.TextLabel.Text=title
end
function Achievement.Claim(p,id)
	if not Data.IsLoaded(p) or not Features.IsEnabled("Achievements") then return false,"Achievements Unavailable" end
	local def=type(id)=="string" and Config.ById[id];if not def then return false,"Achievement not found" end
	local d=Data.GetData(p);local a=d.Achievements
	if a.claimed[id] then return false,"Reward already claimed" end
	if Math.AchievementProgress(d,def)<def.need then return false,"Incomplete" end
	local nextState={claimed=table.clone(a.claimed),equipped=a.equipped};nextState.claimed[id]=true
	if nextState.equipped=="" then nextState.equipped=id end
	-- Marker, Gems and selected title belong to the same session profile; no yields.
	Data.Set(p,"Achievements",nextState);Data.AddCurrency(p,"Gems",def.gems);Achievement.RefreshTitle(p)
	return true,"Success: "..def.name.." +"..def.gems.." Gems • Unlock Title "..def.title
end
function Achievement.Equip(p,id)
	if not Data.IsLoaded(p) or not Features.IsEnabled("Achievements") then return false,"Achievements Unavailable" end
	if type(id)~="string" or (id~="" and (not Config.ById[id] or not Data.Get(p,"Achievements.claimed")[id])) then return false,"Title not unlocked" end
	Data.Set(p,"Achievements.equipped",id);Achievement.RefreshTitle(p);return true,id=="" and "Title removed" or "Title selected"
end
function Achievement.SetAll(p,all)
	local claimed={};if all then for _,def in Config.Achievements do claimed[def.id]=true end end
	Data.Set(p,"Achievements",{claimed=claimed,equipped=""});Achievement.RefreshTitle(p)
end
function Achievement.Init()
	Net.Function("AchievementAction").OnServerInvoke=function(p,action,id)
		if not Data.IsLoaded(p) then return false,"Data not ready" end
		local now=os.clock();if now-(last[p] or -math.huge)<.35 then return false,"Please wait" end;last[p]=now
		local ok,msg;if action=="Sync" then ok,msg=true,"Ready" elseif action=="Claim" then ok,msg=Achievement.Claim(p,id) elseif action=="Equip" then ok,msg=Achievement.Equip(p,id) else return false,"Invalid command" end
		return ok,msg,Achievement.State(p)
	end
	Data.PlayerLoaded:Connect(function(p)
		p.CharacterAdded:Connect(function(c) c:WaitForChild("Head",10);Achievement.RefreshTitle(p) end);Achievement.RefreshTitle(p)
	end)
	Data.Changed:Connect(function(p,path) if path=="" or path:match("^Achievements") then Achievement.RefreshTitle(p) end end)
	game.ReplicatedStorage.FeatureFlags:GetAttributeChangedSignal("Achievements"):Connect(function() for _,p in Players:GetPlayers() do Achievement.RefreshTitle(p) end end)
	Players.PlayerRemoving:Connect(function(p) last[p]=nil end)
end
function Achievement.Start() end
return Achievement
