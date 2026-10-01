# Phase 7 — โซน 3–8 (core)

ทำต่อจากรอบที่หยุดเพราะ session limit วันที่ 2026-10-01 ใน Studio PlaceId `93479990217075`. ไม่ได้ Publish place. แผน/skill/handoff อัปเดตพร้อมกัน.

## สิ่งที่ทำแล้ว

1. `Config.Zones` ตั้ง built=true ครบ 8 โซน; MapBuilder สร้างต้นไม้ฟันได้ 160 ต้น/โซน (รวม 1,280). โซน 3–8 ใช้ Look จาก Creator Store บน Trunk โปร่งใสที่เป็น PrimaryPart/collider; ภาพไม่ชน ไม่รับ raycast และซ่อน/กลับมาเมื่อฟัน/เกิดใหม่ได้.
2. `AssetPrototypes.Sources` ระบุ asset ID/ผู้สร้าง/การปรับสีและขนาด; Build คัดลอกเฉพาะ geometry/appearance ตัด script และองค์ประกอบอื่นออก. ต้นแบบ 8 แบบอยู่ใน ServerStorage.MapAssets.Trees; map ไม่มี script จาก asset. โซน 3 เห็ด 2 แบบ, โซน 4 ซากุระ, โซน 5 ไผ่, โซน 6 ต้นหิมะ 2 แบบ, โซน 7 คริสตัล, โซน 8 ต้นสีทอง/ขาว.
3. ไข่รวม 10 ชนิด, สัตว์ 42 ตัว. เพิ่ม Spore/Petal/Thunder/Frost/Crystal/Celestial Egg และสัตว์ 5 ตัวต่อโซน 3–8 (Common/Rare/Epic/Legendary/Mythic, weights 45/35/15/4.5/0.5). ไข่ใหม่มาจากรังและหีบ (`belt=0`); สายพานยังแสดงเฉพาะชุดเดิม. เวลาฟัก 600/900/1200/1800/2400/3600 วินาที เป็นค่าตั้งต้น.
4. รัง 16 แห่ง มี 48 จุดไข่ และบอสผู้พิทักษ์ครบ 8 โซน. บท 3–8/ศาลเจ้า/ประตู/วาร์ปใช้ระบบ Phase 6 เดิมเมื่อโซน built=true. บอสโซน 8 อยู่ด้านข้าง Lumora.
5. ZoneAmbience ตรวจ footprint เหมือน RunService.ZoneAt: หิ่งห้อย/กลีบซากุระ/ฝนเบา/หิมะ/ประกายคริสตัล/ละอองทอง. เป็น particle ฝั่ง client ไม่แก้ Lighting หรือ mutation. ภาพโซนอยู่ใน `screens/phase7_zone3.jpg` ถึง `phase7_zone8.jpg` (ภาพรวมจากรอบก่อนแก้ตำแหน่งบอส).
6. แก้บอสขวางทางเดิน: MapBuilder เก็บ `BossArena.GuardianOffset` เป็นการเลื่อน 26 studs ไปด้านที่ห่างจากแนวทางเดิน; BossService ใช้ offset นี้. ใส่ attribute แบบเดียวกันให้ arenas ใน Studio Edit โดยไม่สร้างแมพทับฐาน. โซน 8 เลื่อน +X ข้าง Lumora.

## ผลตรวจ

