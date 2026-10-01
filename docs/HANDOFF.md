# Chop a Tree — HANDOFF

อัปเดต 2026-10-02 (ไทย). เริ่มอ่านไฟล์นี้ → [plan](plan.md) → [INDEX](INDEX.md) เฉพาะงาน. กฎทำงาน: [SKILL](../SKILL.md).

## สถานะล่าสุด

- **Phase 9a lobby ทำแล้ว**: พอร์ทัลเดิมเปิดหน้าคิว Duel/FFA/Timber Clash/Egg Heist; Ranked/Casual แยก, ตรวจ Run/ไข่/mount/ระยะ/ชีวิต, reserved-server transfer + failure/timeout recovery. Luau CLI 37 checks; Studio startup/คลิก GUI ผ่าน, source 7 ไฟล์ตรง repo; คืน flags/pivot/anchor แล้ว Studio Edit ไม่มี test scripts. Config Arena.PlaceId=0/PvP=false. Combat/สนาม/แรงก์/รางวัลยังไม่ทำ; ดู [Arena](systems.md#arena).
- Chop Arena ที่ผู้ใช้สร้าง `122495944523559` อยู่ GameId `10768915988` แต่เกมหลัก GameId `10768831527` จึงยังใช้ส่งกลุ่มไม่ได้. แจ้งให้ Publish to Roblox As → เลือกเกมหลัก → Add as a new place; ไม่แก้ Place ที่ผิด Universe.

- **Phase 8g ร้าน Robux + Season Pass ทำและทดสอบแล้ว; ยังไม่ Publish.** ไม่สรุปว่าเกม/ทุก Phase พร้อมเปิดจริง.
- Shop: 10 Pass + 17 Developer Products ID จริงใน `src/shared/Config/Products.luau`; เปิด flag Shop/SeasonPass, PvP ปิด. ราคา UI อ่านสดจาก Roblox.
- Shop **34/34**, Season **33/33** (รอบเพิ่มซีซัน 2). OpenTen คลิกจริง/Pass refresh/capacity ผ่าน. **Phase 4–7 และ 8a–f รันซ้ำหลังร้านครบ**; counts/ข้อจำกัด: [Phase 8g](phase8_shop_season_validation.md).
- Premium ID **3715870274**, ราคาฐาน **499 Robux**. ผู้ใช้รายงานซื้อจริงผ่าน; automation ตรวจ ProcessReceipt โดยตรง ไม่ได้คลิกยืนยันจ่าย Robux.
- ซีซัน `s1_2026_10`: 2026-10-01 ถึง 11-01 UTC; `s2_2026_11` ป่าแสงจันทร์: 11-01 ถึง 12-01 UTC ต่อกันอัตโนมัติ. ใช้รางวัลเดิม 30 เลเวล × 1,000 XP. Pending purchase ผูกซีซัน; มี Premium แล้ว/ซีซันจบ → fallback 4,500 Gems. ค่า XP/รางวัล/fallback ยังเป็น Beta.
- **คอสเมติก: ArmZ ให้รอก่อน.** Premium ปัจจุบันเป็น Gems/บูสต์/หีบ ไม่ใช่ระบบสกินที่เสร็จแล้ว.
- ล่าสุดแก้ WeatherService: forecast อนาคตไม่ล้าง festival preview ปัจจุบัน; 8e ผ่าน 15 checks รวม regression ใหม่ และ 8d1/d2 รันซ้ำ 38/59 ผ่าน. ปรับ test Luck เก่าให้ตรงเพดานรวม 50%. Source ตรง Studio 3549 bytes/hash31 1672120537. ใช้ RegressionHarness เดียว คืนข้อมูลผ่านทุกชุด. ยังไม่ Publish; ponytail full + caveman full; docs 8 ไฟล์.
- เซฟ/receipt/reconnect: บัญชี ArmZKubfu บน DataStore จริง (`Access`) ผ่าน; synthetic receipt จำลอง failed-save 2 ครั้ง/แจก 100 Gems ครั้งเดียว, reconnect เก็บยอด/marker และ replay ไม่จ่ายซ้ำ. ยืนยันซ้ำด้วย ReceiptPersistenceScenario Save/Replay. คืนยอด 221 Gems/ลบ synthetic markers และยืนยันเซฟแล้ว; Studio Edit ไม่มี test scripts. **ยังไม่ใช่การซื้อผ่านหน้าจ่าย Robux จริง**; Roblox Player ยังอยู่เกมอื่นมี Run ค้าง รอผู้ใช้เลือกจัด session.

## งานถัดไป / ค้าง

1. ซีซัน 2 พร้อมแล้ว; เพิ่มแถวซีซัน 3 ID ใหม่ **ก่อน 2026-12-01 UTC** มิฉะนั้นไม่มีซีซันให้เล่น/ขายหลังนั้น.
2. ซื้อผ่าน Roblox Player จริง + reconnect หลังซื้อ; server persistence/failed-save ผ่านแล้วใน Studio ด้วยบัญชีจริง. Regression 2–7/8a–f ครบ; ต้องแยกจาก multi-account/device proof.
3. งานเดิมค้าง: NPC/บทพูด/คัตซีนบท 3–8, ตกแต่งฐาน/กับดัก/สัตว์เฝ้า, GardenController refresh ไม่สร้างปุ่มใหม่. ยืนยันกับโค้ดก่อนแก้.
4. Multi-account ขโมย/บอสร่วม, multi-server Live Events/world boss, mobile/gamepad ยังไม่พิสูจน์ครบ. Balance/เสียง/VFX/UI polish Phase 10.
5. Phase 9 ถัดไป: Place Arena ใน Universe เดียวกัน, match server/combat 4 โหมด, Ranked/monthly ranks/tokens; คอสเมติกเมื่อ ArmZ สั่ง; Publish เมื่อผู้ใช้สั่ง.

## ข้อมูลต่อระบบที่ต้องรู้

- MonetizationService owns receipt ledger; `Grant` ไม่ yield; Granted หลัง SaveAndWait. SeasonService owns XP/claim/Premium; Changed deferred → เทสต้องรอ.
- ซีซันเปลี่ยนรีเซ็ต XP/Premium/claim; pendingFor คงไว้. รับรางวัลค้างก่อนซีซันจบ; อ่าน Phase 8g ก่อนแก้ edge cases.
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
