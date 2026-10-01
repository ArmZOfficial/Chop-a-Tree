# HANDOFF — Chop a Tree (สำหรับ AI ตัวถัดไป)

> อัปเดตล่าสุด: 2026-10-02 (เวลาไทย) · Phase 8f Emote/Photo ทดสอบแล้ว; ถัดไปร้านเติมเงิน + Season Pass (รอ ID จาก ArmZ)
> **อ่านไฟล์นี้ก่อน แล้วอ่าน `docs/plan.md` (แผนหลัก ร่างที่ 17) ประกอบ**

## 0. เริ่มตรงนี้ (สถานะล่าสุด)

**งานล่าสุด — Developer Product 2026-10-02:** ผู้ใช้ขอภาพและคำอธิบายซื้อซ้ำสไตล์ Chop a Tree. เตรียมครบ 17 รายการตาม plan 17.3 ที่ `assets/monetization/developer-products/` (Gems 4, ยา 8, server Luck, hatch/grow, key, base lock). ใช้ `icons/` PNG 512×512 alpha; `README.md`/`gallery.html` สำหรับคัดลอกไทย-อังกฤษ, `products.json` ราคา Beta กำหนดแล้ว/ID null, `prompts.json` exact prompt ของ built-in imagegen, `validation.json` ขนาด/alpha/hash 17/17, `preview.png` ภาพรวม และ `Chop-a-Tree-Developer-Products.zip` ครบชุด. ตรวจภาพจริงและไฟล์ครบแล้ว; ไม่เปลี่ยนโค้ดจึงไม่รัน Roblox regression ใหม่. ยังไม่ได้สร้างสินค้า/ตั้งขาย/ต่อ receipt/เปิด Shop/Publish. ใช้ copy หลังตรวจผลของสินค้าและ receipt ฝั่ง server แบบไม่จ่ายซ้ำ; ราคาเริ่มต้นกำหนดแล้วตาม plan 17.3.1 (Gems 19/79/149/699, Wood-Coins 19/29, EXP 29/49, Luck 39/69, server Luck 99, hatch 39, grow 19, key 29, lock 19). Pass คงราคาเดิมและ Season Premium 499. ต้องรับ Product ID จริงก่อนต่อร้าน/Season Pass; ยังไม่มีข้อมูลยอดซื้อ/balance ที่พิสูจน์ความเหมาะสม. อ่าน MarketplaceService ราคา runtime เมื่อมี Managed Pricing. ZIP/README/gallery/products อัปเดตราคาตรงกัน. plan/SKILL/handoff อัปเดตพร้อมกัน.

**งานล่าสุด — ชุด Game Pass 2026-10-02:** ผู้ใช้เลือกครบ 10 Pass ตาม plan 17.2. สร้างภาพแยก 10 PNG วงกลม 512×512 alpha โปร่งใส สไตล์ป่า/สวน/ไข่/ขวาน Chop a Tree และชื่อ/คำอธิบายไทย-อังกฤษครบที่ `assets/monetization/`. เปิด `gallery.html` เพื่อคัดลอก; `README.md` มีข้อความครบ, `passes.json` มีราคาในแผน/ไฟล์ภาพ, `prompts.json` เก็บ prompt, `validation.json` ตรวจขนาด/alpha/hash 10/10, `preview.png` ภาพรวม และ `Chop-a-Tree-Game-Passes.zip` ชุดดาวน์โหลด. ดูภาพ 512 แล้วครบ/อ่านได้. ไม่เปลี่ยนโค้ดเกม จึงไม่ได้รัน regression ใหม่; ยังไม่ได้ต่อสิทธิ์ซื้อ/เปิด Shop/สร้าง Pass/ตั้ง Sales/มี asset ID/Publish. ให้ใช้ข้อความหลังทำและตรวจสิทธิ์จริงแล้ว. plan/SKILL/handoff อัปเดตพร้อมกัน; งานระบบถัดไปยังร้านเติมเงิน + Season Pass ตามด้านล่าง.