1. รอบก่อนหยุดมี Phase 7 ผ่าน 23/23, regression Phase 6 ผ่าน 51/51 และ Phase 5 ผ่าน 81/81. ดึงหลักฐานจาก workspace attributes ของ Play ที่ยังเปิดอยู่ก่อนแก้บอส; เก็บ regression เดิมใน `phase5_phase7_regression_results.json`. Phase 7 รอบแรกเคยล้มที่การฆ่าบอสโซน 3; ทดสอบแยกและรันซ้ำผ่าน สาเหตุยังไม่ยืนยัน (สงสัย character settling หลัง teleport).
2. ตรวจเส้นทางเพิ่มก่อนแก้: raycast ใน Play พบ 14 ปัญหาจาก Trunk/Root ของบอสโซน 1/2/5/6; เดินจริงโซน 3/4 ผ่าน แต่โซน 5 ติดราก. ปรับ offset ครั้งแรกเหลือปัญหารากโซน 3 หนึ่งจุด; แก้ให้เลือกด้านเดียวกับตำแหน่งลานเดิมที่ห่างจากเส้นทาง.
3. หลังแก้สุดท้าย `tools/map/ValidateRoutes.luau` ใน Play ผ่าน **2,048 จุด ไม่มีปัญหา** รวมตัวบอสที่เกิด runtime. Phase 7 รันซ้ำผ่าน **23/23**; ผลสุดท้ายใน `phase7_test_results.json`. ชุดเทสต์ใช้ Script ใน VM เกมจริงและ snapshot/restore profile.
4. Regression Phase 6 หลังแก้ผ่าน **51/51** (`phase6_phase7_regression_results.json`). รอบแรกผ่าน 16 ข้อแล้วล้มตอนฆ่าบอสโซน 1; เพิ่มเหตุผล Bo.Hit/ตำแหน่งในข้อความ assertion แล้วรันซ้ำผ่าน โดยไม่ได้แก้ gameplay เพื่อให้ผ่าน. สาเหตุของความไม่สม่ำเสมอนี้ยังไม่ยืนยัน.
5. โค้ดที่เพิ่ม/แก้ของ Phase 7 **8 ไฟล์** checksum ตรง repo/Studio ตาม `phase7_source_checksums.json` (LF UTF-8). ไม่แตะ ProfileStore.
6. `python -X utf8 tools/balance_sim.py` รันสำเร็จ; สูตรบอสทุกโซนยังอยู่ที่ประมาณ 100 วินาทีสำหรับอาวุธ Epic ★1 เลเวลรอบ 30. ใช้ UTF-8 เพราะ terminal Python ค่าเริ่มต้น cp1252 พิมพ์ภาษาไทยไม่ได้.
7. เดินจริงหลังแก้บอสผ่าน **16/16 เส้นทาง**: ทางเชื่อม 8 เส้น (WalkSpeed 16, รากขึ้นฟ้า 80) และทางในโซน 8 เส้น (40). ใช้ PreparePlayRoutes/PlayRoutes เดิมและ harness ชั่วคราวที่ snapshot profile→ปลดโซนเพื่อเดินทดสอบ→คืน profile; คืนตำแหน่ง/WalkSpeed ด้วย. รอบแรกของการเดินรวมติดประตูโซน 2 เพราะ client คืน collision ตาม Progress.UnlockedZones (ไม่ใช่พื้นทางเสีย); รอบสุดท้ายปลดโซนด้วย DataService ใน VM เกมจริง. หลักฐานใน `phase7_route_results.json`.

## การสร้างซ้ำและข้อจำกัด

1. เก็บ MapAssets และ MapTools ใน place เมื่อ Save. จาก place ใหม่ให้โหลด asset ตาม `tools/map/AssetPrototypes.luau` ไป ServerStorage.AssetStaging (script ไม่รันใน ServerStorage), ตรวจแล้วเรียก Build/Report ให้ scripts=0 ก่อนสร้างแมพ. Repo เก็บวิธีสร้างและ IDs; ไม่ได้เก็บไฟล์ geometry ของ Creator Store. ถ้าไม่มีต้นแบบ MapBuilder fallback เป็นต้นไม้ Part.
2. โซนและวงจร core ใช้งานได้; บท 3–8 ยังเป็นแม่แบบเข้าโซน→ฟัน 40 ต้น→ล้มบอส→จุดศาลเจ้า. ยังไม่มี NPC พ่อค้ากระรอก/นักวิจัย/สำนักดาบ, บทพูดเฉพาะบท, บอสโจมตีกลับหรือคัตซีนกล้อง. ทดสอบบท 3 บางขั้นและบอสโซน 3/ไข่โซน 6; ยังไม่ได้เล่นเส้นเรื่องครบ 8 บทจากเซฟใหม่.
3. ภาพสัตว์/บอส/Lumora, เสียงและ particle ใช้แบบพื้นฐาน; ขัดเกลา Phase 10. ยังไม่ได้ตรวจ performance/streaming บนอุปกรณ์จริง, มือถือ/gamepad, หลายบัญชีตีบอสร่วมกัน และหลายเซิร์ฟเวอร์.
4. ค้างจาก Phase 5–6: ตกแต่งฐาน/กับดัก/สัตว์เฝ้าฐาน, ขโมยสองบัญชีจริง, GardenController รีเฟรชปุ่ม. Phase 8 เริ่ม Rebirth และระบบระยะยาวตาม plan; บัฟ Index/Achievements และระบบเติมเงินยังไม่ทำ.
