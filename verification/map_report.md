# Map verification report

Method borrowed from `STEAL_AN_EGG_ONE_SHOT_PROMPT.md` §0.5 (M4–M5): fixed-camera captures from Studio, scored by a fresh-context subagent that sees only the captures, the reference image and the written spec (no code, no conversation).

## Round 1 — 2026-10-03 (after Kako9 trees + mountain border)

Captures: `captures/round_1/` (reference: `reference_style.png`). Score **46/100**.

| # | Criterion | Score |
|---|---|---|
| 1 | Layout & proportions | 6 |
| 2 | Tree faithfulness to reference | 5 |
| 3 | Per-zone colour identity | 3 |
| 4 | Mountain border | 3 |
| 5 | Hub readability | 6 |
| 6 | Clutter / density | 3 |
| 7 | Player-height composition | 5 |
| 8 | Retro style consistency | 5 |
| 9 | Scale vs avatar | 6 |
| 10 | Polish | 4 |

Blocking issues reported:
- Zones read as confetti: the TreeKit 55/30/15 own/neighbour/any-zone mix hides each ring's palette.
- Ring floors/lips do not follow the zone palettes (Glowcap reads dark green, every lip is lavender).
- Mountain border thin on the north/north-east; huge faces read flat.
- Tree canopies missing studs on side faces (reference has studs on every face).
- Zone 4 boss arena has no focal landmark; a wall blocks the view.
- Lighting has strong shadows/haze (not flat).

Applied after round 1 (only items inside this change):
- TreeKit parts get studs on all six faces (existing 1,470 trees updated in place).
- Mountain border: two rows on every slot (147 → ~200 rocks, 5,279 parts); continuous band around island + hub.

Not applied (design decisions for ArmZ): tree mix ratio (plan rule 55/30/15), ring floor/lip colours, tree density, boss arena dressing, hub layout, lighting technology, ring widths.

## Round 2 — 2026-10-03 (after ArmZ said continue)

Applied before capture: tree look mix 85/15 own/neighbour zone (1,187 trees rebuilt in place), Glowcap/Sakura/Bamboo floors in their palettes, Trail/boss floor/RotHedge follow each ring floor.
Captures: `captures/round_2/`. Fresh verifier score **53/100** (layout 7, trees 6, zone identity 6, mountains 4, hub 6, clutter 4, player view 4, retro 6, scale 5, polish 5).

Applied after round 2: mountains taller (front ×8–12, back ×1.6 → tops up to y≈89) and alternate two greys; Glowcap floor dark teal so it no longer matches Crystal Ridge's violet (`rings_34_after_fixes.jpg`).

Still open (design/balance, ArmZ to decide): mountain stud scale (Roblox studs do not scale with part size), Tall/Wide canopies reading as mushrooms, accent caps on most canopies, ground props, ring-1 tree height vs avatar, hub layout/altar/props, lighting.
