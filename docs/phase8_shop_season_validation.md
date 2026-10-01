# Phase 8g — ร้าน Robux + Season Pass

ทดสอบ 2026-10-02 (เวลาไทย), Studio PlaceId `93479990217075`. ร้าน **34/34**, Season Pass **29/29**, เปิดหน้าจริงใน Play แล้ว; ยังไม่ได้ Publish.

## ร้าน Robux (commit `89ee78b`)

1. `Config/Products.luau` (shared): 10 Game Pass + 17 Developer Product ใช้ ID จริง ตรวจด้วย `GetProductInfo` แล้ว. ราคาอยู่บน Roblox; UI อ่านราคาสดด้วย `GetProductInfo` (รองรับ Managed Pricing).
2. `MonetizationService`: สิทธิ์ Pass เก็บใน `Purchases.passes` (ตรวจ `UserOwnsGamePassAsync` ตอนเข้าเกม + `PromptGamePassPurchaseFinished`). Developer Product ให้ของเฉพาะใน `ProcessReceipt` ครั้งเดียวต่อ `PurchaseId` (`Purchases.receipts`, เก็บ 90 วัน) และตอบ `PurchaseGranted` หลัง `SaveAndWait` เห็น receipt ในข้อมูลที่เซฟแล้วเท่านั้น. `Grant` ห้าม yield.
3. สินค้าที่ใช้ไม่ได้ตอนนี้ (ฟักทันทีไม่มีไข่, โตทันทีไม่มีต้น, ฐานล็อกอยู่แล้ว) ถูกปฏิเสธก่อนเปิดหน้าซื้อ (`READY`).
4. Pass ไม่ซ้อนกับทางฟรี: ×2 Wood/Coins = เพดานถาวรเดิม, Lucky +25% (ยา/Luck ทั้งเซิร์ฟเพิ่มชั่วคราวได้ถึง +50%), ช่องสัตว์ +2 (สูงสุด 6), ฟักไว ×2 = ตู้ฟักเลเวลสูงสุด, แปลง +10 (สูงสุด 30).
5. Client `ShopController` ปุ่ม "ร้าน Robux" (200,365) แท็บ Game Pass/ไอเทม; เปิดหีบ 10 ใบใน InventoryController เมื่อมี OpenTen; VIP แท็กแชท/ฉายา/Daily +25 Gems.
6. Admin แท็บ shop: สลับ Pass, ให้สินค้า, ยกเลิก Luck ทั้งเซิร์ฟ. Flag `Shop`.
7. ผล `phase8_shop_test_results.json` 34/34 + GUI (เปิดร้าน, ราคา 17 รายการ, กดซื้อเปิด prompt). ค้าง: ยังไม่ได้คลิกปุ่มเปิด 10 ใบจริง และยังไม่ได้รัน regression ชุดเก่าทั้งหมดหลังร้าน.

## Season Pass (commit `4d3ba3e`)

1. `Config/Season.luau`: ซีซัน 1 "ป่าแรกผลิ" `s1_2026_10` 2026-10-01 → 2026-11-01 UTC, 30 เลเวล × 1,000 XP. รางวัลฟรี + Premium ทุกเลเวลเป็น Gems/ยาบูสต์/หีบ (Premium หีบไม่เกิน Legendary = ไม่ P2W). คอสเมติก Exclusive ยังไม่มี: ArmZ เลือก **ยังไม่ทำระบบคอสเมติก** (plan 17.5).
2. XP มาจาก Stats delta (`DataService.Changed`, deferred): ฟันต้นไม้ 10 (Auto Cut 5), ปลูก/เก็บผล 15, ฟักไข่ 40, เปิดหีบ 10, บอส/บอสโลก 150. Flag ปิด = ไม่ได้ XP.
3. `SeasonService`: claim ทีละเลเวล / รับทั้งหมด, ledger `Season.free`/`Season.prem`. Profile `Season={id,xp,premium,free,prem,pendingFor}`; id ซีซันเปลี่ยน → รีเซ็ต XP/Premium/claim (รางวัลค้างหาย) ยกเว้น `pendingFor`.
4. Premium (product `3715870274`, 499 R$): ซื้อผ่าน `ShopAction Prompt seasonPremium` → `CanBuy` (ต้องมีซีซัน, ยังไม่มี Premium) → บันทึก `pendingFor` = ซีซันที่ขาย → `ProcessReceipt` → `GrantPremium` ปลดเฉพาะซีซันนั้น. ถ้าปลดไม่ได้ (มีแล้ว/ซีซันที่ซื้อจบแล้ว) ได้ `PremiumFallbackGems` 4,500 Gems แทน. Receipt ซ้ำไม่จ่ายซ้ำ (ledger เดียวกับร้าน).
5. Client `SeasonController` ปุ่มม่วง "Season Pass" (200,425): ชื่อซีซัน, เลเวล/XP/วันที่เหลือ, ปุ่มรับทั้งหมด, ปุ่มซื้อ Premium (ราคาสด), 30 แถวฟรี/Premium.
6. Admin แท็บ shop: `season.xp` (+1 เลเวล), `season.premium` (สลับ), `season.reset`. Flag `SeasonPass`. Remote `SeasonAction` (Sync/Claim/ClaimAll). Schema เติม `Season` ผ่าน Reconcile ไม่ต้อง migrate.
7. ผล `phase8_season_test_results.json` 29/29, regression ร้าน 34/34, GUI เปิดหน้าถูกต้อง, console ไม่มี error, source 11/11 ตรง Studio Edit. รอบแรกล้มข้อ 6 เพราะเทสอ่าน XP ก่อน handler deferred ทำงาน; แก้ที่เทส (`task.wait()`), service ไม่เปลี่ยน.

## ข้อจำกัด / ต้องทำต่อ

1. หน้าซื้อ Robux จริงเป็น CoreGui คลิกด้วยเครื่องมือไม่ได้ → receipt ทดสอบผ่าน `ProcessReceipt` โดยตรง. ArmZ ทดสอบเองในเกมแล้วว่าผ่าน.
2. **ต้องเพิ่มซีซัน 2 ใน `Seasons` ก่อน 2026-11-01 UTC** ไม่งั้นไม่มีซีซันให้เล่น/ขาย.
3. ค่า XP/รางวัล/ชื่อซีซัน/4,500 Gems เป็นค่าเริ่มต้น Beta ยังไม่ผ่านข้อมูลผู้เล่นจริง.
4. ปุ่ม Season Pass ชิดกล่องเควสด้านล่าง; จัด HUD ใหม่ใน Phase 10.
5. ยังไม่ได้ Publish.
