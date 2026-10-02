local C=require(script.Parent.Config.LiveEvents);local W=require(script.Parent.Config.Weather)
local M={}
function M.Build(sequence,message,now,userId)
 if type(sequence)~="table" or #sequence<1 or #sequence>C.MaxSteps or type(message)~="string" or #message>240 then return nil,"Invalid sequence or message" end
 local rows={};local cursor=now+C.StartDelay
 for k in sequence do if type(k)~="number" or k%1~=0 or k<1 or k>#sequence then return nil,"Entries must be contiguous" end end
 for _,r in sequence do
  if type(r)~="table" or not W.ById[r.id] or r.id=="Clear" or type(r.seconds)~="number" or r.seconds%1~=0 or r.seconds<C.MinSeconds or r.seconds>C.MaxSeconds then return nil,"Invalid weather or duration" end
  table.insert(rows,{id=r.id,startAt=cursor,endsAt=cursor+r.seconds});cursor+=r.seconds
 end
 if cursor-now-C.StartDelay>C.MaxTotal then return nil,"Event exceeds duration limit" end
 return {rows=rows,message=message,startAt=now+C.StartDelay,endsAt=cursor,issuedAt=now,owner=userId}
end
function M.At(event,now)
 if not event or event.cancelled or now>=event.endsAt then return nil end
 local rows=event.rows
 for i,r in rows do
  if now<r.endsAt then
   local pending=now<r.startAt;local nextRow=pending and r or rows[i+1]
   return {id=pending and "Clear" or r.id,endsAt=pending and r.startAt or r.endsAt,nextId=nextRow and nextRow.id or "UTC",nextAt=nextRow and nextRow.startAt or event.endsAt,eventKey="Live:"..tostring(event.revision or event.issuedAt)..":"..i,message=event.message,live=true}
  end
 end
end
return M
