--!strict
-- ย่อ/อ่านตัวเลขแบบเว่อร์ๆ (plan.md หัวข้อ 5.3, 14.5)
-- ทุกที่ในเกมต้องแสดงตัวเลขผ่านโมดูลนี้ → ถ้าวันหนึ่งเปลี่ยนเป็น BigNum แก้ที่เดียว

local NumberFormat = {}

local BASE = { "", "K", "M", "B", "T", "Qa", "Qi", "Sx", "Sp", "Oc", "No", "Dc" }
local UNITS = { "", "U", "D", "T", "Qa", "Qi", "Sx", "Sp", "Oc", "No" }
local TENS = { "", "Dc", "Vg", "Tg", "Qag", "Qig", "Sxg", "Spg", "Ocg", "Nog" }

-- สร้างตัวย่อต่อจาก Dc อัตโนมัติ: UDc, DDc, … Vg, UVg …
local SUFFIX: { string } = table.clone(BASE)
for tens = 1, #TENS - 1 do
	for unit = 0, #UNITS - 1 do
		local n = tens * 10 + unit -- 10^(3n+3)
		if n >= 11 then
			SUFFIX[n + 2] = UNITS[unit + 1] .. TENS[tens + 1]
		end
	end
end

local LOOKUP: { [string]: number } = {}
for i, s in SUFFIX do
	if s ~= "" then
		LOOKUP[string.lower(s)] = i - 1
	end
end

local function trim(s: string): string
	s = string.gsub(s, "(%.%d-)0+$", "%1")
	s = string.gsub(s, "%.$", "")
	return s
end

-- 1234 → "1.23K", 3e18 → "3Qi"
function NumberFormat.Short(n: number): string
	if n ~= n then
		return "NaN"
	end
	if n == math.huge then
		return "∞"
	end
	if n < 0 then
		return "-" .. NumberFormat.Short(-n)
	end
	if n < 1000 then
		return trim(string.format(n < 10 and "%.2f" or n < 100 and "%.1f" or "%.0f", n))
	end
	local e = math.floor(math.log10(n) / 3)
	local suffix = SUFFIX[e + 1]
	if suffix == nil then
		return string.format("%.2e", n)
	end
	local v = n / 10 ^ (3 * e)
	if v >= 999.995 then
		e += 1
		v /= 1000
		suffix = SUFFIX[e + 1]
		if suffix == nil then
			return string.format("%.2e", n)
		end
	end
	local digits = v >= 100 and "%.0f" or v >= 10 and "%.1f" or "%.2f"
	return trim(string.format(digits, v)) .. suffix
end

-- ใส่จุลภาค: 1234567 → "1,234,567" (ใช้กับตัวเลขไม่ใหญ่มาก)
function NumberFormat.Comma(n: number): string
	local s = string.format("%.0f", n)
	local out = string.reverse(s):gsub("(%d%d%d)", "%1,"):reverse()
	return (string.gsub(out, "^(-?),", "%1"))
end

-- อ่านข้อความเป็นตัวเลข: "1.5K", "3m", "2Qa", "1e30", "1,000" → number (nil ถ้าอ่านไม่ได้)
function NumberFormat.Parse(text: string): number?
	local s = string.gsub(string.lower(text), "[%s,_]", "")
	if s == "" then
		return nil
	end
	local direct = tonumber(s)
	if direct then
		return direct
	end
	local num, suf = string.match(s, "^([%-]?[%d%.]+)(%a+)$")
	if not num then
		return nil
	end
	local base = tonumber(num)
	local e = LOOKUP[suf :: string]
	if not base or not e then
		return nil
	end
	return base * 10 ^ (3 * e)
end

return NumberFormat
