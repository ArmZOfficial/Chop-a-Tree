# System reference — Chop a Tree

อ่านเฉพาะ heading ของงาน. สถานะล่าสุด/งานค้าง: [HANDOFF](HANDOFF.md). รายละเอียด intent: [design](design.md).
ผลตรวจด้านล่างเป็นรอบเดิม ไม่ใช่ regression หลังร้าน. Raw reports/screens ก่อน cleanup อยู่ Git commit `5d09e37`; scenario ที่รันซ้ำได้ยังอยู่ `tools/tests/`.

## Map

- Map scripting repo work: [implementation/validation](map-systems.md). ZoneService/GateService/TravelService/DayCycle/WorldEvent/Explorer reuse the existing footprint, progression, pooling, Weather, Garden and reward owners. Data v3 is additive and tested synthetically only; Studio integration/performance/device proof pending. Do not start normal Main with v3 to validate migration on a real profile.

- PlaceId 93479990217075; GameId 10768831527. **เกาะวงกลม 8 วง (2026-10-02)**: ศูนย์ (0,0), ใต้ = +Z; วง `inner/outer/y` อยู่ใน `Config.Zones` (1 Meadow 740–900 y4 → 7 Crystal 200–290 y64, 8 Lumora ที่ราบ r200 y78). Hub Rootfall = `Zones.Hub` (0,4,1010) r190 นอกโซน. ทั้ง 8 built=true.
- ตำแหน่งโซนอ่านผ่าน `Zones.At(pos)` ที่เดียว (RunService.ZoneAt + ZoneAmbience); ห้ามคำนวณ footprint เอง. Merchant.Position อยู่ใน hub (36,0,1072).
- MapBuilder (`tools/map/MapBuilder.luau`, Studio `ServerStorage.MapTools`) + `TreeKit.luau` (24 แบบ ≤7 parts + rot veins 3 ที่ tier 6; ผสม 55/30/15). Trunk = PrimaryPart/collider ที่มองเห็น. ทุกวงเข้าทางแกนใต้: บันไดขั้นละ ≤1 stud + torii ZoneGate (RotBarrier) + RotHedge สูง 8 บนขอบวงบน (ช่องเปิด ±19 พอดีเสา); หน้าผา 8–14 + hedge = กระโดดข้ามไม่ได้. Hub มีกำแพง 10 (ช่อง ForestGate เหนือ, ท่าเรือใต้), ชายฝั่ง CoastRock. MapAssets (Creator Store) ไม่ใช้แล้ว.
- MCP เรียก require โมดูลเกมไม่ได้: Edit ใช้ `loadstring(MapBuilder.Source)()` (MapBuilder fallback เองสำหรับ Zones/TreeKit); Play server ไม่มี loadstring → ใช้ test Script ชั่วคราวใน ServerScriptService. หลัง BuildZone ต้องรัน `BuildZoneKeepers.luau` ซ้ำ.
- ผลตรวจ 2026-10-02: tags ครบ (Tree 1470, ChestSpot 80, Nest 16, ZoneGate 7, WarpStone 9, ZoneSpawn 8, BossArena/Shrine 8, PlayerBase 7, GardenSlot 42, Shop 4, NPC 7, อื่น 1–2), Parts 10,127 (เดิม 18,103); ValidateRoutes Edit 263 samples/0, Play เดิน 16/16 routes; Zones.At ตรง tag 1598/1598; Play `Run.ZoneAt` 8/8 + hub=nil; leak probe ประตู 0. หลังเปลี่ยนภูมิประเทศตรวจใหม่ ไม่อ้างรายงานเดิมแทนผลใหม่.

## Models / builders

Retro builders (Plastic + Studs, BrickColor-style colours, Neon accents only, no hidden Scripts). Model inventory 2026-10-02:

