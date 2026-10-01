-- Season Pass test tools. Every grant marks the target as admin-touched.
return function(Admin,Season)
 Admin.Register({id="season.xp",tab="shop",label="Season XP +1 เลเวล",minLevel="Owner",usesTarget=true,marksTarget=true,run=function(ctx)
  for _,p in ctx.targets do Season.AddXp(p,require(game.ReplicatedStorage.Shared.Config.Season).XpPerLevel) end;return true,"เพิ่ม Season XP แล้ว"
 end})
 Admin.Register({id="season.premium",tab="shop",label="สลับ Season Premium",minLevel="Owner",usesTarget=true,marksTarget=true,run=function(ctx)
  for _,p in ctx.targets do Season.SetPremium(p,not Season.State(p).premium) end;return true,"สลับ Season Premium"
 end})
 Admin.Register({id="season.reset",tab="shop",label="รีเซ็ต Season Pass",minLevel="Owner",usesTarget=true,marksTarget=true,run=function(ctx)
  for _,p in ctx.targets do Season.Reset(p) end;return true,"รีเซ็ต Season Pass แล้ว"
 end})
end
