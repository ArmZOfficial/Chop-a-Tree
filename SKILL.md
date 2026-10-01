---
name: chop-a-tree-assets
description: Maintain the Chop a Tree plan, skill, and handoff together when updating project work; choose and integrate Roblox Creator Store assets for its map, visuals, or gameplay systems.
---

# Creator Store สำหรับ Chop a Tree

## การอัปเดตเอกสารโปรเจกต์

ทุกครั้งที่อัปเดตงาน ให้ปรับทั้ง `docs/plan.md`, `SKILL.md` และ `docs/HANDOFF.md` ในงานเดียวกันให้สอดคล้องกับข้อมูลล่าสุด: plan บันทึกแผนและสถานะ, skill บันทึกแนวทางทำงานและข้อกำหนด, handoff บันทึกงานที่ทำแล้ว ผลตรวจ และงานถัดไป ตรวจทั้งสามไฟล์ให้ตรงกันก่อนสรุปว่างานเสร็จ (ArmZ สั่งเมื่อ 2026-10-01).

## แนวทางต่อระบบอาวุธและ UI

1. อ่าน `docs/phase3_validation.md` ก่อนแก้ inventory/หีบ/อาวุธ. ให้ WeaponService เป็นเจ้าของการสุ่ม สวมใส่ หลอม และทิ้ง; ใช้ Loot + Balance คำนวณ Power และอัตราดรอปทั้ง UI/server จาก Config เดียวกัน.
2. เมื่อนำโมเดลอาวุธใหม่มาแทน procedural visuals ให้รองรับทั้ง Tool และ viewport preview; เก็บ Handle, WeaponId และ ForestAxe attributes, ขนาด Giant ×3 และไม่เปลี่ยน UID/definition ID ของของที่เซฟไว้.
3. ทดสอบเศรษฐกิจจาก Script ใน Play ที่ใช้ require cache เดียวกับเกม; snapshot/restore profile ทุกครั้ง เพราะ Studio เปิด DataStore จริง. อย่า require DataService ผ่าน MCP เพื่ออ่าน live state.
4. UI ที่อ้างไอเทมใหม่ต้องรองรับ DataPatch มาถึงหลัง RemoteFunction response. ตรวจปุ่ม modal ด้วย mouse จริง รวม ZIndex, การยืนยัน Fuse/Delete และการไม่ชน CoreGUI hotbar.
5. แยกงานภาพสุดท้ายไว้ใน Phase 10 ตามแผน: โมเดล/แสง/เสียง/VFX และปรับปรุง UI ทุกหน้าบนคอมพิวเตอร์/มือถือ. บันทึกข้อจำกัดของภาพปัจจุบันและสิ่งที่ยังไม่ได้ทดสอบให้ตรงกับ handoff.

## แนวทางที่ ArmZ อนุญาต

ArmZ อนุญาตเมื่อ 2026-10-01 ให้เลือกของจาก Creator Store ที่เห็นว่าเหมาะสมและช่วยให้งานง่ายขึ้น แล้วนำมาใช้ในโปรเจกต์ได้เลย ไม่ต้องถามอนุญาตซ้ำสำหรับการนำ asset ที่เข้าถึงได้มาใช้ตามงานที่สั่ง แนวทางนี้แทนข้อกำหนดเดิมที่ให้สร้างโมเดลทุกชิ้นจาก Part เอง

เลือกใช้โมเดล ต้นไม้ หิน อาคาร ของตกแต่ง วัสดุ เสียง แอนิเมชัน หรือโมดูลที่ช่วยลดงานและเข้ากับธีม fantasy anime / low-poly ของเกม ปรับสี ขนาด และรายละเอียดให้กลมกลืนกับแมพ รักษาชื่อ เรื่องราว และเอกลักษณ์ของ Chop a Tree

## วิธีนำมาใช้

1. อ่าน `docs/HANDOFF.md` และส่วนที่เกี่ยวข้องของ `docs/plan.md` เพื่อรู้ระบบและผังปัจจุบัน เลือก asset ที่แก้ความต้องการของงานนั้นได้จริง ถ้าไม่เหมาะให้ใช้ของเดิมหรือสร้างเอง
2. ตรวจชื่อ ผู้สร้าง ชนิด และ asset ID จากผลค้นหาก่อนใส่ใน Studio ตรวจ descendant และโค้ดของ asset ในพื้นที่พักที่ไม่รันสคริปต์ก่อนย้ายเข้าแมพ ใช้เฉพาะโค้ดที่เข้าใจและจำเป็นกับงานนั้น
3. ปรับ Anchored, collision, ขนาด และจำนวน Part ให้เหมาะกับการเดินและ Streaming ของเกม เก็บ tags/attributes และโครงที่ระบบใช้อยู่ เช่น Tree, Zone, Tier, ChestSpot และ PlayerBase เมื่อนำโมเดลใหม่มาแทนของเดิม
4. ทำให้สร้างแมพซ้ำได้: เก็บต้นแบบที่ตรวจแล้วใน ServerStorage และอ้างอิงจากตัวสร้างแมพเมื่อใช้กับแมพที่สร้างด้วย MapBuilder บันทึก asset ID, ผู้สร้าง, ตำแหน่งต้นแบบ และสิ่งที่ปรับในเอกสารของงาน
5. ทดสอบส่วนที่ asset กระทบใน Play และตรวจ Output; ถ้าเปลี่ยนพื้นที่เดินให้ตรวจเส้นทางด้วย `tools/map/ValidateRoutes.luau` อัปเดต HANDOFF และ commit/push ตามแนวทางโปรเจกต์

การอนุญาตนี้ครอบคลุมการเลือกและนำ asset มาใช้ในงาน ไม่ใช่การซื้อของด้วย Robux หรือการ Publish เกมจริงโดยอัตโนมัติ
