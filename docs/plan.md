# Chop a Tree — แผนหลักฉบับย่อ (ร่าง 19)

อัปเดต 2026-10-02. สถานะ/ผลตรวจล่าสุดอยู่ [HANDOFF](HANDOFF.md); กฎอยู่ [SKILL](../SKILL.md).
อ่านรายละเอียดเฉพาะงานจาก [INDEX](INDEX.md). Spec รายละเอียด: [design reference](design.md) — เลือกหัวข้อ ไม่อ่านทั้งไฟล์.

## 0. เกมและขอบเขต

Roblox **Chop a Tree** (ชื่อ place Chop a Trees), 7 คน/เซิร์ฟ, เกาะวงกลม 8 วงไต่ขึ้นสู่ที่ราบ Lumora กลางเกาะ. ทิศภาพใหม่ (ArmZ 2026-10-02): **retro classic Roblox** — บล็อกหนา Plastic + Studs/Inlet, สีสด BrickColor, แสงเรียบ; VFX บล็อก/neon เรียบง่าย; เอกลักษณ์/ไอเทมของเราเอง.
Loop: ฟันต้นไม้ → End Run → หีบ/อาวุธ → สำรวจ/ไข่/สัตว์ → สวน/ฐาน → บอส/ปลดโซน → Rebirth.
เรื่อง The Withering: ป่าติดราเน่า; ฟื้นศาลเจ้าและเดินทางถึง Lumora. บท 3–8 มี NPC ผู้เฝ้าโซน/บทพูด/คัตซีนศาลเจ้าแล้ว (ยังไม่ Publish).

## 3. แมพ (เกาะวงกลม — ทำแล้ว 2026-10-02)

ภาพอ้างอิง `assets/reference/map-concept.png`. สไตล์ retro classic (Plastic + Studs/Inlet, สีสด, แสงเรียบ).

| วง | โซน | รัศมี (studs) | พื้น y | ต้นไม้ TreeKit (ธีม) |
|---|---|---|---|---|
| 1 นอกสุด | Sunny Meadow | 740–900 | 4 | Oak / RoundTree / Pine |
| 2 | Amber Woods | 650–740 | 12 | Maple / Birch / AutumnBall |
| 3 | Glowcap Bog | 560–650 | 20 | Mushroom / TwinShroom / GlowBulb |
| 4 | Sakura Highlands | 470–560 | 30 | Sakura / Weeping / Layered |
| 5 | Thunder Bamboo | 380–470 | 40 | BambooClump / BambooTall / ThunderPalm |
| 6 | Frostvale | 290–380 | 52 | SnowPine / IceSpire / SnowRound |
| 7 | Crystal Ridge | 200–290 | 64 | CrystalTree / Prism / Amethyst |
| 8 กลาง | Lumora Plateau (key SkyIsles) | 0–200 | 78 | GoldenTree / LightOrb / SpiritWillow + ต้น Lumora ทอง |

