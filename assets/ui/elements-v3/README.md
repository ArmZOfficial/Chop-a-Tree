# Chop a Tree — elements v3 (chests)

Created 2026-10-02 for master-prompt tracks D/E/J.

## What is here

| File | What | Source |
|---|---|---|
| `chests/chests-front.jpg` | All 5 chests, front view (Common → Mythic, left → right) | Studio `screen_capture` of `Shared.ChestBuilder.Build(1..5)` |
| `chests/chests-three-quarter.jpg` | Same row, 3/4 view | Studio `screen_capture` |

These are reference captures for the chest design bible (§9.7-F), not runtime textures.

## Generation ladder used (track E)

1. ChatGPT in a browser — not used: it needs an account login, which the prompt says to hand to the user. No image was generated there.
2. Claude Design — not needed for these assets.
3. **Roblox GUI / render — used.** Chest icons are rendered live by `Shared.ChestIconRenderer` (a ViewportFrame showing the `ChestBuilder` model at a 3/4 front view). This gives every rarity its own icon, with no uploads and no moderation wait. It replaces the old 2-sprite mapping (`rewards/rareChest`, `rewards/epicChest`) in the Inventory chest cards and detail view.
4. Placeholder — not needed.

## Still to make (track J)

These are built with Roblox GUI (Frame + UIGradient/UIStroke and rotated frames). Upload PNGs only if the GUI versions are not good enough:

- result-card frames in the 5 rarity colours
- per-rarity sunburst
- `LEGENDARY!` / `MYTHIC!` / `GIANT!` banners

## Chest models

| Level | Rarity | Name | Parts / budget |
|---|---|---|---|
| 1 | Common | Mossy Oak Chest | 23 / 25 |
| 2 | Rare | Runed Iron Chest | 28 / 35 |
| 3 | Epic | Gilded Gem Chest | 30 / 45 |
| 4 | Legendary | Crystal Dragon Chest | 37 / 60 |
| 5 | Mythic | Celestial Throne Chest | 61 / 80 |

- The lid is a sub-Model with its pivot on a hinge. `ChestBuilder.SetLid(model, 0..1)` opens it 110°; setting it back to 0 returns the lid exactly to its closed position.
- `FX` holds the floating parts, tagged with the attributes `Float`, `Orbit`, `Spin`, `Flicker` and `Stair`, plus `Hue` on the Mythic body. Track J's idle animator reads these attributes.
- Particles are not built in yet; they are track J work.
