local B=require(script.Parent.Balance)
local Seeds=require(script.Parent.Config.Seeds)
local Mutations=require(script.Parent.Config.Mutations)
local Config=require(script.Parent.Config.Garden)
local Math={}
function Math.Multiplier(tags)
	local special,sum=1,0
	for id,on in tags or {} do if on and Mutations.Values[id] then
		if Mutations.Special[id] then special=math.max(special,Mutations.Values[id]) else sum+=Mutations.Values[id] end
	end end
	return special*(1+sum) -- explicit stacking formula from plan 4.12.3
end
function Math.Apply(tags,id)
	if not Mutations.Values[id] then return end
	tags[id]=true
	for _,c in Mutations.Combos do if tags[c[1]] and tags[c[2]] then tags[c[1]]=nil;tags[c[2]]=nil;tags[c[3]]=true end end
end
function Math.Value(fruit)
	return Seeds.ById[fruit.id].value*B.ZoneScale(fruit.zone)*B.Rot(fruit.rebirthDrop or 0)*Math.Multiplier(fruit.mutations)
end
-- Capped mutation that decides a fruit's daily full-price quota (highest value wins).
function Math.CapKey(tags)
	local best;for id,on in tags or {} do if on and Config.SellCaps[id] and (not best or Mutations.Values[id]>Mutations.Values[best]) then best=id end end
	return best
end
-- Sale total with daily caps; returns total and the updated sold counts (input untouched).
function Math.SellQuote(fruits,sold)
	local total,after=0,table.clone(sold or {})
	for _,f in fruits do
		local value,key=Math.Value(f),Math.CapKey(f.mutations)
		local full=key and math.clamp(Config.SellCaps[key]-(after[key] or 0),0,f.count) or f.count
		if key then after[key]=(after[key] or 0)+f.count end
		total+=value*full+value*Config.OverCapMult*(f.count-full)
	end
	return total,after
end
function Math.SeedPrice(id,zone) return Seeds.ById[id].price*B.ZoneScale(zone) end
function Math.UpgradeCost(slots) return Config.UpgradeWood*(slots/Config.InitialSlots)^2 end
function Math.Key(tags)
	local list={};for id,on in tags or {} do if on then table.insert(list,id) end end;table.sort(list);return table.concat(list,"+")
end
function Math.Advance(plot,now,growth,online)
	local elapsed=math.max(0,now-plot.updatedAt)
	if not plot.mature then
		local live=online and math.min(elapsed,5) or 0
		plot.progress+=((elapsed-live)+live*growth)*(plot.watered and Config.WaterGrowth or 1)
		if plot.progress>=Seeds.ById[plot.id].grow then plot.progress=Seeds.ById[plot.id].grow;plot.mature=true;plot.nextFruitAt=now end
	end
	plot.updatedAt=now
end
return Math
