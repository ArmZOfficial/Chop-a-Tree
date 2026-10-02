-- Picks the display language (Settings.Language: Auto/en/th; Auto follows the Roblox locale) and keeps
-- PlayerGui + Workspace text translated through Shared.Locale. Roblox AutoLocalize stays on as a fallback.
local Players=game:GetService("Players")
local LocalizationService=game:GetService("LocalizationService")
local Shared=game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Locale=require(Shared.Locale)
local Net=require(Shared.Net)
local Data=require(script.Parent.ClientData)
local Controller={}

local NEXT={Auto="en",en="th",th="Auto"}
local LABEL={Auto="AUTO",en="ENGLISH",th="ไทย"}
function Controller.Setting() return Data.Get("Settings.Language") or "Auto" end
function Controller.Label() return LABEL[Controller.Setting()] or "AUTO" end
function Controller.Cycle() Net.Event("SettingIntent"):FireServer("Language",NEXT[Controller.Setting()] or "Auto") end

function Controller.Start()
	local player=Players.LocalPlayer
	local function pick()
		local id=""
		pcall(function() id=LocalizationService.RobloxLocaleId end)
		if id=="" then id=player.LocaleId end
		Locale.SetLang(Locale.Resolve(Controller.Setting(),id))
	end
	pick()
	Data.Changed:Connect(function(path) if path=="" or path=="Settings" or path=="Settings.Language" then pick() end end)
	Locale.Bind(player:WaitForChild("PlayerGui"))
	Locale.Bind(workspace)
end
return Controller
