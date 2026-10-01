local Shared=game.ReplicatedStorage.Shared
local Config=require(Shared.Config.Weather)
local Schedule=require(Shared.WeatherSchedule)
local Features=require(script.Parent.FeatureService)
local Weather={}
local forced,folder,eventProvider
function Weather.SetEventProvider(provider) eventProvider=provider end
function Weather.GetOverride() return forced and table.clone(forced) end
function Weather.State()
	local now=os.time()
	if not Features.IsEnabled("Weather") then return {id="Clear",endsAt=now+60,nextId="Clear",nextAt=now+60,eventKey="disabled"} end
	local event=eventProvider and eventProvider();if event then return event end
	if forced and forced.endsAt>now then return {id=forced.id,endsAt=forced.endsAt,nextId="UTC",nextAt=forced.endsAt,eventKey=forced.id..":"..forced.startedAt} end
	forced=nil;return Schedule.At(now)
end
function Weather.Def() return Config.ById[Weather.State().id] end
function Weather.Publish()
	local state=Weather.State();local def=Config.ById[state.id]
	for k,v in state do folder:SetAttribute(k,v) end
	folder:SetAttribute("Name",def.name);folder:SetAttribute("Growth",def.growth);folder:SetAttribute("HealthMult",def.hp)
	folder:SetAttribute("Mode",state.live and "Live Event" or (forced and "Server override" or "UTC"));folder:SetAttribute("Message",state.message or "");folder:SetAttribute("live",state.live==true)
end
function Weather.Force(id,seconds)
	if id==nil then forced=nil else
		assert(Config.ById[id],"Unknown weather")
		forced={id=id,startedAt=os.time(),endsAt=os.time()+math.clamp(seconds or 300,1,3600)}
	end
	if folder then Weather.Publish() end
end
function Weather.Init()
	folder=Instance.new("Folder");folder.Name="WeatherState";folder.Parent=game.ReplicatedStorage
	Weather.Publish()
	game.ReplicatedStorage.FeatureFlags:GetAttributeChangedSignal("Weather"):Connect(Weather.Publish)
end
function Weather.Start() task.spawn(function() while true do Weather.Publish();task.wait(2) end end) end
return Weather
