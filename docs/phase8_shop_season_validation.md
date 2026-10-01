# Phase 8g — ร้าน Robux + Season Pass

ทดสอบ 2026-10-02 (เวลาไทย), Studio PlaceId `93479990217075`. ร้าน **34/34** รันซ้ำ, Season Pass **33/33**, OpenTen คลิกจริงผ่าน; ยังไม่ได้ Publish.

## ร้าน Robux (commit `89ee78b`)

1. `Config/Products.luau` (shared): 10 Game Pass + 17 Developer Product ใช้ ID จริง ตรวจด้วย `GetProductInfo` แล้ว. ราคาอยู่บน Roblox; UI อ่านราคาสดด้วย `GetProductInfo` (รองรับ Managed Pricing).
2. `MonetizationService`: สิทธิ์ Pass เก็บใน `Purchases.passes` (ตรวจ `UserOwnsGamePassAsync` ตอนเข้าเกม + `PromptGamePassPurchaseFinished`). Developer Product ให้ของเฉพาะใน `ProcessReceipt` ครั้งเดียวต่อ `PurchaseId` (`Purchases.receipts`, เก็บ 90 วัน) และตอบ `PurchaseGranted` หลัง `SaveAndWait` เห็น receipt ในข้อมูลที่เซฟแล้วเท่านั้น. `Grant` ห้าม yield.
3. สินค้าที่ใช้ไม่ได้ตอนนี้ (ฟักทันทีไม่มีไข่, โตทันทีไม่มีต้น, ฐานล็อกอยู่แล้ว) ถูกปฏิเสธก่อนเปิดหน้าซื้อ (`READY`).
4. Pass ไม่ซ้อนกับทางฟรี: ×2 Wood/Coins = เพดานถาวรเดิม, Lucky +25% (ยา/Luck ทั้งเซิร์ฟเพิ่มชั่วคราวได้ถึง +50%), ช่องสัตว์ +2 (สูงสุด 6), ฟักไว ×2 = ตู้ฟักเลเวลสูงสุด, แปลง +10 (สูงสุด 30).
5. Client `ShopController` ปุ่ม "ร้าน Robux" (200,365) แท็บ Game Pass/ไอเทม; เปิดหีบ 10 ใบใน InventoryController เมื่อมี OpenTen; VIP แท็กแชท/ฉายา/Daily +25 Gems.
6. Admin แท็บ shop: สลับ Pass, ให้สินค้า, ยกเลิก Luck ทั้งเซิร์ฟ. Flag `Shop`.
7. ผล scenario ร้าน (raw report ใน Git 5d09e37) 34/34 + GUI (เปิดร้าน, ราคา 17 รายการ, กดซื้อเปิด prompt); รันซ้ำ 34/34 ล่าสุด. OpenTen และ regression ชุดเก่าตรวจเพิ่มด้านล่าง.

## Season Pass (commit `4d3ba3e`)

