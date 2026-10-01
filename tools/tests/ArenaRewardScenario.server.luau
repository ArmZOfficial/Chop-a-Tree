-- Phase 9d Arena ranks/tokens. Add to the main place ServerScriptService in Edit, press Play, read workspace ArenaRewardResults, then delete it.
-- Uses the Studio ledger store and always restores the real profile.
assert(game:GetService("RunService"):IsStudio())
local V=game.ServerScriptService.Server.Services
local D=require(V.DataService);local F=require(V.FeatureService);local R=require(V.ArenaRewardService)
local C=require(game.ReplicatedStorage.Shared.Config.Arena)
local ledger=game:GetService("DataStoreService"):GetDataStore("ArenaPending_v1_Studio")
local p=game.Players:GetPlayers()[1] or game.Players.PlayerAdded:Wait();assert(D.WaitForData(p,120));task.wait(2)
local original=D.ExportJSON(p);local autosave=F.IsEnabled("AutoSave")
local results={}
local function check(name,ok) assert(ok,name);table.insert(results,name) end
local function tokens() return D.GetCurrency(p,"ArenaTokens") end
local ok,err=xpcall(function()
	F.Set("AutoSave",false);D.Set(p,"Meta.AdminTouched",true);R.Reset(p);D.Set(p,"Arena.applied",{});D.SetCurrency(p,"ArenaTokens",0)
	check("Rank thresholds",R.Rank(0)=="Wood" and R.Rank(99)=="Wood" and R.Rank(100)=="Bronze" and R.Rank(1399)=="Diamond" and R.Rank(1400)=="Mythic")
	check("Season key is the UTC month",R.Season(1796083200)=="2026-12" and D.Get(p,"Arena.season")==R.Season())
	check("Ranked win pays tokens, RP and a win",R.Apply(p,{m1={result="win",ranked=true}})==1 and tokens()==C.Tokens.win and D.Get(p,"Arena.rp")==C.RankPoints.win and D.Get(p,"Arena.wins")==1)
	check("Casual loss pays tokens without RP",R.Apply(p,{m2={result="loss",ranked=false}})==1 and tokens()==C.Tokens.win+C.Tokens.loss and D.Get(p,"Arena.rp")==C.RankPoints.win and D.Get(p,"Arena.losses")==1)
	check("Draw pays tokens only",R.Apply(p,{m3={result="draw",ranked=true}})==1 and D.Get(p,"Arena.rp")==C.RankPoints.win and D.Get(p,"Arena.wins")==1 and D.Get(p,"Arena.losses")==1)
	local t=tokens()
	check("Replayed match ids pay nothing",R.Apply(p,{m1={result="win",ranked=true},m2={result="loss"}})==0 and tokens()==t and D.Get(p,"Arena.wins")==1)
	check("Unknown results are ignored",R.Apply(p,{m4={result="mvp",ranked=true},m5="win"})==0 and tokens()==t)
	R.Reset(p);check("Leaver loses RP but never below zero",R.Apply(p,{m6={result="left",ranked=true}})==1 and D.Get(p,"Arena.rp")==0 and tokens()==t and D.Get(p,"Arena.losses")==1)
	R.Apply(p,{m7={result="win",ranked=true}});D.Set(p,"Arena.season","2000-01");R.Touch(p)
	local a=D.Get(p,"Arena")
	check("Month rollover resets rank but keeps paid ids",a.rp==0 and a.wins==0 and a.losses==0 and a.season==R.Season() and a.applied.m7==true)
	-- ledger round trip (same shape the Arena place writes)
	local key=tostring(p.UserId);ledger:SetAsync(key,{ledger1={result="win",ranked=true,at=os.time()}});D.SetCurrency(p,"ArenaTokens",0)
	check("Claim pays the ledger and saves before clearing it",R.Claim(p)==1 and tokens()==C.Tokens.win and D.Get(p,"Arena.applied").ledger1==true)
	local left=ledger:GetAsync(key)
	check("Claimed match leaves the ledger",type(left)~="table" or left.ledger1==nil)
	check("Second claim pays nothing and prunes old ids",R.Claim(p)==0 and tokens()==C.Tokens.win and D.Get(p,"Arena.applied").ledger1==nil and D.Get(p,"Arena.applied").m7==nil)
end,debug.traceback)
pcall(function() ledger:RemoveAsync(tostring(p.UserId)) end)
D.ImportJSON(p,original);F.Set("AutoSave",autosave);D.SaveNow(p)
local o=game.HttpService:JSONDecode(original)
local restored=D.GetCurrency(p,"ArenaTokens")==(o.Currencies.ArenaTokens or 0) and D.Get(p,"Arena.rp")==o.Arena.rp and D.Get(p,"Arena.season")==o.Arena.season and D.Get(p,"Meta.AdminTouched")==o.Meta.AdminTouched and D.GetCurrency(p,"Gems")==o.Currencies.Gems
workspace:SetAttribute("ArenaRewardResults",game.HttpService:JSONEncode({passed=ok and restored,restored=restored,checks=results,error=not ok and err or nil}))
print("[ArenaRewardScenario]",ok and "passed" or err,#results,"restored",restored)
