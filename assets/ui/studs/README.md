# Studs UI theme (2026-10-03)

Replaces the wood/woodland window art. Derived from the reference kit ArmZ put in `Asset 3d/`:

- `2.rbxl` — a Steal-a-Brainrot style place; its `StarterGui.MainUI` (Shop/Index/Gear/Sell windows,
  left button column, money counter) is the layout and colour reference.
- `Buttons.rbxm` — actually a zipped Figma file (`canvas.fig`): six glossy stud-textured buttons
  (orange, red, lime, violet, cyan, rainbow).
- `MEGA AURA PACK.rbxm`, `StudPack1.rbxl` — 3D aura/stud models, not UI.

The binary files were read with a small parser (LZ4 + Node `zlib.zstdDecompressSync` for zstd chunks);
nothing from them is inserted into the place.

## Where it lives

`src/shared/UIKit.luau` — `UIKit.Skin(parent, atlas, sprite)` keeps its old signature, but for the chrome
atlases (`window`, `detail`, `chrome`, `controls`, `cards`) it now builds one native `ImageLabel` named
`SurfaceArt`: fill + vertical `UIGradient`, `UIStroke`, `UICorner` and a tiled stud overlay. Illustration
atlases (`pets`, `garden`, `incubation`, `rewards`, `weapons`) still go through `UIKit.Art`.
Every system window inherits it, so no controller changes its layout.

## Tokens

| Token | Value |
|---|---|
| Stud overlay | `rbxassetid://136024762697460` (tile 88 px windows, 56 px controls), transparency .75–.8 |
| Window vignette | `rbxassetid://79723271062969`, transparency .72 |
| Heading font | GothamSSm Heavy (900), white, ink stroke |
| Body font | GothamSSm Bold |
| Ink (outline, inset panels) | `#0E101C`; inset panels use ink at 45–50 % transparency |
| Button | gradient light → base, hard 3D lip at 84 %, stroke = fill × 0.38, radius 12 |
| Selected tab / lit nav tile / today card | gold `#FFBA00` |
| Rarity cards | common `#96A0B0`, rare `#0096FF`, epic `#AA46FF`, legendary `#FFB000`, mythic `#FF2C60` |
| Slate buttons (`UI.Colors.Slate`) | flat ink "inert" style: info rows and unavailable actions |

Window body / title plate per ScreenGui (`UIKit.Windows`):

| ScreenGui | Body | Plate |
|---|---|---|
| InventoryHUD | blue `#0084FF` | gold |
| PetHUD | purple `#A048FF` | pink |
| GardenHUD | green `#2EB83C` | yellow |
| ShopHUD | orange `#F35900` | red |
| RewardsHUD | raspberry `#F0325A` | gold |
| StoryHUD | teal `#00A8BE` | gold |
| SeasonHUD | amber `#FFA000` | violet |
| RebirthHUD | indigo `#5A46E6` | gold |
| ArenaHUD | crimson `#AA1E28` | gold |
| others (Settings, More) | slate blue `#40568C` | blue |

## Rules

- Buttons/badges pass their colour as attribute `Fill`; `fixed` styles (lit nav tiles) ignore it.
- `SurfaceArt` sits at its parent's ZIndex and the parent's content is shifted above it (keeps relative
  order), so skins work in Sibling and Global ScreenGuis and when skinned before parenting.
- Padded windows keep content row 0..36 for the heading (`UIKit.Window`); their own rows start below.
- The two stud textures belong to other creators (public, load in this place); if either is ever removed,
  upload our own tile and change the two constants at the top of the theme block.
