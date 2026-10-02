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
- `TreeService` preserves hide/reset pooling, tags, 15s population-adjusted respawn and existing formulas. Golden Wood x2; opt-in QA Giant HP x4/scale1.5, Ancient/Cursed HP x2, Wood x2. Shared variants split existing reward totals by clipped normalized damage, minimum 2% participation; lightning cannot bypass shared contribution. Their Wood remains capped by Run.Award. Giant/Ancient/Cursed have no automatic spawn schedule yet; enable through `tree.special` QA.
- `DayCycle`: four visual phases over 20 minutes, synchronized with server time. WeatherController is the sole Lighting owner and composes phase/clear-weather zone overrides. Weather/rare encounter UTC gameplay remains unchanged.
- `MapController`: schematic rings generated from actual configuration, north/camera minimap, players, Home/shop/altar/shrine/explorer markers, M/ButtonSelect/touch world map, unlock hints and exploration counts, compass heading, validated warp intent/fade, native-sized phone list. Desktop EN/TH, iPad TH and iPhone 7 TH were captured in isolated QA; phone map actions have 44px minimum inner buttons. Locked rings now have separate grey tones/boundaries. Minimap/heading hide while the world panel is open.
- `TravelService`: same existing stone/owned Teleport check, 2s cooldown, visited-zone check, combat/egg/Arena guards, validated safe landing, busy lock and revalidation after streaming yields. Home uses Garden's assigned BaseSpawn. Fixed dock route uses two three-part static boats and server distance checks; ride animation/skippable boat cinematic is not implemented.
- `WorldEventService`: one local Golden or Timber event, 600s gap, active-player zone selection, skips other weather. Weather Meteor/world boss/Fog stay owned by existing services in Zone 1. Existing WeatherEncounter collector also handles block Night Spirits during Fog + DayCycle night, with the same 5 Stardust/20s/max12 pickup budget and once-only removal-before-award.
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
- Luau synthetic tests: **148 checks passed** with actual map services, actual DataService template/migrations/reconcile code and actual Balance. Boundary mocks replace players/physics/streaming/ProfileStore; no DataStore APIs exist in the harness. Includes ring/hub/projection, hysteresis/visits, sky/underground/rescue/Arena/flag guards, forged payload/dock/egg/stream-yield/cooldown/blocked travel, 24 IDs, once-only completion chest, Wood cap, real Tree.Hit Golden payout/pool respawn/Giant shared totals, event overlap/timeout/cleanup, Meteor/Night Spirit once-only/stale/day guards.
- Run: `python tools/tests/run_map_systems.py --luau C:/Users/Administrator/AppData/Local/Temp/codex-chop-arena-luau/luau.exe`.
- `python -X utf8 tools/balance_sim.py`: passes, original x100 progression and roughly 100s modeled boss time per zone retained. The Luau checks prove new Wood bonuses obey x4 and Giant payout retains Coins/EXP budget; baseline simulator does not model the new scheduler.
- Studio sync completed: 31 scripts verified by UTF-8 length and rolling checksum against repository sources. Pending ChestOpening bootstrap/settings edits from another task were excluded from Studio sync. Original ProfileStore source was never edited.
- Isolated Studio VM: actual services initialize successfully, all nine selected client modules start, validator passes all eight regions/TreeKit pools. Synthetic migration checks pass using actual DataService with the existing ProfileStore.Mock backend. The deliberately failing v3 rollback case emits its expected warning.
- Runtime Explorer: all 24 IDs collected, eight completed zones, exactly eight Common Level1/source-zone1 chests; zone1 repeated collection rejected, including a second run through native ProfileStore.Mock. Locked-zone2 teleport returns to zone1 and does not record a locked visit. Infinity destination rejected, owned-pass warp to zone1 succeeds, Golden Tree event starts.
- Actual Local Server: Player1–Player7 received unique BaseIndex1–7 and all tracked zone1 after simultaneous positioning. Two extra clients arrived while launching the suite; they received no duplicate base. Rejoin/release endurance remains untested. All temporary server/client windows were closed afterward.
- Captures: Desktop EN/TH, iPad TH (1022×767) and iPhone7 TH (666×374). Phone panel646×314, zone buttons51px high, travel/north/Home/Hub inner buttons44px; minimap/heading hidden behind the open panel. Touch/click opens the map. Injected M/ButtonSelect did not toggle during the device test, so physical keyboard/gamepad navigation remains unverified. Saved phone image and raw fixture report: artifacts/map-qa/.
- `perf.report` computes per-zone parts/trees/particles on demand and Zone batch timings. Studio Zone batching: 745 aggregated samples, mean0.012504ms, peak0.0535ms. The window includes time before all clients arrived; this is not a seven-player-only sample or total map frame cost/FPS proof. New static content adds 24 markers, eight Common ChestBuilder models (23 parts each), and six boat parts; Measured region parts for zones1–8: 1386/1434/1317/1281/1172/986/885/857; trees260/245/213/182/150/140/140/140. Counts exclude Explorer/boats outside region folders. Total map frame budget and real-device FPS remain unverified.

