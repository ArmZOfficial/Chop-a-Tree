# Chop a Tree — HANDOFF

อัปเดต 2026-10-02 (ไทย). เริ่มอ่านไฟล์นี้ → [plan](plan.md) → [INDEX](INDEX.md) เฉพาะงาน. กฎทำงาน: [SKILL](../SKILL.md).

## สถานะล่าสุด

- **Phase 8g ร้าน Robux + Season Pass ทำและทดสอบแล้ว; ยังไม่ Publish.** ไม่สรุปว่าเกม/ทุก Phase พร้อมเปิดจริง.
- Shop: 10 Pass + 17 Developer Products ID จริงใน `src/shared/Config/Products.luau`; เปิด flag Shop/SeasonPass, PvP ปิด. ราคา UI อ่านสดจาก Roblox.
- Shop **34/34** รันซ้ำผ่าน, Season **33/33** (รอบเพิ่มซีซัน 2). OpenTen คลิกจริงผ่าน 10 ใบ + 2 ใบที่เหลือ; ไม่มี Pass server ปฏิเสธโดยไม่เสียของ. Inventory แก้ refresh เมื่อสิทธิ์ Pass เปลี่ยนขณะเปิดอยู่; whole/nested patch เพิ่ม/ถอนปุ่มผ่าน. หลักฐาน/ข้อจำกัด: [Phase 8g](phase8_shop_season_validation.md). Regression ชุดเก่าทั้งหมดยังไม่ได้รันหลังร้าน.
- Premium ID **3715870274**, ราคาฐาน **499 Robux**. ผู้ใช้รายงานซื้อจริงผ่าน; automation ตรวจ ProcessReceipt โดยตรง ไม่ได้คลิกยืนยันจ่าย Robux.
- ซีซัน `s1_2026_10`: 2026-10-01 ถึง 11-01 UTC; `s2_2026_11` ป่าแสงจันทร์: 11-01 ถึง 12-01 UTC ต่อกันอัตโนมัติ. ใช้รางวัลเดิม 30 เลเวล × 1,000 XP. Pending purchase ผูกซีซัน; มี Premium แล้ว/ซีซันจบ → fallback 4,500 Gems. ค่า XP/รางวัล/fallback ยังเป็น Beta.
- **คอสเมติก: ArmZ ให้รอก่อน.** Premium ปัจจุบันเป็น Gems/บูสต์/หีบ ไม่ใช่ระบบสกินที่เสร็จแล้ว.
- ล่าสุดแก้ InventoryController จุดเดียว + ขยาย ShopGUIHarness เดิม; snapshot/restore ผ่าน รวม Stats/Season. Source ตรง Studio 14778 bytes/hash31 593705462; console ไม่มี error, Edit ไม่มี test script ค้าง. ไม่ Publish. ponytail full + caveman full; docs ยัง 8 ไฟล์.

## งานถัดไป / ค้าง

1. ซีซัน 2 พร้อมแล้ว; เพิ่มแถวซีซัน 3 ID ใหม่ **ก่อน 2026-12-01 UTC** มิฉะนั้นไม่มีซีซันให้เล่น/ขายหลังนั้น.
2. ตรวจร้านหลังรวมระบบ: regression ชุดเก่าที่เหลือ, ซื้อ/receipt/reconnect/failed-save กับบัญชีและอุปกรณ์จริง; OpenTen inventory เต็ม/เหลือช่องน้อยยังไม่ได้คลิกตรวจ.
3. งานเดิมค้าง: NPC/บทพูด/คัตซีนบท 3–8, ตกแต่งฐาน/กับดัก/สัตว์เฝ้า, GardenController refresh ไม่สร้างปุ่มใหม่. ยืนยันกับโค้ดก่อนแก้.
4. Multi-account ขโมย/บอสร่วม, multi-server Live Events/world boss, mobile/gamepad ยังไม่พิสูจน์ครบ. Balance/เสียง/VFX/UI polish Phase 10.
5. Phase 9 PvP ยังไม่เริ่ม; คอสเมติกเมื่อ ArmZ สั่ง; Publish เมื่อผู้ใช้สั่ง.

## ข้อมูลต่อระบบที่ต้องรู้

- MonetizationService owns receipt ledger; `Grant` ไม่ yield; Granted หลัง SaveAndWait. SeasonService owns XP/claim/Premium; Changed deferred → เทสต้องรอ.
- ซีซันเปลี่ยนรีเซ็ต XP/Premium/claim; pendingFor คงไว้. รับรางวัลค้างก่อนซีซันจบ; อ่าน Phase 8g ก่อนแก้ edge cases.
- Admin shop: Pass/product/server Luck + `season.xp/premium/reset`. เพิ่มคำสั่งทดสอบตามระบบ.
- Source repo ตรง Studio ตามผลตรวจล่าสุดของแต่ละงาน; ก่อนเขียนเรียก list Studios, ตรวจ PlaceId `93479990217075`. Studio ID ไม่ใช่ค่าถาวร.
- ยังไม่ใช้ Rojo; sync MCP multi_edit + checksum `h=(h*31+byte)%2147483647`. ทดสอบผ่าน Script VM ไม่ require live service จาก MCP; คืน state ก่อน Stop.

## ผลตรวจเดิม (อ่านรายละเอียดเมื่อแก้ระบบนั้น)

Phase 2/3/4/5/6/7: **23/36/55/81/51/23**. Phase 8a/b/c/d1/d2/d3/e/f: **41/45/55/38/59/30/15/5**.
เป็นผลเฉพาะรอบเดิม ไม่ใช่ regression ล่าสุดหลังร้าน. ลิงก์ใน [INDEX](INDEX.md).

## เอกสารและ asset

- [plan](plan.md): design ย่อ/backlog. [INDEX](INDEX.md): validation/สูตร/spec ที่ต้องอ่านตามงาน.
- `assets/monetization/`: Pass 10, Developer Product 17, Season Premium; PNG 512×512 + EN/TH copy + ZIP. ID ที่ใช้จริงดู Config/Products; asset JSON เก่าอาจยังไม่มี ID.
- [systems](systems.md) รวมข้อควรรู้; [design](design.md) spec รายละเอียด. Snapshot/หลักฐานเก่าเรียก Git 5d09e37 เฉพาะสืบประวัติ.
