-- Deterministic merchant schedule/stock/price shared by server and UI.
local S=script.Parent
local C=require(S.Config.Merchant)
local Seeds=require(S.Config.Seeds)
local Eggs=require(S.Config.Eggs)
local GardenMath=require(S.GardenMath)
local PetMath=require(S.PetMath)
local M={}
-- Visit covering `now`, else nil plus the next arrival.
function M.Visit(now)
	local hour=math.floor((now-C.Offset)/C.Period);local startsAt=hour*C.Period+C.Offset
	if now<startsAt+C.Duration then return {key="utc:"..hour,seed=hour,endsAt=startsAt+C.Duration} end
	return nil,startsAt+C.Period
end
-- Weighted pick without replacement, seeded by the visit.
function M.Stock(seed)
	local random=Random.new((seed*48271+C.Seed)%2147483647);local pool=table.clone(C.Offers);local out={}
	for _=1,math.min(C.Slots,#pool) do
		local total=0;for _,o in pool do total+=o.weight end
		local roll=random:NextNumber()*total
		for i,o in pool do roll-=o.weight;if roll<=0 or i==#pool then table.insert(out,o.id);table.remove(pool,i);break end end
	end
	return out
end
function M.Price(id,zone)
	local o=C.ById[id]
	if o.kind=="seed" then return "Coins",math.floor(GardenMath.SeedPrice(o.item,zone)*o.mult) end
	if o.kind=="egg" then return "Coins",math.floor(PetMath.EggPrice(o.item)*o.mult) end
	return "Gems",o.gems
end
function M.Name(id)
	local o=C.ById[id]
	if o.kind=="seed" then return "Seeds "..Seeds.ById[o.item].name end
	if o.kind=="egg" then return Eggs.ById[o.item].name end
	return "Chests "..o.item.." LEVEL "..o.level
end
return M
