return function(Admin,A)
	Admin.Register({id="arena.state",tab="pvp",label="สถานะคิว Arena",usesTarget=true,run=function(ctx)
		local rows={};for _,p in ctx.targets do local s=A.State(p);table.insert(rows,p.Name..": "..(s.mode or "ไม่ได้เข้าคิว")..(s.transferring and " (กำลังส่ง)" or "")) end
		return true,table.concat(rows,"\n")
	end})
	Admin.Register({id="arena.leave",tab="pvp",label="ออกคิว Arena",usesTarget=true,run=function(ctx)
		local n=0;for _,p in ctx.targets do if A.Leave(p) then n+=1 end end;return n>0,"ออกคิว "..n.." คน"
	end})
end