1. ผู้ใช้ตอบ **ต่อ** (เลือกทำ Emote/Photo ก่อนร้าน) → ทำ **Phase 8f** แล้ว: วงล้อท่าทาง 7 ท่า (G), โชว์อาวุธ + ออร่าสีธาตุจาก EmoteService (คูลดาวน์ 4 วิ), โหมดถ่ายรูป (P) ซ่อน UI/CoreGui, กรอบ CHOP A TREE, ฟิลเตอร์ 4 แบบ, กล้องอิสระบนคอม. Feature `Emotes`, remote `EmoteAction`, admin `emote.aura`.
2. Server scenario **5/5** + input จริงครบ (เต้น/W ยกเลิก/โชว์อาวุธ/P/W-E ย้ายกล้อง ตัวละครนิ่ง/ฟิลเตอร์/คืน UI 14 ตัว). Source 7/7 ตรง Studio Edit, console ไม่มี error, ไม่ได้ Publish. อ่าน `docs/phase8_emote_validation.md`.
3. ถัดไป: **ร้านเติมเงิน + Season Pass** (plan หัวข้อ 17) — ArmZ ต้องสร้าง Game Pass/Developer Product ใน Creator Dashboard แล้วส่ง ID; ห้ามซื้อ Robux เอง. ระบบปลดล็อกท่าทางให้ทำพร้อมร้าน/Season Pass.

### บันทึก Phase 8e (ประวัติ)

1. ผู้ใช้สั่ง **ทำต่อได้เลย** → ทำ **Phase 8e อีเวนต์เทศกาล** แล้ว: `Config.Events` 4 เทศกาล (ฮาโลวีน Bloodmoon ทุกคืน, ลอยกระทง Aurora กลางคืน, คริสต์มาส/ปีใหม่ หิมะ, สงกรานต์ ฝน + Splash ×6) ซ้อนบนตาราง UTC ใน WeatherService; อากาศหายาก/Rot คงเดิม. Feature `Festivals`, admin `festival.<id>` (เฉพาะเซิร์ฟ 10 นาที) และ `festival.clear`, badge พยากรณ์ขึ้นชื่อเทศกาล.
2. ผ่าน **15/15** (`phase8_festival_test_results.json`) + GUI AdminRun→badge, regression Weather **38/38** (fixture mutation 15→16 / union 16→17 เพราะ Splash). Source 6/6 ตรง Studio Edit, startup ไม่มี error, ไม่มี test Script ค้าง, ไม่ได้ Publish. อ่าน `docs/phase8_festival_validation.md`.
3. ถัดไป: **ร้านเติมเงิน + Season Pass** (plan หัวข้อ 17 — ต้องใช้ Game Pass/Dev Product ID จริงจาก ArmZ; ห้ามซื้อด้วย Robux เอง) และ **Emote/Photo** (plan 9.4). ของตกแต่งเทศกาลยังค้าง.

### บันทึก Phase 8d3 (ประวัติ)

1. ผู้ใช้สั่ง **อ่าน plan/skill/handoff แล้วทำต่อ** → ทำ **Phase 8d3** แล้ว: ambient zone mutation (สวนจากเมล็ดโซน 3/5/6 สุ่ม Misty/Wet/Chilled 5% ต่อรอบผล ออนไลน์เท่านั้น), พ่อค้าเร่กระรอก (UTC ทุกชั่วโมง นาที 30–40, ของ 4 ชิ้น deterministic, limit ต่อ visit, NPC placeholder ข้างร้านเมล็ด, แท็บ "พ่อค้าเร่" ใน Garden panel, admin `merchant.summon/dismiss`) และเพดานขายผลต่อวัน UTC (Cosmic 5/Celestial 10/Rainbow 10/Aurora 15/Electrified 15 ราคาเต็ม เกิน ×0.1). Schema v1 เติม Garden.sellDay/sold + Merchant.bought; Feature Merchant เปิด.
2. ผ่าน **30/30** (`phase8_merchant_test_results.json`), regression Phase4 **55/55**. GUI จริง: summon ผ่าน client AdminRun, กด E เปิดร้าน, ซื้อ Sunburst 2 ใบแล้วใบที่ 3 ถูกปฏิเสธ, ขาย Cosmic 7 ลูก +78,520 และโควตา 5/5→0/5; harness คืน profile ไม่ต่าง. Source 11/11 ตรง Studio Edit, startup smoke ไม่มี error, ไม่มี test Script ค้าง; ไม่ได้ Publish; ไม่แตะสูตร Balance. อ่าน `docs/phase8_merchant_validation.md`.
3. ข้อควรระวัง: รอบนี้เผลอ require MerchantService จาก MCP แล้ว error (cache แยก) — ไม่กระทบข้อมูล แต่ให้ใช้ Script ใน VM เท่านั้น. ไม่ได้รัน regression ชุดอื่นนอกจาก Phase4 เพราะไม่แตะโค้ดส่วนนั้น.
4. ถัดไป: งาน Phase 8 ที่เหลือ — อีเวนต์เทศกาล (Config.Events), ร้านเติมเงิน + Season Pass, Emote/Photo. ยังห้ามประกาศจบ Phase 8; หลายบัญชี/มือถือ/gamepad/reconnect และราคา/อัตรา Phase 10 ยังค้าง.

