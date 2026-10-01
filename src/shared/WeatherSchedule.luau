-- UTC daily schedules: no network messaging or per-server random rolls.
local Config=require(script.Parent.Config.Weather)
local Schedule={}
local cache={}
local function dayRows(day)
	if cache[day] then return cache[day] end
	local rng=Random.new((day*69621+Config.Seed)%2147483647)
	local rows={};local cursor=day*86400;local finish=cursor+86400
	local total=0;for _,d in Config.List do total+=d.weight end
	while cursor<finish do
		local roll=rng:NextNumber()*total;local def
		for _,d in Config.List do roll-=d.weight;if roll<0 then def=d;break end end
		local eventAt=math.min(finish,cursor+rng:NextInteger(Config.ClearMin,Config.ClearMax))
		local ends=math.min(finish,eventAt+def.duration)
		table.insert(rows,{id=def.id,startAt=eventAt,endsAt=ends,clearAt=cursor})
		cursor=ends
	end
	cache[day]=rows;for key in cache do if math.abs(key-day)>1 then cache[key]=nil end end;return rows
end
function Schedule.At(now)
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
return Schedule
