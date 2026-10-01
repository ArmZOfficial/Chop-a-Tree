# HANDOFF — Chop a Tree (สำหรับ AI ตัวถัดไป)

> อัปเดตล่าสุด: 2026-10-01 (เวลาไทย) · Phase 6 เนื้อเรื่อง/เควส/บอส core ทดสอบแล้ว
> **อ่านไฟล์นี้ก่อน แล้วอ่าน `docs/plan.md` (แผนหลัก ร่างที่ 10) ประกอบ**

## 0. เริ่มตรงนี้ (สถานะล่าสุด)

1. Phase 0 เสร็จแล้ว; Phase 1 เปลี่ยนจากภูเขาเป็น **ทวีปตัว S เสร็จและทดสอบแล้ว** ใน Studio PlaceId `93479990217075`.
2. ArmZ อนุญาตชัดเจน **ลบแมพภูเขาเดิม แล้วสร้างแมพใหม่**; ทำแล้ว ไม่ต้องถามซ้ำ.
3. ArmZ สั่ง **ทำต่อเลย** อีกครั้งหลัง Phase 5 → **Phase 6 core ทำแล้ว**: บอสผู้พิทักษ์โซน 1–2, ศาลเจ้า/ปลดโซน, ประตูราเน่ารายคน, หินวาร์ป, ปู่ Bram บทพูด, เควสหลัก 8 บท (3–8 รอ Phase 7), รายวัน/สัปดาห์, Index, UI เควส/นำทาง/แถบบอส, admin แท็บโซน & เนื้อเรื่อง; อ่าน `docs/phase6_validation.md` ก่อนต่อ **Phase 7 โซน 3–8 แบบเต็ม** (ต้องถามรายละเอียดก่อนสร้างแมพ — skill `roblox-map-builder`). ก่อนหน้านั้น **Phase 5 core ทำแล้ว**: ไข่ 4 ชนิด/สัตว์ 12 ตัว (โซน 1–2), ตู้ฟัก 3 ช่อง, คอกรายได้ (สูงสุด 8 ชม.), พกติดตัว 3 ตัว+บัฟ, หลอมขั้น, Mount, สายพานไข่ UTC, รังป่า+ผู้พิทักษ์, ไข่จากหีบ, ขโมยไข่/ทวงคืน, ล็อกฐาน, โล่ผู้เล่นใหม่/AFK, อัปเกรดฐานด้วย Wood, UI และ admin แท็บไข่ & สัตว์. อ่าน `docs/phase5_validation.md` ก่อนต่อ **Phase 6 เนื้อเรื่อง/เควส/บอส**. ค้างจาก Phase 5: ตกแต่งฐาน, กับดัก/สัตว์เฝ้าฐาน, ทดสอบขโมยกับผู้เล่นจริงหลายบัญชี.
4. ผลตรวจ: raycast 2,048 จุด ไม่มีพื้นขาด ขั้นสูง >3.5 studs หรือสิ่งกีดขวาง (ยกเว้นประตูที่ตั้งใจปิด). Play เดินจริงผ่านครบ **16 เส้นทาง**: ทางเชื่อม 8 เส้น + ทางในโซน 8 เส้น. ทางเชื่อมพื้นดินเดินที่ WalkSpeed 16, รากขึ้นฟ้า 80, ทางในโซน 40 เพื่อเร่งทดสอบ. ใช้ PreparePlayRoutes.luau (Server) แล้ว PlayRoutes.luau (Client).
5. Phase 6 ผ่าน **51/51** (`docs/phase6_test_results.json`) + input จริง (กด E คุย Bram, ต่อไป/ข้าม, รับรางวัลรายวัน, วาร์ปโซน 1, แถบบอส); regression Phase 2/3/4/5 ผ่าน **23/36/55/81**; ภาพ `docs/screens/phase6_dialog.jpg`, `phase6_guardian.jpg`. Phase 5 ผ่าน **81/81** (`docs/phase5_test_results.json`) + mouse GUI วางไข่/ฟัก/พกสัตว์/ล็อกฐาน/อัปเกรดคอก. Regression Phase 2/3/4 ผ่าน **23/36/55**. ภาพ `docs/screens/phase5_pets_base.jpg`, `phase5_follow_lock.jpg`. ชุดทดสอบ `tools/tests/Phase5Scenario.server.luau` และ `Phase5GUIHarness.server.luau` (ใส่เป็น Script ชั่วคราวตอน Play ผ่าน execute_luau ตั้ง `Source`); คืน profile จริงแล้ว. ขโมยทดสอบกับฐานบอท/บอทขโมย ยังไม่ได้ทดสอบสองบัญชีจริง.
6. โค้ด Phase 6 ที่เพิ่ม/แก้ **17 ไฟล์**ตรง Studio Edit ตาม `docs/phase6_source_checksums.json` (checksum Phase 3/4/5 เป็นบันทึกรอบก่อน; ไฟล์ที่แก้ซ้ำใช้ค่าของ Phase ล่าสุด). Zones/MapBuilder ไม่แก้; ใช้ Incubator/PetPen/LockBarrier/Nest/EggConveyor ที่แมพสร้างไว้. Studio กลับ Edit ไม่มี test Script ค้าง; ประตูโซนยังปิดตามปกติ. ห้าม overwrite ProfileStore ใน Studio ด้วยไฟล์จาก repo.
7. ยังไม่ได้ Publish การเปลี่ยนแมพขึ้นเกมจริง; ผู้ใช้ต้อง Save/Publish ใน Studio เพื่อเก็บ place. GitHub เก็บตัวสร้างแมพและโค้ด.