### บันทึก Phase 8d2 (ประวัติ)

1. ผู้ใช้สั่ง **ทำต่อเลย** → ทำ **Phase 8d2 encounters core** แล้ว: Meteor Stardust โซน 1 ทุก 20 วิ (+5, TTL 90 วิ, cap 12), ใช้ server Run/access/distance/eventKey และเก็บธนาคารทันที; แลก 20 = Rare LEVEL 1 IL 1 ที่แท่นหีบ. Fog rare/Bloodmoon Secret-only spot ใช้ Nest carry/guardian/End Run เดิม. Aurora Egg 100K Coins ที่สายพานซื้อได้ครั้งเดียวต่อ event key; schema v1 เพิ่ม Pets.weatherBought/Stats.WorldBossKills โดยคงเซฟและ Rebirth. Catalog pets = 43 (เพิ่ม Blood Raven).
2. RotInvasion ทุก UTC 2 ชม. นาน 10 นาที (weight=0, rare forecast ???) ใช้ลานบอสโซน 1 ชั่วคราว, HP ×8 จาก Balance.BossHP(1,R). แบ่ง pool 1,000 Gems/100 Stardust ตาม normalized damage ≥0.1%/ปัดลง; จ่ายครั้งเดียว เฉพาะ loaded player ที่ยังอยู่ Run เดิม. แยก Stats.WorldBossKills และไม่เพิ่ม Progress.Bosses/ศาลเจ้า/เควส guardian; ปิด flag/อากาศจบคืนบอสปกติ, event key เดิมไม่เกิดซ้ำ.
3. ผ่าน **59/59**, regression หีบ/สัตว์/เนื้อเรื่อง/โซน/Collections/Weather **36/81/51/23/55/38**. GUI mouse แลกหีบ, ซื้อ Aurora/ซื้อซ้ำถูกปฏิเสธ, keyboard E +5 Stardust และ CHOP ลด HP world boss; public Force ถูกปฏิเสธ. Owner admin grant +20/marksTarget ผ่านจริง และมี 2 คำสั่ง weather. หลักฐาน `phase8_encounters_{test_results,regression_results,gui_results,source_checksums}.json`; อ่าน `docs/phase8_encounters_validation.md` ก่อนต่อ.
4. คืน profile/flags/weather/anchor/ตำแหน่ง/Balance และ GUI Finish แล้ว;เทียบข้อมูลเศรษฐกิจ/สัตว์/collection/Meta ไม่ต่าง. Source **18/18** ตรง Studio Edit, startup smoke ไม่มี error, ไม่มี test Script ค้าง; balance baseline/diff --check ผ่าน. ไม่ overwrite ProfileStore/ไม่ Publish. Plan/SKILL/handoff อัปเดตพร้อมกัน. รอบเพิ่ม remote assertion เคยใช้ getter OnServerInvoke ที่ Roblox ไม่รองรับ; ย้าย proof ไป InvokeServer จาก client จริง แล้ว scenario 59 ข้อเดิมผ่าน.
5. ถัดไป **Phase 8d3 ambient zone mutations/merchant/rare fruit daily cap** ตาม plan. เทศกาล/ร้าน/Season Pass/Emote-Photo ยังเป็นส่วนค้าง Phase 8. หลายบัญชี/แชร์ HP ต่าง Rebirth/server hop/reconnect/ขาดการเชื่อมต่อระหว่างจ่าย/มือถือ/gamepad/balance/VFX-เสียงยังไม่ได้พิสูจน์; อย่าประกาศจบ Phase 8. HP/contribution เป็นต่อเซิร์ฟ ไม่มี cross-server shared boss; disconnected/จบ Run ก่อน defeat ไม่ได้ payout ย้อนหลัง. ราคาพิเศษ/rarity odds เป็นค่าเริ่มต้น Phase 10.

### บันทึก Phase 8d1 (ประวัติ)

