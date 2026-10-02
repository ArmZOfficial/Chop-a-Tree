--!strict
-- แท็บ "ผู้เล่น" — บิน, ทะลุกำแพง, อมตะ, ความเร็ว, วาร์ป, ล่องหน, รีเซ็ต
-- บิน/ทะลุกำแพง ทำงานฝั่ง Client ของผู้เล่นนั้น (อ่านจาก Attribute)

local Players = game:GetService("Players")

local function toggleAttr(player: Player, name: string): boolean
	local nextValue = not player:GetAttribute(name)
	player:SetAttribute(name, nextValue)
	return nextValue
end

local function root(player: Player): BasePart?
	local char = player.Character
	return char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
end

local function humanoid(player: Player): Humanoid?
	local char = player.Character
	return char and char:FindFirstChildOfClass("Humanoid")
end

local function applyCharacterState(player: Player)
	local hum = humanoid(player)
	if not hum then
		return
	end
	local speed = player:GetAttribute("AdminSpeed")
	hum.WalkSpeed = if type(speed) == "number" then speed else 16
	if player:GetAttribute("AdminGod") then
		hum.MaxHealth = math.huge
		hum.Health = math.huge
	end
	local invisible = player:GetAttribute("AdminInvisible") == true
	for _, d in (player.Character :: Model):GetDescendants() do
		if d:IsA("BasePart") and d.Name ~= "HumanoidRootPart" then
			d.Transparency = invisible and 1 or 0
		elseif d:IsA("Decal") then
			d.Transparency = invisible and 1 or 0
		end
	end
end

local function onOff(v: boolean): string
	return v and "Open" or "Close"
end

return function(Admin)
	-- คงสถานะไว้หลังเกิดใหม่
	local function hook(player: Player)
		player.CharacterAdded:Connect(function(char)
			char:WaitForChild("Humanoid")
			task.wait()
			applyCharacterState(player)
		end)
	end
	for _, p in Players:GetPlayers() do
		hook(p)
	end
	Players.PlayerAdded:Connect(hook)

	local function each(ctx, fn: (Player) -> ())
		for _, t in ctx.targets do
			fn(t)
		end
	end

	Admin.Register({
		id = "player.fly",
		tab = "player",
		label = "Fly",
		sub = "WASD + Space/Shift",
		color = "Blue",
		order = 1,
		usesTarget = true,
		run = function(ctx)
			local state = false
			each(ctx, function(p)
				state = toggleAttr(p, "AdminFly")
			end)
			return true, "Fly: " .. onOff(state)
		end,
	})
	Admin.Register({
		id = "player.noclip",
		tab = "player",
		label = "Noclip",
		color = "Teal",
		order = 2,
		usesTarget = true,
		run = function(ctx)
			local state = false
			each(ctx, function(p)
				state = toggleAttr(p, "AdminNoclip")
			end)
			return true, "Noclip: " .. onOff(state)
		end,
	})
	Admin.Register({
		id = "player.god",
		tab = "player",
		label = "God Mode",
		color = "Green",
		order = 3,
		usesTarget = true,
		run = function(ctx)
			local state = false
			each(ctx, function(p)
				state = toggleAttr(p, "AdminGod")
				local hum = humanoid(p)
				if hum and not state then
					hum.MaxHealth = 100
					hum.Health = 100
				end
				applyCharacterState(p)
			end)
			return true, "God Mode: " .. onOff(state)
		end,
	})
	for i, speed in { 16, 32, 64, 120 } do
		Admin.Register({
			id = "player.speed" .. speed,
			tab = "player",
			label = speed == 16 and "Normal Speed" or ("Speed ×" .. speed / 16),
			sub = "WalkSpeed " .. speed,
			color = "Purple",
			order = 10 + i,
			usesTarget = true,
			run = function(ctx)
				each(ctx, function(p)
					p:SetAttribute("AdminSpeed", speed)
					applyCharacterState(p)
				end)
				return true, "Speed " .. speed
			end,
		})
	end
	Admin.Register({
		id = "player.invisible",
		tab = "player",
		label = "Invisible",
		color = "Slate",
		order = 20,
		usesTarget = true,
		run = function(ctx)
			local state = false
			each(ctx, function(p)
				state = toggleAttr(p, "AdminInvisible")
				applyCharacterState(p)
			end)
			return true, "Invisible: " .. onOff(state)
		end,
	})
	Admin.Register({
		id = "player.goto",
		tab = "player",
		label = "Warp to Player",
		sub = "Select One Player",
		color = "Orange",
		order = 30,
		usesTarget = true,
		singleTarget = true,
		minLevel = "Moderator",
		run = function(ctx)
			local target = ctx.targets[1]
			local from, to = root(ctx.admin), root(target)
			if not from or not to then
				return false, "Character not found"
			end
			from.CFrame = to.CFrame * CFrame.new(0, 0, 4)
			return true, "Warped to " .. target.Name
		end,
	})
	Admin.Register({
		id = "player.bring",
		tab = "player",
		label = "Bring Player",
		color = "Orange",
		order = 31,
		usesTarget = true,
		minLevel = "Moderator",
		run = function(ctx)
			local me = root(ctx.admin)
			if not me then
				return false, "Your character was not found"
			end
			local n = 0
			for i, t in ctx.targets do
				local r = root(t)
				if r and t ~= ctx.admin then
					r.CFrame = me.CFrame * CFrame.new((i - 1) * 3 - 6, 0, -5)
					n += 1
				end
			end
			return true, "Brought " .. n .. " players"
		end,
	})
	Admin.Register({
		id = "player.spawn",
		tab = "player",
		label = "Warp to Spawn",
		color = "Blue",
		order = 32,
		usesTarget = true,
		run = function(ctx)
			local spawnPart = workspace:FindFirstChildWhichIsA("SpawnLocation", true)
			local cf = spawnPart and spawnPart.CFrame * CFrame.new(0, 4, 0) or CFrame.new(0, 10, 0)
			each(ctx, function(p)
				local r = root(p)
				if r then
					r.CFrame = cf
				end
			end)
			return true, "Warped to spawn"
		end,
	})
	Admin.Register({
		id = "player.reset",
		tab = "player",
		label = "Respawn Character",
		color = "Red",
		order = 40,
		usesTarget = true,
		run = function(ctx)
			each(ctx, function(p)
				p:LoadCharacter()
			end)
			return true, "Reset"
		end,
	})
	Admin.Register({
		id = "player.clearall",
		tab = "player",
		label = "Disable All Admin Modes",
		sub = "Fly / Noclip / God Mode / Speed / Invisible",
		color = "Slate",
		order = 41,
		usesTarget = true,
		run = function(ctx)
			each(ctx, function(p)
				for _, a in { "AdminFly", "AdminNoclip", "AdminGod", "AdminSpeed", "AdminInvisible" } do
					p:SetAttribute(a, nil)
				end
				local hum = humanoid(p)
				if hum then
					hum.MaxHealth = 100
					hum.Health = 100
				end
				applyCharacterState(p)
			end)
			return true, "All modes disabled"
		end,
	})
end
