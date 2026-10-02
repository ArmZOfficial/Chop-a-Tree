local RS = game:GetService("RunService")
local C = require(game.ReplicatedStorage.Shared.Config.DayCycle)
local Features = require(script.Parent.FeatureService)
local Day = {}
local folder, connection, phase, forced
function Day.Set(id)
	if id == nil then forced = nil; return true end
	for i, value in C.Phases do if value.id == id then forced = i; return true end end
	return false
end
function Day.Update()
	local now = workspace:GetServerTimeNow()
	local index = forced or (math.floor(now % C.Seconds / (C.Seconds / #C.Phases)) + 1)
	if not Features.IsEnabled("MapSystems") then index = nil end
	if phase ~= index then phase = index; folder:SetAttribute("phase", index and C.Phases[index].id or nil) end
end
function Day.Init() folder = Instance.new("Folder"); folder.Name = "DayCycleState"; folder.Parent = game.ReplicatedStorage end
function Day.Start()
	Day.Update(); local elapsed = 0
	connection = RS.Heartbeat:Connect(function(dt) elapsed += dt; if elapsed >= 1 then elapsed = 0; Day.Update() end end)
end
function Day.Destroy() if connection then connection:Disconnect(); connection = nil end; if folder then folder:Destroy(); folder = nil end end
return Day