1. ผู้ใช้สั่ง **ทำต่อเลย** → ทำ **Phase 8d1 อากาศ/Live Event core** แล้ว. Config อากาศ 13 แบบ, ผล mutation 15 แบบ/Index union 16 IDs, Wind Area ×1.5/Sakura crit ×15/Aurora Wood-Coins ×1.5/Bloodmoon HP ×2 รางวัล ×4 (Wood/Coins cap ×4), Fog chest เพิ่ม 1 จุดโซน 1. ตาราง UTC + rare weekend weights ×2, night gates, Rainbow 10% ต่อ Rain; RotInvasion manual-only. อ่าน `docs/phase8_weather_validation.md` ก่อนต่อ **Phase 8d2 Stardust/ไข่พิเศษ/บอสโลก**; ยังไม่ถือว่า weather table ทุกช่องหรือทั้ง Phase 8 เสร็จ.
2. LiveEventService ใช้ MemoryStore UpdateAsync revision + MessagingService reread/poll 30 วิ; UTC sequence + start delay 5 วิ/late join/expiry/failed API. Owner-only start/stop ทุกเซิร์ฟ confirm 2, preview/stop preview เฉพาะเซิร์ฟ 2 คำสั่ง. Preset Sakura→Golden→Aurora 2 นาที/ขั้น (preview 20 วิ), Studio topic/store แยก `_Studio`. Global delivery เป็น best effort; ขณะ API ขัดข้องไม่รับประกันเปลี่ยนพร้อมกันทันที. ไม่มี public Force หรือข้อความผู้เล่น broadcast.
3. ผ่าน **38/38**, regression สวน/สัตว์/เนื้อเรื่อง/หีบ/Collections **55/81/51/36/55**. Mouse preview เห็น Sakura→Golden→Aurora, LIVE forecast/particles/ClockTime=0; global request ไม่ confirm ถูกปฏิเสธ. MemoryStore Studio read ready; transaction/notification failure ใช้ fake store ไม่ได้ publish global จริงหรือทดสอบหลายเซิร์ฟ. หลักฐาน `phase8_weather_{test_results,regression_results,gui_results,source_checksums}.json`; source 16/16 ตรง Studio. รอบแรก fixture คาดจำนวน union Mutation ผิดเป็น 18 แล้วแก้เป็น 16 ตามข้อมูลจริง.
4. คืน profile/flags/weather/preview/anchor/ตำแหน่ง/Balance หลัง scenario/GUI Finish แล้ว; snapshot GUI ตรวจข้อมูลเศรษฐกิจและ collection ไม่ต่าง. Startup smoke ใหม่ไม่มี error, Studio กลับ Edit ไม่มี test Script ค้าง. balance_sim.py baseline/diff --check ผ่าน; ไม่ overwrite ProfileStore และไม่ได้ Publish. Plan/skill/handoff อัปเดตพร้อมกัน. ค้าง Meteor pickups/การใช้ Stardust, Fog rare nests, Aurora shop eggs/Bloodmoon Secret eggs, Rot boss ทุก 2 ชม., zone ambient mutations, merchant/เทศกาล/rare fruit sale cap. Multi-serverจริง/สิทธิ์บัญชีอื่น/mobile/gamepad/เสียง-VFX/balance ยังต้องตรวจ.

### บันทึก Phase 8c (ประวัติ)

1. ผู้ใช้สั่ง **ทำต่อเลย** → ทำ **Phase 8c Index buffs/Achievements/ฉายา** แล้ว: อาวุธครบ Power +10%, สัตว์ครบ Coins +25%, เมล็ดครบ Wood +25%, Mutation ครบ Luck +25%. Wood/Coins รวมทักษะ Rebirth แบบบวก cap ×2 ถาวร, บัฟรวม cap ×4. เพิ่ม Luck 2 ขั้นใน Rebirth (2/4 Tokens), +12.5% ต่อขั้น รวม Index cap +25%; สูตร Epic+ แบบสัมพัทธ์/ Giant เดิม. อ่าน `docs/phase8_collections_validation.md` ก่อนต่อ Phase 8d อากาศครบทุกแบบ/Live Event ตาม plan 4.12/5.7.
2. AchievementService ตรวจ Stats/Progress/Index, claim Gems ครั้งเดียวและเลือก/ถอด title ที่รับแล้ว. มี 9 achievements, server BillboardGui บนหัว, StoryHUD แท็บใหม่, Index แสดงโบนัส, Inventory odds ใช้ CollectionMath เดียวกับ server. Schema v1 เพิ่ม Achievements โดยไม่เปลี่ยน store. Quest.ScanIndex นับ catalog จริงและซ่อม completion marker เก่าที่ขาด; marker ที่ได้แล้วคงเมื่อเพิ่มของใหม่. Admin แท็บโซน & เนื้อเรื่อง unlockall/reset 2 คำสั่ง marksTarget; unlock ไม่จ่าย Gems. Feature IndexBonuses/Achievements เปิด.
3. ผล **55/55**, regression หีบ/เนื้อเรื่อง/Rebirth/Daily-Codes-Leaderboard **36/51/41/45**; GUI เมาส์จริงรับ 20 Gems, ถอด/เลือกฉายาไม่จ่ายซ้ำ, ภาพ title บนหัว, Index เมล็ด 8/8 + Wood 25%, ซื้อ Luck rank1 และ preview Epic 5.6%. Remote Force ถูกปฏิเสธ, metadata admin มี 2 คำสั่ง. หลักฐาน `phase8_collections_{test_results,regression_results,gui_results,source_checksums}.json`; source 15/15 ตรง Edit. Zero-Luck เคยเปลี่ยน floating-point baseline แล้วแก้ให้ข้าม reweight; original regression ผ่านโดยไม่ลด assertion.
4. คืน profile หลัง GUI Finish เทียบ Currencies/Inventory/Progress/Index/Achievements/Rebirth/Boosts/Codes/Garden/Quests ไม่ต่าง; flags/weather/anchor/ตำแหน่งคืนแล้ว. Studio กลับ Edit ไม่มี test Script ค้าง; startup smoke ใหม่ไม่มี error. balance_sim.py baseline และ diff --check ผ่าน. ห้าม overwrite ProfileStore; ยังไม่ได้ Publish. Plan/SKILL/handoff อัปเดตพร้อมกัน. ยังไม่ได้ reconnect/respawn จริง/หลายบัญชี/มือถือ/gamepad; บอสโลก/เทศกาล/ร้าน/Season Pass/Emote-Photo เป็นส่วนค้าง Phase 8 และ UI/balance ผู้เล่นจริงรอ Phase 10.

