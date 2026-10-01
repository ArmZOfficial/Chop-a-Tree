local S=game.ReplicatedStorage.Shared
local Zones=require(S.Config.Zones)
local Weapons=require(S.Config.Weapons)
local Pets=require(S.Config.Pets)
local Seeds=require(S.Config.Seeds)
local Mutations=require(S.Config.Mutations)
local Services=game.ServerScriptService.Server.Services
local Data=require(Services.DataService)
local Run=require(Services.RunService)
return function(Admin,Quest,Boss)
	local built={};for _,z in Zones.List do if z.built then table.insert(built,z.id) end end
	Admin.Register({id="story.unlockall",tab="story",label="ปลดล็อกโซนที่สร้างแล้วทั้งหมด",sub="โซน "..table.concat(built,","),color="Green",usesTarget=true,marksTarget=true,run=function(ctx)
		for _,p in ctx.targets do Data.Set(p,"Progress.UnlockedZones",table.clone(built)) end;return true,"ปลดล็อกโซน "..table.concat(built,",")
	end})
	Admin.Register({id="story.lock",tab="story",label="ล็อกเหลือโซน 1",color="Slate",usesTarget=true,marksTarget=true,run=function(ctx)
		for _,p in ctx.targets do Data.Set(p,"Progress.UnlockedZones",{1}) end;return true,"เหลือโซน 1"
	end})
	Admin.Register({id="story.step",tab="story",label="ทำขั้นเควสหลักปัจจุบันให้เสร็จ",color="Blue",usesTarget=true,marksTarget=true,run=function(ctx)
		for _,p in ctx.targets do Quest.ForceStep(p);Quest.Send(p,true) end;return true,"ข้ามขั้นเควสแล้ว"
	end})
	for chapter=2,3 do local c=chapter
		Admin.Register({id="story.chapter"..c,tab="story",label="ข้ามไปบทที่ "..c,sub="ล้มบอส/จุดศาลเจ้าบทก่อนหน้าให้",color="Purple",usesTarget=true,marksTarget=true,run=function(ctx)
			for _,p in ctx.targets do
				local bosses,shrines,unlocked={},{},{}
				for z=1,c-1 do bosses[tostring(z)]=1;shrines[tostring(z)]=true end
				for z=1,c do table.insert(unlocked,z) end
				Data.Set(p,"Progress.Bosses",bosses);Data.Set(p,"Progress.Shrines",shrines);Data.Set(p,"Progress.UnlockedZones",unlocked)
				Data.Set(p,"Progress.StoryChapter",c);Data.Set(p,"Quests.main",{step=1,base=0});Quest.Check(p);Quest.Send(p,true)
			end
			return true,"ข้ามไปบทที่ "..c
		end})
	end
	Admin.Register({id="story.reset",tab="story",label="รีเซ็ตเนื้อเรื่อง",color="Red",confirm=1,usesTarget=true,marksTarget=true,run=function(ctx)
		for _,p in ctx.targets do Quest.ResetStory(p);Quest.Send(p,true) end;return true,"รีเซ็ตเนื้อเรื่องเป็นบทที่ 1"
	end})
	Admin.Register({id="boss.kill",tab="story",label="ล้มบอสโซนที่ยืนอยู่",sub="ต้องอยู่ใน Run ถึงจะได้รางวัล",color="Orange",run=function(ctx)
		local zone=Run.ZoneAt(ctx.admin);if not zone or not Boss.Get(zone) then return false,"ยืนในโซนที่มีบอสก่อน" end
		return Boss.Kill(ctx.admin,zone),"ล้มบอสโซน "..zone
	end})
	Admin.Register({id="boss.low",tab="story",label="บอสทุกตัว HP เหลือ 1%",color="Orange",run=function()
		for _,z in built do Boss.SetRatio(z,.01) end;return true,"บอส HP 1%"
	end})
	Admin.Register({id="index.all",tab="story",label="ปลด Index ทั้งหมด",sub="ไม่ให้ Gems",color="Teal",usesTarget=true,marksTarget=true,run=function(ctx)
		for _,p in ctx.targets do
			local idx={weapons={},pets={},seeds={},mutations={},done={weapons=true,pets=true,seeds=true,mutations=true}}
			for _,w in Weapons.List do idx.weapons[w.id]=true end;for _,x in Pets.List do idx.pets[x.id]=true end;for _,x in Seeds.List do idx.seeds[x.id]=true end
			for id in Mutations.Values do idx.mutations[id]=true end;for id in Pets.Mutations do idx.mutations[id]=true end
			Data.Set(p,"Index",idx);Quest.Send(p,true)
		end
		return true,"ปลด Index ครบแล้ว"
	end})
	Admin.Register({id="index.reset",tab="story",label="รีเซ็ต Index",color="Slate",usesTarget=true,marksTarget=true,run=function(ctx)
		for _,p in ctx.targets do Data.Set(p,"Index",{weapons={},pets={},seeds={},mutations={},done={}});Quest.Send(p,true) end;return true,"รีเซ็ต Index แล้ว"
	end})
	Admin.Register({id="quests.reroll",tab="story",label="รีเซ็ตเควสรายวัน/สัปดาห์",color="Blue",usesTarget=true,marksTarget=true,run=function(ctx)
		for _,p in ctx.targets do for _,kind in {"daily","weekly"} do Data.Set(p,"Quests."..kind,{key=-1,ids={},base={},claimed={}}) end;Quest.Send(p,true) end
		return true,"เควสรายวัน/สัปดาห์เริ่มนับใหม่"
	end})
	Admin.Register({id="quests.complete",tab="story",label="ทำเควสรายวัน/สัปดาห์ให้ครบ",color="Green",usesTarget=true,marksTarget=true,run=function(ctx)
		for _,p in ctx.targets do for _,kind in {"daily","weekly"} do
			local d=Quest.Side(p,kind);for id in d.base do d.base[id]=-1e6 end;Data.Set(p,"Quests."..kind,d)
		end;Quest.Send(p,true) end
		return true,"เควสรายวัน/สัปดาห์พร้อมรับรางวัล"
	end})
end
