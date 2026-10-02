-- Run: ~/luau/luau tools/tests/test_chest_timeline.luau  (from the repo root)
local T = require("../../src/shared/ChestOpeningTimeline")
local fails, n = 0, 0
local function check(name, ok)
	n += 1
	if not ok then
		fails += 1
		print("FAIL " .. name)
	end
end
local function near(a, b)
	return math.abs(a - b) < 1e-6
end

-- Durations follow the rarity of the weapon won.
for rarity, total in { Common = 1.6, Rare = 2.4, Epic = 3.4, Legendary = 4.5, Mythic = 5.5 } do
	local p = T.Plan(rarity, "Full", false)
	check("total " .. rarity, near(p.total, total))
	check("4 phases " .. rarity, #p.steps == 4)
end
-- Phase order and contiguity.
local p = T.Plan("Epic", "Full", false)
for i, phase in { "Intro", "Charge", "Burst", "Reveal" } do
	check("order " .. phase, p.steps[i].phase == phase)
	if i > 1 then
		check("contiguous " .. phase, near(p.steps[i].start, p.steps[i - 1].start + p.steps[i - 1].duration))
	end
end
-- Giant adds to Reveal only in Full.
check("giant full", near(T.Plan("Rare", "Full", true).total, 2.4 + T.GiantExtra))
check("giant fast", near(T.Plan("Rare", "Fast", true).total, T.FastTotal))
-- Fast and Off.
check("fast mythic", near(T.Plan("Mythic", "Fast").total, 0.6))
local off = T.Plan("Mythic", "Off")
check("off empty", off.total == 0 and #off.steps == 0)
check("off at result", T.At(off, 0) == "Result")
-- Unknown inputs fall back safely.
check("bad mode", T.Plan("Rare", "Turbo").mode == "Full")
check("bad rarity", near(T.Plan("Godly", "Full").total, 1.6))
-- At / Skip.
local plan = T.Plan("Legendary", "Full", false)
local phase, prog = T.At(plan, 0)
check("at 0", phase == "Intro" and prog == 0)
phase = T.At(plan, plan.steps[3].start + 0.01)
check("at burst", phase == "Burst")
check("at end", T.At(plan, plan.total) == "Result")
for _, s in plan.steps do
	check("skip from " .. s.phase, T.At(plan, T.Skip(plan)) == "Result")
end
-- Best of a multi-open.
local best, giant = T.Best({ { rarity = "Common" }, { rarity = "Epic", giant = true }, { rarity = "Rare" } })
check("best", best == "Epic" and giant == true)
check("best empty", T.Best({}) == "Common")

print(string.format("%d/%d passed", n - fails, n))
if fails > 0 then
	error("chest timeline tests failed")
end
