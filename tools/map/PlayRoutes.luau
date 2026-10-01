-- Run in Play CLIENT after the server prepares ReplicatedStorage.MapRouteTest.
-- Server payload: JSON routes {name,speed,points={{x,y,z},...}} from MapBuilder.Layout().
local player = game.Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local root = character:WaitForChild("HumanoidRootPart")
local routes = game:GetService("HttpService"):JSONDecode(game.ReplicatedStorage.MapRouteTest.Value)
local originalSpeed = humanoid.WalkSpeed
_G.MapWalkTest = { status = "running", results = {} }
task.spawn(function()
	local ok, err = pcall(function()
		for _, route in routes do
			_G.MapWalkTest.current = route.name
			local points = {}
			for _, p in route.points do table.insert(points, Vector3.new(p[1],p[2],p[3])) end
			player:RequestStreamAroundAsync(points[1],8)
			character:PivotTo(CFrame.new(points[1]+Vector3.new(0,4,0)))
			humanoid.WalkSpeed = route.speed
			task.wait(0.5)
			for i = 2, #points do
				local p = points[i]
				if i % 24 == 0 then player:RequestStreamAroundAsync(points[math.min(i+24,#points)],2) end
				humanoid:MoveTo(p)
				local deadline = os.clock()+math.max(3,(root.Position-p).Magnitude/route.speed+2)
				local function distance()
					return Vector3.new(root.Position.X-p.X,0,root.Position.Z-p.Z).Magnitude
				end
				repeat task.wait(0.05) until distance()<3 or os.clock()>deadline
				assert(distance()<3 and root.Position.Y>=p.Y-2, route.name.." failed at "..i.." "..tostring(root.Position))
			end
			table.insert(_G.MapWalkTest.results, {route=route.name,passed=true,speed=route.speed,waypoints=#points})
		end
	end)
	humanoid.WalkSpeed = originalSpeed
	_G.MapWalkTest.status = ok and "passed" or "failed"
	_G.MapWalkTest.error = not ok and tostring(err) or nil
end)
return "Walking all generated map routes asynchronously"
