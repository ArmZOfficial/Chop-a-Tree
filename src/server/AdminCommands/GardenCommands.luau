local S=game.ReplicatedStorage.Shared
local Seeds=require(S.Config.Seeds)
local Mutations=require(S.Config.Mutations)
return function(Admin,Garden,Weather)
	Admin.Register({id="seeds.demo",tab="garden",label="ให้เมล็ดทุกชนิด ×3",color="Green",usesTarget=true,marksTarget=true,run=function(ctx)
		for _,p in ctx.targets do for _,s in Seeds.List do Garden.GrantSeed(p,s.id,1,0,3,true) end;Garden.Send(p) end
		return true,"ให้เมล็ดทดสอบแล้ว"
	end})
	Admin.Register({id="garden.grow",tab="garden",label="ทำให้สวนโตเต็ม",color="Green",usesTarget=true,marksTarget=true,run=function(ctx)
		for _,p in ctx.targets do Garden.MatureAll(p) end;return true,"ต้นไม้โตและผลพร้อมเก็บแล้ว"
	end})
	for id in Mutations.Values do local mutation=id
		Admin.Register({id="garden."..mutation,tab="garden",label="Mutation: "..mutation,color="Purple",usesTarget=true,marksTarget=true,run=function(ctx)
			for _,p in ctx.targets do Garden.MutateAll(p,mutation) end;return true,"เพิ่ม "..mutation.." แล้ว"
		end})
	end
	for _,id in {"Clear","Rain","Storm","Snow","Golden"} do local weather=id
		Admin.Register({id="weather."..weather,tab="weather",label=weather.." (เซิร์ฟนี้ 5 นาที)",color="Blue",run=function()
			Weather.Force(weather,300);return true,"เปลี่ยนอากาศเฉพาะเซิร์ฟนี้: "..weather
		end})
	end
	Admin.Register({id="weather.utc",tab="weather",label="กลับตาราง UTC",color="Green",run=function() Weather.Force(nil);return true,"กลับตารางอากาศร่วมทุกเซิร์ฟแล้ว" end})
end
