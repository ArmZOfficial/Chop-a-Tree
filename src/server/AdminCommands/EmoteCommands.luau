return function(Admin,E)
 Admin.Register({id="emote.aura",tab="player",label="Weapon Showcase Aura",sub="Test Equipped Weapon Element",usesTarget=true,run=function(ctx)
  local n=0;for _,p in ctx.targets do if E.Showcase(p) then n+=1 end end;return n>0,"Show Aura "..n.." players (Cooldown 4 sec)"
 end})
end
