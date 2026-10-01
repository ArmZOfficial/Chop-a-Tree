local Shared=game.ReplicatedStorage.Shared
local Config=require(Shared.Config.Weather)
local Schedule=require(Shared.WeatherSchedule)
local Events=require(Shared.Config.Events)
local Features=require(script.Parent.FeatureService)
local Weather={}
local forced,folder,eventProvider,festivalPreview
local function festivalAt(now)
	if not Features.IsEnabled("Festivals") then return nil end
	if festivalPreview and festivalPreview.endsAt>now then return Events.ById[festivalPreview.id] end
	festivalPreview=nil
	for _,e in Events.List do if now>=e.startsAt and now<e.endsAt then return e end end
end
-- Festival layer over the UTC schedule; changes the key so mutations roll again.
local function apply(s,now)
	local e=festivalAt(now);local hour=now%86400/3600
	if e and s.id~="RotInvasion" and not Config.ById[s.id].rare and not (e.nightOnly and hour>=6 and hour<18) then
		s.id=e.weather;s.festival=e.id;s.eventKey="fest:"..e.id..":"..s.eventKey
	end
	return s
end
local function festive(s,now)
	apply(s,now)
	if s.nextId~="???" then s.nextId=apply(Schedule.At(s.nextAt),s.nextAt).id end
	return s
end
function Weather.PreviewFestival(id,seconds) festivalPreview=id and {id=id,endsAt=os.time()+seconds} or nil;if folder then Weather.Publish() end end
function Weather.Festival() return festivalAt(os.time()) end
function Weather.SetEventProvider(provider) eventProvider=provider end
function Weather.GetOverride() return forced and table.clone(forced) end
function Weather.State()
	local now=os.time()
	if not Features.IsEnabled("Weather") then return {id="Clear",endsAt=now+60,nextId="Clear",nextAt=now+60,eventKey="disabled"} end
	local event=eventProvider and eventProvider();if event then return event end
	if forced and forced.endsAt>now then return {id=forced.id,endsAt=forced.endsAt,nextId="UTC",nextAt=forced.endsAt,eventKey=forced.id..":"..forced.startedAt} end
	forced=nil;return Weather.AtTime(now)
end
-- UTC schedule with the festival layer for any time (forecasts/tests).
function Weather.AtTime(now) return festive(Schedule.At(now),now) end
function Weather.Def(s)
	s=s or Weather.State();local def=Config.ById[s.id];local e=s.festival and Events.ById[s.festival]
	if e and e.mutation then def=table.clone(def);def.mutation=e.mutation;def.chance=e.chance end
	return def
end
function Weather.Publish()
	local state=Weather.State();local def=Config.ById[state.id]
	for k,v in state do folder:SetAttribute(k,v) end
	local fest=Weather.Festival();folder:SetAttribute("Festival",fest and fest.name or "")
	folder:SetAttribute("festival",state.festival)
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
