local S=game.ReplicatedStorage.Shared;local C=require(S.Config.LiveEvents);local Math=require(S.LiveEventMath)
return function(Admin,Live)
 Admin.Register({id="live.preview",tab="weather",label="View Live Event This server only",sub="Blossom → Golden → Aurora • 20 sec each",minLevel="Owner",run=function()
  local rows={};for _,r in C.Sequence do table.insert(rows,{id=r.id,seconds=20}) end
  Live.Preview(Math.Build(rows,C.Message,os.time(),game.CreatorId));return true,"Start Live Event Preview This server only"
 end})
 Admin.Register({id="live.previewstop",tab="weather",label="Stop Live Event Preview",minLevel="Owner",run=function() Live.Preview(nil);return true,"Preview stopped" end})
 Admin.Register({id="live.start",tab="weather",label="Live Event • All servers",sub="Blossom → Golden → Aurora • 2 min each",minLevel="Owner",confirm=2,color="Purple",run=function() return Live.StartEvent() end})
 Admin.Register({id="live.stop",tab="weather",label="Stop Live Event • All servers",minLevel="Owner",confirm=2,color="Red",run=function() return Live.Cancel() end})
end
