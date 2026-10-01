-- Shared no-yield reward delivery for Daily/Codes. Definitions are server-owned.
local Data=require(script.Parent.DataService)
local Weapon=require(script.Parent.WeaponService)
local Reward={}
function Reward.Grant(p,reward,now,admin)
	if reward.gems then Data.AddCurrency(p,"Gems",reward.gems) end
	if reward.chest then local c=reward.chest;Weapon.GrantChest(p,c.rarity,c.level,1,c.count,admin==true) end
	if reward.boost then local b=reward.boost;local boosts=table.clone(Data.Get(p,"Boosts"))
		boosts[b.kind]=math.max(now,boosts[b.kind] or 0)+b.seconds;Data.Set(p,"Boosts",boosts)
	end
end
function Reward.Mult(p,kind,now)
	return (Data.Get(p,"Boosts."..kind) or 0)>(now or os.time()) and 2 or 1
end
function Reward.Init() end
function Reward.Start() end
return Reward