---

## 1. โปรเจกต์คืออะไร

1. เกม Roblox ชื่อ **Chop a Tree** ของ **ArmZ** (GitHub: ArmZOfficial) ผสม 3 แนว: ฟันต้นไม้เก็บหีบ (แรงบันดาลใจ Cut Trees) + ปลูกสวน (Grow a Garden) + ขโมยไข่/เลี้ยงสัตว์ (Steal an Egg) มีเนื้อเรื่อง "The Withering"
2. แมพเดียวใหญ่ **ทวีปกว้างแนวนอน** (ทางคดตัว S ผ่าน 8 โซน + เกาะลอยฟ้าโซน 8 — เลิกภูเขาเกลียวแล้ว ดู plan.md หัวข้อ 3), หมู่บ้าน Rootfall มีฐานผู้เล่น 7 ฐาน, PvP เป็น Place แยก
3. ชื่อ เรื่องราว และเอกลักษณ์เกมออกแบบเอง; การเลือกและนำ asset จาก Creator Store มาใช้ให้ทำตาม `SKILL.md` ที่ root ของ repo (ArmZ อนุญาตแล้วเมื่อ 2026-10-01).

## 2. วิธีทำงานกับ ArmZ (สำคัญ)

1. **ตอบเป็นภาษาไทย** ใช้ bullet แบบมีตัวเลข
2. ชอบแก้เอกสารแผนฉบับเดียวไปเรื่อยๆ + **มีตัวเลือกให้เลือก (ใส่ Recommended)** ก่อนลงมือ
3. ก่อนสร้างแมพ **ต้องถามรายละเอียดก่อน** (skill `roblox-map-builder`)
4. **ถ้าใกล้เต็ม limit ของ AI ให้หยุดแล้วสรุปลง .md ทุกครั้ง** (ไฟล์นี้) เพื่อส่งต่อ AI ตัวอื่น
5. ทุกครั้งที่แก้ → commit + push ขึ้น GitHub (ใส่ Co-Authored-By ตามที่ระบบกำหนด)
6. ทุกครั้งที่อัปเดตงาน ให้ปรับ `docs/plan.md`, `SKILL.md` และ `docs/HANDOFF.md` ให้สอดคล้องกันก่อนสรุปงาน ตามกฎใน `SKILL.md` (ArmZ สั่งเมื่อ 2026-10-01).

