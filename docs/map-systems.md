# Map scripting — 2026-10-02

## Inspection before implementation

Target: Chop a Tree, PlaceId 93479990217075. User approved Studio edits and adding profile fields; no Publish, no live migration, no new DataStore keys, no monetization changes. Existing uncommitted Locale edits are preserved.

| System | Exists | Missing / action |
|---|---|---|
| Footprint | Config.Zones.At, eight rings + Hub | Keep numeric IDs/key SkyIsles; add metadata and validator, never duplicate geometry |
| Access | Progress.UnlockedZones, boss + LightShrine, local RotBarrier | Keep free boss/shrine progression; add server position enforcement |
| Trees | 1470 tagged trees, TreeKit 24, normalized HP/contributions, hide/reset pool | Preserve Balance/Run.Award and 15s population-adjusted respawn |
| Events | Weather/LiveEvent/WeatherEncounter; Meteor Stardust, Rot world boss, rare eggs | Add local Golden/Timber events; reuse existing Meteor/Boss/Fog rewards and scheduler |
| Weather | Shared WeatherState, WeatherController owns Lighting | DayCycle must compose inside that owner, never create competing Lighting tweens |
| Travel | Story.Warp; stone or existing Teleport pass; egg guard | Add cooldown, Arena/revalidation/safe destination; Home through Garden owner |
| Bases | Garden.Assign/Release loops 1..7; seven tagged PlayerBase | Reuse, no second allocator |
| UI | Locale/Strings WIP, UIKit, Story gate UI | Add zone banner/map/compass using T and existing warp intent |
| Explorer | No Landmark/Secret/ExplorerCollectible tags | 24 permanent IDs, deterministic markers, server distance checks, approved capped completion reward |
| Data | PlayerData_v1, DATA_VERSION 2, Reconcile/Migrate | Approved v3 VisitedZones and Explorer.collected/completed; synthetic checks only |
| QA | Admin.Register, regression scenarios, Luau CLI | Add map commands/validator/synthetic scenario; live multi-player/device proof remains required |

Balance: no paid gates, no new prices/pass IDs and no rarity weight changes. User approved one Common Level 1, source-zone-1 chest per completed zone (eight maximum), and Golden/Timber Wood x2 inside the existing overall x4 cap. Fast travel keeps the purchased Teleport Anywhere benefit: free users use existing stones, or the fixed free dock route. No unlicensed sound IDs; silent placeholders.

## Implemented in repository and synchronized to Studio QA

