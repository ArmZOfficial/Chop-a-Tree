-- Phase 8e festivals. Inject in Studio Play as a temporary Script; touches no profile data.
assert(game:GetService("RunService"):IsStudio())
local V=game.ServerScriptService.Server.Services;local S=game.ReplicatedStorage.Shared
local F=require(V.FeatureService);local WX=require(V.WeatherService);local B=require(S.Balance)
local Ev=require(S.Config.Events);local WC=require(S.Config.Weather);local MC=require(S.Config.Mutations);local Schedule=require(S.WeatherSchedule);local CM=require(S.CollectionMath)
local results={};local flag=F.IsEnabled("Festivals")
local function check(name,ok) assert(ok,name);table.insert(results,{name=name,passed=true}) end
local function utc(y,m,d) return DateTime.fromUniversalTime(y,m,d).UnixTimestamp end
workspace:SetAttribute("Phase8FestivalStatus","running")
local ok,err=xpcall(function()
 F.Set("Festivals",true);WX.PreviewFestival(nil)
 local valid,prev=true,0
 for _,e in Ev.List do valid=valid and e.startsAt<e.endsAt and e.startsAt>=prev and WC.ById[e.weather]~=nil and (not e.mutation or MC.Values[e.mutation]~=nil);prev=e.endsAt end
 check("Festival rows are ordered, non-overlapping and reference real weather/mutations",valid and #Ev.List==4)
 check("Festival dates are UTC midnights",Ev.ById.halloween.startsAt==utc(2026,10,25) and Ev.ById.halloween.startsAt%86400==0)
 check("Splash joins the mutation Index catalog",CM.Catalog.mutations.Splash and CM.Totals.mutations==17)
 -- Songkran: all common weather becomes Rain, rare/Rot untouched, every minute of a day
 local day=utc(2027,4,13);local rain,keep,keys,forecast=true,true,true,true
 for now=day,day+86399,60 do
  local base=Schedule.At(now);local s=WX.AtTime(now)
  if base.id=="RotInvasion" or WC.ById[base.id].rare then keep=keep and s.id==base.id and s.festival==nil
  else rain=rain and s.id=="Rain" and s.festival=="songkran" and s.eventKey=="fest:songkran:"..base.eventKey end
  if s.nextId~="???" and s.nextAt<day+86400 then forecast=forecast and WX.AtTime(s.nextAt).id==s.nextId end
 end
 check("Songkran turns Clear/common weather into Rain all day",rain)
 check("Songkran keeps rare weather and RotInvasion",keep)
 check("Festival forecasts name what actually follows",forecast)
 local s=WX.AtTime(day+3*3600);if s.id~="Rain" then s=WX.AtTime(day+5*3600) end
 check("Songkran Rain rolls Splash instead of Wet",s.id~="Rain" or (WX.Def(s).mutation=="Splash" and WX.Def(s).chance==.25 and WC.ById.Rain.mutation=="Wet"))
 -- Halloween: Bloodmoon only at night
 day=utc(2026,10,27);local night,dayOk=true,true
 for now=day,day+86399,60 do
  local base=Schedule.At(now);local s2=WX.AtTime(now);local hour=now%86400/3600
  if hour>=6 and hour<18 then dayOk=dayOk and s2.id==base.id and s2.festival==nil
  elseif base.id~="RotInvasion" and not WC.ById[base.id].rare then night=night and s2.id=="Bloodmoon" end
 end
 check("Halloween nights become Bloodmoon",night)
 check("Halloween days keep the normal schedule",dayOk)
 local outside=utc(2026,10,10)+3600;check("Outside festival dates the schedule is unchanged",WX.AtTime(outside).id==Schedule.At(outside).id and WX.AtTime(outside).festival==nil)
 -- preview / flag
 WX.PreviewFestival("winter",Ev.PreviewSeconds)
 check("Admin preview activates a festival on this server",WX.Festival()==Ev.ById.winter and game.ReplicatedStorage.WeatherState:GetAttribute("Festival")==Ev.ById.winter.name)
 WX.AtTime(os.time()+Ev.PreviewSeconds+1)
 check("Future forecasts never clear an active preview",WX.Festival()==Ev.ById.winter)
 local now=os.time();local cur=WX.AtTime(now);local base=Schedule.At(now)
 check("Preview applies the festival weather now",(base.id=="RotInvasion" or WC.ById[base.id].rare) and cur.id==base.id or cur.id=="Snow")
 F.Set("Festivals",false);check("Feature off disables festivals and previews",WX.Festival()==nil and WX.AtTime(now).id==base.id);F.Set("Festivals",true)
 WX.PreviewFestival(nil);check("Clearing preview returns to real dates",WX.Festival()==nil)
 check("Balance SelfTest passes",B.SelfTest())
end,debug.traceback)
WX.PreviewFestival(nil);F.Set("Festivals",flag)
workspace:SetAttribute("Phase8FestivalResults",game.HttpService:JSONEncode({passed=ok,checks=results,error=not ok and err or nil}));workspace:SetAttribute("Phase8FestivalStatus",ok and "passed" or "failed")
print("[Phase8FestivalScenario]",ok and "passed" or err,#results)
