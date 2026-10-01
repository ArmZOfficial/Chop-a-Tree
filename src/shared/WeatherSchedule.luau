-- UTC daily schedules: no network messaging or per-server random rolls.
local Config=require(script.Parent.Config.Weather)
local Schedule={}
local cache={}
local function dayRows(day)
	if cache[day] then return cache[day] end
	local rng=Random.new((day*69621+Config.Seed)%2147483647)
	local rows={};local cursor=day*86400;local finish=cursor+86400
	while cursor<finish do
		local eventAt=math.min(finish,cursor+rng:NextInteger(Config.ClearMin,Config.ClearMax))
		local hour=(eventAt%86400)/3600;local weekend=os.date("!*t",eventAt).wday;local weights,total={},0
		for _,d in Config.List do local weight=d.weight
			if d.nightOnly and hour>=6 and hour<18 then weight=0 end
			if d.rare and (weekend==1 or weekend==7) then weight*=Config.WeekendRareMult end
			weights[d.id]=weight;total+=weight
		end
		local roll=rng:NextNumber()*total;local def
		for _,d in Config.List do roll-=weights[d.id];if roll<0 then def=d;break end end
		local ends=math.min(finish,eventAt+def.duration)
		if def.nightOnly and hour<6 then ends=math.min(ends,day*86400+6*3600) end
		table.insert(rows,{id=def.id,startAt=eventAt,endsAt=ends,clearAt=cursor})
		cursor=ends
		if def.id=="Rain" and rng:NextNumber()<Config.RainbowChance and cursor<finish then
			local rainbowEnd=math.min(finish,cursor+Config.ById.Rainbow.duration)
			table.insert(rows,{id="Rainbow",startAt=cursor,endsAt=rainbowEnd,clearAt=cursor});cursor=rainbowEnd
		end
	end
	cache[day]=rows;for key in cache do if math.abs(key-day)>1 then cache[key]=nil end end;return rows
end
local function naturalAt(now)
	local day=math.floor(now/86400);local rows=dayRows(day)
	for i,row in rows do if now<row.endsAt then
		if now<row.startAt then
			local forecast=row.startAt==row.endsAt and dayRows(day+1)[1] or row
			return {id="Clear",endsAt=forecast.startAt,nextId=Config.ById[forecast.id].rare and "???" or forecast.id,nextAt=forecast.startAt,eventKey="Clear:"..forecast.startAt}
		end
		local nextRow=rows[i+1] or dayRows(day+1)[1]
		if nextRow.startAt==nextRow.endsAt then nextRow=dayRows(day+1)[1] end
		return {id=row.id,endsAt=row.endsAt,nextId=Config.ById[nextRow.id].rare and "???" or nextRow.id,nextAt=nextRow.startAt,eventKey=row.id..":"..row.startAt}
	end end
	return {id="Clear",endsAt=(day+1)*86400,nextId="???",nextAt=(day+1)*86400,eventKey="Clear:"..day}
end
function Schedule.At(now)
	local C=require(script.Parent.Config.WeatherEncounters)
	local start=math.floor(now/C.WorldPeriod)*C.WorldPeriod
	if now<start+C.WorldSeconds then
		local after=naturalAt(start+C.WorldSeconds)
		local nextAt=after.id=="Clear" and after.nextAt or start+C.WorldSeconds
		local nextId=after.id=="Clear" and after.nextId or (Config.ById[after.id].rare and "???" or after.id)
		return {id="RotInvasion",endsAt=start+C.WorldSeconds,nextId=nextId,nextAt=nextAt,eventKey="RotInvasion:"..start}
	end
	local s=naturalAt(now);local nextRot=start+C.WorldPeriod
	if s.endsAt>=nextRot then s.endsAt=nextRot end
	if s.nextAt>=nextRot then s.nextAt=nextRot;s.nextId="???" end
	return s
end
return Schedule
