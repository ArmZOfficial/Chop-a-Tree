# UI/UX audit — track C (2026-10-02)

Studio Play with the Device Simulator + Controller Emulator, EN and TH. Measurements come from `tools/ui/UIAudit.luau`
(paste into `execute_luau`, datamodel Client): **OVER** = text that does not fit (`TextFits=false`, non-scaled),
**OFF** = element outside the viewport, **SMALL** = clickable control under 44 px on its short side (after UIScale).
Admin UI and Roblox's TouchGui are excluded. Windows are opened by setting `Visible` (same as their menu tile).

## Results after fixes

| Viewport (Studio device) | Lang | Window scale (960×650 windows) | OVER | OFF | SMALL (min px) |
|---|---|---|---|---|---|
| Desktop HD 1080 (1919×1079) | TH | 1.00 | 0 | 0 | Shop buy 40, Quests tabs 38, Season close 40 |
| Studio viewport (1238×793) | EN | 1.00 | 0 (Arena heading now scales) | 0 | same as above |
| Tablet iPad 6th gen (1023×768) | TH | 0.93 | 0 | 0 | Shop 37, Quests 38, Rewards 41, Season 40 |
| Phone iPhone XR (801×392 safe area) | TH/EN | 0.56 (was 0.50) | 0 | 0 | 21–37 in every large window |
| Small phone iPhone 7 (666×374) | TH | 0.45 | 0 | 0 | 17–38 |

Gamepad (Controller Emulator): Select = Roblox UI navigation; opening a window selects its first control
(Inventory → Weapons tab, Shop → Passes tab, Settings → Music toggle), gold outline marks the selection, **B** closes
the open window or menu and clears the selection. Verified live.

## Fixed in this track

- [x] Window titles were cut off ("Setti…", Arena, "Choose a Menu", long Thai titles): `UIKit.Window` heading now
      scales down (46 → 18 px) and small windows use the full title strip up to the close button.
      Gotcha: `TextWrapped=false` clears `TextScaled`, so `TextScaled` is set after creation.
- [x] Inventory chest odds overflowed ("Comm 69.1% / Rare…", cut to 4 letters): one line of rarity-coloured
      `C 69.1%  R 24.7%  E 6.2%…`, scaled to fit, same in EN/TH.
- [x] Nav tile labels ("Invite Friends", Thai names) overflowed the 94 px tiles: scale 20 → 11 px.
- [x] Settings toggles showed only text: NavigationHUD uses Global ZIndex, so the button skin sat under the row
      background; toggles are lifted above the row. Toggle buttons 42 → 48 px.
- [x] Phones: large windows use the full screen height beside Roblox's top-left buttons (`GuiService.TopbarInset`),
      or under the topbar when that is larger (narrow phones). 960×650 windows 0.50 → 0.56 on iPhone XR.
- [x] Roblox hotbar covered window footers (Exchange / Open buttons): hidden while a window or menu is open,
      restored on close.
- [x] Phone RUN button overlapped the quest tracker on short screens: placed beside the 70 px jump button when the
      short side ≤ 500 px.
- [x] Gamepad: B to close, auto-focus, visible selection outline; full-size click catchers (`ClickBlocker`, shade) are
      no longer selectable.

## Open (not fixed — needs a phone layout)

- [ ] **Touch targets on phones.** Windows are drawn at 960×650 with offset layouts and shrunk by one UIScale, so on
      phones every window control is 17–38 px and Thai text is small. Meeting 44 px needs a phone layout per window
      (two-column cards, full-width detail, bigger tabs), as the elements-v1 UX spec proposes. Biggest offenders:
      Shop buy buttons, Quests tabs, Garden actions, Season/Rebirth close.
- [ ] Desktop/tablet minor: Shop buy buttons (40 px), Quests tabs (38 px), Season close (40 px) are under 44 px.
- [ ] Admin buttons (ADMIN/OWNER, admin-only) overlap window titles on phones.
- [ ] `MapController` (map-systems work, not committed) binds gamepad **Select** to the map, which is also Roblox's
      "enter UI navigation" button; pick another button (e.g. DPadUp / ButtonY) before committing it.
- [ ] Not tested: real devices, notch devices in portrait, console (10-foot) text size, screen readers.

## Re-run

1. Studio → Test → Device Simulator (pick device, *Fit to Window*), Play.
2. `execute_luau` (Client) with `tools/ui/UIAudit.luau`; slice `WINDOWS` if a call times out.
3. Thai: Settings → Language → ไทย. Gamepad: Test → Controller Emulator.