1. `Config/Season.luau`: ซีซัน 1 "ป่าแรกผลิ" `s1_2026_10` 2026-10-01 → 2026-11-01 UTC, 30 เลเวล × 1,000 XP. รางวัลฟรี + Premium ทุกเลเวลเป็น Gems/ยาบูสต์/หีบ (Premium หีบไม่เกิน Legendary = ไม่ P2W). คอสเมติก Exclusive ยังไม่มี: ArmZ เลือก **ยังไม่ทำระบบคอสเมติก** (plan 17.5).
2. XP มาจาก Stats delta (`DataService.Changed`, deferred): ฟันต้นไม้ 10 (Auto Cut 5), ปลูก/เก็บผล 15, ฟักไข่ 40, เปิดหีบ 10, บอส/บอสโลก 150. Flag ปิด = ไม่ได้ XP.
3. `SeasonService`: claim ทีละเลเวล / รับทั้งหมด, ledger `Season.free`/`Season.prem`. Profile `Season={id,xp,premium,free,prem,pendingFor}`; id ซีซันเปลี่ยน → รีเซ็ต XP/Premium/claim (รางวัลค้างหาย) ยกเว้น `pendingFor`.
4. Premium (product `3715870274`, 499 R$): ซื้อผ่าน `ShopAction Prompt seasonPremium` → `CanBuy` (ต้องมีซีซัน, ยังไม่มี Premium) → บันทึก `pendingFor` = ซีซันที่ขาย → `ProcessReceipt` → `GrantPremium` ปลดเฉพาะซีซันนั้น. ถ้าปลดไม่ได้ (มีแล้ว/ซีซันที่ซื้อจบแล้ว) ได้ `PremiumFallbackGems` 4,500 Gems แทน. Receipt ซ้ำไม่จ่ายซ้ำ (ledger เดียวกับร้าน).
5. Client `SeasonController` ปุ่มม่วง "Season Pass" (200,425): ชื่อซีซัน, เลเวล/XP/วันที่เหลือ, ปุ่มรับทั้งหมด, ปุ่มซื้อ Premium (ราคาสด), 30 แถวฟรี/Premium.
6. Admin แท็บ shop: `season.xp` (+1 เลเวล), `season.premium` (สลับ), `season.reset`. Flag `SeasonPass`. Remote `SeasonAction` (Sync/Claim/ClaimAll). Schema เติม `Season` ผ่าน Reconcile ไม่ต้อง migrate.
7. ผล scenario ซีซัน (raw report ใน Git 5d09e37) 29/29, regression ร้าน 34/34, GUI เปิดหน้าถูกต้อง, console ไม่มี error, source 11/11 ตรง Studio Edit. รอบแรกล้มข้อ 6 เพราะเทสอ่าน XP ก่อน handler deferred ทำงาน; แก้ที่เทส (`task.wait()`), service ไม่เปลี่ยน.

## ข้อจำกัด / ต้องทำต่อ

1. Receipt ทดสอบผ่าน `ProcessReceipt` โดยตรง; ArmZ รายงานซื้อเองผ่าน. Native UI ควบคุมได้แล้ว แต่ automation ยังไม่ได้ยืนยัน paid purchase ใน Roblox Player.
2. ซีซัน 2 `s2_2026_11` "ป่าแสงจันทร์" พร้อมช่วง 2026-11-01→12-01 UTC, ใช้ XP/รางวัลเดิม. ซีซัน 3 `s3_2026_12` "ป่าหิมะเงิน" 2026-12-01→2027-01-01 UTC พร้อมแล้ว; เพิ่มซีซัน 4 ก่อน 2027-01-01 UTC.
3. ค่า XP/รางวัล/ชื่อซีซัน/4,500 Gems เป็นค่าเริ่มต้น Beta ยังไม่ผ่านข้อมูลผู้เล่นจริง.
4. ปุ่ม Season Pass ชิดกล่องเควสด้านล่าง; จัด HUD ใหม่ใน Phase 10.
5. ยังไม่ได้ Publish.

## ตรวจเพิ่มซีซัน 2 — 2026-10-02

Phase8SeasonScenario เดิมปรับ boundary ให้รองรับหลายซีซัน เพิ่ม 4 checks: ไม่มี gap, rollover reset XP/Premium/claims แต่คง pendingFor, ใบเสร็จซีซัน 1 มาช้าจ่าย fallback ไม่ปลดซีซัน 2, Premium/claim สองแถวซีซัน 2. ผ่าน **33/33** ใน Script VM; harness คืน profile/flags/ตำแหน่ง. ไม่เปลี่ยน service/สูตร/รางวัล. Balance simulator ผ่าน (`python -X utf8`; รอบแรก console cp1252 พิมพ์ไทยไม่ได้). Config/Season ตรง Studio Edit 2257 bytes/hash31 522002800, ไม่มี error/test script ค้าง; ไม่ Publish. Shop/GUI/regression อื่นยังเป็นผลรอบเดิม.

## ตรวจเพิ่มซีซัน 3 — 2026-10-02

เพิ่ม check ห่วงโซ่ซีซัน (ทุกแถวเริ่มที่ endsAt ของแถวก่อน, ID ไม่ซ้ำ, ≥3 ซีซัน); "Season end" ใช้แถวสุดท้าย (s3) อัตโนมัติ. ผ่าน **34/34** ใน Script VM, console ไม่มี error, harness คืน profile/flags/ตำแหน่ง แล้วลบ Script ก่อน Stop. ไม่เปลี่ยน service/รางวัล. Config/Season ตรง Studio Edit 2412 bytes/hash31 466514145; ไม่ Publish.

