# UI polish — 2026-10-03

Implemented and synced to Studio place `93479990217075`; not published.

## Result

- Shared `UIKit.ScrollEdges` adds 8px minimum canvas padding, reserves scrollbar space, and places fixed 24px gradients at overflowing edges. Full cards keep their outlines at the start/end; partial rows fade while scrolling. Scrolling still clips at its viewport, so rows cannot cover headings or footers. Admin tools and Roblox's backpack are excluded.
- Index categories stay above the list and show names/counts. Discovery hints appear once. Collected items sort first and retain real weapon previews; unknown items show a clear lock. Pages contain at most 12 desktop / 8 phone entries instead of building 380 previews. Previous/Next, category changes and page reset were clicked in Play.
- Garden has illustrated empty states, a countdown from `MerchantMath.Visit`, arrival/remaining-time cards, stock and currency icons, and short purchase rows. Full-price fruit limits remain visible below seed offers. Shop/Merchant phone tabs use the full width. Both absent and naturally arriving merchant states were checked.
- Inventory keeps its main selection simple. A detail dialog shows five named chest rarity percentages plus the separate Giant roll, or six weapon stat tiles. Odds still come from `Loot.Odds` with the existing luck calculation; weapon level, stars, speed, area, fuse cost and Rot stay available. Owned chests use a chest icon. Opening/closing the dialog was verified with native input.
- Pet grids use four columns on phones, with a 130px cell on the Pets tab so a complete first row fits. Garden and Shop purchase controls were enlarged for the notched phone's safe area. English chest/merchant captions scale within their bounds. Pet tier/place captions now use a translatable template.
- Existing Studs illustrations and 48 icons were reused. No new asset purchase/upload, gameplay schema, server intent, price, drop rate or paid transaction was introduced.

## Evidence

| Environment | Checks | Final result |
| --- | --- | --- |
| Desktop 1238×793 | Primary tabs, six Story tabs, Season/Rebirth, final 12-window audit and Index screenshot | OVER/OFF/SMALL 0 |
| iPhone 7 666×374 | Final Inventory, Garden, Pets and Shop tab clicks; Season/Rebirth, Settings/Arena layout | OVER/OFF/SMALL 0 |
| iPhone 17 Pro safe area 749×361 | Primary and Story tabs in EN/TH, category/page clicks, detail dialog native close, final corrected English captions and Garden/Shop buttons | OVER/OFF/SMALL 0 |
| iPad 6 1023×767 | 12-window layout audit with populated mock data | OVER/OFF/SMALL 0 |
| Scrolling | Start/middle/end mask state, geometry, padding, scrollbar inset and first grid row height in visible lists | 0 final failures |

`tools/ui/UIPolishHarness.server.luau` uses the existing ProfileStore.Mock backend. It snapshots/restores the profile and feature flags, disables autosave, supplies synthetic leaderboard data without OrderedDataStore access, and seeds disposable weapons/chests/eggs/pets/seeds. Finish/Restored completed before every Stop. The temporary `PolishUIQA` script was removed from Studio. Studio ended in Edit/default viewport with the original Main scripts enabled and mock-profile setting retained.

Final console contained the normal mock-profile/server-ready/ProfileStore API-availability messages and no runtime errors. All 204 Luau sources in `src`/`tools` compiled; locale extraction: 1,850 keys, 0 missing Thai, 96 retained unused keys; `git diff --check` passed. Nine changed runtime modules match Studio source after line-ending normalization. `gen_strings.py` writes LF consistently on Windows.

## Repeat checks and limits

- Run `UIAudit.luau` for bounds/text/touch targets, then `ScrollEdgeAudit.luau` for visible scrolls. Prime windows through their actual menu callbacks; an empty or hidden panel is not a passing populated-state test. UIAudit deliberately excludes children of clipping frames from OFF, so screenshots and the scrolling audit are also required.
- Native MCP mouse coordinates on the iPhone 17 Pro simulator are relative to the full 874×402 device, while `AbsolutePosition` uses the 749×361 safe area. Add `(62.5, 20.5)` to the GUI target center for this device. Verified against `UserInputService:GetMouseLocation` and the panel that actually opened; uncalibrated attempts were excluded.
- Studio temporarily stopped rendering every ViewportFrame, including a simple test cube. Restarting Play restored previews. This was also recorded in the earlier ChestOpening handoff. Actual collected weapon previews were inspected after restart; temporary probe objects disappeared on Stop.
- Device simulator and mouse input do not prove real touch inertia, portrait layout, physical gamepad use, live leaderboard storage, paid purchase completion or playtesting with children. PvP availability remains unchanged; Arena was checked for layout only.

The scrollbar/clip behavior follows Roblox's [scrolling-frame documentation](https://create.roblox.com/docs/ui/scrolling-frames). Model previews retain the native camera-based [ViewportFrame](https://create.roblox.com/docs/ui/viewport-frames) approach.
