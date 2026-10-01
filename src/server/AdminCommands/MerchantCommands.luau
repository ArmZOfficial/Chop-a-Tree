return function(Admin,M)
 Admin.Register({id="merchant.summon",tab="weather",label="เรียกพ่อค้าเร่ทันที",sub="เฉพาะเซิร์ฟนี้ 10 นาที • ของรอบใหม่",minLevel="Owner",run=function()
  M.Summon(require(game.ReplicatedStorage.Shared.Config.Merchant).SummonSeconds);return true,"พ่อค้าเร่มาแล้ว (เฉพาะเซิร์ฟนี้)"
 end})
 Admin.Register({id="merchant.dismiss",tab="weather",label="ยกเลิกพ่อค้าเร่ที่เรียก",sub="กลับตามตาราง UTC",minLevel="Owner",run=function() M.Summon(nil);return true,"กลับตาราง UTC แล้ว" end})
end
