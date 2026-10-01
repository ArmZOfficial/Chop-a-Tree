local Data=require(game.ServerScriptService.Server.Services.DataService)
return function(Admin,Daily)
	Admin.Register({id="rewards.dailyreset",tab="rewards",label="รีเซ็ต Daily สำหรับทดสอบ",sub="รับซ้ำได้; เป้าหมายถูกตัดจากอันดับ",confirm=1,usesTarget=true,marksTarget=true,run=function(ctx)
		for _,p in ctx.targets do Daily.Reset(p) end;return true,"รีเซ็ต Daily แล้ว"
	end})
	Admin.Register({id="rewards.day7",tab="rewards",label="ตั้ง Daily วันที่ 7",usesTarget=true,marksTarget=true,run=function(ctx)
		for _,p in ctx.targets do Data.Set(p,"Daily",{lastDay=math.floor(os.time()/86400),streak=7,claimedDay=-1}) end;return true,"ทดสอบรางวัลวันที่ 7 ได้แล้ว"
	end})
	Admin.Register({id="rewards.codesreset",tab="rewards",label="ล้างประวัติโค้ดสำหรับทดสอบ",confirm=1,usesTarget=true,marksTarget=true,run=function(ctx)
		for _,p in ctx.targets do Data.Set(p,"Codes.redeemed",{}) end;return true,"ล้างประวัติโค้ดแล้ว"
	end})
	Admin.Register({id="rewards.boost",tab="rewards",label="Wood/Coins ×2 • 15 นาที",usesTarget=true,marksTarget=true,run=function(ctx)
		for _,p in ctx.targets do Data.Set(p,"Boosts",{Wood=os.time()+900,Coins=os.time()+900}) end;return true,"เปิดบูสต์ทดสอบแล้ว"
	end})
	Admin.Register({id="rewards.boards",tab="rewards",label="ดูสถานะ Leaderboard",run=function()
		local s=require(game.ServerScriptService.Server.Services.LeaderboardService).State();return true,"Season "..s.season.." / Global "..s.status..(s.studio and " / Studio store แยก" or "")
	end})
end
