assert(game:GetService('RunService'):IsStudio(), 'Map QA is Studio-only')
local Client=script.Parent.Client
for _,name in {"ClientData","LocaleController","HUD","WeatherController","ZoneAmbience","ZoneController","StoryController","MapController","WorldEventController","GateController"} do local ok,err=pcall(function() require(Client[name]).Start() end);if not ok then warn("[MapClientQA] "..name..": "..tostring(err)) else print("[MapClientQA] "..name.." OK") end end