### บันทึก Phase 8b (ประวัติ)

1. ผู้ใช้สั่ง **ต่อเลย** หลัง Phase 8a → ทำ **Phase 8b Daily login/Codes/Leaderboard** แล้ว. Daily 7 วัน UTC, Codes stable ID/expiry server-owned, timed Wood/Coins boosts, Top 10 Server/Global และกระดานหมู่บ้าน 2 แผ่นพร้อม prompt. Main โหลด Reward/Daily/Code/LeaderboardService และ RewardsController; schema v1 เติม Daily/Codes/Boosts. อ่าน `docs/phase8_rewards_validation.md` ก่อนต่อ Phase 8c บัฟ Index/Achievements.
2. ผล **45/45** + GUI เมาส์/คีย์บอร์ดจริง: Daily 20 Gems, RELEASE 100 Gems + Rare 1 ใบ, ทั้งคู่รับซ้ำไม่ได้; snapshot profile จริงได้ 120 Gems. Global API Studio `ready` และภาพกระดาน/เมนูแสดงอันดับจริง; Studio ใช้ store แยกจากเกมจริง. ผล regression/AutoCut และข้อจำกัดอ่าน validation; ห้ามอ้างว่าเป็นทดสอบ production หลายเซิร์ฟ.
3. Admin rewards 5 คำสั่งครบ; คำสั่งเปลี่ยนของ marksTarget. Global integer log encoding รองรับ 1e300 มี ≈; tombstone 0 ตัดแอดมินและกัน stale write คืนอันดับ. Season config แยก store; Meta.AdminTouched เดิมยังถูกตัดอย่างระมัดระวัง. Codes RELEASE/FORESTBOOST หมดอายุ 2026-11-01 00:00 UTC; เพิ่ม code ใหม่ต้องใช้ stable ID ใหม่.
4. ทุก scenario/GUIHarness คืน profile/flags/weather/anchor/ตำแหน่งหลังตรวจ; source 16 ไฟล์ตรง repo/Studio Edit และไม่มี test Script ค้าง. startup smoke ใหม่พบ RewardsHUD/RebirthHUD ครบ Output ไม่มี error; Studio กลับ Edit. Regression Rebirth/หีบ/Run = 41/36/23; Run เคย timeout AutoCut แล้ว probe/รอบใหม่ผ่านโดยไม่แก้เทสต์ สาเหตุยังไม่ยืนยัน. ห้าม overwrite ProfileStore. หลักฐาน `phase8_rewards_test_results.json`, `phase8_rewards_regression_results.json`, `phase8_rewards_source_checksums.json`. ยังไม่ได้ Publish. Plan, skill และ handoff อัปเดตพร้อมกัน.

### บันทึก Phase 8a (ประวัติ)

