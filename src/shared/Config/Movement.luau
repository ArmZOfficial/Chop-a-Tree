-- Movement / Sprint (master prompt track H). The server owns speed: PetService.ApplySpeed sets
-- WalkSpeed = base (AdminSpeed or WalkSpeed) × Pet.SpeedMult (pet buff × mount × CarryMult) × sprint.
-- Clients only send intent (SprintIntent); the server validates and sets Character.Sprinting.
return table.freeze({
	WalkSpeed = 16,
	LocomotionAnimation = "rbxassetid://103920925204515", -- Demo1: walk and run; default Animate owns blending/rate.
	SprintMultiplier = 1.5,
	SprintAcceleration = 0.25, -- seconds for the client FOV ramp (cosmetic)
	SprintFov = 8, -- extra camera FOV while sprinting (0 with Reduce Motion)
	SprintWhileCarrying = false, -- carried eggs keep their slowdown
	MinSprintInterval = 0.1, -- server rate limit for "start sprinting" intents
	DefaultMode = "Hold", -- Settings.SprintMode: "Hold" | "Toggle" (touch button always toggles)
	ShiftLockKeys = "LeftControl,RightControl", -- Shift is sprint, so shift-lock moves to Ctrl
	DustInterval = 0.12,
})
