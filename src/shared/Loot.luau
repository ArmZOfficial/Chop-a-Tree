local Weapons=require(script.Parent.Config.Weapons)
local Rarities=require(script.Parent.Config.Rarities)
local Config=require(script.Parent.Config.Chests)
local Balance=require(script.Parent.Balance)
local Loot={}
local pools={}
for _,r in Rarities.Order do pools[r]={} end
for _,w in Weapons.List do if not w.retired then table.insert(pools[w.rarity],w) end end

local function choose(weights,rng)
	local total=0; for _,v in weights do total+=v end
	local roll=rng:NextNumber()*total
	for i,v in weights do roll-=v; if roll<0 then return i end end
	return #weights
end

function Loot.Odds(rarity,level)
	local base=assert(Config.Weights[rarity],"Unknown chest rarity")
	local boost=math.clamp(1+(level-1)/Config.LevelStep,1,Config.MaxLevelBoost)
	local weights,total={},0
	for i,v in base do weights[i]=v*boost^(i-1); total+=weights[i] end
	for i,v in weights do weights[i]=v/total end
	return weights,math.min(Config.MaxGiantChance,Rarities.GiantChance[rarity]*(1+Config.GiantLevelBonus*(level-1)))
end

function Loot.Roll(chest,rng)
	local weights,giantChance=Loot.Odds(chest.rarity,chest.level)
	local rarity=Rarities.Order[choose(weights,rng)]
	local pool=pools[rarity]
	local weapon=pool[rng:NextInteger(1,#pool)]
	-- Each definition already occupies a point in its rarity's x1..x4 range.
	return {id=weapon.id,il=chest.zone,stars=1,giant=rng:NextNumber()<giantChance,rebirthDrop=chest.rebirthDrop or 0,roll=1,admin_spawned=chest.admin_spawned==true}
end

function Loot.SpotRarity(depth,rng)
	local weights={}
	for i,v in Config.SpotWeights do weights[i]=v*(1+math.clamp(depth or 0,0,1))^(i-1) end
	return Rarities.Order[choose(weights,rng)]
end

function Loot.Power(item)
	local def=Weapons.ById[item.id]
	if not def then return 0 end
	return Balance.WeaponPower({basePower=def.basePower*(item.roll or 1),itemLevel=item.il,stars=item.stars,giant=item.giant,rebirthDrop=item.rebirthDrop})
end

function Loot.Compatible(a,b)
	return a and b and a.id==b.id and a.il==b.il and a.stars==b.stars and a.giant==b.giant and (a.rebirthDrop or 0)==(b.rebirthDrop or 0)
end

function Loot.FuseCost(item)
	return Config.FuseBaseWood*Balance.ZoneScale(item.il)*Balance.Rot(item.rebirthDrop or 0)*item.stars
end

return Loot