- `Zones`: numeric IDs and all existing keys/radii/y preserved, region paths, TreeKit pool references, free previous-shrine unlock metadata, neutral HP/drop/rarity, ambient presets/lighting, Explorer counts. `ZoneUtil` delegates every footprint to `Zones.At` and shares projection for both map views.
- `ZoneService`: one .35s Heartbeat batch, .7s hysteresis, Player/Character Zone attributes, entered/left signals, authorized visits only, removal/Destroy cleanup and mean/peak timing counters. Gameplay access continues to read fresh positions.
- `GateService` catches locked-zone sky/ground bypass, kill floor and underground falls; restores last grounded authorized position or village spawn. Arena queues/transfers are excluded. Existing Story remains unlock/collision owner; new gate prompts explain the shrine requirement.
- `TreeService` preserves hide/reset pooling, tags, 15s population-adjusted respawn and formulas. Golden Wood x2; Giant HP x4/scale1.5, Ancient/Cursed HP x2, Wood x2. Shared variants split the existing reward budget by clipped normalized damage, minimum 2% participation; lightning cannot bypass contributions. Hit eligibility, Auto Cut selection and ForestController's HP/required-power labels all include SpecialHP. Studio-only tree.spawn accepts any real TreeKit key/tier1–6, validates accessible ground and caps temporary trees at eight; tree.clear removes that QA folder.
- `DayCycle`: four visual phases over 20 minutes, synchronized with server time. WeatherController is the sole Lighting owner and composes phase/clear-weather zone overrides. Weather/rare encounter UTC gameplay remains unchanged.
- **2026-10-03: world map window, minimap, Map button and the M / gamepad map toggle were removed (ArmZ).** `MapController` now only draws the compass (heading + quest/event targets) and runs the client side of the boat ride; zone travel is the Warp tab in Quests (a "Home" row was added there). The line below describes the removed version.
- `MapController`: schematic rings from actual configuration, north/camera minimap, players, Home/shop/altar/shrine/explorer markers, keyboard/gamepad/touch controls, unlock hints and exploration counts, validated warp intent/fade and native phone list. Compass has separate quest/event bearing markers with off-screen arrows and distance; StoryController publishes QuestGuide.TargetPosition from its existing resolver. Locked rings have distinct grey tones/boundaries. Minimap/compass hide while the world panel is open. StoryController remains the sole per-player RotBarrier owner and animates progress changes with a .7s slide; server access enforcement remains active.
- `TravelService`: existing stone/owned Teleport check, 2s cooldown, visits/combat/egg/Arena guards, validated landing, busy lock and revalidation after streaming. Home uses Garden's assigned BaseSpawn. Two three-part dock boats offer a six-second local coastal cinematic; duration, shore (210,5.5,866) and curve control point (540,6,1010) live in Config.Story. Player physics stays under normal control during the cosmetic ride; leaving the registered dock, dying/changing character or losing eligibility cancels. BoatSkip accepts only that player's current server token. Server revalidates after wait/streaming before teleporting; client cleans up its clone/button/camera on completion, removal or camera handoff.
- `WorldEventService`: one local event, 600s gap, occupied accessible zone selection, skips other weather. Config weights Golden/Timber1/1, Giant.2, Ancient.1, Cursed.1 are conservative scheduling defaults: rare variants replace an event slot and add no parallel population. Durations120/90/180/180/120s; all Wood uses the approved x2 within the overall x4 cap and no extra Coins/EXP. Weather Meteor/world boss/Fog stay with existing Zone1 owners. Night Spirits reuse Fog + night, 5 Stardust/20s/max12 and once-only removal-before-award.
- `ExplorerService`: one landmark, secret and ChestBuilder mini-chest per zone. Server access/position/distance/cooldown checks, duplicate rejection, completion/GrantChest without yields, persistent permanent IDs `explorer_zN_I_v1`. Collections/progress do not reset on Rebirth; IDs remain stable.
- Garden still owns all seven base slots. No replacement BaseService/allocator, no WalkSpeed writes, no new monetization/DataStore keys.

## Zones and balance

| ID | Zone | Radius / floor y | Unlock | Themed pool |
|---|---|---|---|---|
| 1 | Sunny Meadow | 740–900 / 4 | Existing free starter zone | Oak, RoundTree, Pine |
| 2 | Amber Woods | 650–740 / 12 | Boss + shrine 1 | Maple, Birch, AutumnBall |
| 3 | Glowcap Bog | 560–650 / 20 | Boss + shrine 2 | Mushroom, TwinShroom, GlowBulb |
| 4 | Sakura Highlands | 470–560 / 30 | Boss + shrine 3 | Sakura, Weeping, Layered |
| 5 | Thunder Bamboo | 380–470 / 40 | Boss + shrine 4 | BambooClump, BambooTall, ThunderPalm |
| 6 | Frostvale | 290–380 / 52 | Boss + shrine 5 | SnowPine, IceSpire, SnowRound |
| 7 | Crystal Ridge | 200–290 / 64 | Boss + shrine 6 | CrystalTree, Prism, Amethyst |
| 8 | Lumora Plateau (SkyIsles key) | 0–200 / 78 | Boss + shrine 7 | GoldenTree, LightOrb, SpiritWillow |
| hub | Rootfall | (0,4,1010), r190 | Safe/free | None |

All zone HP/drop multipliers are 1; rarity bonus 0; travel cost 0. Actual progression remains Balance's x100 per zone with Rebirth/AutoCut/friend/Pet/pass/boost seams. TreeKit retains its existing 55/30/15 themed/neighbour/other mix; pool metadata records the themed references. No extra economic curve.

## Data v3

Existing store `PlayerData_v1`, same player keys. `MIGRATIONS[3] = Shared.MapMigration` adds `Progress.VisitedZones = {}`, `Explorer.collected = {}`, `Explorer.completed = {}`. Empty visits are intentional: unlocked does not mean visited. Reconcile supplies missing fields; the existing copied-step migration runner preserves old data/version on a failure. `data.migratetest` retains Sword Pack checks and adds v0/v1/v2/v3 map samples, idempotency and failed-v3 rollback.

