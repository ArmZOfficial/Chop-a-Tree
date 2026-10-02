--!strict
-- Chest opening cinematic timing (track J). Pure logic, no Roblox APIs: unit-tested by
-- tools/tests/test_chest_timeline.luau. Cosmetic only: the server has already saved the result.
-- Phases: Intro (chest flies in) → Charge (shake, glow) → Burst (lid, beam, shockwave) → Reveal
-- (weapon rises) → Result (card / grid, waits for the player). Length follows the rarity of the
-- weapon won, not of the chest. Modes: Full / Fast / Off (Settings.ChestAnimation).

local T = {}

T.Order = table.freeze({ "Common", "Rare", "Epic", "Legendary", "Mythic" })
T.Total = table.freeze({ Common = 1.6, Rare = 2.4, Epic = 3.4, Legendary = 4.5, Mythic = 5.5 })
T.Phases = table.freeze({ "Intro", "Charge", "Burst", "Reveal" })
T.Split = table.freeze({ Intro = 0.15, Charge = 0.35, Burst = 0.15, Reveal = 0.35 })
T.FastTotal = 0.6
T.GiantExtra = 0.4 -- longer Reveal for the GIANT! stamp (Full only)
T.Modes = table.freeze({ Full = true, Fast = true, Off = true })

export type Step = { phase: string, start: number, duration: number }
export type Plan = { steps: { Step }, total: number, mode: string, rarity: string, giant: boolean }

function T.Rank(rarity: string?): number
	for i, r in T.Order do
		if r == rarity then
			return i
		end
	end
	return 1
end

function T.Mode(mode: any): string
	return if type(mode) == "string" and T.Modes[mode] then mode else "Full"
end

function T.Plan(rarity: string?, mode: any, giant: boolean?): Plan
	local m = T.Mode(mode)
	local r = T.Order[T.Rank(rarity)]
	local steps: { Step } = {}
	if m == "Off" then
		return { steps = steps, total = 0, mode = m, rarity = r, giant = giant == true }
	end
	local base = if m == "Fast" then T.FastTotal else T.Total[r]
	local t = 0
	for _, phase in T.Phases do
		local d = base * T.Split[phase]
		if phase == "Reveal" and giant and m == "Full" then
			d += T.GiantExtra
		end
		table.insert(steps, { phase = phase, start = t, duration = d })
		t += d
	end
	return { steps = steps, total = t, mode = m, rarity = r, giant = giant == true }
end

-- Phase at time t: returns phase name and progress 0..1 within it; "Result" once finished.
function T.At(plan: Plan, t: number): (string, number)
	for _, s in plan.steps do
		if t < s.start + s.duration then
			return s.phase, math.clamp((t - s.start) / s.duration, 0, 1)
		end
	end
	return "Result", 1
end

-- Skipping always lands on the result (any phase, any mode).
function T.Skip(plan: Plan): number
	return plan.total
end

-- Multi-open: the cinematic plays for the best result; giant if any is giant.
function T.Best(results: { { rarity: string, giant: boolean? } }): (string, boolean)
	local best, giant = 1, false
	for _, r in results do
		best = math.max(best, T.Rank(r.rarity))
		giant = giant or r.giant == true
	end
	return T.Order[best], giant
end

return table.freeze(T)
