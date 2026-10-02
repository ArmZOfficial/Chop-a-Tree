# Chop a Tree — modular UI elements v1

36 original sprites in four transparent PNG atlases, plus five generated screen concepts. Source size 1254×1254; alpha verified 0–255. Bounds in sprites.json include small transparent padding; do not assume a regular grid. PROMPTS.md records built-in image_gen generation and refinement prompts.

- frames.png: wide/tall wood windows, menu tile, common/rare/epic/legendary/mythic cards, wood inset.
- controls.png: green/red/gold/blue/wood buttons, red X, green plus, gold lock, empty progress track.
- systems-spaced.png: chest, incubator, pet category, garden, watering can, seed pouch, season ticket, shrine, merchant.
- resources-spaced.png: Coins, Wood, Gems, Arena Token, quest book, trophy, shield, clock, empty plot.
- concepts/: Inventory, Garden, Pets/Incubator, Shop, Rewards. Layout/art references, not actual Studio screenshots. Counts/stats/items are illustrative; use current Config and actual item art at runtime.
- UX.md: audit of existing screens/tabs/actions, proposed layouts, states/mobile behavior, art mapping and assembly order.

Upload the four atlas PNGs as images in Roblox Studio. Use their actual image asset IDs with ElementAtlas.luau; pass the actual uploaded texture dimensions (Roblox may resize the source). The helper converts source bounds to ImageRectOffset/ImageRectSize and preserves aspect ratio. Text, prices, counters, item previews and progress fill remain live GUI objects. These atlases are prepared assets, not yet wired into runtime UIKit; current native UI is unchanged. Full concept images are references, not screen-sized UI backgrounds.

Assembly: wood window background → transparent content frame → colored rarity cards → item previews/live English labels → green purchase button → red close button at top right. Keep existing server callbacks. Inset and empty track are backgrounds, not complete controls. Full-sprite Fit preserves the painted edges; resizing a window to arbitrary proportions needs a separately verified slicing setup.
