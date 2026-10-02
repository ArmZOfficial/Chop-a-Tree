-- Season Pass test tools. Every grant marks the target as admin-touched.
return function(Admin,Season)
 Admin.Register({id="season.xp",tab="shop",label="Season XP +1 Level",minLevel="Owner",usesTarget=true,marksTarget=true,run=function(ctx)
  for _,p in ctx.targets do Season.AddXp(p,require(game.ReplicatedStorage.Shared.Config.Season).XpPerLevel) end;return true,"Season XP added"
 end})
 Admin.Register({id="season.premium",tab="shop",label="Toggle Season Premium",minLevel="Owner",usesTarget=true,marksTarget=true,run=function(ctx)
  for _,p in ctx.targets do Season.SetPremium(p,not Season.State(p).premium) end;return true,"Toggle Season Premium"
 end})
 Admin.Register({id="season.reset",tab="shop",label="Reset Season Pass",minLevel="Owner",usesTarget=true,marksTarget=true,run=function(ctx)
  for _,p in ctx.targets do Season.Reset(p) end;return true,"Reset Season Pass done"
 end})
end
