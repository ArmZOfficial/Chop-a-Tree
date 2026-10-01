# HANDOFF — Chop a Tree (สำหรับ AI ตัวถัดไป)

> อัปเดตล่าสุด: 2026-10-01 17:05 (เวลาไทย) · เขียนโดย Claude ก่อนส่งต่องาน
> **อ่านไฟล์นี้ก่อน แล้วอ่าน `docs/plan.md` (แผนหลัก ร่างที่ 8) ประกอบ**

## 0. เริ่มตรงนี้ (สรุป 30 วินาที)

1. Phase 0 (ระบบฐาน + Admin Panel) **เสร็จ ทดสอบแล้ว**
2. Phase 1 (แมพโครง) **ต้องสร้างใหม่**: ArmZ เลิกแบบภูเขาเกลียว → อยากได้ **ทวีปกว้างแนวนอน** (plan.md หัวข้อ 3 ร่างที่ 9 แก้แล้ว, รายละเอียดหัวข้อ 6.0 ข้างล่าง)
3. งานแรกของ AI ตัวถัดไป:
   1. ถาม ArmZ ว่า **ลบแมพภูเขาเดิมใน Studio (`Workspace.Map`) ได้ไหม** — ถามไปแล้วแต่ยังไม่ได้คำตอบ
   2. แก้ `src/shared/Config/Zones.luau` + เขียน `MapBuilder.Layout()/BuildWorld()/BuildZone()` ใหม่ตามผังตัว S (6.0)
   3. ซิงก์เข้า Studio (หัวข้อ 8) → รัน → ตรวจ (raycast + Play เดินจริง) → ส่งภาพให้ ArmZ → commit/push → อัปเดตไฟล์นี้
   4. ArmZ โอเคแล้วเริ่ม Phase 2 ได้เลย (เขาสั่งไว้แล้ว)
4. ตอบเป็นภาษาไทย bullet มีตัวเลข, มีตัวเลือก (Recommended) ก่อนลงมือ, ใกล้ limit ให้อัปเดตไฟล์นี้

---

## 1. โปรเจกต์คืออะไร

1. เกม Roblox ชื่อ **Chop a Tree** ของ **ArmZ** (GitHub: ArmZOfficial) ผสม 3 แนว: ฟันต้นไม้เก็บหีบ (แรงบันดาลใจ Cut Trees) + ปลูกสวน (Grow a Garden) + ขโมยไข่/เลี้ยงสัตว์ (Steal an Egg) มีเนื้อเรื่อง "The Withering"
2. แมพเดียวใหญ่ **ทวีปกว้างแนวนอน** (ทางคดตัว S ผ่าน 8 โซน + เกาะลอยฟ้าโซน 8 — เลิกภูเขาเกลียวแล้ว ดู plan.md หัวข้อ 3), หมู่บ้าน Rootfall มีฐานผู้เล่น 7 ฐาน, PvP เป็น Place แยก
3. **ทุกอย่างต้องออกแบบเอง** ห้ามใช้ชื่อ/โมเดล/โลโก้ของ Cut Trees, Grow a Garden, Steal an Egg หรืออนิเมะเรื่องจริง

## 2. วิธีทำงานกับ ArmZ (สำคัญ)

1. **ตอบเป็นภาษาไทย** ใช้ bullet แบบมีตัวเลข
2. ชอบแก้เอกสารแผนฉบับเดียวไปเรื่อยๆ + **มีตัวเลือกให้เลือก (ใส่ Recommended)** ก่อนลงมือ
3. ก่อนสร้างแมพ **ต้องถามรายละเอียดก่อน** (skill `roblox-map-builder`)
4. **ถ้าใกล้เต็ม limit ของ AI ให้หยุดแล้วสรุปลง .md ทุกครั้ง** (ไฟล์นี้) เพื่อส่งต่อ AI ตัวอื่น
5. ทุกครั้งที่แก้ → commit + push ขึ้น GitHub (ใส่ Co-Authored-By ตามที่ระบบกำหนด)

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
| วางแผน (plan.md ร่างที่ 8) | ✅ เสร็จ — คำถามทุกข้อตอบแล้ว |
| **Phase 0 ฐานราก** | ✅ เสร็จ ทดสอบแล้วใน Studio ไม่มี error, commit `5f6f7e8` |
| **Phase 1 แมพโครง** | 🟠 **เปลี่ยนผัง** — แมพภูเขาเกลียวสร้าง+ทดสอบแล้ว แต่ ArmZ ไม่เอาภูเขา อยากได้กว้างแนวนอน → plan.md ร่างที่ 9 แก้แล้ว, **ต้องเขียน Layout ใหม่ใน MapBuilder** (ดู 6.0) |
| Phase 2–10 | ⬜ ยังไม่เริ่ม (ดู plan.md หัวข้อ 7, 16) |

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

**ยังไม่ได้ทำใน Studio**: `Config.Weapons` (อยู่ใน repo แต่ยังไม่ใส่ใน Studio — Phase 0 ไม่ใช้ จะเข้าเองตอนต่อ Rojo)

