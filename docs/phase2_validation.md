# Phase 2 — ฟันต้นไม้ + Run

ตรวจใน Roblox Studio Play เมื่อ 2026-10-01, PlaceId 93479990217075.

## ระบบที่ใช้งานได้

1. ผ่าน ForestGate เริ่ม Run เลเวล 1 และได้รับขวานเริ่มต้น Power 125; ฟันด้วย Tool, E หรือปุ่ม CHOP.
2. Server ตรวจต้นไม้ ระยะ 14 studs, สิ่งกีดขวาง, โซนที่ปลดล็อก, Power และคูลดาวน์ 1 วินาที. HP เป็นสัดส่วนกลางเพื่อรองรับ Rebirth ต่างกัน.
3. ผู้ร่วมฟันใน 10 วินาทีก่อนต้นล้มได้รับรางวัลเต็มตามสูตรของตน. เกิดต้นไม้ใหม่ 15 วินาทีและเร็วขึ้นเมื่อโซนมีผู้เล่นมากกว่า 3 คน.
4. Auto Attack ยืนฟัน; Auto Cut ใช้ Pathfinding เฉพาะโซนปัจจุบัน เลี่ยงรัง/ลานบอส ให้ EXP/Wood/Coins 55%. กดเดิน/กระโดดเองหยุด Auto Cut. การสลับโหมดก่อนฟันจังหวะสุดท้ายไม่ล้างส่วนลด.
5. เก็บหีบเมื่อเคลียร์ต้นไม้รอบ ChestSpot, ซ้อนตาม Common/LEVEL/zone, สูงสุด 50 ใบต่อ Run. การเปิดหีบ/สุ่มอาวุธเป็น Phase 3.
6. End Run โอน Wood/Coins/หีบเข้าข้อมูลถาวรครั้งเดียวและกลับหมู่บ้าน. ตายหรือออกเซิร์ฟ settle Run; โหลดข้อมูลที่มี Run ค้างก็ settle ครั้งเดียว.
7. Run HUD, EXP bar, HP bar, floating damage/critical, animation ขวาน, ปุ่มชวนเพื่อน. Friend Boost คำนวณเพื่อนในเซิร์ฟทุก 5 วินาทีตามสูตรเดิม.
8. Admin แท็บ forest และ balance: เริ่ม/จบ Run, เลเวล 50, Power 10K/คืนสูตร, toggles, reset trees, hit, clear zone, stats และ temporary Balance overrides.

## ผลทดสอบ

`tools/tests/Phase2Scenario.server.luau` ผ่าน **23/23 checks** ใน Script ที่รันโดยเกมจริง. ครอบคลุมเริ่ม Run ซ้ำ, รางวัล manual/Auto Cut, cooldown, target ปลอม/ระยะไกล, สลับโหมด, cap/stack หีบ, payout ครั้งเดียว, ผู้ร่วมฟันและหมดอายุ, respawn, Pathfinding (เดิน 19 studs แล้วฟันต้นไม้) และ Balance SelfTest 8 สูตร.

ทดสอบปุ่ม GUI ด้วย mouse/keyboard จริง: ForestGate เริ่ม Run, Auto Attack ON, Auto Cut ON ปิด Auto Attack, W ปิด Auto Cut, End Run แสดง Summary และกลับ VillageSpawn (ระยะ 4.19 studs). CHOP และ E ลด HP จริงจากสัดส่วน 1 → 0.865 → 0.73. ย้าย CHOP ขึ้น 105px จากขอบล่างเพื่อไม่ชน CoreGUI hotbar. Console ไม่มี error ในรอบสุดท้าย. รูป UI: `screens/phase2_run_hud.jpg`.

ตัวทดสอบใช้ snapshot และคืนข้อมูลผู้เล่นก่อนจบ. API services เปิดอยู่และ ProfileStore เซฟจริง; ห้ามหยุด Play กลาง scenario. กรณี test ล้มก่อน cleanup อ่าน OriginalData attribute บน Script เพื่อคืนข้อมูล.

MCP execute_luau ใช้ require cache แยกจาก Script ในเกม: อย่า require DataService จาก MCP เพื่ออ่าน live profile หรือทดสอบ payout. ใส่ Script ชั่วคราวใน Play แล้วอ่าน workspace attributes ของผลลัพธ์. Net ปรับให้ reuse Remotes เดิมเมื่อ require ซ้ำ.

## ขอบเขตและสิ่งที่ยังต้องพิสูจน์

1. Phase 2 core ทำแล้ว; **การ AFK ไม่จำกัดเวลายังไม่เสร็จ**. [Roblox Player.Idled](https://create.roblox.com/docs/reference/engine/classes/Player#Idled) ระบุการ disconnect เมื่อ idle อย่างน้อย 20 นาที. ยังไม่ใช้ VirtualUser หรือรับรอง bypass; Run settle เมื่อออกช่วยเก็บรางวัลที่สะสมไว้ตาม lifecycle ปกติ.
2. โล่ AFK หลัง 10 นาทีต้องต่อกับระบบฐานใน Phase 5; ยังไม่มี shield จริงในเกม.
3. เพื่อนหลายบัญชี, mobile touch/gamepad, Rebirth ต่างกัน, Death/PlayerRemoving และ crash recovery ยังไม่ได้ทดสอบ end-to-end ในเซิร์ฟเผยแพร่. Cooperative scenario ใช้ contributor จำลองผ่าน service จริง.
4. อาวุธเริ่มต้น fixed Power 125; Weapon equip/roll, rarity หีบ, seed drops และเสียง/VFX เต็มอยู่ใน Phase ถัดไป.
5. ยังไม่ Publish place. โค้ดใน Studio Edit ตรงกับ repo และไม่แตะ ProfileStore เวอร์ชัน Creator Store.

## Creator Store asset

ขวานภาพจาก asset **108477167298944**, “Cave Axe! Low Poly Forest Climb Waterfall Christma”, creator **JosephVenomSpark2625**. ค้น/import ใน ServerStorage.AssetReview ก่อนตรวจ.

พบ scripts `qPerfectionWeld` และโครงซ่อน asset ID/PackageLink ที่ไม่จำเป็นกับภาพขวาน จึงทิ้งโมเดลที่ import ทั้งหมด. Runtime สร้าง Tool เองจาก Part + SpecialMesh เท่านั้น: mesh `145815658`, texture `235687506`, size (0.2,3.2,1), scale (1,0.7,0.7). ค่าซ้ำได้อยู่ `src/shared/Config/Forest.luau`; ไม่มี scripts เดิมของ asset ในเกม.