| Model | มี/สร้าง | ที่อยู่ |
|---|---|---|
| ต้นไม้ 24 แบบ | สร้างแล้ว | `tools/map/TreeKit.luau` (MapBuilder ใช้) |
| ท่าเรือ, ร้านขวาน (ขวานยักษ์), ร้านไม้ (กองซุง), Chest Altar + หีบโชว์ Epic, บ้าน 7 หลัง, torii/ประตู, ป้าย, กำแพง, หิน/ตะเกียง/props ต่อโซน | สร้างแล้ว | `tools/map/MapBuilder.luau` |
| หีบ 5 ระดับ + hinge | สร้างแล้ว | `Shared.ChestBuilder` (Build/SetLid/LevelOf/Levels) |
| ไอคอนหีบ 2D | สร้างแล้ว (ViewportFrame) | `Shared.ChestIconRenderer.New(rarity, props)` ใน Inventory |
| ดาบ 380 | สร้างแล้ว (แทร็ก B) | `Shared.WeaponVisual` |
| Opening Stage props / idle FX / particles | ยัง (แทร็ก J) | อ่าน attribute ใน `FX` ของหีบ |

- ChestBuilder: pivot = กลางพื้น, หน้า −Z; ใช้ `body.PivotOffset` เพราะ `WorldPivot` ถูกเมินเมื่อมี PrimaryPart. CanCollide/CanTouch ปิดทุกชิ้น. Budget ตรวจแล้ว 23/28/30/37/61 (≤25/35/45/60/80). ภาพ/สรุป: [elements-v3](../assets/ui/elements-v3/README.md).

## Run / weapons

- RunService owns Run/access/award/AutoCut reward/ChestLevel; WeaponService owns random/equip/fuse/delete. Loot+Balance+Config เป็นสูตรร่วม.
- ไข่ Nest secure เฉพาะส่งหินวาร์ป/End Run ที่ถูกต้อง; ตาย/ออก/Endแบบอื่น Drop. รางวัลอื่นใช้กติกา RunService.
- อาวุธใหม่คง UID/definition ID, Tool+viewport Handle/WeaponId/ForestAxe, Giant×3.
- **Sword Pack 380 (แทร็ก B):** ข้อมูล `data/swords.json` ← `tools/gen_swords.py`; `tools/gen_config.py` สร้าง `Config/SwordPack.luau` (แถวย่อ) + `Config/LegacyWeaponMap.luau` + `docs/sword-pack-migration.md`. ทุกระบบ require `Config.WeaponCatalog` (List = ดาบ 380 สำหรับหีบ/Index, Legacy = wpn_* เดิม legacy=true, ById = ทั้งคู่). Flag `SwordPack` เลือก pool หีบ (ปิด = pool เก่า). DataService v2: `MIGRATIONS[2]` แก้ item.id ในที่ + `legacyId`, Index union; ทุก step รันบน copy ใน pcall — ล้ม = คงข้อมูลเดิม/เวอร์ชันเดิม. Admin `data.migratetest` → `AdminCommands/SwordMigrationCheck` (ข้อมูลสังเคราะห์). WeaponVisual: retro Plastic/Studs ≤9 parts + `SwingTrail` (ForestController เปิดตอนฟัน + hit burst บล็อก neon).
- Phase2 23, Phase3 36; fixtures ใน tools/tests. Power thresholds/EXP/odds ดู Balance/Config. หีบหลายใบไม่เปลี่ยน odds.

## Movement / Sprint

- `Config.Movement` + flag `Sprint`. Client `SprintController` ส่ง intent `SprintIntent` ("Sprint", bool / "Mode", Hold|Toggle) จาก Shift, gamepad L3, ปุ่ม RUN (touch, toggle). Server `PetService.SetSprint` ตรวจ (bool, ตัวละครมีชีวิต, flag, ไม่ AdminFly, ไม่แบกไข่, rate limit เฉพาะ start) → `Character.Sprinting`; ความเร็วรวมที่ `Pet.ApplySpeed` = base(AdminSpeed|16) × Pet.SpeedMult × 1.5. ตัวละครใหม่ไม่มี attribute = รีเซ็ต. Arena Place ไม่มีสคริปต์นี้ (ArenaMatch ตั้ง WalkSpeed เอง).
- Client cosmetics อ่าน attribute: FOV +8 (ramp), ฝุ่นบล็อก; ปิดเมื่อ Reduce Motion/กราฟิกต่ำ. Shift-lock ย้ายไป Ctrl ผ่าน `MouseLockController.BoundKeys`. Photo mode/AdminFly ใช้ Shift ของตัวเอง → sprint ปิด. `Settings.SprintMode` (Reconcile, ไม่เพิ่ม DATA_VERSION) แก้จากหน้าต่าง Settings.

