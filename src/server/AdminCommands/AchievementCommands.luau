return function(Admin,Achievement)
	Admin.Register({id="achievements.unlockall",tab="story",label="Unlock All Achievements / Titles",sub="No Gems added; target excluded from rankings",color="Purple",usesTarget=true,marksTarget=true,run=function(ctx)
		for _,p in ctx.targets do Achievement.SetAll(p,true) end;return true,"Achievements and titles unlocked"
	end})
	Admin.Register({id="achievements.reset",tab="story",label="Reset Achievement / Title",sub="Keeps claimed Gems; allows reclaim testing",color="Red",confirm=1,usesTarget=true,marksTarget=true,run=function(ctx)
		for _,p in ctx.targets do Achievement.SetAll(p,false) end;return true,"Achievements reset"
	end})
end