## OpenTen / สิทธิ์ Pass — 2026-10-02

ใช้ Phase8ShopGUIHarness เดิม: แยก fixture 12 Rare chests, inventory ว่าง, OpenTen=true; Finish คืน profile/flags/anchor/ตำแหน่งและตรวจ Currencies/Inventory/Purchases/Boosts/Meta/Garden/Pets/Stats/Season ตรง snapshot ก่อน SaveNow.

- คลิกปุ่มจริง: 12→2 หีบ, 0→10 อาวุธ, Stats.ChestsOpened 0→10; Result แสดงรางวัล. คลิกอีกครั้งได้ 2 ใบที่เหลือ: 0 หีบ/12 อาวุธ/Stats 12. ผ่านก่อนและหลังแก้ UI.
- พบปุ่มค้างเมื่อถอน Pass ขณะกระเป๋าเปิด: Data.Changed ไม่ฟัง Purchases. Server ปฏิเสธและไม่เสียของอยู่แล้ว. แก้ InventoryController ฟัง `Purchases.passes` และ path ลูก; เพิ่ม/ถอนสิทธิ์ทั้งแบบ whole/nested patch อัปเดตปุ่มทันทีโดยไม่ปิดเปิดกระเป๋า.
- Client InvokeServer OpenTen โดยไม่มี Pass ถูกปฏิเสธ; หีบ/อาวุธ/Stats เท่าเดิม. Shop scenario รันซ้ำผ่าน 34/34; startup Balance 9 checks ผ่าน, console ไม่มี error.
- Finish ตรวจคืนข้อมูลผ่านทั้งสองรอบ; ลบ Script ชั่วคราวก่อน Stop. InventoryController ตรง Studio Edit 14778 bytes/hash31 593705462. Docs คง 8 ไฟล์; ไม่ Publish.

### Capacity — 2026-10-02

ShopGUIHarness.SetFreeSlots เตรียมอาวุธตาม MaxWeapons จริง/หีบ 12 ใบ; คลิก OpenTen ใน Play:

| ช่องว่าง | อาวุธหลังคลิก | หีบเหลือ | Stats.ChestsOpened | ผล |
|---|---:|---:|---:|---|
| 0 | 300 | 12 | 0 | ปฏิเสธพร้อมข้อความกระเป๋าเต็ม; Result ไม่เปิด |
| 1 | 300 | 11 | 1 | ได้ 1 ชิ้น; Result แสดงรางวัล |
| 3 | 300 | 9 | 3 | ได้ 3 ชิ้น; ไม่เกินเพดาน |

กดซ้ำหลังรอบเหลือ 1 ช่อง: อาวุธ/หีบ/Stats คงเดิม. Restore ผ่านทุกหมวดที่ harness ตรวจ; startup Balance 9 checks, console ไม่มี error, ลบ script ก่อน Stop กลับ Edit. ไม่แก้ gameplay/สูตร และไม่ Publish.

ยังไม่พิสูจน์ mobile/gamepad และหลายบัญชีจริง; regression/persistence ตรวจเพิ่มด้านล่าง.

## Regression Run / อาวุธ — 2026-10-02

Phase2Scenario **23/23**: manual/Auto Cut 55%, สลับโหมดไม่เพิ่มรางวัล, cap หีบ 50, End ไม่จ่ายซ้ำ, contributor อายุ 10 วินาที, respawn 15 วินาที, Auto Cut pathfinding เดิน 19 studs และฟันจริง. Phase3Scenario **36/36**: 20K seeded loot, ownership/altar/flag, fuse/delete, Giant/IL/Rot, พลัง/พื้นที่/cooldown. ทั้งสองรันใน Script VM หลังร้าน; gameplay ไม่เปลี่ยน.

ปรับ scenario เดิมให้ปิด autosave/leaderboard และระบบ tick ที่ไม่เกี่ยวข้อง; Run ใช้ baseline ไม่มี Pass/boost แล้วคืน flags/Balance/profile. รอบแรกตรวจ restore พบเฉพาะ Pets.bankAt: Import เรียก Pet.Advance deferred แม้ปิด Eggs. Harness รอ handler แล้วคืน Pets snapshot; รันซ้ำผ่านและ restore Currencies/Inventory/Purchases/Boosts/Pets/Garden/Stats/Season/Progress ตรง snapshot ทั้งสองชุดก่อนเซฟ. Console ไม่มี error; ลบ test scripts แล้วกลับ Edit. งานที่ค้างตรวจเพิ่มด้านล่าง; ไม่ Publish.