No live profile migration was run for this task. **Do not start the normal Main with v3 merely to validate it:** use isolated mock-profile tests first. Normal Play loads real profiles and would apply v3. Deployment/live migration needs separate approval under the supplied prompt.

## Validation

- `luau-compile`: **185 files, zero syntax errors** (src and tools/tests). This is syntax proof, not Studio runtime/type/visual proof.
- Luau synthetic tests: **162 checks passed** with actual services, DataService template/migrations/reconcile and Balance. Boundary mocks contain no DataStore APIs. Coverage includes geometry/hysteresis/visits, access rescue/flags, forged travel/egg/stream-yield/cooldown/landing, 24 Explorer IDs and once-only chest, Wood cap, real Golden cut/pool respawn/shared Giant payouts, weighted rare scheduling and restoration, Auto Cut required-power consistency, invalid boat tokens, overlap/timeout and Meteor/Night Spirit guards.
- Run: `python tools/tests/run_map_systems.py --luau C:/Users/Administrator/AppData/Local/Temp/codex-chop-arena-luau/luau.exe`.
- `python -X utf8 tools/balance_sim.py`: passes, original x100 progression and roughly 100s modeled boss time per zone retained. The Luau checks prove new Wood bonuses obey x4 and Giant payout retains Coins/EXP budget; baseline simulator does not model the new scheduler.
- Studio sync completed: 31 scripts verified by UTF-8 length and rolling checksum against repository sources. Pending ChestOpening bootstrap/settings edits from another task were excluded from Studio sync. Original ProfileStore source was never edited.
- Isolated Studio VM: services initialize successfully, all ten selected client modules start, validator passes eight regions/TreeKit pools. Synthetic migrations pass with actual DataService/ProfileStore.Mock; the deliberate failing v3 rollback emits its expected warning.
- Runtime Explorer: all 24 IDs collected, eight completed zones, exactly eight Common Level1/source-zone1 chests; zone1 repeated collection rejected, including a second run through native ProfileStore.Mock. Locked-zone2 teleport returns to zone1 and does not record a locked visit. Infinity destination rejected, owned-pass warp to zone1 succeeds, Golden Tree event starts.
- Actual Local Server: Player1–Player7 received unique BaseIndex1–7 and all tracked zone1 after simultaneous positioning. Two extra clients arrived while launching the suite; they received no duplicate base. Native mock reopening and base release/assign cycles passed below; real client/network rejoin endurance remains untested. All temporary server/client windows were closed afterward.
- Captures: Desktop EN/TH, iPad TH (1022×767) and iPhone7 TH (666×374). Phone panel646×314, zone buttons51px high, travel/north/Home/Hub inner buttons44px; minimap/heading hidden behind the open panel. Touch/click opens the map. Native Windows M now opens/closes the map; injected gamepad inputs did not open it, so physical gamepad remains unverified. Saved phone image and raw fixture report: artifacts/map-qa/.
- `perf.report` computes per-zone parts/trees/particles on demand and Zone batch timings. Studio Zone batching: 745 aggregated samples, mean0.012504ms, peak0.0535ms. The window includes time before all clients arrived; this is not a seven-player-only sample or total map frame cost/FPS proof. New static content adds 24 markers, eight Common ChestBuilder models (23 parts each), and six boat parts; Measured region parts for zones1–8: 1386/1434/1317/1281/1172/986/885/857; trees260/245/213/182/150/140/140/140. Counts exclude Explorer/boats outside region folders. Total map frame budget and real-device FPS remain unverified.

## Admin and next verification

Existing Admin.Register authorization: `zone.info/tp/unlock/bounds`, `tree.respawn/special/spawn/clear`, `event.start/stop/list`, `time.set`, `explorer.reset/fill`, `travel.test`, `perf.report`, `map.dump`. Mutations require Studio; read-only commands retain Tester checks. Unlock/Explorer changes must use a mock profile for this task.

Remaining: physical gamepad, sustained real client/network rejoin, full gameplay/manual traversal on all eight zones and seven-player total frame budget/real-device FPS. Licensed audio is still a silent placeholder. No Publish, live migration or paid asset action performed.

## Files and Git