## Localization (EN + TH)

- `Shared.Locale`: English text = key; Thai from `Config.Strings` (generated from `assets/localization/strings.csv` by `tools/gen_strings.py`) + `.thai` of WeaponCatalog/Pets/Seeds/Eggs/Zones. `Translate` = exact → template (`{1}` slots, longest literal first, slots translated recursively) → per line. `Bind(root)` (client) tracks TextLabel/TextButton Text, TextBox PlaceholderText, ProximityPrompt texts and re-translates when code changes them; language change re-applies everything live. Server sends English; client translates at display.
- Language: `Settings.Language` Auto/en/th (Reconcile, no DATA_VERSION bump) via `SettingIntent` (DataService whitelist + rate limit). Auto = `LocalizationService.RobloxLocaleId` starts with th. Settings window row AUTO/ENGLISH/ไทย.
- Fonts: UIKit fonts lack Thai glyphs; Roblox falls back to its Thai font automatically — Play capture shows vowels/tone marks intact (Settings/HUD/Inventory). No Thai family available as `rbxasset://fonts/families/*` in Studio.
- Roblox automatic translation (Creator Hub) is a second layer for text we miss; it cannot translate dynamic text, chat or pass names, and our Thai overrides it. Owner must enable it in Creator Hub (see HANDOFF).
- Tools: `tools/locale_extract.py` (scan src/client, src/server/Services, src/shared; `--check` fails on missing Thai), `docs/localization-glossary.md`.

## Garden

- GardenService owns 7ฐาน/OwnerUserId/BaseIndex; ownership reuse ผ่าน BaseById/OwnerOf. GardenSlots runtime30.
- Crops เก็บ seed UID/sourceZone/Rot/admin/timestamps. Offlineโตปกติ ไม่ mutation/harvestย้อนหลัง; สูตร Mutation = พิเศษสูงสุด × (1+ผลรวมอื่น), รวม parent tagsก่อนราคา.
- GardenMath.SellQuote เป็นทางเดียว: cap UTCตาม highest mutation, Garden.sellDay/sold; OverCapMult จาก Config.Garden.
- UI refreshใช้ปุ่มเดิมไม่สร้างซ้ำ: GardenController reuses list rows by name (text/color/callback/LayoutOrder updated, unused rows removed) since GardenState arrives every tick; Studio 2026-10-02 kept 16/16 slot rows and 9/9 shop rows across ticks while countdown text updated, tab switch removed stale rows, Slot3 click selected. state packet/DataPatch มาช้ากว่า responseได้. Phase4 55 checks.

## Pets / stealing

- PetService owns eggs/incubator/pets/pen/buffs/Mount/belt; StealService owns theft/lock/shield/bots; NestService owns forest nests/guardians.
- ไข่ขโมยอยู่ profileเจ้าของและ carriedBy จนส่งถึงฐาน แล้วโอนในเธรดเดียวไม่ yield. ห้ามลบตอนเริ่มถือ; protected Robux eggsขโมยไม่ได้.
- Pet.Mult เป็นจุดบัฟ; ApplySpeed รวม AdminSpeed×Mount×buff×CarryMult. Humanoid float32 assert tolerance ≥1e-3.
- Base defence (2026-10-02): `Pets.upgrades.trap/guard` (0–3, Wood 2500/3000 × (level+1)²) via the existing Pet.Upgrade/Base tab. Trap multiplies the thief carry speed: 0.75×(1−0.1L), so L3 = 52.5%. Guard rolls 15%/level in Steal.Try before the egg moves; a chased-off thief still gets the base cooldown and the owner is notified. Rebirth resets both with other base upgrades. The bot base reads `Steal.SetBotDefence` (admin `steal.botdefence`). Proof: `tools/tests/BaseDefenceScenario.server.luau` 8/8 vs the bot base, restored; multi-account theft is still unproven.
- Base decoration (2026-10-02): DecorService + Config.Decor (10 pieces, Wood 150–10K, beauty 1–10; maple/sakura/ice/trophy unlock by lighting shrine 2/4/6/8). Place where you stand on your own slab (4-stud grid, one piece per cell, max 40); rotate/remove act on the nearest piece, remove refunds 50%. Pieces are anchored with CanCollide/CanQuery/CanTouch off so they never block incubators or theft, and give no power. Saved in `Decor.items` (Reconcile), rebuilt on load/import, kept by Rebirth; base attribute `Beauty` sums the score. UI rows live in the pet panel Base tab; admin `decor.clear`. Likes and a "popular base" leaderboard are not built. Proof: `tools/tests/DecorScenario.server.luau` 15/15 (incl. festival pieces/village dressing) on the real profile, restored; Base tab rows present in Play (scrolled-off rows were not clicked).
- Mount StoryChapter2 gate; ไข่โซน3–8 belt=0. Catalog43หลังเพิ่ม Blood Raven. Phase5 81 checks; botไม่ได้แทน multi-account proof.

