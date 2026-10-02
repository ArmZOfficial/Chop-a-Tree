-- Shared pet/egg formulas so the server and UI show the same numbers.
local B=require(script.Parent.Balance)
local Pets=require(script.Parent.Config.Pets)
local Eggs=require(script.Parent.Config.Eggs)
local Base=require(script.Parent.Config.Base)
local M={}
function M.MutationMult(id) local m=id and Pets.Mutations[id];return m and m.mult or 1 end
function M.Income(pet)
	local def=Pets.ById[pet.id]
	return Pets.Income[def.rarity]*B.ZoneScale(pet.zone)*B.Rot(pet.rebirthDrop or 0)*M.MutationMult(pet.mutation)*(1+Pets.TierIncome*((pet.tier or 1)-1))
end
function M.Bonus(pet)
	local def=Pets.ById[pet.id]
	return Pets.Bonus[def.rarity]*Pets.ZoneBonus^(pet.zone-1)*(1+Pets.TierBuff*((pet.tier or 1)-1))
end
-- Multiplier from following pets; capped so boosts never stack past plan 17.1.6.
function M.Mult(pets,kind)
	local sum=0
	for _,pet in pets do local def=Pets.ById[pet.id];if def and def.buff==kind then sum+=M.Bonus(pet) end end
	if kind=="Speed" then return math.min(Pets.MaxSpeed,1+sum*Pets.SpeedScale) end
	return math.min(Pets.MaxBuff,1+sum)
end
function M.EggPrice(id) local def=Eggs.ById[id];return def.price*B.ZoneScale(def.zone) end
function M.HatchSpeed(level) return 1+Base.IncubatorStep*(level or 0) end
function M.LockSeconds(level) return Base.LockSeconds+Base.LockStep*(level or 0) end
function M.PenSlots(level) return Base.PenSlots+Base.PenStep*(level or 0) end
function M.TrapSlow(level) return Base.StealSlow*(1-Base.TrapSlowStep*(level or 0)) end
function M.GuardChance(level) return Base.GuardChanceStep*(level or 0) end
function M.MaxLevel(kind) return ({lock=Base.LockMaxLevel,incubator=Base.IncubatorMaxLevel,pen=Base.PenMaxLevel,trap=Base.TrapMaxLevel,guard=Base.GuardMaxLevel})[kind] end
function M.UpgradeCost(kind,level) return Base.UpgradeWood[kind]*((level or 0)+1)^2 end
function M.Weighted(pairs,random)
	local total=0;for _,row in pairs do total+=row[2] end
	local roll=random:NextNumber()*total
	for _,row in pairs do roll-=row[2];if roll<0 then return row[1] end end
	return pairs[#pairs][1]
end
-- Conveyor eggs are a UTC function, so every server shows the same belt.
function M.Belt(epoch)
	local rows={};for _,e in Eggs.List do if e.belt>0 then table.insert(rows,{e.id,e.belt}) end end
	return M.Weighted(rows,Random.new((epoch*7919+40261001)%2147483647))
end
function M.BeltWindow(now)
	local current=math.floor(now/Base.BeltSeconds);local out={}
	for epoch=current-Base.BeltVisible+1,current do
		table.insert(out,{epoch=epoch,id=M.Belt(epoch),leavesAt=(epoch+Base.BeltVisible)*Base.BeltSeconds})
	end
	return out
end
function M.Stealable(egg)
	return not egg.robux and not egg.done and not egg.carriedBy and egg.progress/Eggs.ById[egg.id].hatch<Base.SafeProgress
end
return M
