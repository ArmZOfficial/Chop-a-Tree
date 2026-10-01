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
	register("forest.start","เริ่ม Run",function(ctx)
		for _,p in ctx.targets do Run.Begin(p) end; return true,"เริ่ม Run แล้ว"
	end)
	register("forest.end","จบ Run + กลับหมู่บ้าน",function(ctx)
		for _,p in ctx.targets do Run.End(p,true) end; return true,"จบ Run แล้ว"
	end,{color="Red"})
	register("forest.level50","เลเวลรอบ 50",function(ctx)
		for _,p in ctx.targets do if Data.IsLoaded(p) then Run.Begin(p); local r=Run.Get(p); r.Level=50; r.Exp=0; Run.Send(p) end end
		return true,"ตั้งเลเวลรอบ 50"
	end)
	register("forest.power","Power ทดสอบ 10K",function(ctx)
		for _,p in ctx.targets do p:SetAttribute("AdminCutPower",1e4); Run.Send(p) end
		return true,"Power override 10K"
	end)
	register("forest.powerclear","คืน Power ตามสูตร",function(ctx)
		for _,p in ctx.targets do p:SetAttribute("AdminCutPower",nil); Run.Send(p) end
		return true,"คืน Power แล้ว"
	end,{color="Blue"})
	for _,mode in {"AutoAttack","AutoCut"} do
		register("forest."..mode,"เปิด/ปิด "..mode,function(ctx)
			for _,p in ctx.targets do Run.Begin(p); Run.SetMode(p,mode,not Run.GetModes(p)[mode]) end
			return true,"สลับ "..mode
		end)
	end
	register("forest.resettrees","เกิดต้นไม้ใหม่ทั้งหมด",function()
		for _,m in Collection:GetTagged("Tree") do Tree.Reset(m) end
		return true,"ต้นไม้เกิดใหม่แล้ว"
	end,{usesTarget=false,color="Blue"})
	register("forest.cleartrees","ฟันต้นไม้ใกล้ตัว 1 ต้น",function(ctx)
		for _,p in ctx.targets do Run.Begin(p); local tree=Tree.Nearest(p,14,false); if tree then Tree.Hit(p,tree) end end
		return true,"ฟันผ่านระบบจริงแล้ว (ตรวจระยะ/Power/คูลดาวน์)"
	end)
	register("forest.clearzone","ล้มต้นไม้ทั้งโซน",function(ctx)
		local count=0; for _,p in ctx.targets do Run.Begin(p); count+=Tree.ClearZone(p) end
		return true,"ล้มต้นไม้ "..count.." ต้น (ของแอดมิน)"
	end,{color="Red",confirm=1})
	register("forest.stats","ดูสถานะ Run",function(ctx)
		local out={}
		for _,p in ctx.targets do local r=Run.Get(p); if r then table.insert(out,p.Name..": Lv "..r.Level..", Power "..NF.Short(Run.Power(p))..", trees "..r.Trees..", Wood "..NF.Short(r.Wood)..", Coins "..NF.Short(r.Coins)) end end
		return true,"สถานะรอบ",{text=table.concat(out,"\n")}
	end,{marksTarget=false,minLevel="Tester"})
	local limits={RunMult={1,2},ExpBase={1,1e9},ExpGrowth={1.01,2},CritChance={0,1},CritMult={1,100},AutoCutReward={0.55,0.75},ExpRatio={0.01,10},WoodRatio={0.01,10},CoinRatio={0.01,10}}
	Admin.Register({id="balance.set",tab="balance",label="ตั้งค่า Key Value",sub="พิมพ์เช่น RunMult 1.1 ในช่องข้อความ",color="Teal",run=function(ctx)
		local text=ctx.args.text or ""
		local key,value=text:match("^(%S+)%s+(%S+)$")
		local n=value and NF.Parse(value)
		local bounds=key and limits[key]
		if not bounds or type(n)~="number" or n~=n or n<bounds[1] or n>bounds[2] then return false,"Key/ค่าไม่ถูกต้อง: RunMult, ExpBase, ExpGrowth, CritChance, CritMult, AutoCutReward, ExpRatio, WoodRatio, CoinRatio" end
		Balance.SetOverride(key,n); return true,key.." = "..n.." (เฉพาะเซิร์ฟนี้)"
	end})
	Admin.Register({id="balance.restore",tab="balance",label="คืน Balance เดิม",color="Blue",run=function() Balance.ClearOverrides(); return true,"คืนสูตรเดิมแล้ว" end})
	Admin.Register({id="balance.view",tab="balance",label="ดูสูตรสด",color="Teal",minLevel="Tester",run=function()
		local out={}; for key in limits do table.insert(out,key.." = "..Balance.Get(key)) end; table.sort(out)
		return true,"Balance สด",{text=table.concat(out,"\n")}
	end})
end