## Admin and next verification

Existing Admin.Register authorization: `zone.info/tp/unlock/bounds`, `tree.respawn/special`, `event.start/stop/list`, `time.set`, `explorer.reset/fill`, `travel.test`, `perf.report`, `map.dump`. QA mutations reject non-Studio servers; read-only commands retain Tester checks. `zone.unlock` and Explorer fill/reset can alter the active Studio profile; only run them with a mock profile for this task.

Remaining: obtain exclusive Studio use, inspect current sources before syncing, run isolated VM/GUI tests with normal Main disabled, verify live region/TreeKit/string validator, 7-player assignment and tracking, mobile/tablet/gamepad/Thai layout, gate border/manual walking, real physics/landing, event disconnect behavior and FPS. Tree.spawn arbitrary TreeKit kinds, fully animated gate opening, quest/target compass arrows and animated dock ride remain beyond the current implementation. No Publish, live migration or paid asset action performed.

## Files and Git

New: Shared `ZoneUtil`, `MapMigration`, Config `DayCycle`, `Explorer`, `WorldEvents`; Services `ZoneService`, `GateService`, `DayCycleService`, `TravelService`, `WorldEventService`, `ExplorerService`; AdminCommands `MapCommands`, `MapMigrationCheck`; client `ZoneController`, `MapController`, `WorldEventController`, `GateController`; tests `MapSystemsMocks.luau`, `MapSystemsAssertions.luau`, `run_map_systems.py`; this report.

Extended: Config `Zones`, `Features`, generated `Strings` + localization CSV; server Main, Data/Run/Tree/Story/WeatherEncounter services, DataCommands; client Main/HUD/WeatherController/ZoneAmbience; docs HANDOFF/plan/INDEX/systems and SKILL. The concurrent Inventory/Navigation/Sprint/UIKit/Weapons/asset work was not staged or overwritten.

- `c23a38f` — server zone/gates/travel/events/Explorer + v3 migration.
- `bb39a11` — bilingual map/compass/zone/event UI.
- QA/docs commit: `test(map): add isolated map checks and integration handoff` (see Git log for the resulting hash).

No push or Publish was performed. Source synchronization is still required after resolving concurrent Studio use; these commits do not mean the game running in Studio contains this implementation.

## Studio QA mode and next checks

Studio is left in Edit with safe map QA configured: normal Server.Main and Client.Main are disabled; Server.MapQABootstrap and StarterPlayerScripts.MapClientQA are enabled. DataService attribute MapUseMockProfiles=true selects the existing ProfileStore.Mock memory backend only in Studio. The QA bootstrap also asserts Studio and that opt-in before loading services. It loads the map/required gameplay services and nine selected UI modules; admin, leaderboards, live-event networking, purchases and the normal full bootstrap are not started. Press Play to review this map slice without loading PlayerData_v1 profiles. QA profile changes disappear with the test VM.

Reproducible server fixture: tools/tests/StudioMapQA.server.luau, installed as Server.MapQABootstrap. Requests are server-only attributes on ReplicatedStorage.MapQARequests: action=report/migration/collect/allExplorer/zone2/travel/event/hub/language; completion/result attributes report the result. Reset Play between independent cases. Client fixture tools/tests/StudioMapQA.client.luau is installed as StarterPlayerScripts.MapClientQA and starts ClientData, LocaleController, HUD, WeatherController, ZoneAmbience, ZoneController, MapController, WorldEventController and GateController.

Before switching back to the full game, disable/remove both QA bootstraps and restore the original Main Disabled values (saved in MapOriginalDisabled attributes). Keep mock profiles selected during any further Studio testing. Starting real profile sessions with v3, or publishing, remains outside the authorization for this task. Backup of inspected pre-sync sources is artifacts/studio-map-backup/sources-before.json (local only).

Remaining spec work: animated gate opening, quest/target compass markers, animated/skippable dock ride, arbitrary tree.spawn and automatic Giant/Ancient/Cursed scheduling. Licensed audio remains a documented silent placeholder. Real gamepad/keyboard, save/rejoin endurance, total map tick cost and device FPS still need proof; this report does not claim full acceptance.

Continuation commit: mobile layout/guarded native mock QA in `b2c5843`. Earlier map system commits: c23a38f / bb39a11 / c7e08d5.
