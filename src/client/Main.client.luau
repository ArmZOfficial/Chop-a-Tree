--!strict
-- จุดเริ่มฝั่ง Client — เพิ่มโมดูลใหม่ใน MODULES

local MODULES = { "ClientData", "LocaleController", "HUD", "AdminEffects", "ForestController", "InventoryController", "WeatherController", "GardenController", "PetController", "StoryController", "ZoneAmbience", "RebirthController", "RewardsController", "EmoteController", "ShopController", "SeasonController", "ArenaController", "SprintController", "ChestOpening", "NavigationController" }

table.insert(MODULES, "ZoneController")
table.insert(MODULES, "MapController")
table.insert(MODULES, "WorldEventController")
table.insert(MODULES, "GateController")

for _, name in MODULES do
	local ok, err = pcall(function()
		require(script.Parent[name]).Start()
	end)
	if not ok then
		warn("[Client] " .. name .. " failed: " .. tostring(err))
	end
end
