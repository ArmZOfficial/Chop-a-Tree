-- Test passes/products without Robux. Every grant marks the target as admin-touched.
local C=require(game.ReplicatedStorage.Shared.Config.Products)
return function(Admin,M,D)
 for _,pass in C.Passes do local key=pass.key
  Admin.Register({id="pass."..key,tab="shop",label="Toggle Game Pass: "..pass.name,minLevel="Owner",usesTarget=true,marksTarget=true,run=function(ctx)
   for _,p in ctx.targets do M.SetPass(p,key,not M.Owns(p,key)) end;return true,"Toggle "..pass.name
  end})
 end
 for _,row in C.Products do local key=row.key
  Admin.Register({id="product."..key,tab="shop",label="Grant: "..row.name,minLevel="Owner",usesTarget=true,marksTarget=true,run=function(ctx)
   for _,p in ctx.targets do if D.IsLoaded(p) then M.Grant(p,key) end end;return true,"Grant "..row.name
  end})
 end
 Admin.Register({id="shop.serverluck.clear",tab="shop",label="Cancel Server Luck",minLevel="Owner",run=function()
  game.ReplicatedStorage:SetAttribute("ServerLuckUntil",0);return true,"Canceled"
 end})
end
