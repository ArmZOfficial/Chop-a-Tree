local Players=game:GetService("Players")
local Data=require(script.Parent.DataService);local Features=require(script.Parent.FeatureService)
local Reward=require(script.Parent.RewardService)
local Config=require(game.ReplicatedStorage.Shared.Config.Daily);local Net=require(game.ReplicatedStorage.Shared.Net)
local Daily={};local last={}
function Daily.Touch(p,now)
	local day=math.floor((now or os.time())/86400);local d=Data.Get(p,"Daily")
	if day>d.lastDay then
		d={lastDay=day,streak=day==d.lastDay+1 and d.streak+1 or 1,claimedDay=d.claimedDay};Data.Set(p,"Daily",d)
	end
	return d,day
end
function Daily.State(p,now)
	local d,day=Daily.Touch(p,now);return {streak=d.streak,day=(d.streak-1)%7+1,
		claimed=d.claimedDay>=day,nextAt=(day+1)*86400,enabled=Features.IsEnabled("Daily")}
end
function Daily.Claim(p,now)
	if not Data.IsLoaded(p) or not Features.IsEnabled("Daily") then return false,"Daily Unavailable" end
	now=now or os.time();local d,day=Daily.Touch(p,now)
	if d.claimedDay>=day then return false,"Already claimed today. Return tomorrow (UTC)" end
	local reward=Config.Rewards[(d.streak-1)%7+1]
	d.claimedDay=day;Data.Set(p,"Daily",d);Reward.Grant(p,reward,now,Data.Get(p,"Meta.AdminTouched"))
	if (Data.Get(p,"Purchases.passes") or {}).VIP then Data.AddCurrency(p,"Gems",Config.VipGems);return true,"Daily reward claimed: "..reward.label.." + VIP "..Config.VipGems.." Gems" end
	return true,"Daily reward claimed: "..reward.label
end
function Daily.Reset(p) Data.Set(p,"Daily",{lastDay=-1,streak=0,claimedDay=-1}) end
function Daily.Init()
	Net.Function("DailyAction").OnServerInvoke=function(p,action)
		if not Data.IsLoaded(p) then return false,"Data not ready" end
		local now=os.clock();if now-(last[p] or -math.huge)<.35 then return false,"Please wait" end;last[p]=now
		local ok,msg;if action=="Sync" then ok,msg=true,"Ready" elseif action=="Claim" then ok,msg=Daily.Claim(p) else return false,"Invalid command" end
		return ok,msg,Daily.State(p)
	end
	Data.PlayerLoaded:Connect(function(p) if Features.IsEnabled("Daily") then Daily.Touch(p) end end)
	Players.PlayerRemoving:Connect(function(p) last[p]=nil end)
end
function Daily.Start() end
return Daily
