return function(Admin,E,D)
 Admin.Register({id="encounters.refresh",tab="weather",label="Update Weather Encounters",minLevel="Owner",run=function() E.Update();return true,"Stardust/special nests/world boss updated" end})
 Admin.Register({id="stardust.give",tab="weather",label="Stardust +20",minLevel="Owner",usesTarget=true,marksTarget=true,run=function(ctx)
  for _,p in ctx.targets do if D.IsLoaded(p) then D.AddCurrency(p,"Stardust",20) end end;return true,"Add Stardust 20"
 end})
end