## 3. ลิงก์และที่อยู่

| อะไร | ที่ไหน |
|---|---|
| Repo | https://github.com/ArmZOfficial/Chop-a-Tree (branch `main`, private) |
| แผนหลัก | `docs/plan.md` (หัวข้อ 0–18) |
| อาวุธ 100 ชิ้น | `docs/weapons.md`, `data/weapons.json` |
| ตัวจำลอง Balance | `tools/balance_sim.py` → ผลใน `docs/balance_report.txt` |
| Roblox Studio place | **"Chop a Trees"** PlaceId `93479990217075`, GameId `10768831527`, เจ้าของ UserId `7488194538` (ArmZ) |
| Mockup Admin Panel | Artifact "Chop a Tree Admin Panel" (claude.ai) |

> หมายเหตุ: เดิมทำใน "Place2" แล้ว ArmZ ย้ายไป place ใหม่ "Chop a Trees" (เผยแพร่แล้ว) — สคริปต์ Phase 0 ทั้งหมดและ `Config.Zones` ย้ายมาครบ ตรวจแล้ว (RS 11 สคริปต์, SSS 9, ServerStorage 2, StarterPlayer 4) Baseplate + SpawnLocation เดิมถูกย้ายไป `ServerStorage.OldTemplate` แล้ว (ไม่ได้ลบ)

## 4. สถานะ Phase

| Phase | สถานะ |
|---|---|
| วางแผน (plan.md ร่างที่ 10) | ✅ อัปเดตสถานะ Phase 6 และงาน UI แล้ว |
| **Phase 0 ฐานราก** | ✅ เสร็จ ทดสอบแล้วใน Studio ไม่มี error, commit `5f6f7e8` |
| **Phase 1 แมพโครง** | ✅ ทวีปตัว S กระชับ สร้างและทดสอบแล้ว |
| **Phase 2 ฟันต้นไม้ + Run** | ✅ core ผ่าน 23 checks + GUI; AFK ไม่จำกัดเวลายังไม่รองรับ, โล่ AFK รอ Phase 5 |
| **Phase 3 หีบ + อาวุธ** | ✅ core ผ่าน 36 checks + GUI; ภาพโมเดล procedural รอขัดเกลา Phase 10 |
| **Phase 4 สวน + อากาศพื้นฐาน** | ✅ core ผ่าน 55 checks + GUI; ทดสอบเซิร์ฟจริงหลายเครื่อง/มือถือและภาพ/เสียง/UI สุดท้ายยังค้าง |
| **Phase 5 ไข่ + สัตว์ + ขโมย + ฐาน** | ✅ core ผ่าน 81 checks + GUI; ค้างตกแต่งฐาน/กับดัก และทดสอบขโมยหลายบัญชีจริง |
| **Phase 6 เนื้อเรื่อง + เควส + บอส** | ✅ core ผ่าน 51 checks + GUI; บท 3–8 รอ Phase 7, บัฟ Index/Achievements รอ Phase 8 |
| Phase 7–10 | ⬜ ยังไม่เริ่ม (ดู plan.md หัวข้อ 7, 16) |

## 5. Phase 0 ที่ทำแล้ว (โครงโค้ด Rojo)

