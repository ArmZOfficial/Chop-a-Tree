local Data=require(game.ServerScriptService.Server.Services.DataService)
local Config=require(game.ReplicatedStorage.Shared.Config.Rebirth)
return function(Admin,Rebirth)
	Admin.Register({id="rebirth.force",tab="rebirth",label="Rebirth Instant (skip boss/Coins)",sub="Resets currencies/zones/base upgrades. End Run first",color="Red",confirm=2,usesTarget=true,marksTarget=true,run=function(ctx)
		local messages={};local all=true;for _,p in ctx.targets do local ok,msg=Rebirth.Perform(p,Data.Get(p,"Progress.Rebirth"),true);all=all and ok;table.insert(messages,p.Name..": "..msg) end
		return all,table.concat(messages,"\n")
	end})
	Admin.Register({id="rebirth.tokens",tab="rebirth",label="Add 100 Rebirth Token",color="Green",usesTarget=true,marksTarget=true,run=function(ctx)
		for _,p in ctx.targets do Data.AddCurrency(p,"RebirthTokens",100) end;return true,"Tokens added"
	end})
	Admin.Register({id="rebirth.skillsall",tab="rebirth",label="Unlock All Skills",color="Purple",usesTarget=true,marksTarget=true,run=function(ctx)
		for _,p in ctx.targets do Rebirth.SetSkills(p,true) end;return true,"All skills maxed"
	end})
	Admin.Register({id="rebirth.skillsreset",tab="rebirth",label="Reset Skills (no Token refund)",color="Slate",confirm=1,usesTarget=true,marksTarget=true,run=function(ctx)
		for _,p in ctx.targets do Rebirth.SetSkills(p,false) end;return true,"Skills reset"
	end})
	Admin.Register({id="rebirth.set",tab="rebirth",label="Set Rebirth Count",sub="Enter a count in the command box; no Tokens or item reset",color="Orange",usesTarget=true,marksTarget=true,run=function(ctx)
		local n=tonumber(ctx.args.text);if not n or n~=n or n%1~=0 or n<0 or n>Config.MaxRebirth then return false,"Enter an integer 0–"..Config.MaxRebirth.." in the command box" end
		for _,p in ctx.targets do Data.Set(p,"Progress.Rebirth",n);Rebirth.Refresh(p) end;return true,"Set Rebirth "..n
	end})
end
