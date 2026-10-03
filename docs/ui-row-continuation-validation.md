# UI row continuation — 2026-10-03

Continues the work shown in `For Continue/` screenshots. Place: Chop a Tree, `93479990217075`. No publish. Files and Studio use the same 11 UI/quest/locale sources; unrelated Weapons edits were preserved.

## Changes

- Reused the pending `UIKit.Row` implementation and 48-icon sheets for Quests, Pets Base/Conveyor, Season, Rebirth and Leaderboard. Server intents remain unchanged; Quest packets expose stat/kind for icon choice.
- Pets publishes its tab for `PhoneLayouts.PetLayout`. Rendering no longer overwrites phone positions every two seconds; six pet actions use the full footer width. Returning to desktop redraws desktop geometry. Incubator refresh preserves phone egg-label positions.
- Season shows Free/Premium headers on phones. Each column now ends before the next starts; measured gap at 666×374 is 6.55 px. Claimable and claimed states remain separate for each track.
- Rebirth requirement keeps its phone position. Confirmation has named heading/body and proportional buttons; button text has a higher ZIndex than the surface.
- Phone pet/board tabs show icons to avoid labels extending outside their tabs. Affected buttons include space for the 4 px bottom lip at the smaller notched safe-area scale.
- Side rail remains above the active window: Navigation DisplayOrder 31, window 30. Clicking Rewards from Pets closes Pets and opens Rewards.

## Proof

`UIAudit` checks visible text fit, viewport bounds and 44 px minimum touch targets. It excludes clipped scrolling children from viewport checks, so actual screenshots and tab clicks supplement it. Tests cover landscape; screenshots were inspected through Studio screen capture.

| Device / actual viewport | Language | Five affected windows: OVER / OFF / SMALL |
|---|---|---|
| iPhone 7 / 666×374 | EN + TH | 0 / 0 / 0 |
| iPhone 17 Pro / safe area 749×361 | TH | 0 / 0 / 0 |
| iPad 6th generation / 1023×767 | TH | 0 / 0 / 0 |
| Default desktop / 1238×793 | EN + TH | 0 / 0 / 0 |

- Real mouse clicks: all 5 Pets, 6 Quests and 3 Rewards tabs in EN and TH on iPhone 7. Pets measurements wait over two seconds to include a state refresh.
- Mock daily Quest claim: +5 Gems message and claimed badge. Mock Season free/premium claims: claimed badge; the other track remains independently claimable. No paid purchase was made.
- Synthetic boards: Server/Global changes the displayed player; Likes changes the reward-chip icon to heart. This tests the client without reading real global rankings.
- Rebirth Prepare shows the confirmation; Confirm text is visible above its surface; Cancel closes it. The destructive Confirm action was not invoked.
- Desktop restoration after phone/tablet switching: no unexpected position differences in checked nested objects; affected windows stay in bounds.
- Final Play console: no runtime errors. `MapUseMockProfiles=true`; fixture imports the original snapshot before Stop, restores service overrides and is removed from Studio. Studio is left in Edit/default viewport.
- Final gates: compile all 202 `src`/`tools` Luau files, localization 1,800 keys / 0 missing Thai, `git diff --check`, 11/11 source hashes. Machine-readable output: [validation.json](../artifacts/ui-continuation/validation.json).

## Remaining

Real devices, touch, gamepad, portrait layouts, populated pet inventory, actual Global DataStore rankings and all economic edge cases remain outside this visual continuation. Existing Shop small purchase buttons still measure about 42 px on desktop / 34 px on iPhone 7 and need a separate Shop layout pass. The full gameplay regression suite was not rerun for these layout changes.

To replay: insert `tools/ui/RowUIHarness.server.luau` as a temporary Script in ServerScriptService with mock profiles selected. It prepares ready quests, a level-4 Season, Rebirth tokens and synthetic boards. Set `Language` to `en`/`th`, `Premium` to true for premium claim states. Set `Finish=true`, wait for `Restored`, Stop and remove the Script. Never include the fixture in deployment.
