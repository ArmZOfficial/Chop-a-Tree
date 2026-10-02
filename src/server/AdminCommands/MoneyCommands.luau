--!strict
-- แท็บ "เงิน & ค่าสถานะ" — เสก/ตั้งค่า/ลบ ทุกสกุลเงิน
-- UI แท็บนี้เป็นแบบพิเศษ (แถวละสกุลเงิน) จึงซ่อนปุ่มทั่วไปไว้ (hidden)

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Currencies = require(Shared.Config.Currencies)
local NumberFormat = require(Shared.NumberFormat)

local MAX = 1e300

local function readArgs(ctx): (string?, number?, string?)
	local id = ctx.args.currency
	if type(id) ~= "string" or not Currencies.ById[id] then
		return nil, nil, "Unknown currency"
	end
	local amount = ctx.args.amount
	if type(amount) == "string" then
		amount = NumberFormat.Parse(amount)
	end
	if type(amount) ~= "number" or amount ~= amount or amount < 0 then
		return nil, nil, "Invalid amount"
	end
	return id, math.min(amount, MAX), nil
end

return function(Admin, DataService)
	local function eachLoaded(ctx, fn: (Player) -> ()): number
		local n = 0
		for _, t in ctx.targets do
			if DataService.IsLoaded(t) then
				fn(t)
				n += 1
			end
		end
		return n
	end

	Admin.Register({
		id = "money.add",
		tab = "money",
		label = "Grant Currency",
		hidden = true,
		usesTarget = true,
		marksTarget = true,
		run = function(ctx)
			local id, amount, err = readArgs(ctx)
			if err then
				return false, err
			end
			eachLoaded(ctx, function(p)
				DataService.AddCurrency(p, id, amount)
			end)
			return true, string.format("+%s %s", NumberFormat.Short(amount :: number), Currencies.ById[id :: string].label)
		end,
	})
	Admin.Register({
		id = "money.set",
		tab = "money",
		label = "Set Currency",
		hidden = true,
		usesTarget = true,
		marksTarget = true,
		run = function(ctx)
			local id, amount, err = readArgs(ctx)
			if err then
				return false, err
			end
			eachLoaded(ctx, function(p)
				DataService.SetCurrency(p, id, amount)
			end)
			return true, string.format("Set %s = %s", Currencies.ById[id :: string].label, NumberFormat.Short(amount :: number))
		end,
	})
	Admin.Register({
		id = "money.rich",
		tab = "money",
		label = "Set Rich",
		sub = "All currencies = 1Qi",
		color = "Orange",
		order = 1,
		usesTarget = true,
		marksTarget = true,
		run = function(ctx)
			eachLoaded(ctx, function(p)
				for _, c in Currencies.List do
					DataService.SetCurrency(p, c.id, 1e18)
				end
			end)
			return true, "All currencies = 1Qi"
		end,
	})
	Admin.Register({
		id = "money.zero",
		tab = "money",
		label = "Set Poor",
		sub = "All currencies = 0",
		color = "Red",
		order = 2,
		usesTarget = true,
		marksTarget = true,
		run = function(ctx)
			eachLoaded(ctx, function(p)
				for _, c in Currencies.List do
					DataService.SetCurrency(p, c.id, 0)
				end
			end)
			return true, "All currencies = 0"
		end,
	})
end