1. ผู้ใช้สั่ง **ทำต่อเลย** หลังปิด Phase 7 → ทำ **Phase 8a Rebirth + ทักษะถาวร 5 สาย** แล้ว. Server ตรวจบอส/Coins ของวัฏจักรปัจจุบัน, เตรียม token ยืนยัน 30 วิใช้ครั้งเดียว, ตรวจเงื่อนไขซ้ำและรีเซ็ตเงิน/โซน/เควสหลัก/อัปเกรดฐาน. คง inventory/Gems/Index/Stats/เควสรายวัน/สัปดาห์/crops/skills; สัตว์เกินความจุกลับกระเป๋า. อ่าน `docs/phase8_rebirth_validation.md` ก่อนต่อ Phase 8b Daily login/Codes/Leaderboard.
2. AutoCut reward .55→.75, ช่องสัตว์สูงสุด 6, หีบใน Run +5 เลเวล, Wood/Coins skill สูงสุด ×2. Run.Award รวม Wood friend/weather/pet/skill cap ×4 และ Coins friend/skill cap ×4; reward บอสแยกจาก cap. ราคากับ Token เป็นค่าตั้งต้น Config.Rebirth รอจูน Phase 10. แท็บ admin Rebirth มี 5 คำสั่ง; Feature Rebirth=true.
3. ผลตรวจ **Rebirth 41/41**, GUI เมาส์จริงซื้อ/ยกเลิก/ยืนยัน/หมดอายุ/ตรวจ modal ZIndex; regression **Phase 2/4/5/6 = 23/55/81/51**. ผลจริงอยู่ `phase8_rebirth_test_results.json` และ `phase8_rebirth_regression_results.json`. balance_sim.py และ diff --check ผ่าน. Source 17 ไฟล์ตรง repo/Studio Edit ตาม `phase8_rebirth_source_checksums.json`; ห้าม overwrite ProfileStore.
4. คืน profile/flags/weather/anchor/ตำแหน่งหลังเทสต์และกลับ Studio Edit ไม่มี test Script ค้าง; Output ไม่มี error. ยังไม่ได้ Publish place. Plan, SKILL.md และ handoff อัปเดตพร้อมกันตามคำสั่งผู้ใช้. ยังไม่ได้ทดสอบ reconnect/multi-account/มือถือ/gamepad และ economy ผู้เล่นจริง.

### บันทึก Phase 7 (ประวัติ)

1. ผู้ใช้สั่ง **ทำต่อ** จากรอบ Phase 7 ที่หยุดเพราะ session limit. ปิดงาน Phase 7 core: Zones ทั้ง 8 built=true, ต้นไม้ 160/โซน, Creator Store prototypes 8 แบบที่ตัด script ออก, ไข่ 10 ชนิด/สัตว์ 42 ตัว, รัง 16 แห่ง/48 จุดไข่, บอส 8 ตัว, ZoneAmbience. อ่าน `docs/phase7_validation.md` ก่อนต่อ **Phase 8**; บท 3–8 ยังเป็นแม่แบบและ NPC/คัตซีนเฉพาะบทยังค้าง.
2. ตรวจเพิ่มเติมพบราก/ลำต้นบอสขวางทางจริง (เดินติดโซน 5). แก้ MapBuilder ให้เก็บ `BossArena.GuardianOffset` และ BossService ใช้ offset 26 studs ไปด้านห่างจากทางเดิน; โซน 8 อยู่ข้าง Lumora. ตรวจใน Play ด้วย raycast 2,048 จุด ไม่มีปัญหาหลังแก้. ผลเดินจริง/ผลเทสต์รอบสุดท้ายดู validation และ JSON ของ Phase 7.
3. Source ของ Phase 7 ทั้ง 8 ไฟล์ตรวจเทียบ repo/Studio ตาม `docs/phase7_source_checksums.json`; ห้าม overwrite ProfileStore. MapAssets ที่ตรวจแล้วอยู่ใน ServerStorage ของ place; สร้างซ้ำจาก place ใหม่ต้องโหลดต้นแบบตาม `tools/map/AssetPrototypes.luau` ก่อน (ไม่มีต้นแบบจะ fallback เป็นต้นไม้ Part).
4. ยังไม่ได้ Publish เกมจริง; Save/Publish place ใน Studio เมื่อพร้อม. แผน, skill และ handoff อัปเดตพร้อมกันตามคำสั่งผู้ใช้.
5. ผลสุดท้าย: Phase 7 **23/23**, regression Phase 6 **51/51**; Phase 5 **81/81** เป็นผลจากรอบก่อนแก้ตำแหน่งบอส. Raycast Play **2,048 จุด** และเดินจริง **16/16 เส้นทาง** ผ่าน; JSON อยู่ใน `docs/phase7_*` และ `phase5_phase7_regression_results.json`. คืน profile/ตำแหน่ง/WalkSpeed แล้ว; Studio กลับ Edit ไม่มี test Script ค้าง. การฆ่าบอสในเทสต์เคยล้มไม่สม่ำเสมอแล้วรันซ้ำผ่าน; สาเหตุยังไม่ยืนยัน ดู validation.