- **Hub Rootfall ทิศใต้** (0,4,1010) r190: ท่าเรือใต้สุด, Chest Altar กลางลาน, ร้านขวาน (UpgradeShop) ซ้าย, ร้านไม้ (Sawmill) ขวา, Seed/Egg Conveyor/Bram/Warp/Leaderboards/Arena portal, บ้านผู้เล่น 7 หลัง (กระท่อมสีหลังคาต่างกันบนฐาน), Forest Gate ทิศเหนือเข้า Meadow; กำแพง hub กันเดินอ้อมประตู.
- ทุกวงเข้าที่แกนใต้: บันไดหิน + torii ZoneGate (ปลดเมื่อชนะบอส) + ป้ายชื่อโซน; ขอบวงบนมี RotHedge; ลานบอส + ศาลเจ้า 75° ตะวันออกของทางเข้า; tier ต้นไม้สูงขึ้นตามระยะรอบวง (ฝั่งเหนือลึกสุด); หีบ 10 + รัง 2 ต่อโซน.
- ต้นไม้ ~1 ต้น/1600 studs² (140–260 ต่อโซน รวม 1470). Lumora: ลานบอสกลาง + Realm Gate ฝั่งเหนือ.
- โค้ด: `Config.Zones` (inner/outer/y + `Zones.At` + `Hub`), `tools/map/MapBuilder.luau`, `tools/map/TreeKit.luau`; constraints/ผลตรวจ: [systems §Map](systems.md#map).

## 4. ข้อตกลง gameplay ที่คงไว้

- Map scripting (2026-10-02): repo implementation + synthetic checks in [map-systems](map-systems.md). Boss/shrine unlock, x100 progression, seven Garden bases, existing Teleport pass and reward caps retained. Approved Explorer completion reward = one Common Level1/source-zone1 chest per zone (max8); Golden/Timber Wood x2 within overall x4. Studio sync/validator/mock VM/UI phone/tablet/seven-base checks passed; guarded map QA remains enabled. Total frame budget/input-device/rejoin proof and gate/dock/compass/variant work remain pending; no live v3 migration or Publish.

- UI audit (2026-10-02): desktop/tablet/phone/gamepad ผ่านเรื่องข้อความล้น/หลุดจอ; ค้างเลย์เอาต์มือถือให้ปุ่ม ≥44px ([UX-audit](../assets/ui/UX-audit.md)).
- สองภาษา EN+TH (ทำแล้ว 2026-10-02): ผู้เล่นเลือก Auto/English/ไทย ใน Settings; ดู [systems §Localization](systems.md#localization-en--th).
- Sprint (ทำแล้ว 2026-10-02): Shift/L3/ปุ่ม RUN ×1.5 ไม่มี stamina; ไม่เร่งตอนแบกไข่; ตั้งค่า Hold/Toggle. รายละเอียด [systems §Movement](systems.md#movement--sprint).

- Run จบโดยผู้เล่น End Run ไม่มีเวลาจำกัด; รางวัล/ของถือใช้ RunService และกติกา secure เดิม. ไข่จากรังต้องส่งกลับอย่างถูกต้อง; ออก/ตายต่างจาก secure.
- Auto Attack = ยืนฟัน, Auto Cut = เดินฟันฟรีทุกคนในโซนปัจจุบัน; manual override หยุด. ค่าเริ่มต้นผลตอบแทน .55; ทักษะฟรีลดโทษถึง .75; ไม่ขาย Auto Cut.
- ต้น 6 tier/โซน, scale `100^(zone-1)`; respawn 15 วิ, contribution reward. สูตรอ้างอิง Config/Balance ไม่คัดตัวเลขซ้ำใน docs.
- Cut Power ผ่าน Balance; run multiplier `1.08^level`, Rebirth power `1.5^R`/Rot `10^R`. รายละเอียด/เพดานใน validation + design §14.
- Pet/สวน/ฐานใช้ ownership เดิม; อาวุธ/ของเซฟมี stable ID+UID. Mutation สูตรพิเศษสูงสุด × (1+ผลรวมอื่น); offline โตปกติ ไม่สุ่ม mutation/สะสม harvest ย้อนหลัง.
- Rebirth แรกหลังบอสโซน 4; คง inventory/Gems/Index/Stats/crops/skills, reset progression/เงิน/อัปเกรดตาม RebirthService.
- Daily/weekly/weather/merchant/season ใช้ UTC. เงิน: Wood/Coins/Gems + Stardust จาก event. ใช้ service เจ้าของระบบและ server reward checks.

## 7. สถานะและลำดับงาน

| Phase | ขอบเขต | สถานะ |
|---|---|---|
| 0–1 | โครง/แมพ | ทำแล้ว |
| 2–7 | Run/อาวุธ/สวน/สัตว์/เนื้อเรื่อง/8 โซน | core ทดสอบแล้ว; narrative/art บางส่วนค้าง |
| 8a–f | Rebirth, Rewards, Index, Weather/Encounters, Merchant, Festivals, Emote/Photo | core ทดสอบแล้ว |
| 8g | ร้าน Robux + Season Pass | Shop 34/34 รันซ้ำ + OpenTen คลิกจริง/Pass refresh/capacity ผ่าน; Season 34/34 + ซีซัน 2–3 พร้อม; ยังไม่ Publish |
| 9 | PvP แยก Place | 9a lobby/คิว ทำแล้ว; 9b Duel/FFA Publish แล้ว; 9c Timber Clash/Egg Heist + 9d แรงก์รายเดือน/Arena Tokens Publish แล้ว (รอทดสอบหลายบัญชี); 9e ฟันหนัก/บล็อก/dash ใน Studio (ยังไม่ Publish); ด่าน Arena พื้นฐาน + 9f ท่าอาวุธตามธาตุ (ยังไม่ Publish); เหลือทดสอบหลายบัญชีแล้วเปิด PvP |
| 10s | Sword Pack 380 + Map rework retro | Sword Pack ทำแล้ว (B); เกาะวงกลม 8 วง + TreeKit 24 ทำแล้ว (A, ยังไม่ Publish); ดู §3 และ §ดาบ |
| 10 | Balance + UI/ภาพ/เสียง/VFX/อุปกรณ์จริง | Wood windows/outlined headings/red X/blur, Inventory rarity grid, Shop art cards, Index gallery, Music/SFX implemented and desktop checked; English copy; device/all-flow proof and item/world art/VFX/balance pending; not published |

Regression หลังร้าน 2–7/8a–f รันซ้ำครบและ restore ผ่าน; แก้ festival preview ถูก forecast อนาคตล้าง. Receipt failed-save/reconnect ผ่านบน DataStore บัญชีจริงด้วย synthetic receipt และยืนยันซ้ำด้วย harness Save/Replay; คืนข้อมูลและเซฟแล้ว. ซื้อผ่านหน้าจ่าย Robux จริงยังค้าง รอจัด session เกม. Counts/หลักฐานอยู่ Phase 8g.
ซีซัน 2 ป่าแสงจันทร์ (`s2_2026_11`) 2026-11-01→12-01 และซีซัน 3 ป่าหิมะเงิน (`s3_2026_12`) 12-01→2027-01-01 UTC พร้อม; ใช้ XP/รางวัลเดิม. Rollover/late receipt/ห่วงโซ่ซีซันผ่าน scenario 34/34.
ถัดไป: ซื้อผ่าน Roblox Player จริงแล้ว reconnect และตรวจหลายบัญชี/อุปกรณ์; เพิ่มซีซัน 4 ก่อน **2027-01-01 UTC**.
ผู้ใช้สั่งเริ่ม Phase 9 ระหว่างรอซื้อจริง: เริ่มจากพอร์ทัล/คิว Ranked-Casual แยกกัน, reserved server, ยกเลิก/failed-transfer recovery. PvP ยังปิดและ Arena.PlaceId=0 จนสนามอยู่ Universe เดียวกันและ match server พร้อม. รายละเอียดสถานะ/ข้อจำกัดใน [systems §Arena](systems.md#arena).
ค้าง: ไลก์/กระดานฐานยอดนิยม. ตกแต่งฐาน/ของเทศกาล/กับดัก/สัตว์เฝ้า/NPC บท 3–8 ทำแล้ว ยังไม่ Publish.
**คอสเมติกให้รอ ArmZ สั่ง.** ไม่ประกาศ Beta/Publish เอง. Milestone M4 เป้าหมาย Beta หลังตรวจ readiness; M5 PvP, M6 polish (รายละเอียด design §16).

Player-facing UI/signs/dialogue/notifications are **English + Thai** (Locale). Phase 10 direction: simulator-style brown wood windows, large original icons, outlined labels, red close/green buy buttons, rarity grids with previews and blurred scene; one modal at a time. Keep live prices and existing systems. Actual Play proof/remaining item art: [Phase 10 UI](systems.md#phase-10-ui).

UI art/design ready: [elements-v1](../assets/ui/elements-v1/UX.md), 36 reusable sprites + five screen concepts. Assemble shared art first, then Garden/Pets selection with contextual actions; keep service rules/live English labels. New pack integration and mobile/gamepad proof remain pending.

Five primary windows now follow the elements-v1 concepts (layout, plaques, tabs, cards, side rail) and the HUD follows the reference game; see HANDOFF for proof and gaps. Concept-matched [elements-v2](../assets/ui/elements-v2/README.md) imported/assembled: 10 atlases, shared wood/button/nav art and five primary page layouts. Desktop Play: HUD, Inventory, Garden selection/Seeds, Pets tabs, Shop Passes/Products and Rewards Daily/Codes/red X clicked; Incubator illustrations verified after layer fix. Final Garden row-height/encoding and Rewards shade fixes compiled/synced; final screenshots interrupted by concurrent Studio map edits. Luau120 compile (0 errors), 8/8 UI sources match Studio. Mobile/gamepad and all transaction flows remain unverified. Concurrent Sword Pack catalog drops legacy weapon IDs: saved old items need a separate migration; do not restore the old catalog. Remaining catalog/world art and device proof belong to Phase 10; pixel-identical matching not established.

## ดาบ: Sword Pack 380 (วางแผน ArmZ 2026-10-02)

- **ทำแล้ว 2026-10-02** (ดู HANDOFF/systems §Run). ดาบใหม่ 380 ชิ้น ID `swd_001`–`swd_380` (stable); Common 110 / Rare 95 / Epic 80 / Legendary 60 / Mythic 35. basePower Base×1–×4 ในความหายาก, ธาตุ 8 คีย์เดิม (~25% Common ไม่มีธาตุ).
- ต้นทางข้อมูลยังเป็น `data/weapons.json` → `gen_config.py`; ระหว่างทดลองใช้ `Config.SwordPack` + `Shared.WeaponCatalog` รวมกับ `Config.Weapons` (ห้ามแก้ Weapons.luau ด้วยมือ). ก่อนปิดงานย้ายเข้า pipeline JSON และรัน `balance_sim.py`.
- Feature flag `SwordPack`; ปิดแล้ว Loot ไม่สุ่ม swd_ แต่ ById ยังหาเจอ (เซฟไม่พัง). Index/collection totals ต้องนับใหม่.
- ภาพ: ต่อ `WeaponVisual` (Tool `ForestWeapon` contract เดิม) ดาบ retro ≤10 parts + trail ตามธาตุเฉพาะตอนฟัน, VFX ตาม rarity, hit burst ที่ต้นไม้; ไม่สร้างระบบต่อสู้ใหม่. Mesh เสริมได้จาก `3d weapon/RPGWeapons_Free.zip` (Long/Short Sword, Sabre, Dagger).

## 8–9. การตัดสินใจที่คงไว้

มี Friend Boost/Mount/ตกแต่งฐาน/Photo-Emote/เติมเงินไม่ P2W; ไม่มี Co-op Run แชร์ตัวคูณ.
ไม่คัดแมพ/ชื่อ/อาวุธอนิเมะจริง. Creator Store ใช้ได้ตาม SKILL; การซื้อเสียเงินต้องมีคำสั่ง.

## 14–15. Balance / การเพิ่มระบบ

Config เป็น registry; เพิ่มของ/โซน/ซีซันเป็นแถวด้วย ID ใหม่. คง compatibility ผ่าน Reconcile/versioned migrations.
สูตรเดียวใน Balance/Config; เปลี่ยนตัวเลขรัน `tools/balance_sim.py`. Feature Flag + Admin test commands ทุกระบบ.
Wood/Coins รวม cap ×4; permanent type ใช้ค่าสูงสุดกับทางฟรี (cap ถาวรเดิม). Pet/Luck/hatch/slots อ่าน validation ที่เกี่ยวข้องก่อนแก้.
ข้อมูล/รางวัล/ราคา/ownership ตัดสินที่ server; ledger สำหรับธุรกรรมซ้ำ. รายละเอียด persistence/scaling: design §14–15.

## 17. Monetization

- ทางฟรีถึงพลัง/ความจุปลายทางเดียวกัน; เติมเร่งเวลา/สะดวก/cosmetics. Exclusive ซื้ออย่างเดียวเป็น cosmetic; Ranked PvP ค่าสถานะเท่ากัน.
- ไข่ Robux ต้องปลอดภัย/ขโมยไม่ได้. Temporary boosts ซื้อซ้ำต่อเวลา; ใช้เพดานเกม. Managed Pricing ต้องแสดงราคาจริงจาก MarketplaceService และตรวจผลต่อการโอนของก่อนเปิดใช้.
- **ระบบร้านและ receipt ทำแล้ว**; ID จริง/นิยามสินค้า = `src/shared/Config/Products.luau`. Assets/listing JSON ไม่ใช่ runtime config.
- Pass 10: VIP 249; Wood/Coins ×2 299/299; Lucky 399; Pets +2 349; Hatch ×2/Garden +10 249/249; AutoSell/OpenTen 149/149; Teleport 199 Robux.
- Products 17: Gems 100/550/1200/6500 = 19/79/149/699; Wood/Coins 15/30 นาที = 19/29; EXP = 29/49; Luck = 39/69; server Luck 15 นาที 99; hatch 39; grow 19; key 29; base lock 19. ราคาฐาน Beta ไม่ใช่การรับประกันราคาภูมิภาค.
- Season Premium 499, ID 3715870274: เฉพาะซีซันที่ซื้อ; เล่นเก็บ XP เพื่อ claim ฟรี/Premium. ปัจจุบัน 30 × 1,000 XP, Gems/boost/chest ≤Legendary; **ไม่มี cosmetics implementation**.
- Receipt เซฟก่อน Granted; Premium pendingFor ผูกซีซัน, ซื้อซ้ำ/หมดซีซัน fallback 4,500 Gems; ค่าเริ่มต้นรอ balance. ก่อนต่อร้าน/ซีซันอ่าน [Phase 8g](phase8_shop_season_validation.md).
- ภาพ/EN-TH copy/ZIP: `assets/monetization/`, `developer-products/`, `season-premium/`; PNG 512×512 alpha. ข้อความอาจถูก Roblox filter ต้องตรวจหลัง save.
- รายละเอียด intent ร้าน/cosmetics/Premium: design §17; **โค้ดและ Phase 8g เป็นสถานะ implementation ล่าสุด**.

## 18. Admin และ readiness

Server ตรวจสิทธิ์ Admin/Owner; public remote ส่ง intent ไม่รับ Force. คำสั่งแจกของมี provenance; ตัด AdminTouched จากอันดับ.
Flag ใหม่มีปุ่มทดสอบ Admin; destructive/global live action ใช้ confirmation ตามระบบเดิม.
ก่อน Publish: ตรวจ source sync/startup, receipts/เซฟ/restore, exploit/สิทธิ์, multi-account/server, mobile/gamepad, balance/UI. ผลรายงานแยกตามระบบใน INDEX.

## การดูแลเอกสาร

อัปเดต **plan/SKILL/HANDOFF พร้อมกัน**: plan เก็บ intent/backlog, SKILL เก็บกฎ, handoff เก็บ current state. ไม่เพิ่มประวัติซ้ำ; validation เก็บหลักฐาน.
design.md เป็น spec snapshot; systems.md รวม seams. หากขัดกันใช้ไฟล์หลักล่าสุด/Config และตรวจ implementation. Raw reports/history เก็บใน Git 5d09e37; ลบสำเนา archive/JSON/screens จาก docs แล้ว.
