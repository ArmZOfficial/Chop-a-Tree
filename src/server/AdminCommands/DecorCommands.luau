return function(Admin,Data,Decor)
	Admin.Register({id="decor.clear",tab="pets",label="Clear Base Decorations",sub="No Wood refund",color="Red",usesTarget=true,confirm=1,run=function(ctx)
		for _,p in ctx.targets do Data.Set(p,"Decor",{items={},next=Data.Get(p,"Decor.next")});Decor.Build(p) end
		return true,"Cleared"
	end})
end
