local Shared=game.ReplicatedStorage.Shared
local Balance=require(Shared.Balance)
local NF=require(Shared.NumberFormat)
local Collection=game:GetService("CollectionService")
local Data=require(script.Parent.Parent.Services.DataService)

return function(Admin,Run,Tree)
	local function register(id,label,fn,extra)
		local cmd={id=id,tab="forest",label=label,color="Green",usesTarget=true,marksTarget=true,run=fn}
		for k,v in extra or {} do cmd[k]=v end
		Admin.Register(cmd)
	end
	register("forest.start","Start Run",function(ctx)
		for _,p in ctx.targets do Run.Begin(p) end; return true,"Run started"
	end)
	register("forest.end","End Run & Return Home",function(ctx)
		for _,p in ctx.targets do Run.End(p,true) end; return true,"Run ended"
	end,{color="Red"})
	register("forest.level50","Run Level 50",function(ctx)
		for _,p in ctx.targets do if Data.IsLoaded(p) then Run.Begin(p); local r=Run.Get(p); r.Level=50; r.Exp=0; Run.Send(p) end end
		return true,"Set Run Level 50"
	end)
	register("forest.power","Power Test 10K",function(ctx)
		for _,p in ctx.targets do p:SetAttribute("AdminCutPower",1e4); Run.Send(p) end
		return true,"Power override 10K"
	end)
	register("forest.powerclear","Restore Calculated Power",function(ctx)
		for _,p in ctx.targets do p:SetAttribute("AdminCutPower",nil); Run.Send(p) end
		return true,"Power restored"
	end,{color="Blue"})
	for _,mode in {"AutoAttack","AutoCut"} do
		register("forest."..mode,"Toggle "..mode,function(ctx)
			for _,p in ctx.targets do Run.Begin(p); Run.SetMode(p,mode,not Run.GetModes(p)[mode]) end
			return true,"Toggle "..mode
		end)
	end
	register("forest.resettrees","Respawn All Trees",function()
		for _,m in Collection:GetTagged("Tree") do Tree.Reset(m) end
		return true,"Trees respawned"
	end,{usesTarget=false,color="Blue"})
	register("forest.cleartrees","Chop One Nearby Tree",function(ctx)
		for _,p in ctx.targets do Run.Begin(p); local tree=Tree.Nearest(p,14,false); if tree then Tree.Hit(p,tree) end end
		return true,"Chopped through the real system (range/Power/cooldown checks)"
	end)
	register("forest.clearzone","Fell All Trees in Zone",function(ctx)
		local count=0; for _,p in ctx.targets do Run.Begin(p); count+=Tree.ClearZone(p) end
		return true,"Fell trees "..count.." trees (admin spawned)"
	end,{color="Red",confirm=1})
	register("forest.stats","View Run Status",function(ctx)
		local out={}
		for _,p in ctx.targets do local r=Run.Get(p); if r then table.insert(out,p.Name..": Lv "..r.Level..", Power "..NF.Short(Run.Power(p))..", trees "..r.Trees..", Wood "..NF.Short(r.Wood)..", Coins "..NF.Short(r.Coins)) end end
		return true,"Run Status",{text=table.concat(out,"\n")}
	end,{marksTarget=false,minLevel="Tester"})
	local limits={RunMult={1,2},ExpBase={1,1e9},ExpGrowth={1.01,2},CritChance={0,1},CritMult={1,100},AutoCutReward={0.55,0.75},ExpRatio={0.01,10},WoodRatio={0.01,10},CoinRatio={0.01,10}}
	Admin.Register({id="balance.set",tab="balance",label="Settings Key Value",sub="Enter e.g. RunMult 1.1 in the text box",color="Teal",run=function(ctx)
		local text=ctx.args.text or ""
		local key,value=text:match("^(%S+)%s+(%S+)$")
		local n=value and NF.Parse(value)
		local bounds=key and limits[key]
		if not bounds or type(n)~="number" or n~=n or n<bounds[1] or n>bounds[2] then return false,"Invalid key/value: RunMult, ExpBase, ExpGrowth, CritChance, CritMult, AutoCutReward, ExpRatio, WoodRatio, CoinRatio" end
		Balance.SetOverride(key,n); return true,key.." = "..n.." (This server only)"
	end})
	Admin.Register({id="balance.restore",tab="balance",label="Restore Balance",color="Blue",run=function() Balance.ClearOverrides(); return true,"Original formula restored" end})
	Admin.Register({id="balance.view",tab="balance",label="View Live Formula",color="Teal",minLevel="Tester",run=function()
		local out={}; for key in limits do table.insert(out,key.." = "..Balance.Get(key)) end; table.sort(out)
		return true,"Balance Live",{text=table.concat(out,"\n")}
	end})
end
