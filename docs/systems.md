# System reference — Chop a Tree

อ่านเฉพาะ heading ของงาน. สถานะล่าสุด/งานค้าง: [HANDOFF](HANDOFF.md). รายละเอียด intent: [design](design.md).
ผลตรวจด้านล่างเป็นรอบเดิม ไม่ใช่ regression หลังร้าน. Raw reports/screens ก่อน cleanup อยู่ Git commit `5d09e37`; scenario ที่รันซ้ำได้ยังอยู่ `tools/tests/`.

## Map

- PlaceId 93479990217075; GameId 10768831527. ทวีป 2100×1100, โซนล่าง 500×480/grid500 ชิดกัน, แม่น้ำ20/สะพานตะวันออก; เกาะ300เหนือโซน7. ทั้ง8 built=true.
- Workspace.Map.Village + Wilds.ZoneN_Key. Trunk โปร่งใส PrimaryPart/collider; Look ไม่ชน. Prototype ServerStorage.MapAssets.Trees.ZoneKey; AssetPrototypes Sources → AssetStaging → Build/Report scripts=0.
- Boss GuardianOffset26 studs ห่างทางเดิน (โซน8ด้านข้าง Lumora). ValidateRoutes ใน Edit+Play; ZoneAmbience ใช้ Run.ZoneAt footprint ไม่เปลี่ยน Lighting/mutation.
- Route เดิม 2048 samples/16 walks; Phase7 23 checks. ผังภูเขาเลิกใช้. หลังเปลี่ยนภูมิประเทศตรวจใหม่ ไม่อ้างรายงานเดิมแทนผลใหม่.

## Run / weapons

- RunService owns Run/access/award/AutoCut reward/ChestLevel; WeaponService owns random/equip/fuse/delete. Loot+Balance+Config เป็นสูตรร่วม.
- ไข่ Nest secure เฉพาะส่งหินวาร์ป/End Run ที่ถูกต้อง; ตาย/ออก/Endแบบอื่น Drop. รางวัลอื่นใช้กติกา RunService.
- อาวุธใหม่คง UID/definition ID, Tool+viewport Handle/WeaponId/ForestAxe, Giant×3.
- Phase2 23, Phase3 36; fixtures ใน tools/tests. Power thresholds/EXP/odds ดู Balance/Config. หีบหลายใบไม่เปลี่ยน odds.

## Garden

- GardenService owns 7ฐาน/OwnerUserId/BaseIndex; ownership reuse ผ่าน BaseById/OwnerOf. GardenSlots runtime30.
- Crops เก็บ seed UID/sourceZone/Rot/admin/timestamps. Offlineโตปกติ ไม่ mutation/harvestย้อนหลัง; สูตร Mutation = พิเศษสูงสุด × (1+ผลรวมอื่น), รวม parent tagsก่อนราคา.
- GardenMath.SellQuote เป็นทางเดียว: cap UTCตาม highest mutation, Garden.sellDay/sold; OverCapMult จาก Config.Garden.
- UI refreshใช้ปุ่มเดิมไม่สร้างซ้ำ; state packet/DataPatch มาช้ากว่า responseได้. Phase4 55 checks.

## Pets / stealing

- PetService owns eggs/incubator/pets/pen/buffs/Mount/belt; StealService owns theft/lock/shield/bots; NestService owns forest nests/guardians.
- ไข่ขโมยอยู่ profileเจ้าของและ carriedBy จนส่งถึงฐาน แล้วโอนในเธรดเดียวไม่ yield. ห้ามลบตอนเริ่มถือ; protected Robux eggsขโมยไม่ได้.
- Pet.Mult เป็นจุดบัฟ; ApplySpeed รวม AdminSpeed×Mount×buff×CarryMult. Humanoid float32 assert tolerance ≥1e-3.
- Mount StoryChapter2 gate; ไข่โซน3–8 belt=0. Catalog43หลังเพิ่ม Blood Raven. Phase5 81 checks; botไม่ได้แทน multi-account proof.

## Story / bosses

- QuestService owns story/daily/weekly/Index; StoryService owns NPC/shrine/unlock/warp; BossService guardian. Progress.Bosses/Shrines keysเป็นstring.
- Counter questsใช้ Stats delta; เพิ่ม Data.Increment+Config.Story row. daily/weekly deterministic UTC.
- Balance.BossHP/BossRequiredPower เจ้าของสูตร; built=trueจึงสร้างboss. Server Run.CanAccess ก่อน reward. Phase6 51, Phase7 23 checks; บทเฉพาะ/NPC/คัตซีนยังค้าง.

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
- NewmutationขยายIndex/fixturesแต่คงcompletionmarker. Phase8e15checks; festivaldecorยังค้าง.

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

Phase 9b match server (2026-10-02): source in `arena/server/` lives in the Arena place as `ServerScriptService.Arena` (ArenaMatch module + Main script). Only lobby-reserved servers run matches; public/VIP servers send players home. Mode comes from TeleportData as a hint (Duel/FFA only; team modes return home with a message). Equal stats for Ranked and Casual (100 HP, speed 16), server-side tool swing: 10 damage, 8 studs, front cone, 0.5s cooldown. Last fighter wins; 180s timeout or no survivors is a draw; everyone teleports back after 8s. No respawn, rewards, ranks or tokens yet. Proof: `tools/tests/ArenaMatchSelfTest.server.luau` 10/10 in Studio Play (mode hints, equal stats, hit/cooldown/range/dead checks, outcome, solo refuses to start). MCP cannot require or inject scripts during Play in this place (Capabilities), so add the test in Edit, Play, read `ArenaMatchResults`, then delete it. Arena place published by ArmZ 2026-10-02; Config.Arena.PlaceId=135249057761883 in repo and main Studio Edit (lobby self-test forces PlaceId 0 for its unconfigured check, still 37/37). PvP flag stays false. Two-player match and real teleports remain unverified until the main place is published and PvP is enabled for a test.

Place setup: main Place `93479990217075`, GameId `10768831527`. Arena was published as a new place `135249057761883` ("ArmZKubfu's Place: 10012026_4") under the main GameId (2026-10-02, verified via GetGamePlacesAsync). Old `122495944523559` (GameId `10768915988`) and the empty `102360238431045` are unused. Set Config.Arena.PlaceId only after the match server is built in `135249057761883`. Keep lobby disabled until the destination implements match entry and server-authoritative combat.
