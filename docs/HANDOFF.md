# Chop a Tree — HANDOFF

อัปเดต 2026-10-02 (ไทย). ล่าสุด: เพิ่มซีซัน 3, Season 34/34; Arena Place ใหม่ `135249057761883` อยู่ Universe หลักแล้ว. เริ่มอ่านไฟล์นี้ → [plan](plan.md) → [INDEX](INDEX.md) เฉพาะงาน. กฎทำงาน: [SKILL](../SKILL.md).

## สถานะล่าสุด

## Master prompt run 2026-10-02

**แทร็ก H เสร็จ (Sprint, ยังไม่ Publish):** Shift/L3/ปุ่ม RUN มือถือ, Settings Hold/Toggle, server-validated ใน PetService.ApplySpeed (×1.5). Studio Play: server self-test 12/12 (×1.5, rate limit, แบกไข่ไม่เร่ง, flag ปิด, หยุด, payload ปลอม, AdminFly, AdminSpeed×sprint, respawn รีเซ็ต) + กด Shift จริง: Hold 16→24 FOV 70→78 ปล่อยกลับ, Toggle แตะ/แตะ, ปุ่ม Settings สลับ HOLD↔TOGGLE ผ่าน server (คืน HOLD แล้ว). ยังไม่ทดสอบ: มือถือจริง/gamepad จริง/latency สูง/หลายคน; shift-lock rebind ตรวจใน Studio ไม่ได้ (PlayerModule ไม่แสดงใน MCP).

