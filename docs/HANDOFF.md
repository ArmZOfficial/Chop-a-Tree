# HANDOFF — Chop a Tree (สำหรับ AI ตัวถัดไป)

> อัปเดตล่าสุด: 2026-10-01 16:35 (เวลาไทย) · เขียนโดย Claude ก่อนส่งต่องาน
> **อ่านไฟล์นี้ก่อน แล้วอ่าน `docs/plan.md` (แผนหลัก ร่างที่ 8) ประกอบ**

---

## 1. โปรเจกต์คืออะไร

1. เกม Roblox ชื่อ **Chop a Tree** ของ **ArmZ** (GitHub: ArmZOfficial) ผสม 3 แนว: ฟันต้นไม้เก็บหีบ (แรงบันดาลใจ Cut Trees) + ปลูกสวน (Grow a Garden) + ขโมยไข่/เลี้ยงสัตว์ (Steal an Egg) มีเนื้อเรื่อง "The Withering"
2. แมพเดียวใหญ่ ไต่ขึ้นภูเขาแบบเกลียว 8 โซน, หมู่บ้าน Rootfall มีฐานผู้เล่น 7 ฐาน, PvP เป็น Place แยก
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

> หมายเหตุ: เดิมทำใน "Place2" แล้ว ArmZ ย้ายไป place ใหม่ "Chop a Trees" (เผยแพร่แล้ว) — สคริปต์ Phase 0 ทั้งหมดและ `Config.Zones` ย้ายมาครบ ตรวจแล้ว (RS 11 สคริปต์, SSS 9, ServerStorage 2, StarterPlayer 4) ใน Workspace ยังมี Baseplate + SpawnLocation เดิม

## 4. สถานะ Phase

| Phase | สถานะ |
|---|---|
| วางแผน (plan.md ร่างที่ 8) | ✅ เสร็จ — คำถามทุกข้อตอบแล้ว |
| **Phase 0 ฐานราก** | ✅ เสร็จ ทดสอบแล้วใน Studio ไม่มี error, commit `5f6f7e8` |
| **Phase 1 แมพโครง** | 🟡 **กำลังทำ** — โค้ดตัวสร้างแมพเขียนเสร็จ แต่ **ยังไม่ได้รันใน Studio** |
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

### 6.1 คำตอบของ ArmZ สำหรับแมพ
1. หมู่บ้าน: **วงกลมรอบลานกลาง** (แท่นหีบกลาง, ร้าน/NPC วงใน, ฐาน 7 ฐานวงนอก, เว้นช่องตรงประตูป่า)
2. ทางขึ้นเขา: **เกลียววนรอบภูเขาลูกเดียว**
3. โมเดล: **สร้างจาก Part low-poly เอง**
4. ต้นไม้: **~120 ต้น/โซน** (ป่าใช้ร่วมทั้งเซิร์ฟ 7 คน)

### 6.2 ไฟล์ที่เขียนแล้ว
1. `src/shared/Config/Zones.luau` — 8 โซน (y, radius, สี, ไข่, บอส), MountainBase 820, MountainSlope 0.5, RoadMaxSlopeDeg 18, Village (angle 0, distance 1180, radius 190) — **อยู่ใน Studio แล้ว**
2. `tools/map/MapBuilder.luau` — ตัวสร้างแมพ (edit-time, ไม่อยู่ใน Rojo tree) — **ยังไม่ได้ใส่ใน Studio** (การอัปโหลดล้มเพราะ ArmZ เปลี่ยน place กลางทาง)

### 6.3 ผังที่คำนวณแล้ว (ตรวจด้วย Python: ทุกถนนชัน 18°, ไม่ทับกัน, วนรอบเขา ~2 รอบ)
| โซน | y | R จากกลางเขา | มุม |
|---|---|---|---|
| 1 ทุ่งหญ้า | 20 | 884 | 40° |
| 2 เมเปิล | 150 | 815 | 92° |
| 3 บึงเห็ด | 280 | 740 | 146° |
| 4 ซากุระ | 440 | 656 | 211° |
| 5 ไผ่ | 620 | 562 | 289° |
| 6 น้ำแข็ง | 840 | 449 | 36° |
| 7 คริสตัล | 1080 | 322 | 181° |
| 8 เกาะลอยฟ้า | 1360 | 0 (ยอดเขา) | — |
หมู่บ้านอยู่ (0, 0, 1180)

### 6.4 ขั้นตอนที่ต้องทำต่อ
1. ใส่ `tools/map/MapBuilder.luau` ลง Studio เป็น ModuleScript ที่ `ServerStorage.MapTools.MapBuilder` (ใช้ `multi_edit` สร้างสคริปต์, className ModuleScript)
2. รันทีละส่วนด้วย `execute_luau` (Edit mode) — require ผ่าน Clone เพื่อไม่ติด cache:
   ```lua
   local B = require(game.ServerStorage.MapTools.MapBuilder:Clone())
   B.BuildWorld()      -- พื้น, ภูเขาขั้นบันได, ถนนเกลียว, แสง Future, StreamingEnabled, ย้าย Baseplate/SpawnLocation ไป ServerStorage.OldTemplate
   B.BuildVillage()    -- ลาน, ฐาน 7 ฐาน, แท่นหีบ, ร้าน, NPC ปู่ Bram, กระดานผู้นำ, พอร์ทัล Arena, หินวาร์ป, จุดเกิด, ประตูป่า
   B.BuildZone(1) ; B.BuildZone(2)          -- สร้างเต็ม (ต้นไม้ 120, หีบ 10, รัง 2, ศาลเจ้า, ลานบอส, ประตู, ของตกแต่ง)
   for i = 3, 8 do B.BuildZone(i) end       -- โครง (พื้น + ป้าย "สร้างเต็มใน Phase 7" + ต้นตัวอย่าง PreviewTree) โซน 8 มีต้น Lumora + RealmGate
   return B.Report()
   ```
3. ถ้า error → แก้ทั้งใน repo และ Studio ให้ตรงกัน (โค้ดยังไม่เคยรันจริง อาจมีบั๊กเล็กๆ)
4. ตรวจ: `B.Report()` นับ tag, `screen_capture` มุมกว้าง/หมู่บ้าน/โซน 1–2, กด Play เดินจากหมู่บ้านขึ้นโซน 1 ดูว่าเดินได้, เช็ค console
5. ส่งภาพให้ ArmZ แล้ว **ถามว่าอยากเปลี่ยนอะไร** (สี, ขนาด, ตำแหน่ง, ความหนาแน่น, แสง)
6. commit + push, อัปเดตสถานะใน `docs/plan.md` บรรทัดที่ 5 และไฟล์นี้

### 6.5 Tags / Attributes ที่แมพสร้าง (ระบบ Phase 2+ ใช้)
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

- `roblox-map-builder` (skill ของ ArmZ) — เวอร์ชันที่บันทึกในบัญชีเป็นเวอร์ชันแรก (โฟลเดอร์ `Map/<Zone>`) แต่ให้ใช้โครงตาม plan.md: `Workspace.Map.Village`, `Workspace.Map.Wilds.ZoneN_<Key>`, สูตร ×100/โซน
