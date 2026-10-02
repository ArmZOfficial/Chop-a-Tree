# Chop a Tree — concept-matched elements v2

65 reusable image elements in 10 transparent PNGs, redrawn with built-in image_gen from the five generated screen concepts in elements-v1. Text/numbers/prices remain live Roblox GUI objects. This pack is prepared artwork, not an integrated or published UI and not a pixel-identical extraction of the concepts.

| File | Elements | Use |
|---|---:|---|
| window.png | 1 | Wide wood backplate with empty header and content surface |
| detail.png | 1 | Tall selected-item/detail surface |
| chrome.png | 9 | Nav normal/gold/green, tabs normal/gold/green, header plaque, info row, currency capsule |
| controls.png | 9 | Green/gold/red/disabled buttons, close, delete, ready/claimed badges, empty progress track |
| cards.png | 9 | Common/Rare/Epic/Legendary/Mythic, unknown, product, today, selected |
| incubation.png | 6 | Empty/growing/ready cradle, growing/ready egg, nest |
| garden.png | 6 | Empty/growing/ready plot, fruit, watering can, seed pouch |
| rewards.png | 9 | Three Gems illustrations, Rare/Epic chest, Wood/Luck boosts, key, gift |
| pets.png | 6 | Clover Bunny, Ember Fox, Honey Bee, Sun Deer, Meadow Wolf, Little Sun Drake |
| weapons-spaced.png | 9 | First nine existing weapon IDs from data/weapons.json; no new items |

Full sprite names/ID bindings, source dimensions and padded crop coordinates: sprites.json. Source dimensions vary: read the manifest; never assume a square source or a regular grid. PNG alpha is preserved. Image bounds are non-overlapping and inside the source; incubation alpha max254, other images max255. PROMPTS.md records generation and the weapon spacing refinement.

## Assemble

1. Upload the 10 PNGs as image assets; record each actual image ID and uploaded texture dimensions. Moderation and runtime loading still need checking.
2. ElementAtlas.luau creates independent ImageLabels/ImageButtons using ImageRect; it scales source crops to uploaded dimensions. Keep Fit and matching aspect ratios. Painting arbitrary proportions with Slice needs a separately verified setup.
3. Build window → transparent content container → tabs/detail/cards → actual item artwork → live English labels → actions/status/fill. Manifest safeAreas are conservative sprite-local heading/content rectangles, measured before display scaling.
4. Reuse existing nav/resource art from elements-v1 and woodland-icons-v2; preserve every existing callback, price lookup, owner/capacity check and confirmation.

Inventory: window + detail + rarity cards + actual weapon image + Equip/Fuse/Delete. Garden: selected plot + garden state + one contextual action. Incubator: cradle state + timer/ready badge + existing Place/Hatch flow. Shop: product cards + Gems/boost/key art + live prices. Rewards: today/normal card + reward image + claimed badge + Claim Today.

The six pet and nine weapon illustrations are a first catalog set, not all species/items. Other items retain their real previews/art until illustrated; do not substitute an incorrect species or weapon. Egg/plot states are generic UI illustrations, not new content. These PNGs do not replace world models or gameplay data.

## Verification / next work

Checked: 10 RGBA images with transparent alpha, 65 crop bounds and rectangle isolation, manifest IDs against current catalogs, helper Luau compilation. New art still needs import, actual Play composition, font/layout matching and phone/gamepad checks. Full-screen references/UX matrix remain in ../elements-v1/UX.md. No gameplay source changed in this pack.