| ในเกม | ไฟล์ใน repo | หน้าที่ |
|---|---|---|
| `ReplicatedStorage.Shared.Config.*` | `src/shared/Config/` | Admins, Features, Currencies, Rarities, BalanceConfig, AdminTabs, Weapons (สร้างจาก JSON), **Zones (ใหม่ Phase 1)** |
| `Shared.NumberFormat` | `src/shared/NumberFormat.luau` | ย่อเลข K/M/B…/Dc/UDc…, Parse("2.5Qa") |
| `Shared.Balance` | `src/shared/Balance.luau` | สูตรทั้งเกม + SelfTest (ต้องตรง balance_sim.py) |
| `Shared.Net` | `src/shared/Net.luau` | Remotes: DataPatch, Notify, AdminEvent, DataRequest, AdminRun |
| `Shared.UIKit` | `src/shared/UIKit.luau` | ปุ่ม/ป้าย/Toast สไตล์เกม (ขอบดำหนา เงาล่าง) |
| `ServerScriptService.Server.Main` | `src/server/Main.server.luau` | โหลด Service → Init → ลงทะเบียนคำสั่งแอดมิน → Start |
| `Server.Services.DataService` | ProfileStore + DataVersion + Migration + Backup/Restore + Export/Import JSON |
| `Server.Services.FeatureService` | Feature flags เป็น Attribute บน `ReplicatedStorage.FeatureFlags` |
| `Server.Services.AdminService` | ยศ (Studio=Owner, เจ้าของเกม, UserId list, Group rank), Register คำสั่ง, rate limit 8/วินาที, ยืนยัน 1–2 ชั้น, log |
| `Server.AdminCommands.*` | Player/Money/Data/Debug(+Mod) commands — 34 คำสั่ง |
| `Server.Packages.ProfileStore` | ใน Studio ใช้เวอร์ชัน Creator Store (asset 109379033046155, Sandboxed=false) ใน repo ใช้เวอร์ชัน GitHub (ต่างกันเล็กน้อย ไม่เป็นไร) |
| `ServerStorage.AdminUI.AdminPanel` | `src/admin/AdminPanel/` | ScreenGui + Controller (LocalScript) + CommandParser — ส่งให้เฉพาะคนมียศ |
| `StarterPlayerScripts.Client.*` | `src/client/` | Main, ClientData, HUD (Coins/Wood/Gems), AdminEffects (บิน/ทะลุ) |

**ผลทดสอบ Phase 0**: คำสั่งผ่านหมด, ยืนยัน 2 ชั้นบล็อกถูก, rate limit ทำงาน, HUD อัปเดตสด, Balance SelfTest 8/8, กดปุ่ม UI จริงได้ (ซ่อนหน้าต่างแชทตอนเปิดแผงเพราะแชทของ Roblox ทับฝั่งซ้าย)

**อัปเดต Phase 3**: `Config.Weapons` 100 ชิ้นใส่ใน Studio แล้ว. ดู `docs/phase3_validation.md` สำหรับ WeaponService, Loot, WeaponVisual และ InventoryController.

**อัปเดต Phase 6**: BossService (ผู้พิทักษ์ tag `Boss`), QuestService (เควสหลัก/รายวัน/สัปดาห์/Index), StoryService (NPC/ศาลเจ้า/ปลดโซน/วาร์ป), Config.Story, StoryController และ AdminCommands.StoryCommands ใส่ใน Studio แล้ว; Feature `Story` เปิด. Service order ต่อท้าย: … TreeService → BossService → QuestService → StoryService. Remotes ใหม่ QuestState/StoryShow/BossEvent/StoryAction. อ่าน `docs/phase6_validation.md`.

**อัปเดต Phase 5**: PetService (ไข่/ตู้ฟัก/สัตว์/คอก/บัฟ/Mount/สายพาน), StealService (ขโมย/ล็อกฐาน/โล่/บอททดสอบ), NestService (รังป่า/ผู้พิทักษ์), Config.Eggs/Pets/Base + PetMath/PetVisual, PetController และ AdminCommands.PetCommands ใส่ใน Studio แล้ว. Service order: … WeaponService → PetService → StealService → NestService → RunService → TreeService. Remotes ใหม่ PetState/PetShow/PetAction/BaseAction. อ่าน `docs/phase5_validation.md`.

