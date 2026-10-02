-- All gameplay footprint checks delegate to Zones.At; only UI projection lives here.
local Zones = require(script.Parent.Config.Zones)
local Util = {}
function Util.At(position)
	local h = Zones.Hub
	local delta = position - h.center
	if delta.X * delta.X + delta.Z * delta.Z <= h.radius * h.radius and math.abs(delta.Y) < 60 then return "hub" end
	return Zones.At(position)
end
function Util.Config(id) return id == "hub" and { id = "hub", name = "Rootfall", thai = "รูตฟอลล์", safe = true } or Zones.List[id] end
function Util.SurfaceAt(position)
	-- Vertical rescue/access probe still delegates every footprint to the single Zones.At owner.
	local h=Zones.Hub; local flat=Vector3.new(position.X,h.center.Y,position.Z)
	if Util.At(flat)=="hub" then return "hub" end
	for _,z in Zones.List do if Zones.At(Vector3.new(position.X,z.y,position.Z))==z.id then return z.id end end
end
function Util.Project(position, center, span, yaw)
	local dx, dz = position.X - center.X, position.Z - center.Z
	local c, s = math.cos(yaw or 0), math.sin(yaw or 0)
	return Vector2.new(.5 + (dx*c-dz*s)/span, .5 + (dx*s+dz*c)/span)
end
function Util.Resolve(path)
	local node = game
	for name in path:gmatch("[^.]+") do node = node and node:FindFirstChild(name) end
	return node
end
function Util.Validate()
	local errors, seen = {}, {}
	local kit = game:GetService("ServerStorage"):FindFirstChild("MapTools")
	kit = kit and kit:FindFirstChild("TreeKit")
	local kinds = {}
	if kit then
		local ok, result = pcall(require, kit)
		if ok then for _, kind in result.Kinds do kinds[kind.key] = true end end
	end
	if #Zones.List ~= 8 then table.insert(errors, "Expected eight zones") end
	for i, z in Zones.List do
		if seen[z.id] or z.id ~= i then table.insert(errors, "Invalid/duplicate zone id: " .. tostring(z.id)) end
		seen[z.id] = true
		if not Util.Resolve(z.region) then table.insert(errors, "Missing region: " .. z.region) end
		if z.name == "" or z.thai == "" then table.insert(errors, "Missing EN/TH name: " .. z.key) end
		if not (z.inner >= 0 and z.outer > z.inner) then table.insert(errors, "Invalid radii: " .. z.key) end
		if z.id < 8 and z.inner ~= Zones.List[z.id+1].outer then table.insert(errors, "Ring seam mismatch: " .. z.key) end
		if z.trees.pool then for _, key in z.trees.pool do if not kinds[key] then table.insert(errors, "Missing TreeKit kind: " .. key) end end end
	end
	return #errors == 0, errors
end
return Util
