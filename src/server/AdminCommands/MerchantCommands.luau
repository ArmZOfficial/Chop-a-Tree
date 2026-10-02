return function(Admin,M)
 Admin.Register({id="merchant.summon",tab="weather",label="Spawn Merchant Now",sub="This server only 10 min • New stock",minLevel="Owner",run=function()
  M.Summon(require(game.ReplicatedStorage.Shared.Config.Merchant).SummonSeconds);return true,"Merchant arrived (this server only)"
 end})
 Admin.Register({id="merchant.dismiss",tab="weather",label="Cancel Spawned Merchant",sub="Restore UTC Schedule",minLevel="Owner",run=function() M.Summon(nil);return true,"UTC schedule restored" end})
end