**แทร็ก D+E เสร็จ (ยังไม่ Publish):** `Shared.ChestBuilder` หีบ 5 ระดับตาม Chest Design Bible (parts 23/28/30/37/61 ≤ budget, lid hinge `SetLid` คืนตำแหน่งตรง 0.000), `Shared.ChestIconRenderer` ไอคอน ViewportFrame แทน sprite 2 แบบใน Inventory (Play: แท็บ Chests แสดง Common/Rare ถูกระดับ, console สะอาด), Chest Altar มีหีบ Epic โชว์ (PrimaryPart/prompt เดิม), ร้านขวานมีขวานยักษ์ ร้านไม้มีกองซุง. Model inventory: [systems §Models](systems.md#models--builders). บันได E: ChatGPT ต้องล็อกอิน → ไม่ใช้; ไอคอนใช้ขั้น Roblox render; ภาพอ้างอิงใน `assets/ui/elements-v3/chests/`. ค้าง (แทร็ก J): idle FX/particles, result card/sunburst/banner, `chest preview`.

**แทร็ก A เสร็จ (เกาะวงกลม 8 วง, ยังไม่ Publish):** ตาม `assets/reference/map-concept.png` — วง 1 Meadow นอกสุด → 8 Lumora กลาง (y 4→78), Hub ใต้ (ท่าเรือ, Chest Altar, ร้านขวานซ้าย/ร้านไม้ขวา, บ้าน 7 หลัง), บันได+torii บนแกนใต้, TreeKit 24 แบบ, retro Plastic/Studs. `Zones.At` เป็น footprint เดียว (RunService/ZoneAmbience), Merchant ย้ายเข้า hub; Studio Zones WIP "ทวีปราบ" ถูกแทนแล้ว. ตรวจ: tags ครบ (Tree 1280→1470, อื่นเท่าเดิม), Parts 18,103→10,127, ValidateRoutes Edit 263/0 + Play เดิน 16/16, Zones.At ตรง tag 1598/1598, Play Run.ZoneAt 8/8 + hub nil, leak probe ประตู 0, console ไม่มี error; source 6 ไฟล์ = repo (hash). ไม่มี DATA_VERSION ใหม่. ค้าง: playtest เดินเองครบ/ฟัน/บอสทุกโซนบนผังใหม่, mobile FPS, hub อยู่นอกวงเกาะ (ทรงรูกุญแจ) ต่างจาก concept เล็กน้อย. ผัง: [plan §3](plan.md#3-แมพ-เกาะวงกลม--ทำแล้ว-2026-10-02).

**แทร็ก B เสร็จ (Studio = repo checksum ยกเว้น Zones WIP/ProfileStore):** ดาบ 380 ชื่อ EN/TH ไม่มีเลขท้าย, LegacyWeaponMap 100→100 (1:1, rarity เดิม, power ไม่ลด สูงสุด +22.7%, ธาตุตรง 61/100) ตาราง [sword-pack-migration](sword-pack-migration.md); DATA_VERSION 2. ผลตรวจ Studio Play: migratetest ผ่าน (v0/v1 → v2, 100 legacy id, 300 ชิ้น, equip/giant/locked/ซ้ำ/unknown/Index union/idempotent/step ล้มแล้วข้อมูลไม่เปลี่ยน), catalog 380+100 (110/95/80/60/35), WeaponVisual 760 tools ≤9 parts + trail ครบ, Loot 2000/2000 swd และปิด flag ได้ wpn 500/500; python `tools/tests/test_sword_pack.py` 4/4; luau-compile 169 ไฟล์ 0 error. **หมายเหตุ:** Studio Play ใช้ DataStore จริง → เซฟ ArmZKubfu ถูก migrate v1→v2 แล้ว (อาวุธ 0 ชิ้นอยู่แล้ว, Index wpn 3 → +swd 3; ไม่มีอะไรหาย). ยังไม่ Publish.

### สำรวจก่อนแก้ (§1)

Prompt: [Claude outputs/chop-a-tree-master-prompt.md](../Claude%20outputs/chop-a-tree-master-prompt.md) (แทร็ก A–J). Studio `Chop a Tree` PlaceId 93479990217075, Edit mode.

**ของที่มี (Studio = repo ยกเว้นที่ระบุ):** 49 shared/config, 29 services, 20 admin command modules, 18 client controllers; ProfileStore ใน Studio ≠ repo (ห้าม overwrite). แมพปัจจุบัน = ทวีปตัว S ราบ (Zones halfSize 350, GridStep 700 ใน Studio; repo ยังเป็น 250/500 แบบขั้นบันได) + Sky Isles y=364; Workspace 18,798 parts (Zone8 7,719, Road_7_8 1,159). Tags: Tree 1280, ChestSpot 80, Nest 16, ZoneGate 7, WarpStone 9, ZoneSpawn 8, BossArena 8, Shrine 8, PlayerBase 7, GardenSlot 42, Shop 4, NPC 7, ForestGate/ArenaPortal/RealmGate/Lumora/ChestAltar 1, Leaderboard 2.

**ของที่ค้าง (WIP ใน Studio ไม่อยู่ใน repo):** `Config.SwordPack` (380 ดาบสร้างตอนรัน ชื่อมีเลขท้าย เช่น "Inferno Katana 37") + `Config.WeaponCatalog` = ดาบอย่างเดียว → 100 อาวุธเก่า `wpn_*` หาไม่เจอ = "Retired item"; 10 สคริปต์ require WeaponCatalog แล้ว (Loot, CollectionMath, WeaponService, QuestService, EmoteService, ArenaService, WeaponCommands, StoryCommands, StoryController, InventoryController fallback); WeaponVisual มี sword builder (SmoothPlastic, ไม่มี trail). ไม่มี LegacyWeaponMap/migration, DATA_VERSION=1. MapBuilder/Zones ใน Studio เป็นงาน "ทวีปราบ" ครึ่งทาง (แทนแล้วโดยแทร็ก A).

**ของที่ขาด:** LegacyWeaponMap + migration v2, flag SwordPack, Config.Movement/Sprint, Shared.Locale/Strings (ไทย), ChestBuilder/ChestIconRenderer/Opening Stage, เกาะวงกลม 8 โซน, TreeKit, elements-v3, ภาพ concept แมพ และ `assets/reference/chest-open/` (ไม่มีในโฟลเดอร์ → ทำตามสเปก, รอ reference).


- **UI matched to concepts (2026-10-02):** Inventory/Pets/Garden/Shop/Rewards rebuilt to the five elements-v1 concepts with elements-v2 art (plaque titles, wood tabs, 9-sliced cards/buttons, info bars, cradle/plot/calendar cards, Cut confirm popover); HUD follows the reference game (big Coins top-centre + Wood/Gems capsules, 2×3 menu tiles, PLAY). Primary windows show a side nav rail with the active tile lit. Live Config/server data, prices and intents unchanged. Desktop Play (1366×793): all five windows screenshotted; real clicks: tile open, side-rail switch, Shop tab, in-window click stays open, red X close. Studio sources = repo (checksum). Inventory shows 12 legacy weapons as "Retired item" until the Sword Pack catalog migration. Mobile/gamepad, Codes/Leaderboard/Base/Conveyor tab visuals and transactions not re-verified. Not published.

- **UI parts v2 assembled in Studio:** 10 imported atlases; runtime UIArt/UIKit wood windows, buttons/nav, Inventory rarity/detail, Garden plot/grid, Pets cradle/cards, Shop 3-column cards, Rewards 4+3 calendar. Live English data/prices/intents retained. Desktop Play: HUD, Inventory, Garden selection/Seeds, Pets tabs, Shop Passes/Products and Rewards Daily/Codes/red X clicked; Incubator illustrations verified after layer fix. Final Garden row-height/encoding and Rewards shade fixes compiled/synced; final screenshots interrupted by concurrent Studio map edits. Luau120 compile (0 errors), 8/8 UI sources match Studio. Mobile/gamepad and all transaction flows remain unverified. Concurrent Sword Pack catalog drops legacy weapon IDs: saved old items need a separate migration; do not restore the old catalog. Not published or pixel-identical. [Pack](../assets/ui/elements-v2/README.md).

- **UI art pack prepared:** 36 transparent sprites / 4 atlases + 5 generated concepts (Inventory/Garden/Pets/Shop/Rewards), ImageRect helper and all-screen UX audit in [elements-v1](../assets/ui/elements-v1/README.md). PNG alpha/bounds and helper compile checked. These new atlases are not uploaded/wired; runtime below unchanged. Next: shared art assembly, Garden/Pets contextual actions, then remaining views/device proof. Prompts included; no Publish.

- **วางแผนใหม่ (ArmZ 2026-10-02), ยังไม่เริ่มโค้ด:** (1) Sword Pack 380 ชิ้น `swd_001–380` ผ่าน `Config.SwordPack` + `Shared.WeaponCatalog` + flag `SwordPack` + ดาบ retro/trail ใน WeaponVisual; (2) Map rework — ทวีปกว้างราบระดับเดียว, กำแพงสูง ~60 studs, สไตล์ retro classic, TreeKit ≥24 แบบผสมหลายโซน. ขอบเขต: [plan §3/§ดาบ](plan.md). Prompt สำหรับ Studio AI (14 ขั้น): [prompts/studio-ai-sword-pack-map-rework.md](../prompts/studio-ai-sword-pack-map-rework.md). ต้องตรวจ: tag counts ก่อน/หลัง, ValidateRoutes Edit+Play, ทุกระบบที่อ่าน Zones.y, balance_sim, sync source กลับ repo.

- **Phase 10 UI / English:** wood windows/outlined icon headings/red X/blur; Inventory rarity grid + preview, Shop actual product art/live prices, Index categories/gallery/silhouettes, independent Music/SFX mute/restore implemented. Desktop clicks/17 product prices/Index counts/sound fixtures checked; Luau129 compile. Earlier authored English scan Thai0; stable element keys kept. Item models/category art, mobile/gamepad, all flows/world art/VFX/balance remain pending. Details: [UI](systems.md#phase-10-ui). Not published.

- **Phase 9a lobby ทำแล้ว**: พอร์ทัลเดิมเปิดหน้าคิว Duel/FFA/Timber Clash/Egg Heist; Ranked/Casual แยก, ตรวจ Run/ไข่/mount/ระยะ/ชีวิต, reserved-server transfer + failure/timeout recovery. Luau CLI 37 checks; Studio startup/คลิก GUI ผ่าน, source 7 ไฟล์ตรง repo; คืน flags/pivot/anchor แล้ว Studio Edit ไม่มี test scripts. PvP=false. Combat/สนาม/แรงก์/รางวัลยังไม่ทำ; ดู [Arena](systems.md#arena).
- Arena Place ใหม่ `135249057761883` อยู่ Universe เกมหลักแล้ว (ตรวจ GetGamePlacesAsync). Place เก่า `122495944523559` ผิด Universe ไม่ใช้. **Phase 9b/9c match server** Duel/FFA + Timber Clash/Egg Heist อยู่ใน Studio Place นี้ (`arena/server/`), self-test 15/15, source 2 ไฟล์ตรง; ยังไม่ทดสอบ 4 คน; Place Arena Publish แล้ว (ArmZ สั่ง); Config.Arena.PlaceId=135249057761883 (เกมหลัก Publish แล้ว ArmZ สั่ง 2026-10-02, ไม่มี test script ค้าง), lobby 37/37; PvP ยังปิด. ยังไม่ทดสอบ 2 คน/teleport จริง. **9d แรงก์/Arena Tokens**: Arena เขียนผลลง DataStore ledger, เกมหลักจ่ายตอนกลับ (กันจ่ายซ้ำ), scenario 12/12 restore ผ่าน; ArmZ Publish ทั้งสอง Place แล้ว (9c+9d, 2026-10-02); รอทดสอบแมตช์จริงหลายบัญชี. Tokens ยังใช้ซื้อไม่ได้ (รอคอสเมติก). **9e ท่าต่อสู้** ฟันหนักกดค้าง/บล็อก F/dash Q ใน Studio Arena, self-test 24/24, ยังไม่ Publish. ด่าน Arena (กำแพงวงกลม/หิน/ท่อนไม้) สร้างด้วย `arena/tools/BuildArenaMap.luau` แล้ว ยังไม่ Publish. **9f ท่าอาวุธ (E)** ตามธาตุอาวุธที่ใส่ (Cone/Pierce/Burst พลังรวมเท่ากัน), Arena 30/30, ยังไม่ Publish ทั้งสอง Place. เหลือทดสอบหลายบัญชีแล้วเปิด PvP; Casual ใช้ค่าเท่ากับ Ranked (ไม่ทำ cap); ดู [Arena](systems.md#arena).

- **Phase 8g ร้าน Robux + Season Pass ทำและทดสอบแล้ว; ยังไม่ Publish.** ไม่สรุปว่าเกม/ทุก Phase พร้อมเปิดจริง.
- Shop: 10 Pass + 17 Developer Products ID จริงใน `src/shared/Config/Products.luau`; เปิด flag Shop/SeasonPass, PvP ปิด. ราคา UI อ่านสดจาก Roblox.
- Shop **34/34**, Season **34/34** (รอบเพิ่มซีซัน 3). OpenTen คลิกจริง/Pass refresh/capacity ผ่าน. **Phase 4–7 และ 8a–f รันซ้ำหลังร้านครบ**; counts/ข้อจำกัด: [Phase 8g](phase8_shop_season_validation.md).
- Premium ID **3715870274**, ราคาฐาน **499 Robux**. ผู้ใช้รายงานซื้อจริงผ่าน; automation ตรวจ ProcessReceipt โดยตรง ไม่ได้คลิกยืนยันจ่าย Robux.
- ซีซัน `s1_2026_10`: 2026-10-01 ถึง 11-01 UTC; `s2_2026_11` ป่าแสงจันทร์: 11-01 ถึง 12-01 UTC; `s3_2026_12` ป่าหิมะเงิน: 12-01 ถึง 2027-01-01 UTC ต่อกันอัตโนมัติ. ใช้รางวัลเดิม 30 เลเวล × 1,000 XP. Pending purchase ผูกซีซัน; มี Premium แล้ว/ซีซันจบ → fallback 4,500 Gems. ค่า XP/รางวัล/fallback ยังเป็น Beta.
- **คอสเมติก: ArmZ ให้รอก่อน.** Premium ปัจจุบันเป็น Gems/บูสต์/หีบ ไม่ใช่ระบบสกินที่เสร็จแล้ว.
- ล่าสุดแก้ WeatherService: forecast อนาคตไม่ล้าง festival preview ปัจจุบัน; 8e ผ่าน 15 checks รวม regression ใหม่ และ 8d1/d2 รันซ้ำ 38/59 ผ่าน. ปรับ test Luck เก่าให้ตรงเพดานรวม 50%. Source ตรง Studio 3549 bytes/hash31 1672120537. ใช้ RegressionHarness เดียว คืนข้อมูลผ่านทุกชุด. ยังไม่ Publish; ponytail full + caveman full; docs 8 ไฟล์.
- เซฟ/receipt/reconnect: บัญชี ArmZKubfu บน DataStore จริง (`Access`) ผ่าน; synthetic receipt จำลอง failed-save 2 ครั้ง/แจก 100 Gems ครั้งเดียว, reconnect เก็บยอด/marker และ replay ไม่จ่ายซ้ำ. ยืนยันซ้ำด้วย ReceiptPersistenceScenario Save/Replay. คืนยอด 221 Gems/ลบ synthetic markers และยืนยันเซฟแล้ว; Studio Edit ไม่มี test scripts. **ยังไม่ใช่การซื้อผ่านหน้าจ่าย Robux จริง**; Roblox Player ยังอยู่เกมอื่นมี Run ค้าง รอผู้ใช้เลือกจัด session.

## งานถัดไป / ค้าง

0. Master prompt ที่เหลือ (ตามลำดับ): D+E ChestBuilder/props/elements-v3 → H Sprint → I Locale EN+TH → C UI audit → J chest cinematic → F+G → regression. ดู `prompts/cli-continue.md`.

1. ซีซัน 2–3 พร้อมแล้ว; เพิ่มแถวซีซัน 4 ID ใหม่ **ก่อน 2027-01-01 UTC** มิฉะนั้นไม่มีซีซันให้เล่น/ขายหลังนั้น.
2. ซื้อผ่าน Roblox Player จริง + reconnect หลังซื้อ; server persistence/failed-save ผ่านแล้วใน Studio ด้วยบัญชีจริง. Regression 2–7/8a–f ครบ; ต้องแยกจาก multi-account/device proof.
3. งานเดิมค้าง: ไลก์/กระดานฐานยอดนิยม. ทำแล้วรอ Publish: ตกแต่งฐาน+ของเทศกาล 15/15, กับดัก/สัตว์เฝ้า 8/8, NPC บท 3–8 7/7, Garden UI. ยืนยันกับโค้ดก่อนแก้. (Garden UI refresh แก้แล้ว; NPC ผู้เฝ้าโซน 3–8 + บทพูด + คัตซีนศาลเจ้า ทำแล้ว scenario 7/7; ทั้งหมดยังไม่ Publish)
4. Multi-account ขโมย/บอสร่วม, multi-server Live Events/world boss, mobile/gamepad ยังไม่พิสูจน์ครบ. Balance/เสียง/VFX/UI polish Phase 10.
5. Phase 9 ถัดไป: Place Arena ใน Universe เดียวกัน, match server/combat 4 โหมด, Ranked/monthly ranks/tokens; คอสเมติกเมื่อ ArmZ สั่ง; Publish เมื่อผู้ใช้สั่ง.

## ข้อมูลต่อระบบที่ต้องรู้

- MonetizationService owns receipt ledger; `Grant` ไม่ yield; Granted หลัง SaveAndWait. SeasonService owns XP/claim/Premium; Changed deferred → เทสต้องรอ.
- ซีซันเปลี่ยนรีเซ็ต XP/Premium/claim; pendingFor คงไว้. รับรางวัลค้างก่อนซีซันจบ; อ่าน Phase 8g ก่อนแก้ edge cases.
- Admin roles: Owner ตั้ง/ถอด Tester/Moderator/Admin ได้จากแท็บ "จัดการผู้เล่น" เก็บ DataStore ไม่ต้อง Publish; ยังไม่ได้ตรวจกับบัญชีที่ไม่ใช่ Owner ในเกมจริง. ดู [Admin roles](systems.md#admin-roles).
- Admin shop: Pass/product/server Luck + `season.xp/premium/reset`. เพิ่มคำสั่งทดสอบตามระบบ.
- Source repo ตรง Studio ตามผลตรวจล่าสุดของแต่ละงาน; ก่อนเขียนเรียก list Studios, ตรวจ PlaceId `93479990217075`. Studio ID ไม่ใช่ค่าถาวร.
- ยังไม่ใช้ Rojo; sync MCP multi_edit + checksum `h=(h*31+byte)%2147483647`. ทดสอบผ่าน Script VM ไม่ require live service จาก MCP; คืน state ก่อน Stop.

## ผลตรวจเดิม (อ่านรายละเอียดเมื่อแก้ระบบนั้น)

Phase 2/3/4/5/6/7 หลังร้าน: **23/36/55/80/51/23**. Phase 8a/b/c/d1/d2/d3/e/f: **41/45/55/38/59/30/15/5**.
Phase 5 count ขึ้นกับข้อสายพานตามเวลา (รอบเดิม 81); เป็น single-account scenario + bot/seams ไม่ใช่ multi-account proof. ลิงก์ใน [INDEX](INDEX.md).

## เอกสารและ asset

- [plan](plan.md): design ย่อ/backlog. [INDEX](INDEX.md): validation/สูตร/spec ที่ต้องอ่านตามงาน.
- `assets/monetization/`: Pass 10, Developer Product 17, Season Premium; PNG 512×512 + EN/TH copy + ZIP. ID ที่ใช้จริงดู Config/Products; asset JSON เก่าอาจยังไม่มี ID.
- [systems](systems.md) รวมข้อควรรู้; [design](design.md) spec รายละเอียด. Snapshot/หลักฐานเก่าเรียก Git 5d09e37 เฉพาะสืบประวัติ.