## Story / bosses

- QuestService owns story/daily/weekly/Index; StoryService owns NPC/shrine/unlock/warp; BossService guardian. Progress.Bosses/Shrines keysเป็นstring.
- Counter questsใช้ Stats delta; เพิ่ม Data.Increment+Config.Story row. daily/weekly deterministic UTC.
- Balance.BossHP/BossRequiredPower เจ้าของสูตร; built=trueจึงสร้างboss. Server Run.CanAccess ก่อน reward. Phase6 51, Phase7 23 checks.
- Chapters 3–8 (2026-10-02): one keeper NPC per zone (Myco, Hana, Raiko, Borin, Quartz, Lumi) placed 14 studs from each ZoneSpawn by `tools/map/BuildZoneKeepers.luau` (rerun after a MapBuilder rebuild). Each chapter appends step 5 "talk to keeper" after the shrine, so saved step indexes stay valid. Talk shows intro lines while the keeper's chapter is active, outro on the closing step, idle otherwise; Lumi's outro ends The Withering and points to Rebirth. Shrine lighting plays a 3s client camera pan around the shrine before the dialog. Proof: `tools/tests/StoryKeepersScenario.server.luau` 7/7 on the real profile, restored; client dialog showed Lumi's outro. The camera pan was not triggered in Studio (MCP cannot fire remotes).

## Rebirth

- RebirthService transaction; RebirthMath+Config.Rebirth formulas. Required bossesของวัฏจักรนี้; resetstoryผ่าน Quest.ResetStory คง Stats/Index/daily/weekly.
- Prepare token ผูกplayer/R, TTL30s/once; Confirm recheck. Skillซื้อส่ง expected rank; transactionไม่มี yield.
- คง UID/crops; Pet.Trim คืนสัตว์เกินcapเข้ากระเป๋า; visible vs unlocked slots, cropsเกินช่องยังเก็บผลได้แต่ห้ามปลูกใหม่.
- Wood/Coins permanent cap×2 ก่อนรวมfriend/weather/pet/boost cap×4; boss rewardMultแยก. Phase8a 41 checks.

## Rewards / leaderboard

- DailyService UTCday/streak/claim; loginนับแม้ไม่claim, ไม่มีย้อนหลัง, ขาดวันเริ่มใหม่/วน7. CodeService normalize/expiry/stable redemption ID; IDใหม่เมื่อแคมเปญใหม่.
- RewardService owns gems/chest/boost; expiryUTCคงผ่านRebirth/reconnect, ซื้อซ้ำต่อเวลาไม่คูณstrength. EXP/Luckผ่าน seamของระบบนั้น.
- Leaderboard owns Stats/Progress/Pet income, excludes Meta.AdminTouched. Integer logencoding; score0 tombstoneรักษาจากstalewrites.
- Studio stores/topicsแยก production; clientอ่านcacheไม่เปิดDataStore refreshต่อclick. Phase8b45 checks.

## Collections

