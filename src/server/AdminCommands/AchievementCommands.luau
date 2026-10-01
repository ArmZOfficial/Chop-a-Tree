return function(Admin,Achievement)
	Admin.Register({id="achievements.unlockall",tab="story",label="ปลด Achievement / ฉายาทั้งหมด",sub="ไม่เพิ่ม Gems; เป้าหมายถูกตัดจากอันดับ",color="Purple",usesTarget=true,marksTarget=true,run=function(ctx)
		for _,p in ctx.targets do Achievement.SetAll(p,true) end;return true,"ปลดความสำเร็จและฉายาแล้ว"
	end})
	Admin.Register({id="achievements.reset",tab="story",label="รีเซ็ต Achievement / ฉายา",sub="ไม่หัก Gems ที่รับไป; ใช้ทดสอบรับใหม่",color="Red",confirm=1,usesTarget=true,marksTarget=true,run=function(ctx)
		for _,p in ctx.targets do Achievement.SetAll(p,false) end;return true,"รีเซ็ตความสำเร็จแล้ว"
	end})
end
