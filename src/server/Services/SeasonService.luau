-- Season Pass (plan 17.4). Pass XP comes from Stats deltas, so other systems only increment Stats.
-- Profile Season = {id, xp, premium, free, prem, pendingFor}; a new season id resets everything but pendingFor.
local Players=game:GetService("Players")
local S=game.ReplicatedStorage.Shared
local C=require(S.Config.Season)
local Net=require(S.Net)
local D=require(script.Parent.DataService)
local F=require(script.Parent.FeatureService)
local Reward=require(script.Parent.RewardService)
local Run=require(script.Parent.RunService)
local M={}
local seen,last={},{}

function M.Active(now)
	now=now or os.time()
	for _,s in C.Seasons do if now>=s.startsAt and now<s.endsAt then return s end end
	return nil
end
function M.Level(xp) return math.min(#C.Levels,math.floor(xp/C.XpPerLevel)) end
-- Rolls the profile onto the active season. Unclaimed rewards of an ended season are dropped.
function M.Touch(p,now)
	local season=M.Active(now);local d=D.Get(p,"Season")
	local id=season and season.id or ""
	if d.id~=id then d={id=id,xp=0,premium=false,free={},prem={},pendingFor=d.pendingFor or ""};D.Set(p,"Season",d) end
	return d,season
end
function M.State(p,now)
	now=now or os.time();local d,season=M.Touch(p,now)
	return {id=d.id,name=season and season.name or "",endsAt=season and season.endsAt or 0,xp=d.xp,level=M.Level(d.xp),
		xpPerLevel=C.XpPerLevel,premium=d.premium,free=d.free,prem=d.prem,enabled=F.IsEnabled("SeasonPass") and season~=nil}
end
function M.AddXp(p,amount,now)
	if amount<=0 or not F.IsEnabled("SeasonPass") or not D.IsLoaded(p) then return end
	local d,season=M.Touch(p,now);if not season then return end
	local cap=#C.Levels*C.XpPerLevel;if d.xp>=cap then return end
	local before=M.Level(d.xp);d.xp=math.min(cap,d.xp+amount);D.Set(p,"Season.xp",d.xp)
	local after=M.Level(d.xp)
	if after>before then Net.Event("Notify"):FireClient(p,{text="Season Pass เลเวล "..after.."! เปิดหน้า Season เพื่อรับรางวัล",color="Accent"}) end
end
local function claimOne(p,d,track,level,now)
	local row=C.Levels[level];local ledger=track=="premium" and d.prem or d.free;local key=tostring(level)
	if not row or ledger[key] or level>M.Level(d.xp) or (track=="premium" and not d.premium) then return nil end
	ledger[key]=true;Reward.Grant(p,row[track],now,D.Get(p,"Meta.AdminTouched")==true);return row[track].label
end
function M.Claim(p,track,level,now)
	if not D.IsLoaded(p) or not F.IsEnabled("SeasonPass") then return false,"Season Pass ยังไม่เปิด" end
	now=now or os.time();local d,season=M.Touch(p,now)
	if not season then return false,"ตอนนี้ไม่มีซีซัน" end
	if track~="free" and track~="premium" then return false,"คำสั่งไม่ถูกต้อง" end
	if type(level)~="number" or level%1~=0 then return false,"เลเวลไม่ถูกต้อง" end
	local label=claimOne(p,d,track,level,now)
	if not label then return false,track=="premium" and not d.premium and "ต้องมี Season Pass Premium" or "ยังรับรางวัลนี้ไม่ได้" end
	D.Set(p,"Season",d);return true,"ได้รับ "..label
end
function M.ClaimAll(p,now)
	if not D.IsLoaded(p) or not F.IsEnabled("SeasonPass") then return false,"Season Pass ยังไม่เปิด" end
	now=now or os.time();local d,season=M.Touch(p,now)
	if not season then return false,"ตอนนี้ไม่มีซีซัน" end
	local n=0
	for level=1,M.Level(d.xp) do
		if claimOne(p,d,"free",level,now) then n+=1 end
		if claimOne(p,d,"premium",level,now) then n+=1 end
	end
	if n==0 then return false,"ไม่มีรางวัลที่รับได้" end
	D.Set(p,"Season",d);return true,"รับรางวัลแล้ว "..n.." รายการ"
end
-- Premium purchase flow. The prompt stamps the season on sale so a late receipt cannot unlock a later season.
function M.CanBuy(p,now)
	if not F.IsEnabled("SeasonPass") then return false,"Season Pass ยังไม่เปิด" end
	local d,season=M.Touch(p,now)
	if not season then return false,"ตอนนี้ไม่มีซีซันที่เปิดขาย" end
	if d.premium then return false,"มี Premium ของ "..season.name.." แล้ว" end
	return true
end
function M.MarkPending(p,now) local d=M.Touch(p,now);D.Set(p,"Season.pendingFor",d.id) end
-- Must not yield (called inside ProcessReceipt). Returns the notify text.
function M.GrantPremium(p,now)
	local d,season=M.Touch(p,now);local target=d.pendingFor~="" and d.pendingFor or d.id
	d.pendingFor=""
	if season and target==season.id and not d.premium then
		d.premium=true;D.Set(p,"Season",d);return "ปลดล็อก Season Pass Premium • "..season.name
	end
	D.Set(p,"Season",d);D.AddCurrency(p,"Gems",C.PremiumFallbackGems)
	return "ซีซันที่ซื้อจบแล้วหรือมี Premium อยู่แล้ว จึงได้ "..C.PremiumFallbackGems.." Gems แทน"
end
function M.SetPremium(p,on) local d=M.Touch(p);d.premium=on==true;D.Set(p,"Season",d) end
function M.Reset(p) D.Set(p,"Season",{id="",xp=0,premium=false,free={},prem={},pendingFor=""});M.Touch(p) end

local function snapshot(p) local st=D.Get(p,"Stats");local t={};for k in C.Xp do t[k]=st[k] or 0 end;seen[p]=t end
local function onChanged(p,path,value)
	if path=="" then snapshot(p);return end
	local stat=string.match(path,"^Stats%.(%w+)$");if not stat or not C.Xp[stat] or not seen[p] then return end
	local delta=(value or 0)-(seen[p][stat] or 0);seen[p][stat]=value or 0
	if delta<=0 then return end
	local per=C.Xp[stat];if stat=="TreesCut" and Run.GetModes(p).AutoCut then per=C.Xp.AutoTreesCut end
	M.AddXp(p,per*delta)
end
function M.Init()
	D.PlayerLoaded:Connect(function(p) snapshot(p);M.Touch(p) end)
	D.Changed:Connect(onChanged)
	Net.Function("SeasonAction").OnServerInvoke=function(p,action,track,level)
		if not D.IsLoaded(p) then return false,"กำลังโหลดข้อมูล" end
		local now=os.clock();if now-(last[p] or -math.huge)<.3 then return false,"รอสักครู่" end;last[p]=now
		local ok,msg
		if action=="Sync" then ok,msg=true,""
		elseif action=="Claim" then ok,msg=M.Claim(p,track,level)
		elseif action=="ClaimAll" then ok,msg=M.ClaimAll(p)
		else return false,"คำสั่งไม่ถูกต้อง" end
		return ok,msg,M.State(p)
	end
	Players.PlayerRemoving:Connect(function(p) seen[p]=nil;last[p]=nil end)
end
function M.Start() for _,p in Players:GetPlayers() do if D.IsLoaded(p) then snapshot(p);M.Touch(p) end end end
return M
