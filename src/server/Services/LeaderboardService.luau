local Players=game:GetService("Players");local DSS=game:GetService("DataStoreService")
local Collection=game:GetService("CollectionService");local RunService=game:GetService("RunService")
local S=game.ReplicatedStorage.Shared;local Net=require(S.Net);local Config=require(S.Config.Leaderboards)
local Math=require(S.LeaderboardMath);local NF=require(S.NumberFormat)
local Data=require(script.Parent.DataService);local Features=require(script.Parent.FeatureService);local Pet=require(script.Parent.PetService)
local Leader={};local entries,stores,global,last={},{},{},{}
local status="loading";local updatedAt=0;local refreshing=false;local boards={};local blocked={}
local prefix=RunService:IsStudio() and "ChopBoards_Studio_v1_" or "ChopBoards_v1_"
function Leader.Snapshot(p)
	if not Data.IsLoaded(p) then return end
	local entry={userId=p.UserId,name=p.DisplayName,blocked=Data.Get(p,"Meta.AdminTouched")==true or blocked[p.UserId]==true,
		values={TreesCut=Data.Get(p,"Stats.TreesCut"),HighestHit=Data.Get(p,"Stats.HighestHit"),Rebirth=Data.Get(p,"Progress.Rebirth"),Income=Pet.Income(p)}}
	entries[p.UserId]=entry;if entry.blocked then blocked[p.UserId]=true end;return entry
end
-- Zero is a season tombstone. UpdateAsync prevents a stale eligible write reviving it.
function Leader.Write(entry,targetStores)
	local okAll=true
	for _,metric in Config.Metrics do local store=(targetStores or stores)[metric.id]
		local ok=pcall(function() store:UpdateAsync(tostring(entry.userId),function(old)
			if old==0 or entry.blocked or (not targetStores and blocked[entry.userId]) then return 0 end
			return Math.Encode(entry.values[metric.id] or 0)
		end) end);okAll=okAll and ok
	end
	return okAll
end
function Leader.State()
	local localBoards,globalBoards={},{}
	for _,metric in Config.Metrics do
		localBoards[metric.id]=Math.Sort(entries,metric.id,Config.Top);globalBoards[metric.id]={}
		for _,row in global[metric.id] or {} do if not blocked[row.userId] then table.insert(globalBoards[metric.id],row) end end
	end
	return {localBoards=localBoards,globalBoards=globalBoards,status=status,updatedAt=updatedAt,season=Config.Season,studio=RunService:IsStudio(),enabled=Features.IsEnabled("Leaderboard")}
end
function Leader.Render()
	local state=Leader.State()
	for _,board in boards do local id=board.part:GetAttribute("Board");local rows=(status=="ready" and state.globalBoards or state.localBoards)[id] or {}
		board.label.Parent.Enabled=state.enabled;board.part.LeaderboardPrompt.Enabled=state.enabled
		local text=board.title.."\n"..(status=="ready" and "GLOBAL ≈" or "SERVER • Global Update pending").."\n"
		for i,row in rows do text..="\n"..i..". "..row.name.."  "..NF.Short(row.value) end
		if #rows==0 then text..="\nNo eligible players yet" end
		board.label.Text=text
	end
end
function Leader.Refresh()
	if refreshing or not Features.IsEnabled("Leaderboard") then return false end;refreshing=true
	local successful=true
	for _,p in Players:GetPlayers() do Leader.Snapshot(p) end
	for _,entry in entries do if not Leader.Write(entry) then successful=false end end
	local nextGlobal={}
	for _,metric in Config.Metrics do
		local ok,page=pcall(function() return stores[metric.id]:GetSortedAsync(false,Config.Top,1):GetCurrentPage() end)
		if not ok then successful=false else
			local rows={};for _,item in page do local id=tonumber(item.key)
				if id and not blocked[id] then
					local name=entries[id] and entries[id].name or "User "..id
					-- Names from loaded players; offline IDs avoid a per-row yielding API request.
					table.insert(rows,{userId=id,name=name,value=Math.Decode(item.value)})
				end
			end;nextGlobal[metric.id]=rows
		end
	end
	if successful then global=nextGlobal;updatedAt=os.time();status="ready" else status="unavailable" end
	refreshing=false;Leader.Render();return successful
end
function Leader.Init()
	for _,metric in Config.Metrics do stores[metric.id]=DSS:GetOrderedDataStore(prefix..Config.Season.."_"..metric.id) end
	Net.Function("LeaderboardRequest").OnServerInvoke=function(p)
		if not Data.IsLoaded(p) then return false,"Data not ready" end
		local now=os.clock();if now-(last[p] or -math.huge)<1 then return false,"Please wait" end;last[p]=now
		if not Features.IsEnabled("Leaderboard") then return false,"Leaderboard Unavailable" end
		Leader.Snapshot(p);return true,"Ready",Leader.State()
	end
	Data.Changed:Connect(function(p) Leader.Snapshot(p) end)
	Data.PlayerLoaded:Connect(Leader.Snapshot)
	game.ReplicatedStorage.FeatureFlags:GetAttributeChangedSignal("Leaderboard"):Connect(Leader.Render)
	Players.PlayerRemoving:Connect(function(p)
		local entry=entries[p.UserId];entries[p.UserId]=nil;last[p]=nil
		if entry and Features.IsEnabled("Leaderboard") then task.spawn(Leader.Write,entry) end
	end)
	for _,part in Collection:GetTagged("Leaderboard") do if part:IsA("BasePart") and part:IsDescendantOf(workspace) then
		local id=part:GetAttribute("Board");local title
		for _,metric in Config.Metrics do if metric.id==id then title=metric.name end end
		if title then
			for _,gui in part:GetChildren() do if gui:IsA("SurfaceGui") then gui:Destroy() end end
			local gui=Instance.new("SurfaceGui");gui.Name="LeaderboardDisplay";gui.Face=Enum.NormalId.Front;gui.CanvasSize=Vector2.new(600,720);gui.Parent=part
			local label=Instance.new("TextLabel");label.Size=UDim2.fromScale(1,1);label.BackgroundTransparency=1;label.TextColor3=Color3.fromRGB(255,231,158);label.TextSize=30;label.TextWrapped=true;label.Font=Enum.Font.GothamBold;label.Parent=gui
			table.insert(boards,{part=part,label=label,title=title})
			local prompt=Instance.new("ProximityPrompt");prompt.Name="LeaderboardPrompt";prompt.ActionText="View All Leaderboards";prompt.ObjectText=title;prompt.MaxActivationDistance=16;prompt.RequiresLineOfSight=false;prompt.Parent=part
			prompt.Triggered:Connect(function(p) if Features.IsEnabled("Leaderboard") then Net.Event("LeaderboardShow"):FireClient(p) end end)
		end
	end end
	game:BindToClose(function() if Features.IsEnabled("Leaderboard") then
		local pending=0;for _,entry in entries do pending+=1;task.spawn(function() Leader.Write(entry);pending-=1 end) end
		local deadline=os.clock()+25;while pending>0 and os.clock()<deadline do task.wait(.1) end
	end end)
end
function Leader.Start()
	task.spawn(function() while true do
		if Features.IsEnabled("Leaderboard") then for _,p in Players:GetPlayers() do Leader.Snapshot(p) end;Leader.Render() end
		task.wait(5)
	end end)
	task.spawn(function() task.wait(15);while true do Leader.Refresh();task.wait(Config.RefreshSeconds) end end)
end
return Leader
