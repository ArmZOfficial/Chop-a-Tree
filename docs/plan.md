# Chop a Tree — แผนหลักฉบับย่อ (ร่าง 18)

อัปเดต 2026-10-02. สถานะ/ผลตรวจล่าสุดอยู่ [HANDOFF](HANDOFF.md); กฎอยู่ [SKILL](../SKILL.md).
อ่านรายละเอียดเฉพาะงานจาก [INDEX](INDEX.md). Spec รายละเอียด: [design reference](design.md) — เลือกหัวข้อ ไม่อ่านทั้งไฟล์.

## 0. เกมและขอบเขต

Roblox **Chop a Tree** (ชื่อ place Chop a Trees), 7 คน/เซิร์ฟ, 8 โซนในทวีปแนวนอน → เกาะ Lumora. Low-poly fantasy + แสงสมจริง + VFX อนิเมะ; เอกลักษณ์/ไอเทมของเราเอง.
Loop: ฟันต้นไม้ → End Run → หีบ/อาวุธ → สำรวจ/ไข่/สัตว์ → สวน/ฐาน → บอส/ปลดโซน → Rebirth.
เรื่อง The Withering: ป่าติดราเน่า; ฟื้นศาลเจ้าและเดินทางถึง Lumora. บท 3–8 มี NPC ผู้เฝ้าโซน/บทพูด/คัตซีนศาลเจ้าแล้ว (ยังไม่ Publish).

## 3. แมพ

Rootfall hub + ฐาน 7 หลัง; Wilds Zone1–8, ประตู/warp/shrine/boss/nests; ป่าและ HP ใช้ร่วมเซิร์ฟ. Rebirth ต่างกัน normalized damage.
โซน 1–7 ต่อกันแนวนอน, โซน 8 เกาะลอย; **ไม่กลับไปภูเขาเกลียว**. ผัง/asset/tag constraints: design reference §3/§6 และ [map constraints](systems.md#map).

## 4. ข้อตกลง gameplay ที่คงไว้

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
| 10 | Balance + UI/ภาพ/เสียง/VFX/อุปกรณ์จริง | Wood windows/outlined headings/red X/blur, Inventory rarity grid, Shop art cards, Index gallery, Music/SFX implemented and desktop checked; English copy; device/all-flow proof and item/world art/VFX/balance pending; not published |

Regression หลังร้าน 2–7/8a–f รันซ้ำครบและ restore ผ่าน; แก้ festival preview ถูก forecast อนาคตล้าง. Receipt failed-save/reconnect ผ่านบน DataStore บัญชีจริงด้วย synthetic receipt และยืนยันซ้ำด้วย harness Save/Replay; คืนข้อมูลและเซฟแล้ว. ซื้อผ่านหน้าจ่าย Robux จริงยังค้าง รอจัด session เกม. Counts/หลักฐานอยู่ Phase 8g.
ซีซัน 2 ป่าแสงจันทร์ (`s2_2026_11`) 2026-11-01→12-01 และซีซัน 3 ป่าหิมะเงิน (`s3_2026_12`) 12-01→2027-01-01 UTC พร้อม; ใช้ XP/รางวัลเดิม. Rollover/late receipt/ห่วงโซ่ซีซันผ่าน scenario 34/34.
ถัดไป: ซื้อผ่าน Roblox Player จริงแล้ว reconnect และตรวจหลายบัญชี/อุปกรณ์; เพิ่มซีซัน 4 ก่อน **2027-01-01 UTC**.
ผู้ใช้สั่งเริ่ม Phase 9 ระหว่างรอซื้อจริง: เริ่มจากพอร์ทัล/คิว Ranked-Casual แยกกัน, reserved server, ยกเลิก/failed-transfer recovery. PvP ยังปิดและ Arena.PlaceId=0 จนสนามอยู่ Universe เดียวกันและ match server พร้อม. รายละเอียดสถานะ/ข้อจำกัดใน [systems §Arena](systems.md#arena).
ค้าง: ไลก์/กระดานฐานยอดนิยม. ตกแต่งฐาน/ของเทศกาล/กับดัก/สัตว์เฝ้า/NPC บท 3–8 ทำแล้ว ยังไม่ Publish.
**คอสเมติกให้รอ ArmZ สั่ง.** ไม่ประกาศ Beta/Publish เอง. Milestone M4 เป้าหมาย Beta หลังตรวจ readiness; M5 PvP, M6 polish (รายละเอียด design §16).

Player-facing UI/signs/dialogue/notifications use **English**. Phase 10 direction: simulator-style brown wood windows, large original icons, outlined labels, red close/green buy buttons, rarity grids with previews and blurred scene; one modal at a time. Keep live prices and existing systems. Actual Play proof/remaining item art: [Phase 10 UI](systems.md#phase-10-ui).

UI art/design ready: [elements-v1](../assets/ui/elements-v1/UX.md), 36 reusable sprites + five screen concepts. Assemble shared art first, then Garden/Pets selection with contextual actions; keep service rules/live English labels. New pack integration and mobile/gamepad proof remain pending.

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