- QuestService discovery/completion; CollectionMath+Config.Progression UI/servercatalog; AchievementService claim/equip/title.
- เก็บ IDจริงไม่ใช่admin_spawned; คงcompletionที่ปลดแล้วเมื่อcatalogโต; reconcile missingmarkerรางวัลครั้งเดียว.
- Weapon.Open Luck+25%เป็นrelative Epic+ (4%→5%), ไม่25pp; Giantoddsเดิม. Power pet/Index cap×4, Wood/Coins permanentcap×2ก่อนoverall×4. Phase8c55 checks.

## Weather / Live Events

- Config.Weather+WeatherSchedule UTC; rareweekend/night/Rainbow rulesคงเดิม. WeatherServiceเป็นจุดเลือกweather; use Weather.Def()สำหรับfestival mutation.
- MemoryStore UpdateAsync revision + MessagingService reread/poll30s; globalbest-effort APIfailureไม่รับประกันพร้อมกัน. Studio namespaceแยก.
- Owner globalstart/stop confirmation2, localpreviewแยก; clientไม่มีForce/broadcastข้อความผู้เล่น. Phase8d1 38checks; fakeAPI failureไม่ใช่multiserverproof.

## Encounters

- WeatherEncounterService runtime lifecycle; EncounterMath+Config.WeatherEncounters payout. Stardust: serverdistance/Run/access/key/TTL, ลบก่อนจ่ายไม่yield; exchangeผ่านWeapon.GrantChest/provenance.
- Aurora PetServiceซื้อ marker+debit+GrantEgg atomic; Pets.weatherBoughtแยกbeltBought, retainthroughRebirth/reload/prune7days.
- Nestspot retireเมื่อweatherจบ; heldegg securedefinitionเดิมได้, Dropลบ; refill callbackตรวจgeneration/registered/retired.
- Rot suppressguardian/restoreเมื่อจบ. Boss.CreateWorldแยกBoss.Get/Progress.Bosses; damageclipถึงremainingHP, markerก่อนจ่าย, loadedplayerในRunเดิมเท่านั้น. Stats.WorldBossKillsแยก, once/eventkey, nocross-serverHP.
- RemoteFunctionตรวจผ่านclient InvokeServer (อ่านcallback OnServerInvokeกลับไม่ได้). Phase8d2 59checks; differentRebirth/disconnect/multiplayerยังค้าง.

## Merchant / festivals

- MerchantService visit/stock/price/limit; MerchantMath+Config deterministic UTCminute30–40/hour. offerIDใหม่ไม่reuse, summonslocal.
- Garden.SetMerchant providerเลี่ยงrequirecycle; buy marker+debit+grantไม่yield, Merchant.bought visitkey prune2days.
- Ambient Garden.Advance uses ambientSeen=nextFruitAt once/fruitcycle onlineonly; mutationcatalog/completionคง. Phase8d3 30checks.
- Config.Events UTCrows, newyearใหม่ไม่แก้ย้อนหลัง; วันลอยกระทงตรวจจันทรคติ. Override/Liveeventมาก่อนfestival; festivalเปลี่ยนเฉพาะordinaryweather คงrare/Rot.
- NewmutationขยายIndex/fixturesแต่คงcompletionmarker. Phase8e15checks. Festival decor (2026-10-02): Config.Decor pumpkin/krathong/pine/watergun (800 Wood, beauty 3) are sold only while `Weather.Festival()` matches; placed ones stay forever. DecorService.DressVillage puts 8 of the running festival's piece on a 34-stud ring round VillageSpawn (raycast to ground, no collision) and removes them when it ends; checked every 5s. Admin festival preview drives both. Proof in DecorScenario 15/15 (with base decor).

## Emote / Photo

- EmoteController wheel/photo; standardAnimateanimationsreplicate; EmoteService chooses replicatedaura/weaponFX server.
- Photo hidesnewScreenGui andrestoreoriginalEnabled. HUD secondcolumn x200 y245/305/365/425ใช้แล้ว; Phase10จัดไม่ชนquest/weather/run.
- Specialemotesต้องserverunlock/profile, basicfree; cosmeticunlockรอคำสั่ง. Phase8f5checks+input; mobile/gamepadยังค้าง.

## Shop / Season

