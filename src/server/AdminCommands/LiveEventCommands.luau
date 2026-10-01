local S=game.ReplicatedStorage.Shared;local C=require(S.Config.LiveEvents);local Math=require(S.LiveEventMath)
return function(Admin,Live)
 Admin.Register({id="live.preview",tab="weather",label="ดู Live Event เฉพาะเซิร์ฟนี้",sub="ซากุระ → แสงทอง → ออโรรา อย่างละ 20 วิ",minLevel="Owner",run=function()
  local rows={};for _,r in C.Sequence do table.insert(rows,{id=r.id,seconds=20}) end
  Live.Preview(Math.Build(rows,C.Message,os.time(),game.CreatorId));return true,"เริ่มตัวอย่าง Live Event เฉพาะเซิร์ฟนี้"
 end})
 Admin.Register({id="live.previewstop",tab="weather",label="หยุดตัวอย่าง Live Event",minLevel="Owner",run=function() Live.Preview(nil);return true,"หยุดตัวอย่างแล้ว" end})
 Admin.Register({id="live.start",tab="weather",label="Live Event • ทุกเซิร์ฟ",sub="ซากุระ → แสงทอง → ออโรรา อย่างละ 2 นาที",minLevel="Owner",confirm=2,color="Purple",run=function() return Live.StartEvent() end})
 Admin.Register({id="live.stop",tab="weather",label="หยุด Live Event • ทุกเซิร์ฟ",minLevel="Owner",confirm=2,color="Red",run=function() return Live.Cancel() end})
end
