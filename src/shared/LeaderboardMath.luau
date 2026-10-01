-- OrderedDataStore requires integers. Log encoding preserves order up to 1e300
-- with about 2.4 ppm relative quantization for large values; near zero has absolute
-- quantization. Global display is explicitly approximate.
local M={}
function M.Encode(value)
	if type(value)~="number" or value~=value or value<=0 then return 1 end
	return 1+math.floor(math.log10(1+math.min(value,1e300))*1e6+.5)
end
function M.Decode(score)
	if score<=1 then return 0 end
	return 10^((score-1)/1e6)-1
end
function M.Sort(entries,metric,limit)
	local rows={};for _,entry in entries do if not entry.blocked then
		table.insert(rows,{userId=entry.userId,name=entry.name,value=entry.values[metric] or 0})
	end end
	table.sort(rows,function(a,b) return a.value>b.value or (a.value==b.value and a.userId<b.userId) end)
	while #rows>limit do table.remove(rows) end;return rows
end
return M