**อัปเดต Phase 4**: GardenService เป็นเจ้าของฐาน/เมล็ด/ผล/แปลง; WeatherService ส่ง WeatherState โดยใช้ WeatherSchedule UTC. Config.Seeds/Garden/Weather/Mutations + GardenMath, GardenController/WeatherController และ AdminCommands.GardenCommands ใส่ใน Studio แล้ว. DataService v1 Reconcile เพิ่ม Garden และ Seeds/Fruits/Run.Seeds; อ่าน `docs/phase4_validation.md` สำหรับค่าตั้งต้น mutation formula และการทดสอบ.

## 6. Phase 1 — ทวีปใหม่ (เสร็จ)

### 6.0 ผังปัจจุบัน

1. ทวีป 2,100×1,100 studs; โซน 1–7 เป็นสี่เหลี่ยมมุมมน 500×480, grid 500, ไม่มีช่องคั่นในแถวเดียวกัน; แม่น้ำกว้าง 20. ArmZ ขอให้โซนชิดรวมกันหลังดูผังแรกแล้ว.
2. หมู่บ้านตะวันตกเฉียงใต้ → 1→2→3 ไปตะวันออก → สะพานเดียวข้าม Root River → 4→5→6→7 กลับตะวันตก.
3. พื้น Y 4/12/20/30/40/52/64; เชื่อมด้วยทางลาดสั้น โดยเจาะช่องรับทางลาดในชั้น Soil และ Meadow ลึก 34 studs เพื่อไม่ให้พื้นสูงขวางทางเข้า. Layout.trailStart/trailEnd แยกช่วงพื้นราบออกจากทางลาด. เนินเตี้ยริมชายฝั่ง. โซน 8 Y=364 (สูงกว่าโซน 7 300 studs), เกาะกลม 500 studs + รากเกลียว 4 รอบและเสาแสง.
4. ชื่อใหม่: ป่าไผ่สายฟ้า, Frostvale/ทุ่งน้ำแข็ง, ทุ่งคริสตัล. `Config.Zones` ใช้ col,row,halfSize แทนค่าภูเขา.
5. หมู่บ้าน 7 ฐาน, ต้นไม้ 160 ต้นต่อโซนในโซน 1–2, โซน 3–8 PreviewTree 14 ต้นต่อโซน. สวน/รัง/หีบ/ศาลเจ้า/บอส/ประตู/วาร์ปยังเป็นจุดรองรับระบบตาม Phase.
6. แนวหนามราเน่าเป็นขอบโซน มีกำแพงสูง 12 studs และหนาม. ช่องทางผ่านตรงกับเสาประตู; ประตูปิดจนมีระบบปลดล็อกใน Phase 6.
7. แก้หินวงลานบอสที่ขวางทางเดิน: `bossArena()` เว้นช่องตาม trail. ห้ามคืนหินที่ทับทางเดิน.
8. ของภูเขาเก่าอยู่ใน Git history `3522508`; ไม่อยู่ใน Workspace แล้ว (ArmZ อนุญาตลบ).

### 6.1 คำตอบของ ArmZ ที่ยังใช้กับผังใหม่
1. หมู่บ้าน: **วงกลมรอบลานกลาง** (แท่นหีบกลาง, ร้าน/NPC วงใน, ฐาน 7 ฐานวงนอก, เว้นช่องตรงประตูป่า) — ลานเป็นสนามหญ้า ลานกลางเป็นหิน
2. โมเดล: ธีม fantasy anime / low-poly; แนวทาง Creator Store ล่าสุดอยู่ใน `SKILL.md` (แทนข้อกำหนดเดิมที่สร้างจาก Part เองทั้งหมด).
3. ต้นไม้: **160 ต้น/โซน** ในโซนที่สร้างเต็ม (1–2), โซน 3–8 เป็นโครง (PreviewTree 14 ต้น + ป้าย "สร้างเต็มใน Phase 7")
4. ~~ทางขึ้นเขาเกลียว~~ → ยกเลิก ใช้ทวีปตัว S แทน

