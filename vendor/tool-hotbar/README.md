# Tool hotbar (Creator Store asset)

**Full Custom Inventory System** by @supdoggyDev — Creator Store asset `73852738603629`
(https://create.roblox.com/store/asset/73852738603629/Full-Custom-Inventory-System), free, added 2026-10-03 at ArmZ's request.
It replaces Roblox's backpack bar with a custom hotbar and an optional backpack grid for `Tool`s.

Lives in Studio only: `StarterGui.ToolHotbar` (ScreenGui with `hotBar`, `Inventory`, `openButton`, and
`InventoryController` LocalScript → `SETTINGS` ModuleScript + `toolButton` slot template). It is **not** in the Rojo
tree or `tools/studio_sync_check.py`; re-insert the asset and re-apply the list below to rebuild it.

Review before use (SKILL "Creator Store"): 2 scripts, both client-side; no `require` by asset id, no HttpService,
no `loadstring`/`getfenv`, no remotes. The model's `READ ME` script and `ThumbnailCamera` were deleted.

## Changes from the original

`SETTINGS` (each marked `Chop a Tree:` in the source):
- `DEFAULT_COLOR` (70,45,30), `EQUIPPED_COLOR` (196,128,52) — wood theme.
- `INVENTORY_KEYBIND = nil`, `OPEN_BUTTON = false` — the game has at most two tools (weapon + watering can), so the
  backpack grid, its search box and the "open inventory" button stay off. Set them back to
  `Enum.KeyCode.Backquote` / `true` to enable the grid.
- Slot label shows `tool.ToolTip` (weapon name) instead of `tool.Name` ("ForestWeapon"), two lines.

`InventoryController`: unchanged (one header comment).

Instances: ScreenGui renamed `ToolHotbar`, `DisplayOrder 6`; `hotBar` is 56 px high at `(0.5, 0, 1, -6)` (the original
5 % height gave 36 px slots on phones); slot template: FredokaOne, dark 3 px stroke, 10 px corners, wrapped name.

## Game-side hooks

- `NavigationController` hides `ToolHotbar` while a window or the menu is open (it used to toggle Roblox's backpack bar).
- `GardenService`: the watering can's `ToolTip` is now "Watering Can" (it is the slot label).

Checked in Studio Play (mock profile): slot appears, click equips/unequips and highlights, hides under windows,
Roblox's bar stays off; 56x56 px slot below PLAY at 666x374. Not checked: number keys (the test harness cannot send
them), drag between slots, gamepad, weapon slot (mock profile had no weapon).
