-- Execute in Play SERVER, then execute PlayRoutes.luau in Play CLIENT.
assert(game:GetService("RunService"):IsRunning(), "Play mode only")
local B = loadstring(game.ServerStorage.MapTools.MapBuilder.Source)() -- MCP threads cannot require game modules
local L = B.Layout()
local routes = {}
local function add(name, points, speed)
	local arr = {}
	for i = 1, #points-1 do
		local a,b = points[i],points[i+1]
		local n = math.max(1,math.ceil((b-a).Magnitude/24))
		for k = 0,n-1 do
			local p = a:Lerp(b,k/n)
			table.insert(arr,{p.X,p.Y,p.Z})
		end
	end
	local p = points[#points]
	table.insert(arr,{p.X,p.Y,p.Z})
	table.insert(routes,{name=name,points=arr,speed=speed})
end
for _, r in L.roads do add("Road_"..r.from.."_"..r.to,r.points,r.sky and 80 or 16) end
for i,z in L.zones do
	local inward = Vector3.new(z.center.X-z.entry.X,0,z.center.Z-z.entry.Z).Unit
	add("Zone"..i, {z.trailStart or z.entry,z.trailEnd or z.exit or (z.center+Vector3.new(inward.Z,0,-inward.X)*80)},40)
end
for _, gate in game:GetService("CollectionService"):GetTagged("ZoneGate") do
	if gate:IsDescendantOf(workspace.Map) then
		gate.PrimaryPart.CanCollide = false
		gate:SetAttribute("Open",true)
	end
end
local old = game.ReplicatedStorage:FindFirstChild("MapRouteTest")
if old then old:Destroy() end
local payload = Instance.new("StringValue")
payload.Name = "MapRouteTest"
payload.Value = game:GetService("HttpService"):JSONEncode(routes)
payload.Parent = game.ReplicatedStorage
return #routes