อ่าน [Phase 8g](phase8_shop_season_validation.md) ก่อนแก้ receipt/สิทธิ์/ซีซัน. Config/Products = IDsจริง/runtime, Config/Season = UTCwindows/XP/rewards.
Asset listingอาจเก่า; ไม่ใช้READMEภาพเป็นสถานะระบบ. Shop34/Season29เป็นlatestfocusedchecks, olderregressionsยังต้องรันตามผลกระทบ.
## Arena

Phase 9a (2026-10-02): `ArenaService` owns local-server queues; `ArenaController` opens from the tagged ArenaPortal prompt. Config.Arena owns destination/mode player limits. Duel starts at 2; FFA 2–7 waits 15s unless full; team modes 4–6 use an even count. Ranked/Casual queues stay separate. Players must remain alive, loaded and near the portal, outside Run/carry/mount; leaving cancels. Remote spam is limited. No profile rewards are written.

Transfer uses server-only TeleportAsync with ShouldReserveServer; synchronous errors, matching TeleportInitFailed and 60s timeout release the affected player for manual requeue. TeleportData carries only mode/ranked hints, never trusted rewards/stats. **PvP=false**: lobby stays closed until a live two-account test passes; team modes/rank/token payout are pending. This is lobby code, not completion of Phase 9. Same-server matching is deliberate; cross-server matchmaking waits for real traffic.

