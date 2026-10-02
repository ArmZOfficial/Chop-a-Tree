local S=game.ReplicatedStorage.Shared
local Seeds=require(S.Config.Seeds)
local Mutations=require(S.Config.Mutations)
local WeatherConfig=require(S.Config.Weather)
return function(Admin,Garden,Weather)
	Admin.Register({id="seeds.demo",tab="garden",label="Grant All Seeds ×3",color="Green",usesTarget=true,marksTarget=true,run=function(ctx)
		for _,p in ctx.targets do for _,s in Seeds.List do Garden.GrantSeed(p,s.id,1,0,3,true) end;Garden.Send(p) end
		return true,"Test seeds granted"
	end})
	Admin.Register({id="garden.grow",tab="garden",label="Grow Garden",color="Green",usesTarget=true,marksTarget=true,run=function(ctx)
		for _,p in ctx.targets do Garden.MatureAll(p) end;return true,"Trees grown and fruit ready"
	end})
	for id in Mutations.Values do local mutation=id
		Admin.Register({id="garden."..mutation,tab="garden",label="Mutation: "..mutation,color="Purple",usesTarget=true,marksTarget=true,run=function(ctx)
			for _,p in ctx.targets do Garden.MutateAll(p,mutation) end;return true,"Add "..mutation.." done"
		end})
	end
	for _,def in WeatherConfig.List do local weather=def.id
		Admin.Register({id="weather."..weather,tab="weather",label=weather.." (This server 5 min)",color="Blue",run=function()
			Weather.Force(weather,300);return true,"Set weather for this server: "..weather
		end})
	end
	for _,e in require(game.ReplicatedStorage.Shared.Config.Events).List do local event=e
		Admin.Register({id="festival."..event.id,tab="weather",label="Festival "..event.name.." (This server 10 min)",color="Purple",run=function()
			Weather.PreviewFestival(event.id,600);return true,"Preview Festival "..event.name.." This server only"
		end})
	end
	Admin.Register({id="festival.clear",tab="weather",label="Stop Festival Preview",color="Green",run=function() Weather.PreviewFestival(nil);return true,"Actual date restored" end})
	Admin.Register({id="weather.utc",tab="weather",label="Restore UTC Schedule",color="Green",run=function() Weather.Force(nil);return true,"Shared weather schedule restored" end})
end