## 6. Phase 1 — งานค้าง (ทำต่อตรงนี้)

### 6.0 ⚠️ เปลี่ยนผังแมพ (2026-10-01 16:53) — งานถัดไปจริงๆ อยู่ตรงนี้
1. ArmZ: "ไม่เอาเป็นภูเขา อยากให้มันดูใหญ่ๆ กว้างๆ ออกแนวนอนมากกว่า" แล้วเลือก:
   - ผัง: **ทางคดเคี้ยวผ่านทวีปกว้าง** (ตัว S: แถวล่าง หมู่บ้าน→1→2→3 ไปตะวันออก, ข้ามแม่น้ำที่โค้ง, แถวบน 4→5→6→7 กลับตะวันตก)
   - ความสูง: **ราบ มีเนินเตี้ยๆ** (โซนละ +8–12 studs: y = 4/12/20/30/40/52/64)
   - ขนาด: **โซนละ ~500×500 studs**, ช่องคั่น ~130 → ทวีป ~2,800 × 1,500
   - โซน 8: **เกาะลอยเหนือจุดปลายทาง** (สูง ~300 เหนือโซน 7, ขึ้นด้วยบันไดรากเกลียวรอบเสาแสง + วาร์ป)
   - ชื่อเปลี่ยน: โซน 5 "ป่าไผ่สายฟ้า", โซน 6 "ทุ่งน้ำแข็ง (Frostvale)", โซน 7 "ทุ่งคริสตัล" (key ใน Config.Zones ต้องเปลี่ยน Frostpeak → Frostvale)
2. ArmZ ตอบไว้ก่อนเปลี่ยนผัง (ยังใช้): ต้นไม้ **160 ต้น/โซน** (แก้ใน MapBuilder แล้ว), ฐานผู้เล่นตกแต่งไว้ Phase 4–5, เสร็จแมพแล้วเริ่ม Phase 2 ได้เลย
3. ต้องทำ:
   - `Config.Zones`: เปลี่ยน y, radius → ขนาดสี่เหลี่ยม (half-size ~250), เพิ่มตำแหน่ง grid (col,row), ลบ MountainBase/MountainSlope/RoadMaxSlopeDeg, ย้าย Village ไปมุมตะวันตกเฉียงใต้
   - `MapBuilder.Layout()` เขียนใหม่: ตำแหน่งโซนแบบ grid ตัว S, ทางเชื่อม (ทางลาดระหว่างโซนติดกัน), แม่น้ำคั่นแถว + สะพานเดียวระหว่างโซน 3→4, เกาะลอยโซน 8
   - `BuildWorld()`: เลิกสร้าง Mountain/Roads เกลียว → สร้างพื้นทวีป, ทะเล, แม่น้ำ, เนินเตี้ย, กำแพงหนามราเน่าระหว่างโซน
   - `BuildZone()`: ที่ราบเป็นสี่เหลี่ยมมุมมน (หรือ disk รัศมี ~250) ไม่ต้องมีหน้าผาสูง; โซน 8 เป็นเกาะลอย + บันไดราก
   - ของเดิมในหมู่บ้าน/ในโซน (ฐาน, ร้าน, ต้นไม้, หีบ, รัง, ศาลเจ้า, ลานบอส, ประตู, หินวาร์ป, tags) ใช้ฟังก์ชันเดิมได้
   - **ถาม ArmZ ก่อนลบแมพภูเขาเดิมใน Studio** (Workspace.Map ทั้งหมด) — ตอนส่งต่อ ยังไม่ได้ถาม
   - ทดสอบ: Report(), raycast ตามเส้นทาง, Play เดินจริง (RequestStreamAroundAsync ก่อนวาร์ป)
4. แมพภูเขาที่สร้างไว้ยังอยู่ใน Studio และโค้ดอยู่ใน commit `3522508` (ถ้าอยากดูวิธีแก้บั๊กกำแพง/ทางลาด)

### 6.1 คำตอบของ ArmZ ที่ยังใช้กับผังใหม่
1. หมู่บ้าน: **วงกลมรอบลานกลาง** (แท่นหีบกลาง, ร้าน/NPC วงใน, ฐาน 7 ฐานวงนอก, เว้นช่องตรงประตูป่า) — ลานเป็นสนามหญ้า ลานกลางเป็นหิน
2. โมเดล: **สร้างจาก Part low-poly เอง** (ไม่ใช้ Creator Store)
3. ต้นไม้: **160 ต้น/โซน** ในโซนที่สร้างเต็ม (1–2), โซน 3–8 เป็นโครง (PreviewTree 14 ต้น + ป้าย "สร้างเต็มใน Phase 7")
4. ~~ทางขึ้นเขาเกลียว~~ → ยกเลิก ใช้ทวีปตัว S แทน

