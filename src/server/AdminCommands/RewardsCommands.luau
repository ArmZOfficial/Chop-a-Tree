local Data=require(game.ServerScriptService.Server.Services.DataService)
return function(Admin,Daily)
	Admin.Register({id="rewards.dailyreset",tab="rewards",label="Reset Daily for Testing",sub="Repeatable; target excluded from rankings",confirm=1,usesTarget=true,marksTarget=true,run=function(ctx)
		for _,p in ctx.targets do Daily.Reset(p) end;return true,"Reset Daily done"
	end})
	Admin.Register({id="rewards.day7",tab="rewards",label="Set Daily Day 7",usesTarget=true,marksTarget=true,run=function(ctx)
		for _,p in ctx.targets do Data.Set(p,"Daily",{lastDay=math.floor(os.time()/86400),streak=7,claimedDay=-1}) end;return true,"Day 7 reward test ready"
	end})
	Admin.Register({id="rewards.codesreset",tab="rewards",label="Clear Code History for Testing",confirm=1,usesTarget=true,marksTarget=true,run=function(ctx)
		for _,p in ctx.targets do Data.Set(p,"Codes.redeemed",{}) end;return true,"Code history cleared"
	end})
	Admin.Register({id="rewards.boost",tab="rewards",label="Wood/Coins ×2 • 15 min",usesTarget=true,marksTarget=true,run=function(ctx)
		for _,p in ctx.targets do Data.Set(p,"Boosts",{Wood=os.time()+900,Coins=os.time()+900}) end;return true,"Test boost enabled"
	end})
	Admin.Register({id="rewards.boards",tab="rewards",label="View Leaderboard Status",run=function()
		local s=require(game.ServerScriptService.Server.Services.LeaderboardService).State();return true,"Season "..s.season.." / Global "..s.status..(s.studio and " / Studio store separate" or "")
	end})
end
