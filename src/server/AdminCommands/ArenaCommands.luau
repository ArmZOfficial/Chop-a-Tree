return function(Admin,A,R)
	Admin.Register({id="arena.state",tab="pvp",label="Arena Queue Status",usesTarget=true,run=function(ctx)
		local rows={};for _,p in ctx.targets do local s=A.State(p);table.insert(rows,p.Name..": "..(s.mode or "Not queued")..(s.transferring and " (Transferring)" or "")) end
		return true,table.concat(rows,"\n")
	end})
	Admin.Register({id="arena.leave",tab="pvp",label="Leave Queue Arena",usesTarget=true,run=function(ctx)
		local n=0;for _,p in ctx.targets do if A.Leave(p) then n+=1 end end;return n>0,"Leave Queue "..n.." players"
	end})
	Admin.Register({id="arena.rank",tab="pvp",label="View PvP Rank",usesTarget=true,minLevel="Tester",run=function(ctx)
		local rows={};for _,p in ctx.targets do local d=R.State(p);table.insert(rows,p.Name..": "..R.Rank(d.rp).." "..d.rp.." RP • Wins "..d.wins.." Losses "..d.losses) end
		return true,table.concat(rows,"\n")
	end})
	Admin.Register({id="arena.win",tab="pvp",label="Simulate Ranked Win",sub="Uses the same ledger as a real match",usesTarget=true,marksTarget=true,run=function(ctx)
		for _,p in ctx.targets do R.Apply(p,{["admin-"..game:GetService("HttpService"):GenerateGUID(false)]={result="win",ranked=true}}) end
		return true,"+Tokens/RP for one match win"
	end})
	Admin.Register({id="arena.resetRank",tab="pvp",label="Reset Current Season Rank",usesTarget=true,confirm=1,run=function(ctx)
		for _,p in ctx.targets do R.Reset(p) end;return true,"Reset"
	end})
	Admin.Register({id="arena.claim",tab="pvp",label="Claim Pending Match Results",usesTarget=true,run=function(ctx)
		local n=0;for _,p in ctx.targets do n+=R.Claim(p) end;return true,"Pay "..n.." Matches"
	end})
end
