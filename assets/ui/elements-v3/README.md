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

## Result card art (2026-10-03, ladder step 1: ChatGPT)

Generated with ChatGPT image generation (ArmZ's account, chat "Generate UI Frame Image"), downloaded as PNG with alpha.
Neutral silver so one image serves all five rarities: `ChestOpening` tints it with `ImageColor3`.

| File | Size | Roblox image asset | Use |
|---|---|---|---|
| `chests/card-frame.png` | 1254x1254 | original | |
| `chests/card-frame-1024.png` | 1024x1024 | `rbxassetid://115975654245049` | Result card / multi-open grid frame, 9-slice `Rect(300,300,724,724)`, `SliceScale 0.26` |
| `chests/ribbon.png` | 2172x724 | original | |
| `chests/ribbon-1024.png` | 1024x284 (cropped to content) | `rbxassetid://139487178872339` | LEGENDARY! / MYTHIC! banner; the text is a live label on top (EN/TH) |

Prompts:
- Frame: "one ornate fantasy UI frame for a game reward card, square 1024x1024, flat front view. Chunky stylized cartoon look
  like a Roblox simulator game: thick carved metal border with leaf and vine ornaments at the four corners and a small round
  gem socket at the top centre. LIGHT SILVER / WHITE metal only (neutral grey tones, no colour) so it can be tinted in-game.
  The inside of the frame is completely empty and transparent. Transparent background (PNG with alpha). No text, no
  characters, no shadow outside the frame. Border thickness about 12% of the width and symmetric on all four sides."
- Ribbon: "same style and same LIGHT SILVER / WHITE metal-and-cloth tones: one wide blank ribbon banner for a game reward
  title, 1536x512, flat front view, curled folded ends on both sides, a few small leaf ornaments at the ends. The ribbon face
  is empty (no text, no symbols). Transparent background (PNG with alpha), no shadow, nothing else in the image."

The 1024 versions were cropped/resized with Pillow (LANCZOS). No text or logos in either image.
