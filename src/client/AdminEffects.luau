--!strict
-- ผลของคำสั่งแอดมินที่ต้องทำฝั่ง Client (บิน, ทะลุกำแพง)
-- ทำงานกับทุกผู้เล่น เพราะแอดมินสั่งให้ผู้เล่นคนอื่นได้ (อ่านจาก Attribute ที่ Server ตั้ง)

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local AdminEffects = {}

local player = Players.LocalPlayer
local FLY_SPEED = 80

function AdminEffects.Start()
	local velocity: LinearVelocity? = nil
	local gyro: AlignOrientation? = nil
	local attachment: Attachment? = nil

	local function stopFly()
		if velocity then
			velocity:Destroy()
			velocity = nil
		end
		if gyro then
			gyro:Destroy()
			gyro = nil
		end
		if attachment then
			attachment:Destroy()
			attachment = nil
		end
		local char = player.Character
		local hum = char and char:FindFirstChildOfClass("Humanoid")
		if hum then
			hum.PlatformStand = false
		end
	end

	RunService.Heartbeat:Connect(function()
		local char = player.Character
		local root = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
		local hum = char and char:FindFirstChildOfClass("Humanoid")
		if not root or not hum then
			return
		end

		-- บิน
		if player:GetAttribute("AdminFly") then
			if not velocity or velocity.Parent ~= root then
				stopFly()
				attachment = Instance.new("Attachment")
				attachment.Name = "AdminFlyAttachment"
				attachment.Parent = root
				velocity = Instance.new("LinearVelocity")
				velocity.Attachment0 = attachment
				velocity.MaxForce = math.huge
				velocity.RelativeTo = Enum.ActuatorRelativeTo.World
				velocity.Parent = root
				gyro = Instance.new("AlignOrientation")
				gyro.Mode = Enum.OrientationAlignmentMode.OneAttachment
				gyro.Attachment0 = attachment
				gyro.MaxTorque = math.huge
				gyro.Responsiveness = 50
				gyro.Parent = root
			end
			hum.PlatformStand = true
			local cam = workspace.CurrentCamera
			local move = Vector3.zero
			if UserInputService:IsKeyDown(Enum.KeyCode.W) then
				move += cam.CFrame.LookVector
			end
			if UserInputService:IsKeyDown(Enum.KeyCode.S) then
				move -= cam.CFrame.LookVector
			end
			if UserInputService:IsKeyDown(Enum.KeyCode.D) then
				move += cam.CFrame.RightVector
			end
			if UserInputService:IsKeyDown(Enum.KeyCode.A) then
				move -= cam.CFrame.RightVector
			end
			if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
				move += Vector3.yAxis
			end
			if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then
				move -= Vector3.yAxis
			end
			-- มือถือ: ใช้จอยสติ๊กของ Humanoid
			if move.Magnitude < 0.01 and hum.MoveDirection.Magnitude > 0 then
				move = hum.MoveDirection
			end
			local v = (velocity :: LinearVelocity)
			v.VectorVelocity = if move.Magnitude > 0 then move.Unit * FLY_SPEED else Vector3.zero;
			(gyro :: AlignOrientation).CFrame = CFrame.lookAlong(Vector3.zero, Vector3.new(cam.CFrame.LookVector.X, 0, cam.CFrame.LookVector.Z).Unit)
		elseif velocity then
			stopFly()
		end
	end)

	-- ทะลุกำแพง
	RunService.Stepped:Connect(function()
		if not player:GetAttribute("AdminNoclip") then
			return
		end
		local char = player.Character
		if not char then
			return
		end
		for _, d in char:GetDescendants() do
			if d:IsA("BasePart") then
				d.CanCollide = false
			end
		end
	end)

	player:GetAttributeChangedSignal("AdminNoclip"):Connect(function()
		if player:GetAttribute("AdminNoclip") then
			return
		end
		local char = player.Character
		local root = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
		if root then
			root.CanCollide = true
		end
	end)
	player.CharacterAdded:Connect(stopFly)
end

return AdminEffects
