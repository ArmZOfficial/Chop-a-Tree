# Studs theme — image prompts (ChatGPT)

Save results as PNG in this folder with the file name given; Claude slices, uploads and wires them.

## icons.png — 16 menu/system icons (replaces assets/ui/woodland-icons-v2.png)

Done 2026-10-03: generated in ChatGPT (1254 px), resized to 1024, uploaded as `rbxassetid://78845524834085`; bounds in `Config/UIIcons.luau`.

```
Create ONE square image, 1024x1024, transparent background (PNG with alpha), a 4x4 grid of 16 game UI icons
for a Roblox simulator game. Each icon sits centred in its own 256x256 cell with ~24 px empty margin and does
NOT touch neighbours. Style: bold flat cartoon icons like popular Roblox simulator games (Steal a Brainrot,
Pet Simulator): thick dark navy outline (#0E101C, ~10 px), bright saturated fills, one simple white gloss
highlight on the upper-left, soft inner shading, no text, no letters, no background shapes, no drop shadows
outside the outline. No wood, no leaves, no vines.
Row 1: backpack (orange), axe (steel head, red handle), egg (cream with blue spots), sprout in a small pot (green).
Row 2: shop stall basket (orange with blue handle), gift box (red with gold ribbon), open book (blue), crossed swords (silver, gold hilts).
Row 3: golden ticket (season pass), circular green arrows (rebirth), gear/cog (grey with orange centre), happy smiley face (yellow).
Row 4: camera (blue), two friends heads (orange and teal), key with a tag (gold, "codes"), gold trophy cup.
```

Order must stay as listed: it maps to `Config/UIIcons.luau` ids
`bag axe egg leaf / shop gift book arena / season cycle gear face / camera friends codes trophy`.