### 6.2 สถานะไฟล์ (repo ตรงกับ Studio)
1. `src/shared/Config/Zones.luau` — **ยังเป็นค่าของภูเขา** (y 20…1360, radius, MountainBase 820, MountainSlope 0.5, RoadMaxSlopeDeg 18, Village angle 0 / distance 1180 / radius 190) → ต้องแก้ตาม 6.0; อยู่ใน Studio ที่ `ReplicatedStorage.Shared.Config.Zones`
2. `tools/map/MapBuilder.luau` (edit-time, ไม่อยู่ใน Rojo tree) — อยู่ใน Studio ที่ `ServerStorage.MapTools.MapBuilder` **checksum ตรง repo: 44827 bytes, h=1243792539** (รวมการแก้ล่าสุด: ภูเขาไล่สีตามโซน + ต้นไม้ 160 — ส่วนภูเขาจะถูกทิ้ง)
3. ฟังก์ชันใน MapBuilder: `Layout()`, `RoadPoints(r)`, `BuildWorld()`, `BuildVillage()`, `BuildZone(i)`, `BuildAllZones()`, `BuildAll()`, `Report()` + helper `P`, `F`, `M`, `tag`, `disk`, `sign`, `pathSegments`, `withHistory` (ChangeHistoryService), `fresh` (ลบโฟลเดอร์เดิมแล้วสร้างใหม่ → รันซ้ำได้)
4. ของที่ใช้ต่อได้เลย: `BuildVillage()` ทั้งหมด, ใน `BuildZone()` ส่วนต้นไม้/หีบ/รัง/ศาลเจ้า/ลานบอส/ประตูราเน่า/หินวาร์ป/ป้าย/ZoneSpawn/Lumora/RealmGate และระบบ `free()` กันของวางทับกัน
5. สิ่งที่อยู่ใน Studio ตอนนี้: `Workspace.Map.{Ground, Mountain, Roads, Village, Wilds.Zone1..8}` (แมพภูเขา), Baseplate/SpawnLocation เดิมอยู่ `ServerStorage.OldTemplate`, Lighting = Future + Atmosphere (Density 0.2, Offset 0.3, Haze 0.3), `StreamingEnabled = true`

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
3. `require` จาก `execute_luau` มี cache → ใช้ `:Clone()` ก่อน require ถ้าแก้โมดูล
4. คลิกเมาส์ทดสอบ: ใช้ `instance_path` ดีกว่าพิกัด (พิกัดมี GUI inset ~58px), หน้าต่างแชท Roblox ทับมุมซ้ายบนและบล็อกคลิก
5. ProfileStore แจ้ง "API services unavailable" ใน Studio จนกว่า ArmZ จะเปิด Game Settings → Security → Enable Studio Access to API Services (place เผยแพร่แล้ว เปิดได้)
6. เครื่องมือ Studio: `mcp__remote-devices__Roblox_Studio__*` — studio_id ปัจจุบัน **`f57cd27c-3efe-4efa-b2be-4d1dd00f875a`** (เปลี่ยนได้ ให้เรียก list_roblox_studios ก่อน)

## 9. สิ่งที่ ArmZ ต้องทำเอง (แจ้งไว้แล้ว)

1. เปิด Enable Studio Access to API Services
2. ลง Rojo (plugin + CLI) แล้ว `rojo serve` ในโฟลเดอร์ repo
3. (ทางเลือก) ใส่ UserId ทีมงาน/GroupId ใน `Config/Admins.luau`

## 10. Phase ถัดไปหลังแมพเสร็จ

1. **Phase 2 ฟันต้นไม้ + Run**: TreeService (HP ที่ Server, ฟันร่วมกันได้รางวัลเต็มถ้าฟันใน 10 วิก่อนล้ม, เกิดใหม่ 15 วิ), RunService (เริ่มเมื่อผ่าน ForestGate, End Run), RunPanel UI ตามรูปของ ArmZ (Auto Attack, Auto Cut, End Run, รายการหีบ LEVEL + x2), Auto Cut pathfinding −45%, Friend Boost, ตัวเลขดาเมจลอย + แท็บแอดมิน "ป่า & Run" + "Balance สด"
2. Phase 3 หีบ+อาวุธ, Phase 4 สวน+อากาศ, Phase 5 ไข่/สัตว์/ขโมย/ฐาน/Mount … (plan.md หัวข้อ 7)
3. **ทุก Phase ต้องเพิ่มปุ่มทดสอบใน Admin Panel** ผ่าน `AdminService.Register` และปิดระบบที่ยังไม่พร้อมด้วย Feature Flag

## 11. Skill ที่ใช้

- `roblox-map-builder` (skill ของ ArmZ) — บังคับถามรายละเอียดก่อนสร้างแมพ; เวอร์ชันในบัญชีเป็นเวอร์ชันแรก (โฟลเดอร์ `Map/<Zone>`) แต่ให้ใช้โครงตาม plan.md: `Workspace.Map.Village`, `Workspace.Map.Wilds.ZoneN_<Key>`, สูตร ×100/โซน, ผังทวีปแนวนอน (ไม่ใช่ภูเขา)