### 6.2 ไฟล์และ Studio (ตรงกันแล้ว)

1. `src/shared/Config/Zones.luau` → `ReplicatedStorage.Shared.Config.Zones`: UTF-8 LF **4,100 bytes, hash=1795469735**.
2. `tools/map/MapBuilder.luau` → `ServerStorage.MapTools.MapBuilder`: UTF-8 LF **45,794 bytes, hash=182475945**.
3. `Workspace.Map.{Ground,Water,Hills,Roads,Village,Wilds.Zone1..8}`; 4,619 BaseParts. ไม่มี Mountain.
4. `Layout()/RoadPoints()/BuildWorld()/BuildZone()` ใช้ผังใหม่; `BuildVillage()` เดิมยังใช้. MapBuilder require Zones ด้วย `:Clone()` กัน require cache เก่า.
5. Lighting Future, Atmosphere Density 0.2/Offset 0.3/Haze 0.3, StreamingEnabled=true.
6. Studio id ล่าสุด `c1163648-12f6-4336-9953-e3d19be9259a`; ชื่อหน้าต่างเป็น Place2 แต่ตรวจ PlaceId/GameId แล้วเป็นเกมถูกต้อง. **เรียก list_roblox_studios และตรวจ PlaceId ทุกครั้งก่อนเขียน** เพราะ id เปลี่ยนเมื่อเปิด Studio ใหม่.

### 6.3 บทเรียนจากแมพภูเขา (เอาไปใช้กับผังใหม่)
1. **กำแพงล่องหนรอบโซนต้องเว้นช่องกว้างพอ**: ช่อง = ครึ่งความยาวกำแพง + 16 (ถนนกว้าง 26) ไม่งั้นบังทางเข้า
2. **ทางเชื่อมต้องถึงระดับพื้นโซนก่อนชนขอบ** ไม่งั้นเหลือขั้น 6–12 studs เดินขึ้นไม่ได้ (Humanoid ก้าวขึ้นได้แค่ ~2–3 studs)
3. RealmGate ต้องอยู่ **ฝั่งตรงข้ามทางเข้า** (`C + inward * (radius - 20)`) — แก้แล้วในโค้ด
4. หมอกต้องบาง (Density 0.2/Haze 0.3) ไม่งั้นมองไกลไม่เห็น — สำคัญกับเกาะลอยโซน 8 ที่ต้องเห็นจากทั่วแมพ
5. วิธีตรวจที่ใช้ได้ผล: (ก) Edit mode raycast ลงพื้นทุก 4 studs ตามเส้นทาง เช็คขั้นสูง >3.5 และสิ่งกีดขวางระดับอก (ข) Play แล้ว `Humanoid:MoveTo` ทีละจุด
6. ตอนทดสอบใน Play: StreamingEnabled เปิดอยู่ → เรียก `player:RequestStreamAroundAsync(pos)` ก่อนวาร์ป ไม่งั้นตัวละครตกทะลุพื้น; `execute_luau` timeout 60 วิ → งานยาวใช้ `task.spawn` แล้วอ่านผลจาก `_G` ในการเรียกครั้งถัดไป
7. คำสั่งรัน (หลังเขียนใหม่ก็ใช้แบบเดียวกัน):
   ```lua
   local B = require(game.ServerStorage.MapTools.MapBuilder:Clone())
   B.BuildWorld() ; B.BuildVillage() ; for i = 1, 8 do B.BuildZone(i) end
   return B.Report()
   ```
8. ภาพแมพภูเขา (ไว้เทียบ): `docs/screens/phase1_overview.jpg`, `phase1_village.jpg`, `phase1_zone1.jpg` — commit `3522508`

