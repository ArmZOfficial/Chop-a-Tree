-- StoryController continues to own RotBarrier collision/visuals; only the new hint prompt is managed here.
local Collection=game:GetService("CollectionService")
local S=game.ReplicatedStorage.Shared
local Data=require(script.Parent.ClientData)
local Locale=require(S.Locale)
local Gate={}
local models,connections={},{}
function Gate.Start()
	local flags=game.ReplicatedStorage:WaitForChild("FeatureFlags")
	local function update()
		local unlocked=Data.Get("Progress.UnlockedZones") or {1}
		for model in models do
			local wall=model:FindFirstChild("RotBarrier");local prompt=wall and wall:FindFirstChild("ZoneUnlockPrompt")
			if prompt then prompt.Enabled=flags:GetAttribute("MapSystems")==true and not table.find(unlocked,model:GetAttribute("ToZone"));prompt.ActionText=Locale.T("Unlock Zone") end
		end
	end
	local function add(model) models[model]=true;update() end
	for _,model in Collection:GetTagged("ZoneGate") do add(model) end
	table.insert(connections,Collection:GetInstanceAddedSignal("ZoneGate"):Connect(add))
	table.insert(connections,Collection:GetInstanceRemovedSignal("ZoneGate"):Connect(function(model) models[model]=nil end))
	table.insert(connections,workspace.DescendantAdded:Connect(function(x) if x.Name=="ZoneUnlockPrompt" then task.defer(update) end end))
	table.insert(connections,Data.Changed:Connect(update));table.insert(connections,Locale.Changed:Connect(update))
	table.insert(connections,flags:GetAttributeChangedSignal("MapSystems"):Connect(update));update()
end
function Gate.Destroy() for _,c in connections do c:Disconnect() end;table.clear(connections);table.clear(models) end
return Gate
