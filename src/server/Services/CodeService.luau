local Players=game:GetService("Players")
local Data=require(script.Parent.DataService);local Features=require(script.Parent.FeatureService)
local Reward=require(script.Parent.RewardService);local Codes=require(script.Parent.Parent.Config.Codes)
local Net=require(game.ReplicatedStorage.Shared.Net)
local Code={};local last={}
function Code.Normalize(value)
	if type(value)~="string" or #value>64 then return nil end
	value=value:match("^%s*(.-)%s*$"):upper()
	return #value>0 and #value<=32 and value:match("^[A-Z0-9_%-]+$") and value or nil
end
function Code.Redeem(p,input,now)
	if not Data.IsLoaded(p) or not Features.IsEnabled("Codes") then return false,"Codes ยังไม่เปิด" end
	local key=Code.Normalize(input);local def=key and Codes[key];now=now or os.time()
	if not def or (def.starts and now<def.starts) or now>=def.expires then return false,"โค้ดไม่ถูกต้องหรือหมดอายุ" end
	local redeemed=Data.Get(p,"Codes.redeemed")
	if redeemed[def.id] then return false,"ใช้โค้ดนี้แล้ว" end
	local nextRedeemed=table.clone(redeemed);nextRedeemed[def.id]=now;Data.Set(p,"Codes.redeemed",nextRedeemed)
	Reward.Grant(p,def.reward,now,Data.Get(p,"Meta.AdminTouched"));return true,"รับรางวัลจาก "..key.." แล้ว"
end
function Code.Init()
	Net.Function("CodeAction").OnServerInvoke=function(p,input)
		if not Data.IsLoaded(p) then return false,"ข้อมูลยังไม่พร้อม" end
		local now=os.clock();if now-(last[p] or -math.huge)<1 then return false,"รอ 1 วินาทีก่อนลองใหม่" end;last[p]=now
		return Code.Redeem(p,input)
	end
	Players.PlayerRemoving:Connect(function(p) last[p]=nil end)
end
function Code.Start() end
return Code