### 6.4 Tags / Attributes ที่แมพสร้าง (ระบบ Phase 2+ ใช้)
`Tree` (Zone, Tier 1–6), `PreviewTree`, `ChestSpot` (Zone, Depth), `Nest` (Zone, EggType), `ZoneGate` (FromZone, ToZone, Open), `WarpStone` (Zone; 0 = หมู่บ้าน), `ZoneSpawn` (Zone), `BossArena` (Zone, Boss), `Shrine` (Zone, Lit), `PlayerBase` (BaseIndex, OwnerUserId), `GardenSlot` (BaseIndex, SlotIndex), `Incubator`, `PetPen`, `OwnerSign`, `BaseSpawn`, `Shop` (ShopType), `NPC` (NpcId), `Leaderboard` (Board), `ForestGate`, `ArenaPortal`, `RealmGate`, `Lumora`, `ChestAltar`
— ค่า HP/รางวัลของต้นไม้ **ไม่เก็บในโมเดล** ให้คำนวณจาก `Shared.Balance` ตาม Zone/Tier

## 7. ตัวเลขสำคัญ (ล็อกแล้ว — plan.md หัวข้อ 14)

1. โซน ×100 ต่อโซน, ต้นไม้ 6 ระดับ HP โซน 1 = 1K/3K/7K/12K/20K/30K, Power ขั้นต่ำ = HP/8 (ระดับ 1 = 0) เทียบ Cut Power ที่รวมตัวคูณรอบ
2. ตัวคูณรอบ 1.08^เลเวล, EXP ต่อเลเวล 2.5K × 1.25^เลเวล × 100^(โซน−1)
3. ความหายาก Common 125 / Rare 375 / Epic 1.25K / Legendary 4K / Mythic 12.5K (สุ่ม ×1–×4), Item Level ×100/โซน, ดาว +50%/ดาว, Giant ×5
4. Auto Cut −45% (EXP/Wood/Coins/โอกาสเมล็ด) → ผลรวม 50–55% ของเล่นเอง, ใช้ฟรีทุกคน, AFK ได้
5. Rebirth: ราเน่า ×10^R, พลัง ×1.5^R, ครั้งแรกหลังบอสโซน 4
6. เติมเงินไม่ P2W: Game Pass กับทางฟรีไม่ทับกัน, ไข่ Robux ขโมยไม่ได้, PvP Ranked ค่าเท่ากัน

## 8. วิธีซิงก์โค้ดเข้า Studio (ข้อควรรู้)

1. **ArmZ ยังไม่ได้ลง Rojo** → ตอนนี้ใส่โค้ดด้วย MCP `multi_edit` ทีละไฟล์ (old_string ว่าง = สร้างใหม่) แล้ว**ตรวจ checksum** ว่าตรง repo:
   - Python: `h=(h*31+byte)%2147483647` ทุกไบต์ของไฟล์
   - Luau ใน Studio: วนเดียวกันบน `script.Source`
2. Studio เข้าเว็บภายนอกไม่ได้ (HttpEnabled ปิด, repo private) → ดึงจาก GitHub ไม่ได้
3. `require` จาก `execute_luau` มี cache แยกจาก Script ในเกม. ใช้ `:Clone()` เมื่อตรวจโมดูล stateless ใน Edit; **ห้าม require DataService จาก MCP เพื่ออ่าน live profile**. ทดสอบ service ใน Play ด้วย Script ชั่วคราว แล้วอ่านผลจาก workspace attributes. Net reuse Remotes เดิมแล้ว.
4. คลิกเมาส์ทดสอบ: ใช้ `instance_path` ดีกว่าพิกัด (พิกัดมี GUI inset ~58px), หน้าต่างแชท Roblox ทับมุมซ้ายบนและบล็อกคลิก
5. รอบ Play ล่าสุด ProfileStore แจ้ง "Roblox API services available - data will be saved" (เปิด API services แล้ว)
6. เครื่องมือ Studio: `mcp__remote-devices__Roblox_Studio__*` — studio_id ล่าสุด **`c1163648-12f6-4336-9953-e3d19be9259a`** (เปลี่ยนได้ ให้เรียก list_roblox_studios ก่อน)

