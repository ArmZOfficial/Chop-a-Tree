# Rounded scroll edges, menu layout and Demo1 locomotion (2026-10-03)

Studio place `93479990217075`, universe `10768831527`. Not published.

## Design read and changes

Preserve the bright Studs game UI for children: GothamSSm Heavy, original icons, ink outlines, gold selection and red close buttons. Apply the requested `design-taste-frontend` skill's audit, spacing, shape consistency and interaction guidance to native Roblox UI. Its website stack/marketing rules do not apply. Design variance 3, motion intensity 4 for brief state feedback, visual density 4.

- Scroll gradients now round their own backgrounds with 14px corners, use a 28px fade and match the window's vertical fill. Rounding a transparent parent alone would leave its children square. Scroller/controller paths remain intact.
- Desktop secondary menus use four columns. Phone landscape shows all 12 menus in six columns/two rows; portrait uses three columns/four rows. The drawer reserves heading/close space and fits the safe area. The phone Menu control is a 126×62 icon/text button.
- The drawer has a dimming shade and an internal click blocker, rises above other HUDs, and hides the underlying menu controls. Existing callbacks, navigation labels and primary/secondary ownership remain.
- `Movement.LocomotionAnimation` uses `rbxassetid://103920925204515` for both default Animate walk/run entries. Preloading precedes the override; inaccessible assets preserve avatar locomotion. New characters and subsequent Animate ID updates receive the configured asset. Default idle/jump/climb/emotes and server speed ownership remain.
- Shared window/button motion is being handled in the concurrent chat **ปรับช่องกดด้านล่างให้น่าใช้**. Duplicate experimental window/button bindings from this chat were removed before sync; the current integration uses one `EntranceMotion` multiplier over `LayoutScale` and one `ButtonMotion` scale per button.

## Verified in mock Play

- Desktop 1238×793: native More open, close and Rebirth/Season selection. Drawer canvas equals its viewport, both fades hidden, shade active, main rail hidden, DisplayOrder 30. Twelve-window layout audit: OVER/OFF/SMALL 0.
- Notched iPhone 17 Pro 749×361: native Menu click using the safe-area offset, all 12 tiles visible with no overflowing canvas or fade. Native Rebirth/Season selection and close passed. Twelve-window layout audit: OVER/OFF/SMALL 0.
- Populated Rebirth start/middle/end: shared scroll-edge audit 0 failures on both desktop and phone. Desktop screenshot confirmed rounded top/bottom gradients over the moving cards.
- Initially Roblox denied Demo1 access. After the user confirmed access was granted, a new Play loaded the asset without permission errors. Both Animate entries use the requested ID; native W movement produces two blended tracks with Length 1.6s and nonzero weights. WalkSpeed 16; native Shift sprint changes it to 24 and track rate to approximately 1.34. After `LoadCharacterAsync`, both walk/run entries again use Demo1.
- Before access was granted, native walk/run retained the avatar's valid animation tracks (nonzero length); sprint still reached 24. This exercised the preload-failure fallback.

The existing `UIPolishHarness` uses ProfileStore.Mock, snapshots/restores data and flags, disables autosave and supplies synthetic boards. Its Finish/Restored completed before this chat's controlled stops. Other active chat sessions can independently start/stop the same Studio; check its state before each test and sync only fresh sources.

## Limits and repeat checks

Demo1 playback was proven on the current R15 avatar. R6, real mobile touch/gamepad and child playtesting remain unverified. Portrait menu geometry is implemented but needs a separate native device check. Shared motion's final evidence belongs to the hotbar chat's validation; do not replace its code while that chat is active.

Compile and source/fixture cleanup results are recorded in HANDOFF at completion. No new image was needed: existing Studs art supports these changes.

## Follow-up (same day, after review)

ArmZ rejected the rounded colour fades too: over bright cards they read as a muddy band, and their window colour never matched the ink panels behind lists. `UIKit.ScrollEdges` now keeps only padding, the scrollbar lane and clean clipping; `tools/ui/ScrollEdgeAudit.luau` checks that contract and flags any leftover overlay. Same pass: tab labels shrink to fit, More drawer height follows its tile rows, Season renders on every open. Desktop audit results are in HANDOFF.