## Regression 4–7 / 8a–f — 2026-10-02

ใช้ scenario เดิมครอบด้วย RegressionHarness.Prepare/Finish: แยก Pass/boost/Index/skills จากบัญชีจริง, ปิด autosave/leaderboard/SeasonPass/FriendBoost, คืน profile/flags/weather/Balance/pivot/anchor/server Luck ทุกชุด แม้ fail. Restore 9 หมวดเดียวกับชุด Run ผ่านทุกครั้ง.

| ชุด | Checks ผ่าน |
|---|---:|
| 4 Garden | 55 |
| 5 Pets/Stealing | 80 |
| 6 Story | 51 |
| 7 Zones | 23 |
| 8a Rebirth | 41 |
| 8b Rewards | 45 |
| 8c Collections | 55 |
| 8d1 Weather/Live Events | 38 |
| 8d2 Encounters | 59 |
| 8d3 Merchant | 30 |
| 8e Festivals | 15 |
| 8f Emote | 5 |

Phase 5 มี conditional checks ตามไข่ในหน้าต่างสายพาน จึงไม่ยึด count เดิม 81. 8c รอบแรก fail ข้อ Luck clamp เดิม 25%; แก้ assertion เป็น Epic+ .075 ที่ cap รวม 50% ตามร้าน (เพดานถาวรยัง 25%) ไม่แก้ Loot.

8e พบ bug จริง: festivalAt(future) ล้าง preview ปัจจุบันเมื่อตรวจ forecast เกิน endsAt. Probe Before=true/After=false พิสูจน์ก่อนแก้; WeatherService เปลี่ยนให้ expire ตาม os.time() จริง และใช้เวลาที่ query เฉพาะเลือกผล. เพิ่ม check future forecast ไม่ล้าง preview; 8e ผ่านและ 8d1/d2 รันซ้ำผ่าน 38/59. Source ตรง Studio 3549 bytes/hash31 1672120537. MCP Start ค้างหลัง Stop; เริ่ม Play ด้วยปุ่ม native Studio แล้วทดสอบต่อ ไม่มี Publish.

## Receipt / save / reconnect บัญชีจริง — 2026-10-02

ArmZKubfu (`7488194538`), Studio ใช้ PlayerData_v1 / Player_7488194538, ProfileStore state **Access**. Synthetic receipt `codex-reconnect-*` สำหรับ product 100 Gems `3715863360`: seam SaveAndWait คืน false สองครั้ง ทำให้ NotProcessedYet ทั้งคู่ แต่ยอดเพิ่มเพียง 100 ครั้งเดียว. คืน seam แล้ว retry เป็น Granted หลัง LastSavedData มี marker.

Stop/Play ใหม่เป็น session จริง: โหลด Gems 321 จากเดิม 221 และ marker เดิม; ProcessReceipt replay เป็น Granted โดยไม่เพิ่มยอด. Import snapshot เดิมและลบเฉพาะผล synthetic ด้วย snapshot; SaveAndWait ยืนยัน Gems 221 และไม่มี marker ก่อนจบ. ไม่ overwrite ProfileStore และไม่จ่าย Robux. การซื้อผ่าน UI จริง/production-server reconnect ยังต้องตรวจ; Roblox Player เดิมเปิดเกมอื่น รอจัด session โดยผู้ใช้. [Roblox developer product docs](https://create.roblox.com/docs/production/monetization/developer-products) แยกการซื้อผ่าน Roblox ออกจากการเรียก receipt ใน harness.

ยืนยันซ้ำด้วย `tools/tests/ReceiptPersistenceScenario.server.luau`: Save/Replay ผ่านบน Access ทั้งคู่; คืน snapshot และยืนยันเซฟ Gems 221/ไม่มี synthetic markers. Studio กลับ Edit ไม่มี Codex test scripts; WeatherService checksum ตรง repo.
