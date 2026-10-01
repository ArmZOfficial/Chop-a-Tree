local Data=require(game.ServerScriptService.Server.Services.DataService)
local Config=require(game.ReplicatedStorage.Shared.Config.Rebirth)
return function(Admin,Rebirth)
	Admin.Register({id="rebirth.force",tab="rebirth",label="Rebirth ทันที (ข้ามบอส/Coins)",sub="รีเซ็ตเงิน/โซน/อัปเกรดฐานจริง ต้องจบ Run ก่อน",color="Red",confirm=2,usesTarget=true,marksTarget=true,run=function(ctx)
		local messages={};local all=true;for _,p in ctx.targets do local ok,msg=Rebirth.Perform(p,Data.Get(p,"Progress.Rebirth"),true);all=all and ok;table.insert(messages,p.Name..": "..msg) end
		return all,table.concat(messages,"\n")
	end})
	Admin.Register({id="rebirth.tokens",tab="rebirth",label="เพิ่ม 100 Rebirth Token",color="Green",usesTarget=true,marksTarget=true,run=function(ctx)
		for _,p in ctx.targets do Data.AddCurrency(p,"RebirthTokens",100) end;return true,"เพิ่ม Token แล้ว"
	end})
	Admin.Register({id="rebirth.skillsall",tab="rebirth",label="ปลดต้นไม้ทักษะทั้งหมด",color="Purple",usesTarget=true,marksTarget=true,run=function(ctx)
		for _,p in ctx.targets do Rebirth.SetSkills(p,true) end;return true,"ปลดทักษะสูงสุดแล้ว"
	end})
	Admin.Register({id="rebirth.skillsreset",tab="rebirth",label="รีเซ็ตทักษะ (ไม่คืน Token)",color="Slate",confirm=1,usesTarget=true,marksTarget=true,run=function(ctx)
		for _,p in ctx.targets do Rebirth.SetSkills(p,false) end;return true,"รีเซ็ตทักษะแล้ว"
	end})
	Admin.Register({id="rebirth.set",tab="rebirth",label="ตั้งจำนวน Rebirth",sub="พิมพ์จำนวนในช่องคำสั่ง; ไม่ให้ Token/ไม่รีเซ็ตของ",color="Orange",usesTarget=true,marksTarget=true,run=function(ctx)
		local n=tonumber(ctx.args.text);if not n or n~=n or n%1~=0 or n<0 or n>Config.MaxRebirth then return false,"พิมพ์จำนวนเต็ม 0–"..Config.MaxRebirth.." ในช่องคำสั่ง" end
		for _,p in ctx.targets do Data.Set(p,"Progress.Rebirth",n);Rebirth.Refresh(p) end;return true,"ตั้ง Rebirth "..n
	end})
end