Proof: official Luau CLI 0.740 compiles 9 changed/new Luau files; `tools/tests/RunArenaLobby.ps1 -LuauPath <luau.exe>` runs production service against isolated platform stubs, 37 checks (gates, queue split/counts, wait/timeout, all four mode sizes, transfer failure, disconnect/rate limit). Studio startup/native clicks pass: unavailable join keeps its error through state refresh, Ranked/Casual toggles, disabling PvP closes the panel. GUIHarness restores flags/pivot/anchor and writes no profile data. Source checksums match all 7 shipped scripts; Edit has no test scripts. Actual teleport/multi-account match remain unverified. [Roblox teleport limitations](https://create.roblox.com/docs/projects/teleport).

Phase 9b match server (2026-10-02): source in `arena/server/` lives in the Arena place as `ServerScriptService.Arena` (ArenaMatch module + Main script). Only lobby-reserved servers run matches; public/VIP servers send players home. Mode comes from TeleportData as a hint; unknown modes return home. Equal stats for Ranked and Casual (100 HP, speed 16), server-side tool swing: 10 damage, 8 studs, front cone, 0.5s cooldown. Last fighter wins; 180s timeout or no survivors is a draw; everyone teleports back after 8s. Phase 9c team modes: players split alternately into ทีมแดง/ทีมน้ำเงิน (Roblox Teams, odd extra sent home), no friendly hits, respawn at team base after 5s. Timber Clash: each team fells its own 300 HP tree (Humanoid model, low root so Attack reuses melee range). Egg Heist: server-owned egg pickup by touch, carried by weld, dropped on death/leave, 3 deliveries to own base pad win. A team with nobody left loses; at time-out the side further along wins, equal is a draw. No rewards, ranks or tokens yet. Proof: `tools/tests/ArenaMatchSelfTest.server.luau` 15/15 in Studio Play (mode hints, equal stats, hit/cooldown/range/dead checks, team split, ally skip, tree stand/chop/fall, outcome, solo refuses to start); 4-player team flow, egg carry and pads are unverified. MCP cannot require or inject scripts during Play in this place (Capabilities), so add the test in Edit, Play, read `ArenaMatchResults`, then delete it. Arena place published by ArmZ 2026-10-02; Config.Arena.PlaceId=135249057761883 in repo and main Studio Edit (lobby self-test forces PlaceId 0 for its unconfigured check, still 37/37). PvP flag stays false. Main place published by ArmZ 2026-10-02. Two-player match and real teleports remain unverified until a live test enables PvP in one server (Admin debug.flag).

Phase 9e combat moves (2026-10-02): hold the axe 0.8s and release for a heavy hit (25 damage, 9 studs, 1.5s cooldown) timed on the server from replicated Activated/Deactivated; light hits fire on release. F/ButtonL1 sends `ArenaAction` Block; the server sets `Blocking`, slows to 8, cuts front light hits to 30%, heavy breaks it, blockers cannot swing. Q/ButtonB dash is client-owned movement (`arena/client/ArenaInput.client.luau`, LinearVelocity 60 for 0.18s, 3s cooldown) like any walking, so it grants no server advantage. ContextActionService adds touch buttons. Phase 9f weapon skills: the lobby adds `skills={[userId]={name,element}}` from the equipped weapon (move name or weapon name) to TeleportData; E/ButtonX casts it, 8s cooldown, server-side. The element picks the shape only (fire/wind/light Cone 12 studs 20 dmg; lightning/shadow Pierce 16x2.5 line 25 dmg; others and Common Burst r8 15 dmg) so Ranked stays equal; blocks cut it from the front and blockers cannot cast. The touch button shows the skill name. Proof: arena self-test 30/30 (shapes, cooldown, ally skip, blocker), lobby 37/37 with a WeaponService stub, main startup clean. Proof for 9e: arena self-test 24/24 (heavy range/damage/cooldown, block front/back/speed/break, blocker cannot swing plus earlier checks); real input feel needs a live match.

Arena map (2026-10-02): `arena/tools/BuildArenaMap.luau` (run with MCP execute_luau in Arena Edit) rebuilds `workspace.ArenaMap`: 260-stud grass disc, cobblestone centre, 14-stud stone ring wall at r=100, four cover rocks at r=42, four logs at (±36,±38), trees outside the wall; removes Baseplate and hides the SpawnLocation at the centre. Keep the gameplay spots clear (bases x=±60, trees x=±15, egg centre, FFA ring r=30). Plain parts, no Creator Store assets; Phase 10 can dress it.

Phase 9d ranks/tokens (2026-10-02): the Arena place never touches profiles. At match end it writes `{[matchId]={result,ranked,at}}` per UserId to DataStore `ArenaPending_v1` (Studio `_Studio`); result is win/loss/draw, or `left` for anyone gone at the end. Main-place `ArenaRewardService` claims on PlayerLoaded: pays `Config.Arena.Tokens` (15/5/8/0) and Ranked-only `RankPoints` (+25/-10/0/-10, floor 0), records ids in `Arena.applied`, waits for `SaveAndWait` to hold them, then deletes those rows; a failed save leaves the rows for the next join and applied ids stop double pay. RP/wins/losses reset each UTC month (`Arena.season`); ranks Wood 0, Bronze 100, Silver 250, Gold 500, Diamond 900, Mythic 1400. The portal panel title shows rank, RP and Tokens. Admin pvp tab: `arena.rank`, `arena.win` (simulated Ranked win, marks AdminTouched), `arena.resetRank`, `arena.claim`. Ranked comes from the reserved-server TeleportData set by the lobby server. Proof: `tools/tests/ArenaRewardScenario.server.luau` 12/12 on the real profile with the Studio ledger, restored; arena `M.Results` check plus solo start passed. Tokens are not spendable yet (cosmetics wait for ArmZ); both places published by ArmZ 2026-10-02; a real arena-to-lobby payout still needs the live match test.

Place setup: main Place `93479990217075`, GameId `10768831527`. Arena was published as a new place `135249057761883` ("ArmZKubfu's Place: 10012026_4") under the main GameId (2026-10-02, verified via GetGamePlacesAsync). Old `122495944523559` (GameId `10768915988`) and the empty `102360238431045` are unused. Set Config.Arena.PlaceId only after the match server is built in `135249057761883`. Keep lobby disabled until the destination implements match entry and server-authoritative combat.

## Admin roles

Owner grants Tester/Moderator/Admin from the panel tab "จัดการผู้เล่น" (`admin.grantTester/Moderator/Admin`, `admin.revoke`, `admin.list`; Owner only, confirm 1, target one player in the server). Grants live in DataStore `AdminUsers_v1` key `users` (Studio uses `AdminUsers_v1_Studio`), so no Publish is needed; AdminService takes the highest of creator, Config.Admins, group rank and grant. Effect is immediate in that server (cache reset, panel given/removed) and on next join elsewhere. Owner cannot be granted from the menu; Config/group roles cannot be revoked there. Proof 2026-10-02: Studio remote round-trip (confirm required, grant/list/revoke/list) passed, no errors; Studio treats everyone as Owner, so a real non-owner grant still needs a live check.

## Phase 10 UI

- Current v2 assembly: 10 imported atlases with measured uploaded dimensions in `assets/ui/elements-v2/sprites.json`; runtime UIArt/UIKit (window Z1/card Z2/content Z3). Inventory detail/rarity, Garden selected plot/grid, Incubator state cards, Shop 3 columns, Rewards 4+3 calendar; English live callbacks retained. Desktop Play: HUD, Inventory, Garden selection/Seeds, Pets tabs, Shop Passes/Products and Rewards Daily/Codes/red X clicked; Incubator illustrations verified after layer fix. Final Garden row-height/encoding and Rewards shade fixes compiled/synced; final screenshots interrupted by concurrent Studio map edits. Luau120 compile (0 errors), 8/8 UI sources match Studio. Mobile/gamepad and all transaction flows remain unverified. Concurrent Sword Pack catalog drops legacy weapon IDs: saved old items need a separate migration; do not restore the old catalog. Not published/pixel-identical.

- Earlier art/design: `assets/ui/elements-v1/` has 36 sprites in four 1254-square transparent atlases, five generated concepts, crop manifest, ImageRect helper and UX screen/action matrix. Built-in image_gen prompts recorded; alpha/bounds/helper checked. Not imported/wired yet; concepts are illustrative. Use UX.md for assembly/state/mobile rules; existing runtime proof below remains separate.

- Shared UIKit.Window: brown wood panels/rim/grain, outlined icon headings, red X, bright buttons; local BlurEffect=18 while a modal/More is open, 0 when closed. Navigation reuses existing callbacks. Primary Inventory/Pets/Garden/Shop/Rewards + More, compact Menu, one modal and outside-click close.
- Inventory: four-column rarity cards, selected 3D preview/details, Weapons/Chests tabs; original equip/fuse/delete/open intents. Shop: two-column cards, actual IconImageAssetId/live prices from GetProductInfo, atlas fallback; original server prompts. Index: category counts/gallery, discovered cards/unknown silhouettes; rebuild only when category/discovered IDs change, preserving buttons during 1-second refresh. Weapon previews still use procedural WeaponVisual; pets/seeds use category art.
- Track C (2026-10-02): phones (`compact`, short side <500 or width <700) fit big windows to the full height beside `GuiService.TopbarInset` (or below the topbar if larger); Roblox Backpack hidden while a window/menu is open. Gamepad: opening a window selects its top-left control, gold `SelectionImageObject`, ButtonB closes. Window headings `TextScaled` 46→18 (set after `TextWrapped=false`, which clears it). NavigationHUD is Global ZIndex: lift children above row frames. Audit: `tools/ui/UIAudit.luau`, results [UX-audit](../assets/ui/UX-audit.md).
- Settings: independent session-local Music/SFX ON/OFF. Music identified by SoundCategory=Music, SoundGroup.Name=Music or name containing music/ambience; everything else SFX. Cache original Volume strongly until restored (weak keys lost it); handle sounds added while muted and cleanup destroyed sounds.
- Image `121083844656821`, source `assets/ui/woodland-icons-v2.png`; uploaded texture 1024, individual padded crop bounds Config/UIIcons. Source grid1254 caused tiny/mixed icons; Play screenshots confirmed corrected art. Live English labels, legacy `.thai` metadata/internal element IDs retained.
- 2026-10-02 proof: Luau129 compile; real desktop clicks Inventory4 columns/selection/X, Shop tabs (17 live product prices; visible Gems icons loaded), More/Settings, Index (100 weapons/3 collected; Seeds8/5 collected), Pets and blur close/restore. Music/SFX mute/restore independence + new Music sound checked with local Sound fixtures, cleaned afterwards; no purchase/profile mutation. Earlier English migration: source79/79, icons12/12, Thai PlayerGui0, Run.Play guards10/10 isolated (Run.Begin stubbed).
- Final Edit source checksum: changed5/5 match repo; no injected scripts/local fixtures left. Index grid retained through periodic refresh. Pending: every flow, mobile/gamepad, per-item art, full world art/VFX/audio/balance, paid Player purchase/reconnect and multi-account Arena. No Publish in this UI work.
