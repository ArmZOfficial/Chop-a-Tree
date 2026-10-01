-- Edit-time validation. Closed progression gates are intentionally excluded.
local B = require(game.ServerStorage.MapTools.MapBuilder:Clone())
local L = B.Layout()
local params = RaycastParams.new()
params.FilterType = Enum.RaycastFilterType.Exclude
params.RespectCanCollide = true
local excluded = {}
for _, gate in game:GetService("CollectionService"):GetTagged("ZoneGate") do
	table.insert(excluded, gate)
end
params.FilterDescendantsInstances = excluded
local issues, samples = {}, 0
local function check(name, points)
	local last, lastHeight
	for i = 1, #points - 1 do
		local a, b = points[i], points[i + 1]
		local n = math.max(1, math.ceil((b - a).Magnitude / 4))
		for k = 0, n do
			local p = a:Lerp(b, k / n)
			samples += 1
			local hit = workspace:Raycast(p + Vector3.new(0, 3, 0), Vector3.new(0, -12, 0), params)
			if not hit then
				table.insert(issues, {route=name, problem="missing ground", position=tostring(p)})
			elseif math.abs(hit.Position.Y - p.Y) > 2 then
				table.insert(issues, {route=name, problem="surface height", part=hit.Instance:GetFullName(), delta=hit.Position.Y-p.Y})
			end
			if hit and lastHeight and math.abs(hit.Position.Y-lastHeight) > 3.5 then
				table.insert(issues, {route=name, problem="step too high", delta=hit.Position.Y-lastHeight})
			end
			lastHeight = hit and hit.Position.Y
			if last then
				local obstacle = workspace:Raycast(last + Vector3.new(0, 3, 0), p-last, params)
				if obstacle then table.insert(issues, {route=name, problem="obstacle", part=obstacle.Instance:GetFullName()}) end
			end
			last = p
		end
	end
end
for _, road in L.roads do check(string.format("Road_%d_%d", road.from, road.to), B.RoadPoints(road)) end
for i, z in L.zones do
	local inward = Vector3.new(z.center.X-z.entry.X,0,z.center.Z-z.entry.Z).Unit
	local finish = z.trailEnd or z.exit or (z.center + Vector3.new(inward.Z,0,-inward.X)*80)
	check("Zone"..i, {z.trailStart or z.entry, finish})
end
return {samples=samples, issues=issues, count=#issues}