### บันทึกก่อน Phase 7 (ประวัติ; สถานะล่าสุดใช้รายการด้านบน)

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
| วางแผน (plan.md ร่างที่ 17) | ✅ plan/SKILL/handoff ตรง Phase 8f และงาน Phase 8 ที่เหลือ |
| **Phase 0 ฐานราก** | ✅ เสร็จ ทดสอบแล้วใน Studio ไม่มี error, commit `5f6f7e8` |
| **Phase 1 แมพโครง** | ✅ ทวีปตัว S กระชับ สร้างและทดสอบแล้ว |
| **Phase 2 ฟันต้นไม้ + Run** | ✅ core ผ่าน 23 checks + GUI; AFK ไม่จำกัดเวลายังไม่รองรับ, โล่ AFK รอ Phase 5 |
| **Phase 3 หีบ + อาวุธ** | ✅ core ผ่าน 36 checks + GUI; ภาพโมเดล procedural รอขัดเกลา Phase 10 |
| **Phase 4 สวน + อากาศพื้นฐาน** | ✅ core ผ่าน 55 checks + GUI; ทดสอบเซิร์ฟจริงหลายเครื่อง/มือถือและภาพ/เสียง/UI สุดท้ายยังค้าง |
| **Phase 5 ไข่ + สัตว์ + ขโมย + ฐาน** | ✅ core ผ่าน 81 checks + GUI; ค้างตกแต่งฐาน/กับดัก และทดสอบขโมยหลายบัญชีจริง |
| **Phase 6 เนื้อเรื่อง + เควส + บอส** | ✅ core ผ่าน 51 checks + GUI; บท 3–8 แม่แบบใช้ได้แล้ว, NPC/บทพูดเฉพาะ/คัตซีนยังค้าง |
| **Phase 7 โซน 3–8** | ✅ core ครบ 8 โซน ผ่าน 23/23; รายละเอียดเส้นทาง/ข้อจำกัดใน phase7_validation.md |
| **Phase 8** | 🟨 Rebirth 41/41; Rewards 45/45; Collections 55/55; Weather/Live Event 38/38; encounters 59/59; merchant/ambient/sell cap 30/30; festivals 15/15; Emote/Photo 5/5 + input; ถัดไปร้าน/Season Pass |
| Phase 9–10 | ⬜ ยังไม่เริ่ม (ดู plan.md หัวข้อ 7, 16) |

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
3. ต้นไม้: **160 ต้น/โซนครบทั้ง 8 โซน** หลัง Phase 7; โซน 3–8 ใช้ต้นแบบ Creator Store ตาม `docs/phase7_validation.md`.
4. ~~ทางขึ้นเขาเกลียว~~ → ยกเลิก ใช้ทวีปตัว S แทน

### 6.2 ไฟล์และ Studio (snapshot Phase 1; ไฟล์แก้ล่าสุดใช้ phase8_rewards_source_checksums.json)

1. `src/shared/Config/Zones.luau` → `ReplicatedStorage.Shared.Config.Zones`: UTF-8 LF **4,100 bytes, hash=1795469735**.
2. `tools/map/MapBuilder.luau` → `ServerStorage.MapTools.MapBuilder`: UTF-8 LF **45,794 bytes, hash=182475945**.
3. `Workspace.Map.{Ground,Water,Hills,Roads,Village,Wilds.Zone1..8}`; 4,619 BaseParts. ไม่มี Mountain.
4. `Layout()/RoadPoints()/BuildWorld()/BuildZone()` ใช้ผังใหม่; `BuildVillage()` เดิมยังใช้. MapBuilder require Zones ด้วย `:Clone()` กัน require cache เก่า.
5. Lighting Future, Atmosphere Density 0.2/Offset 0.3/Haze 0.3, StreamingEnabled=true.
6. Studio id ล่าสุด `975c8f5c-175f-44d4-bfcb-44154dd33573`; ชื่อ Chop a Trees ตรวจ PlaceId `93479990217075` แล้ว. **เรียก list_roblox_studios และตรวจ PlaceId ทุกครั้งก่อนเขียน** เพราะ id เปลี่ยนเมื่อเปิด Studio ใหม่/เชื่อมใหม่.

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
6. เครื่องมือ Studio: `mcp__Roblox_Studio__*` — studio_id ล่าสุด **`975c8f5c-175f-44d4-bfcb-44154dd33573`** (เปลี่ยนได้ ให้เรียก list_roblox_studios ก่อน)

