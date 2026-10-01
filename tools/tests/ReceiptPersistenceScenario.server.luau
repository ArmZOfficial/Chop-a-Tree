-- Studio only. Set Phase="Save" and a unique ReceiptId before injection.
-- Reconnect, inject Phase="Replay" with the same ReceiptId and ExpectedGems.
-- Keep OriginalData outside Play; restore it and confirm SaveAndWait after Replay.
-- This synthetic receipt tests persistence; it is not a paid Roblox purchase.
assert(game.RunService:IsStudio())
local V=game.ServerScriptService.Server.Services
local D=require(V.DataService);local M=require(V.MonetizationService);local F=require(V.FeatureService)
local C=require(game.ReplicatedStorage.Shared.Config.Products)
local p=game.Players:GetPlayers()[1];assert(D.WaitForData(p,30))
local phase=script:GetAttribute("Phase");local id=script:GetAttribute("ReceiptId")
assert((phase=="Save" or phase=="Replay") and type(id)=="string" and id:match("^codex%-"))
local flags={AutoSave=F.IsEnabled("AutoSave"),Leaderboard=F.IsEnabled("Leaderboard")}
F.Set("AutoSave",false);F.Set("Leaderboard",false)
local info={PlayerId=p.UserId,ProductId=C.ProductByKey.gems100.id,PurchaseId=id}
local save=D.SaveAndWait
local ok,err=xpcall(function()
 if phase=="Save" then
  assert(D.Get(p,"Purchases.receipts")[id]==nil,"Use a new ReceiptId")
  script:SetAttribute("OriginalData",D.ExportJSON(p))
  local expected=D.GetCurrency(p,"Gems")+100;script:SetAttribute("ExpectedGems",expected)
  D.SaveAndWait=function() return false end
  for _=1,2 do
   assert(M.ProcessReceipt(info)==Enum.ProductPurchaseDecision.NotProcessedYet)
   assert(D.GetCurrency(p,"Gems")==expected,"Failed-save retry paid twice")
  end
  D.SaveAndWait=save
 else
  assert(D.Get(p,"Purchases.receipts")[id],"Marker lost on reconnect")
  assert(D.GetCurrency(p,"Gems")==script:GetAttribute("ExpectedGems"),"Gems lost on reconnect")
 end
 assert(M.ProcessReceipt(info)==Enum.ProductPurchaseDecision.PurchaseGranted)
 assert(D.GetCurrency(p,"Gems")==script:GetAttribute("ExpectedGems"),"Replay paid twice")
end,debug.traceback)
D.SaveAndWait=save;for k,v in flags do F.Set(k,v) end
script:SetAttribute("Passed",ok);script:SetAttribute("Error",ok and "" or err)
script:SetAttribute("DataStoreState",D.DataStoreState());script:SetAttribute("Done",true)
