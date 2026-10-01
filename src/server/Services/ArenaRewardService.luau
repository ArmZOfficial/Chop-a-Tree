-- Pays Arena match results written by the Arena place (DataStore ledger) into the profile once per match id.
-- Ledger rows leave the store only after the profile save holds their ids, so a failed save is retried on the next join.
local DataStoreService=game:GetService("DataStoreService")
local C=require(game.ReplicatedStorage.Shared.Config.Arena)
local D=require(script.Parent.DataService)
local R={}
local store
function R.Season(now) return os.date("!%Y-%m",now or os.time()) end
function R.Rank(rp) local name=C.Ranks[1].name;for _,r in C.Ranks do if rp>=r.rp then name=r.name end end;return name end
function R.Reset(p,now) D.Set(p,"Arena",{season=R.Season(now),rp=0,wins=0,losses=0,applied=D.Get(p,"Arena.applied") or {}}) end
function R.Touch(p,now) if D.Get(p,"Arena.season")~=R.Season(now) then R.Reset(p,now) end end
function R.State(p) R.Touch(p);return D.Get(p,"Arena") end
-- entries: {[matchId]={result="win"|"draw"|"loss"|"left",ranked=boolean}}; returns how many were paid now.
function R.Apply(p,entries,now)
	R.Touch(p,now);local applied=table.clone(D.Get(p,"Arena.applied") or {});local paid=0
	for id,e in entries do
		if applied[id] or type(e)~="table" or C.Tokens[e.result]==nil then continue end
		applied[id]=true;paid+=1
		D.AddCurrency(p,"ArenaTokens",C.Tokens[e.result])
		if e.ranked==true then D.Set(p,"Arena.rp",math.max(0,D.Get(p,"Arena.rp")+C.RankPoints[e.result])) end
		if e.result=="win" then D.Increment(p,"Arena.wins",1) elseif e.result~="draw" then D.Increment(p,"Arena.losses",1) end
	end
	D.Set(p,"Arena.applied",applied);return paid
end
function R.Claim(p)
	if not store or not D.IsLoaded(p) then return 0 end
	local key=tostring(p.UserId)
	local ok,entries=pcall(store.GetAsync,store,key)
	if not ok then warn("[ArenaReward] Read failed: "..tostring(entries));return 0 end
	entries=type(entries)=="table" and entries or {}
	local paid=R.Apply(p,entries)
	local applied=table.clone(D.Get(p,"Arena.applied"));for id in applied do if entries[id]==nil then applied[id]=nil end end -- ids already gone from the ledger
	D.Set(p,"Arena.applied",applied)
	local ids={};for id in entries do if applied[id] then ids[id]=true end end
	if next(ids)==nil then return paid end
	local saved=D.SaveAndWait(p,function(data) local a=data and data.Arena and data.Arena.applied;if not a then return false end;for id in ids do if not a[id] then return false end end;return true end,30)
	if saved then
		pcall(store.UpdateAsync,store,key,function(old) if type(old)~="table" then return nil end;for id in ids do old[id]=nil end;return old end)
	end
	return paid
end
function R.Init()
	pcall(function() store=DataStoreService:GetDataStore("ArenaPending_v1"..(game:GetService("RunService"):IsStudio() and "_Studio" or "")) end)
	D.PlayerLoaded:Connect(function(p) R.Touch(p);task.spawn(R.Claim,p) end)
end
function R.Start() end
return R
