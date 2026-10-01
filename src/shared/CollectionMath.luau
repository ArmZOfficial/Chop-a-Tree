local Config=require(script.Parent.Config.Progression)
local Rebirth=require(script.Parent.RebirthMath)
local Weapons=require(script.Parent.Config.Weapons);local Pets=require(script.Parent.Config.Pets)
local Seeds=require(script.Parent.Config.Seeds);local Mutations=require(script.Parent.Config.Mutations)
local M={Catalog={weapons={},pets={},seeds={},mutations={}},Totals={}}
for _,w in Weapons.List do M.Catalog.weapons[w.id]=true end
for _,p in Pets.List do M.Catalog.pets[p.id]=true end
for _,s in Seeds.List do M.Catalog.seeds[s.id]=true end
for id in Mutations.Values do M.Catalog.mutations[id]=true end
for id in Pets.Mutations do M.Catalog.mutations[id]=true end
for cat,ids in M.Catalog do local n=0;for _ in ids do n+=1 end;M.Totals[cat]=n end
function M.Counts(data)
	local out={};local index=data.Index or {}
	for cat,ids in M.Catalog do local n=0;for id in ids do if index[cat] and index[cat][id]==true then n+=1 end end;out[cat]={have=n,total=M.Totals[cat]} end
	return out
end
function M.Bonus(data,kind,enabled)
	if not enabled then return 0 end
	local done=data.Index and data.Index.done or {}
	for cat,def in Config.Index do if def.kind==kind and done[cat]==true then return def.bonus end end
	return 0
end
function M.Permanent(data,kind,rebirthOn,indexOn)
	return math.min(Config.PermanentCap,Rebirth.Mult(data,kind,rebirthOn)+M.Bonus(data,kind,indexOn))
end
function M.Luck(data,rebirthOn,indexOn)
	return math.min(Config.LuckCap,.125*Rebirth.Rank(data,"Luck",rebirthOn)+M.Bonus(data,"Luck",indexOn))
end
function M.AchievementProgress(data,def)
	local value=0
	if def.kind=="Rebirth" then value=data.Progress.Rebirth
	elseif def.kind=="Index" then for cat in Config.Index do if data.Index.done[cat]==true then value+=1 end end
	else value=data.Stats[def.stat] or 0 end
	return math.clamp(value,0,def.need)
end
return M
