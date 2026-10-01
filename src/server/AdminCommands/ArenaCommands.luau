return function(Admin,A,R)
	Admin.Register({id="arena.state",tab="pvp",label="สถานะคิว Arena",usesTarget=true,run=function(ctx)
		local rows={};for _,p in ctx.targets do local s=A.State(p);table.insert(rows,p.Name..": "..(s.mode or "ไม่ได้เข้าคิว")..(s.transferring and " (กำลังส่ง)" or "")) end
		return true,table.concat(rows,"\n")
	end})
	Admin.Register({id="arena.leave",tab="pvp",label="ออกคิว Arena",usesTarget=true,run=function(ctx)
		local n=0;for _,p in ctx.targets do if A.Leave(p) then n+=1 end end;return n>0,"ออกคิว "..n.." คน"
	end})
	Admin.Register({id="arena.rank",tab="pvp",label="ดูแรงก์ PvP",usesTarget=true,minLevel="Tester",run=function(ctx)
		local rows={};for _,p in ctx.targets do local d=R.State(p);table.insert(rows,p.Name..": "..R.Rank(d.rp).." "..d.rp.." RP • ชนะ "..d.wins.." แพ้ "..d.losses) end
		return true,table.concat(rows,"\n")
	end})
	Admin.Register({id="arena.win",tab="pvp",label="จำลองชนะ Ranked",sub="ผ่าน ledger เดียวกับแมตช์จริง",usesTarget=true,marksTarget=true,run=function(ctx)
		for _,p in ctx.targets do R.Apply(p,{["admin-"..game:GetService("HttpService"):GenerateGUID(false)]={result="win",ranked=true}}) end
		return true,"+Tokens/RP ของการชนะ 1 แมตช์"
	end})
	Admin.Register({id="arena.resetRank",tab="pvp",label="รีเซ็ตแรงก์ซีซันนี้",usesTarget=true,confirm=1,run=function(ctx)
		for _,p in ctx.targets do R.Reset(p) end;return true,"รีเซ็ตแล้ว"
	end})
	Admin.Register({id="arena.claim",tab="pvp",label="รับผลแมตช์ค้าง",usesTarget=true,run=function(ctx)
		local n=0;for _,p in ctx.targets do n+=R.Claim(p) end;return true,"จ่าย "..n.." แมตช์"
	end})
end