## 9. สิ่งที่ ArmZ ต้องทำเอง (แจ้งไว้แล้ว)

1. Save/Publish place ใน Studio เมื่อพร้อม; รอบล่าสุด API services เปิดแล้ว
2. ลง Rojo (plugin + CLI) แล้ว `rojo serve` ในโฟลเดอร์ repo
3. (ทางเลือก) ใส่ UserId ทีมงาน/GroupId ใน `Config/Admins.luau`

## 10. Phase ถัดไป

1. **Phase 7 โซน 3–8 แบบเต็ม**: ตาม skill `roblox-map-builder` **ต้องถามรายละเอียดหน้าตาแต่ละโซนกับ ArmZ ก่อนสร้าง** (ธีม/ต้นไม้/ของตกแต่ง/asset Creator Store ตาม `SKILL.md`). หลังสร้างให้ตั้ง `Config.Zones[n].built=true` — บอส บทเควส วาร์ป และประตูจะทำงานเอง; ต้องเพิ่มไข่/สัตว์ของโซน (Config.Eggs/Pets ตาม EggType ของรัง) และตรวจเส้นทางด้วย `tools/map/ValidateRoutes.luau`.
2. ค้างจาก Phase 5–6: **ตกแต่งฐาน (plan 9.2)**, กับดัก/สัตว์เฝ้าฐาน, ทดสอบขโมย/ตีบอสร่วมกับผู้เล่นจริง 2+ บัญชี, แก้ GardenController ไม่ให้สร้างปุ่มใหม่ทุก 2 วิ (มีงานแยกเสนอไว้แล้ว), NPC อื่นตามเนื้อเรื่อง (พ่อค้ากระรอก/นักวิจัย), บัฟถาวร Index + Achievements (Phase 8).
3. อ่าน `docs/phase6_validation.md`, `phase5_validation.md`, `phase4_validation.md`, `phase3_validation.md` สำหรับ seams. ยังต้องทดสอบ multi-account/multi-server มือถือ/gamepad. อากาศชุดที่เหลือ/Live Event/ไข่ Robux/Secret/Rebirth ต่อ Phase 8; art/เสียง/โมเดลบอส-สัตว์/คัตซีน/UI polish ต่อ Phase 10.
4. **ทุก Phase ต้องเพิ่มปุ่มทดสอบใน Admin Panel** ผ่าน `AdminService.Register` และปิดระบบที่ยังไม่พร้อมด้วย Feature Flag
5. ArmZ ขอระบุ **งานปรับปรุง UI** ในแผนแล้ว: Phase 10 ครอบคลุม HUD, Run, Inventory, เปิดหีบ, สวน/เมล็ด, ไข่/สัตว์, เควส/Index, พยากรณ์อากาศ, ร้านค้า และ Admin Panel ให้เป็นสไตล์เดียวกัน อ่านง่ายและกดสะดวกบนคอมพิวเตอร์/มือถือ พร้อมขัดเกลาภาพแมพ แสง เสียง VFX และแอนิเมชัน (ดู plan.md หัวข้อ 7).

## 11. Skill ที่ใช้

- `../SKILL.md` — อ่านเมื่อเลือกหรือนำ asset มาใช้ใน Chop a Tree; เป็นแนวทางล่าสุดที่ ArmZ อนุญาตให้ใช้ Creator Store เพื่อช่วยงาน.
- `roblox-map-builder` (skill ของ ArmZ) — บังคับถามรายละเอียดก่อนสร้างแมพ; เวอร์ชันในบัญชีเป็นเวอร์ชันแรก (โฟลเดอร์ `Map/<Zone>`) แต่ให้ใช้โครงตาม plan.md: `Workspace.Map.Village`, `Workspace.Map.Wilds.ZoneN_<Key>`, สูตร ×100/โซน, ผังทวีปแนวนอน (ไม่ใช่ภูเขา)
