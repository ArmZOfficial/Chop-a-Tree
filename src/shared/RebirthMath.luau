local Config=require(script.Parent.Config.Rebirth)
local Balance=require(script.Parent.Balance)
local Math={}
function Math.RequiredZone(rebirth) return math.min(8,Config.FirstBossZone+rebirth) end
function Math.Cost(rebirth) return Config.CoinBase*Balance.ZoneScale(Math.RequiredZone(rebirth)-3)*Balance.Rot(rebirth) end
function Math.Tokens(rebirth) return rebirth+1 end
function Math.Rank(data,id,enabled)
	if not enabled then return 0 end
	local def=Config.ById[id];local rank=data and data.Rebirth and data.Rebirth.skills[id] or 0
	if not def or type(rank)~="number" or rank~=rank then return 0 end
	return math.clamp(math.floor(rank),0,def.max)
end
function Math.Mult(data,id,enabled) return 1+.5*Math.Rank(data,id,enabled) end
function Math.AutoReward(data,enabled) return math.min(.75,Balance.Get("AutoCutReward")+.05*Math.Rank(data,"AutoCut",enabled)) end
function Math.SkillCost(id,rank) local def=Config.ById[id];return def and rank<def.max and def.baseCost*(rank+1) or nil end
return Math