## 9. สิ่งที่ ArmZ ต้องทำเอง (แจ้งไว้แล้ว)

1. Save/Publish place ใน Studio เมื่อพร้อม; รอบล่าสุด API services เปิดแล้ว
2. ลง Rojo (plugin + CLI) แล้ว `rojo serve` ในโฟลเดอร์ repo
3. (ทางเลือก) ใส่ UserId ทีมงาน/GroupId ใน `Config/Admins.luau`

## 10. Phase ถัดไป

**Phase 8f Emote/Photo ทำแล้ว; ถัดไปคือร้านเติมเงิน + Season Pass**. อ่าน `phase8_emote_validation.md`, `phase8_festival_validation.md`, `phase8_merchant_validation.md`, `phase8_encounters_validation.md`, `phase8_weather_validation.md` และ SKILL.md ก่อนต่อ. เทศกาล/ร้าน/Season Pass/Emote-Photo ยังเป็นงาน Phase 8 ที่เหลือตาม plan หัวข้อ 7; คงเพดานบัฟ/กฎทางฟรีในหัวข้อ 17.

1. **Phase 7 core ทำแล้ว**: โซนทั้ง 8 built=true; บอส/บทแม่แบบ/วาร์ป/ประตูทำงาน และเพิ่มไข่/สัตว์โซน 3–8 แล้ว. อ่าน `docs/phase7_validation.md` สำหรับผลตรวจ/ข้อจำกัด; รักษา GuardianOffset และต้นแบบ MapAssets เมื่อแก้แมพ.
2. ค้างจาก Phase 5–6: **ตกแต่งฐาน (plan 9.2)**, กับดัก/สัตว์เฝ้าฐาน, ทดสอบขโมย/ตีบอสร่วมกับผู้เล่นจริง 2+ บัญชี, แก้ GardenController ไม่ให้สร้างปุ่มใหม่ทุก 2 วิ (มีงานแยกเสนอไว้แล้ว), NPC อื่นตามเนื้อเรื่อง (พ่อค้ากระรอก/นักวิจัย). Index buffs/Achievements ทำแล้วใน Phase 8c.
3. อ่าน `docs/phase6_validation.md`, `phase5_validation.md`, `phase4_validation.md`, `phase3_validation.md` สำหรับ seams. ยังต้องทดสอบ multi-account/multi-server มือถือ/gamepad. ไข่ Secret/weather encounters ทำแล้ว, ไข่ Robux/ร้านยังค้าง; art/เสียง/โมเดลบอส-สัตว์/คัตซีน/UI polish ต่อ Phase 10.
4. **ทุก Phase ต้องเพิ่มปุ่มทดสอบใน Admin Panel** ผ่าน `AdminService.Register` และปิดระบบที่ยังไม่พร้อมด้วย Feature Flag
5. ArmZ ขอระบุ **งานปรับปรุง UI** ในแผนแล้ว: Phase 10 ครอบคลุม HUD, Run, Inventory, เปิดหีบ, สวน/เมล็ด, ไข่/สัตว์, เควส/Index, พยากรณ์อากาศ, ร้านค้า และ Admin Panel ให้เป็นสไตล์เดียวกัน อ่านง่ายและกดสะดวกบนคอมพิวเตอร์/มือถือ พร้อมขัดเกลาภาพแมพ แสง เสียง VFX และแอนิเมชัน (ดู plan.md หัวข้อ 7).

## 11. Skill ที่ใช้

- `../SKILL.md` — อ่านเมื่อเลือกหรือนำ asset มาใช้ใน Chop a Tree; เป็นแนวทางล่าสุดที่ ArmZ อนุญาตให้ใช้ Creator Store เพื่อช่วยงาน.
- `roblox-map-builder` (skill ของ ArmZ) — บังคับถามรายละเอียดก่อนสร้างแมพ; เวอร์ชันในบัญชีเป็นเวอร์ชันแรก (โฟลเดอร์ `Map/<Zone>`) แต่ให้ใช้โครงตาม plan.md: `Workspace.Map.Village`, `Workspace.Map.Wilds.ZoneN_<Key>`, สูตร ×100/โซน, ผังทวีปแนวนอน (ไม่ใช่ภูเขา)
