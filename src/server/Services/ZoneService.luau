-- One bounded batch for all players. Attributes are presentation; gameplay uses fresh Zones.At.
local Players = game:GetService("Players")
local Heartbeat = game:GetService("RunService").Heartbeat
local S = game.ReplicatedStorage.Shared
local Zones = require(S.Config.Zones)
local Util = require(S.ZoneUtil)
local Data = require(script.Parent.DataService)
local Features = require(script.Parent.FeatureService)
local Zone = {}
local entered, left = Instance.new("BindableEvent"), Instance.new("BindableEvent")
Zone.PlayerEntered, Zone.PlayerLeft = entered.Event, left.Event
local states, connections = {}, {}
local elapsed, total, ticks, peak = 0, 0, 0, 0
function Zone.GetZone(p) return states[p] and states[p].zone end
function Zone.GetZoneAt(position) return Util.At(position) end
Zone.GetConfig = Util.Config
function Zone.GetPlayersIn(id)
	local out = {}
	for p, state in states do if state.zone == id then table.insert(out, p) end end
	return out
end
local function set(p, state, id)
	local previous = state.zone
	if previous == id then return end
	state.zone = id
	p:SetAttribute("Zone", id)
	if p.Character then p.Character:SetAttribute("Zone", id) end
	if previous then left:Fire(p, previous, id) end
	if id then entered:Fire(p, id, previous) end
end
function Zone.Update(now)
	for _, p in Players:GetPlayers() do
		local state = states[p] or {}; states[p] = state
		local c = p.Character
		if state.character ~= c then
			set(p, state, nil); state.character = c; state.candidate = nil; state.since = nil
		end
		local h = c and c:FindFirstChildOfClass("Humanoid")
		local hr = h and h.Health > 0 and c:FindFirstChild("HumanoidRootPart")
		local id = Features.IsEnabled("MapSystems") and hr and Util.At(hr.Position) or nil
		if not hr or not Features.IsEnabled("MapSystems") then set(p, state, nil)
		elseif id == state.zone then state.candidate = id; state.since = now
		elseif id ~= state.candidate then state.candidate = id; state.since = now
		elseif now - (state.since or now) >= Zones.Tracking.settleSeconds then
			set(p, state, id)
			if type(id) == "number" and Data.IsLoaded(p) then
				local unlocked = Data.Get(p, "Progress.UnlockedZones") or {}
				local visits = Data.Get(p, "Progress.VisitedZones")
				if visits and table.find(unlocked, id) and not visits[tostring(id)] then
					visits[tostring(id)] = true; Data.Set(p, "Progress.VisitedZones", visits)
				end
			end
		end
	end
end
function Zone.Report() return { samples = ticks, meanMs = ticks > 0 and total / ticks * 1000 or 0, peakMs = peak * 1000 } end
function Zone.Init()
	local ok, errors = Util.Validate()
	if not ok then for _, err in errors do warn("[Zones] " .. err) end end
	table.insert(connections, Players.PlayerRemoving:Connect(function(p)
		local state = states[p]; if state then set(p, state, nil) end; states[p] = nil
	end))
end
function Zone.Start()
	table.insert(connections, Heartbeat:Connect(function(dt)
		elapsed += dt; if elapsed < Zones.Tracking.interval then return end; elapsed = 0
		local started = os.clock(); Zone.Update(started)
		local duration = os.clock() - started; ticks += 1; total += duration; peak = math.max(peak, duration)
	end))
end
function Zone.Destroy()
	for _, c in connections do c:Disconnect() end; table.clear(connections)
	for p, state in states do set(p, state, nil) end; table.clear(states)
end
return Zone
