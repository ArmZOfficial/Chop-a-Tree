return function(Admin,E)
 Admin.Register({id="emote.aura",tab="player",label="ออร่าโชว์อาวุธ",sub="ทดสอบสีธาตุอาวุธที่สวมอยู่",usesTarget=true,run=function(ctx)
  local n=0;for _,p in ctx.targets do if E.Showcase(p) then n+=1 end end;return n>0,"แสดงออร่า "..n.." คน (คูลดาวน์ 4 วิ)"
 end})
end
