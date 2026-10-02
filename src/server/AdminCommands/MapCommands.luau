local RS = game:GetService("RunService")
local Collection = game:GetService("CollectionService")
local S = game.ReplicatedStorage.Shared
local Zones = require(S.Config.Zones)
local Util = require(S.ZoneUtil)
local Data = require(script.Parent.Parent.Services.DataService)
local Zone = require(script.Parent.Parent.Services.ZoneService)
local Story = require(script.Parent.Parent.Services.StoryService)
local Day = require(script.Parent.Parent.Services.DayCycleService)
local Tree = require(script.Parent.Parent.Services.TreeService)
local Explorer = require(S.Config.Explorer)
local Event = require(script.Parent.Parent.Services.WorldEventService)
local Events = require(S.Config.WorldEvents)
local Travel = require(script.Parent.Parent.Services.TravelService)
return function(Admin)
	local function register(id,label,run,mutation)
		Admin.Register({id=id,tab="forest",label=label,minLevel="Tester",usesTarget=false,run=function(ctx)
			if mutation and not RS:IsStudio() then return false,"Map QA mutations require Studio" end
			return run(ctx)
		end})
	end
	register("zone.info","Zone Info",function(ctx)
		return true,"Zone Info",{text="Zone: "..tostring(Zone.GetZone(ctx.admin)).."\nUnlocked: "..table.concat(Data.Get(ctx.admin,"Progress.UnlockedZones") or {},",")}
	end)
	register("zone.tp","QA Teleport to Zone",function(ctx)
		local id=tonumber(ctx.args.text);local z=id and Zones.List[id]
		if not z then return false,"Enter zone 1–8" end
		if not table.find(Data.Get(ctx.admin,"Progress.UnlockedZones") or {},id) then return false,"Zone locked" end
		for _,spawn in Collection:GetTagged("ZoneSpawn") do if spawn:IsDescendantOf(workspace) and spawn:GetAttribute("Zone")==id and ctx.admin.Character then ctx.admin.Character:PivotTo(spawn:GetPivot()+Vector3.new(0,4,0));return true,z.name end end
		return false,"Missing spawn"
	end,true)
	register("zone.unlock","QA Unlock Zone / All",function(ctx)
		local id=tonumber(ctx.args.text)
		if ctx.args.text=="all" then for _,z in Zones.List do Story.UnlockZone(ctx.admin,z.id) end
		elseif id and Zones.List[id] then Story.UnlockZone(ctx.admin,id) else return false,"Enter 1–8 or all" end
		return true,"Zones unlocked"
	end,true)
	register("zone.bounds","QA Show / Hide Bounds",function(ctx)
		local existing=workspace:FindFirstChild("MapQABounds");if existing then existing:Destroy() end
		if ctx.args.text=="hide" then return true,"Bounds hidden" end
		if ctx.args.text~="show" then return false,"Enter show or hide" end
		local folder=Instance.new("Folder");folder.Name="MapQABounds";folder.Parent=workspace
		for _,z in Zones.List do for step=1,32 do
			local angle=step/32*math.pi*2;local p=Instance.new("Part");p.Anchored=true;p.CanCollide=false;p.CanQuery=false;p.CanTouch=false
			p.Size=Vector3.new(3,5,3);p.Position=Vector3.new(math.cos(angle)*z.outer,z.y+3,math.sin(angle)*z.outer);p.Material=Enum.Material.Neon;p.Color=z.colors.accent;p.Parent=folder
		end end
		return true,"32 outer-bound markers per zone; Zones.At remains authoritative"
	end,true)
	register("tree.respawn","QA Respawn Trees",function() for _,tree in Collection:GetTagged("Tree") do Tree.Reset(tree) end;return true,"Trees reset" end,true)
	register("tree.special","QA Special Tree",function(ctx)
		local model=Tree.Nearest(ctx.admin,14,false);if not model then return false,"Stand beside a healthy tree" end
		return Tree.SetSpecial(model,ctx.args.text),"GoldenTree/GiantTree/AncientTree/CursedTree"
	end,true)
	register("event.start","QA Start Map Event",function(ctx)
		local id,zone=(ctx.args.text or ""):match("^(%S+)%s*(%d*)$")
		return Event.StartEvent(id,tonumber(zone))
	end,true)
	register("event.stop","QA Stop Map Event",function() Event.Stop();require(script.Parent.Parent.Services.WeatherService).Force(nil);return true,"Local event stopped; weather override cleared" end,true)
	register("event.list","Map Event List",function() local out={};for _,def in Events.List do table.insert(out,def.id..(def.weather and " (existing weather owner, Zone 1)" or " (any zone)")) end;return true,"Events",{text=table.concat(out,"\n")} end)
	register("travel.test","Travel Eligibility (No Move)",function(ctx) return Travel.Check(ctx.admin,tonumber(ctx.args.text) or "Home") end)
	register("time.set","QA Set Time",function(ctx) return Day.Set(ctx.args.text~="auto" and ctx.args.text or nil),"Enter morning/noon/evening/night/auto" end,true)
	for _,kind in {"reset","fill"} do
		register("explorer."..kind,"QA Explorer "..kind,function(ctx)
			local id=tonumber(ctx.args.text);if not id or not Zones.List[id] then return false,"Enter zone 1–8" end
			local data=Data.Get(ctx.admin,"Explorer");if not data then return false,"Data not ready" end
			for _,def in Explorer.List do if def.zone==id then data.collected[def.id]=kind=="fill" and true or nil end end
			data.completed[tostring(id)]=kind=="fill" and true or nil;Data.Set(ctx.admin,"Explorer",data);return true,"Explorer updated"
		end,true)
	end
	register("map.dump","Validate Map Config",function()
		local ok,errors=Util.Validate();return ok,ok and "Zones valid" or "Zones invalid",{text=table.concat(errors,"\n")}
	end)
	register("perf.report","Map Performance Report",function()
		local rows={};local metrics=Zone.Report()
		table.insert(rows,string.format("Zone batch samples=%d mean=%.3fms peak=%.3fms",metrics.samples,metrics.meanMs,metrics.peakMs))
		for _,z in Zones.List do
			local region=Util.Resolve(z.region);local parts,particles,trees=0,0,0
			if region then for _,x in region:GetDescendants() do if x:IsA("BasePart") then parts+=1 elseif x:IsA("ParticleEmitter") then particles+=1 end end end
			for _,x in Collection:GetTagged("Tree") do if x:GetAttribute("Zone")==z.id and x:IsDescendantOf(workspace) then trees+=1 end end
			table.insert(rows,string.format("%s: parts=%d trees=%d particles=%d",z.key,parts,trees,particles))
		end
		return true,"Map Performance",{text=table.concat(rows,"\n").."\nZone timing excludes other services; device FPS needs a real playtest."}
	end)
end