New: Shared `ZoneUtil`, `MapMigration`, Config `DayCycle`, `Explorer`, `WorldEvents`; Services `ZoneService`, `GateService`, `DayCycleService`, `TravelService`, `WorldEventService`, `ExplorerService`; AdminCommands `MapCommands`, `MapMigrationCheck`; client `ZoneController`, `MapController`, `WorldEventController`, `GateController`; tests `MapSystemsMocks.luau`, `MapSystemsAssertions.luau`, `run_map_systems.py`; this report.

Extended: Config `Zones`, `Features`, generated `Strings` + localization CSV; server Main, Data/Run/Tree/Story/WeatherEncounter services, DataCommands; client Main/HUD/WeatherController/ZoneAmbience; docs HANDOFF/plan/INDEX/systems and SKILL. The concurrent Inventory/Navigation/Sprint/UIKit/Weapons/asset work was not staged or overwritten.

- `c23a38f` — server zone/gates/travel/events/Explorer + v3 migration.
- `bb39a11` — bilingual map/compass/zone/event UI.
- QA/docs commit: `test(map): add isolated map checks and integration handoff` (see Git log for the resulting hash).

No push or Publish was performed. Initial 31-script synchronization and continuation 12-script + map-only Strings synchronization were checksum verified. Concurrent chest/weapon edits were excluded.

## Studio QA mode and next checks

Update 2026-10-03: the full Main bootstrap is enabled again and both QA bootstraps are disabled (kept in place); MapUseMockProfiles stays true. The paragraph below describes the earlier QA state.

Studio is left in Edit/default viewport with safe QA: normal Main scripts disabled, MapQABootstrap/MapClientQA enabled, DataService.MapUseMockProfiles=true. It asserts Studio/mock opt-in and loads map/gameplay/Quest services plus ten UI modules, including StoryController for gates/quest targets. Admin/leaderboards/live-event networking/purchases/full bootstrap are not started. Play reviews this slice without PlayerData_v1 reads/writes; memory profiles disappear with the VM.

Fixtures: tools/tests/StudioMapQA.server.luau (Server.MapQABootstrap) and StudioMapQA.client.luau (StarterPlayerScripts.MapClientQA). Server-only MapQARequests.action supports report/migration/collect/allExplorer/zone2/travel/event/hub/language/variants/unlock2/boat/boatBack/boatCancel/spawnTree/basesCycle/perf/mockRoundTrip. Observe completion/result and reset Play between independent cases. mockRoundTrip saves the existing mock key, kicks the QA client to release its session/base, then reopens/verifies/ends a native mock session; run it last. boatCancel requires moving the character away during the ride. Never enable these fixtures for deployment.

Before switching back to the full game, disable/remove both QA bootstraps and restore the original Main Disabled values (saved in MapOriginalDisabled attributes). Keep mock profiles selected during any further Studio testing. Starting real profile sessions with v3, or publishing, remains outside the authorization for this task. Backup of inspected pre-sync sources is artifacts/studio-map-backup/sources-before.json (local only).

Continuation proof (2026-10-02/03): artifacts/map-qa/continuation-report.json. Gate Y22→44 (+22), collision off/transparency1; native Windows M opens/closes map. Boat out/back6.034/6.050s, skip1.051s, moving away cancels in .584s; camera restores. Tree.spawn Oak has Zone1/Tier1/Tree tag/Alive; unknown key rejected. Giant/Ancient/Cursed start and restore. Twenty-five base release/assign cycles passed. Native mock save/reopen preserves Progress/Explorer/chest UID and releases base; this is not a real client/network rejoin endurance test. Four synchronous update owners, 200 samples/one player: mean.080237ms, peak.103600ms, excludes rendering/network callbacks. Thai phone boat button and tablet compass captured; CoreUISafeInsets/ClipToDeviceSafeArea=true, iPhone7 viewport666×374, iPad1022×766, ScreenOrientation.Sensor. Simulator reset to default. Gamepad injection did not open the panel, so physical gamepad remains unverified. Map translation keys are complete; global locale extraction still finds one missing key in concurrent ChestOpening WIP, excluded from this commit/sync.

Continuation commit: mobile layout/guarded native mock QA in `b2c5843`. Earlier map system commits: c23a38f / bb39a11 / c7e08d5.
