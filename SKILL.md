---
name: chop-a-tree-assets
description: Maintain the Chop a Tree plan, skill, and handoff together when updating project work; follow its gameplay-system seams (weapons, gardens, eggs, pets, stealing); choose and integrate Roblox Creator Store assets for its map, visuals, or gameplay systems.
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

## แนวทางต่อสวน อากาศ และ Phase 5

1. Phase 4 core ผ่าน 55 checks; อ่าน `docs/phase4_validation.md` ก่อนต่อไข่/สัตว์/ฐาน. GardenService จัด OwnerUserId/BaseIndex ของ 7 ฐานและสร้าง GardenSlots runtime 30 ช่อง; ใช้ ownership นี้ต่อ ไม่สร้างเจ้าของฐานอีกชุด.
2. สวนใช้ seed UID/source zone/Rot/admin และ timestamp ใน profile. รักษา offline growth แบบปกติ, ไม่มี mutation offline และไม่สะสม harvest หลายรอบย้อนหลัง. Inventory.Seeds/Fruits กับ Garden เพิ่มด้วย Reconcile v1 โดยไม่รีเซ็ตเซฟเดิม.
3. WeatherSchedule เป็นฟังก์ชัน UTC day/seed; ตรวจ midnight และ nextAt ด้วยตารางจริงเมื่อแก้ schedule. local admin override ต้องกลับ UTC ได้. อากาศทั้งหมด/Live Event ทุกเซิร์ฟต่อ Phase 8; art/เสียง/VFX และ **ปรับปรุง UI รวมสวน/อากาศ** ต่อ Phase 10.
4. สูตร mutation ยึดพิเศษสูงสุด × (1+ผลรวมค่าอื่น) ตาม plan 4.12.3; Apply รวม parent tags ก่อนคิดราคา. ห้ามเปลี่ยนสูตรจากคำบรรยาย ×2 โดยไม่ปรับ plan/report ให้ตรงกัน.
5. ทดสอบ Phase 4 ด้วย Script ใน VM เกมจริง และคืน profile/flags/อากาศ/Balance/anchor หลังจบ. GUIHarness ต้องสั่ง Finish ก่อน Stop. Regression Phase 2/3 ใช้ Clear เพื่อแยก weather จากสูตรที่กำลังตรวจ. อย่า overwrite ProfileStore ของ Studio.

## แนวทางต่อไข่ สัตว์ ฐาน และ Phase 6

1. Phase 5 core ผ่าน 81 checks; อ่าน `docs/phase5_validation.md` ก่อนแก้ไข่/สัตว์/ขโมย. PetService เป็นเจ้าของไข่ ตู้ฟัก สัตว์ คอก บัฟ Mount และสายพาน; StealService เป็นเจ้าของขโมย ล็อกฐาน โล่ และบอททดสอบ; NestService เป็นเจ้าของรังป่าและผู้พิทักษ์. ใช้ ownership ฐานของ GardenService (`Garden.BaseIndex/BaseById/OwnerOf`) ไม่สร้างชุดใหม่.
2. ไข่ที่ถูกขโมยต้องอยู่ใน profile เจ้าของ (`carriedBy`) จนส่งถึงฐานคนขโมย แล้วย้ายในเธรดเดียวไม่มี yield. ห้ามลบไข่ตอนเริ่มขโมย. ไข่ที่ถือจากรังจะได้ก็ต่อเมื่อถึงหินวาร์ปหรือกดปุ่ม End Run (`Run.End(player,true)`); ตาย/ออก/จบแบบอื่นคืนรัง.
3. บัฟสัตว์ผ่าน `Pet.Mult` เท่านั้น (Power เข้า `Balance.CutPower` petMult, Wood/EXP เข้า `Run.Award`) และต้องเคารพเพดาน ×4/×1.5. ความเร็วเดินคำนวณที่ `Pet.ApplySpeed` จาก AdminSpeed × Mount × บัฟ × CarryMult — ระบบใหม่ที่เปลี่ยน WalkSpeed ต้องผ่านจุดนี้.
4. UI ที่รีเฟรชจาก state packet ต้องอัปเดตปุ่มเดิมแทนการสร้างใหม่ (ดู `reuse` ใน PetController) ไม่งั้นคลิกหายระหว่างรีเฟรช. Humanoid.WalkSpeed เป็น float32 — เทียบในเทสต์ด้วย tolerance ≥1e-3.
5. ทดสอบขโมยด้วยฐานบอท/บอทขโมยจาก PetCommands จนกว่าจะมีผู้เล่นจริงหลายบัญชี; บันทึกผลหลายบัญชีลง handoff เมื่อได้ทดสอบ. Phase 6 ใช้ `Progress.StoryChapter` เปิดการขี่บทที่ 2 (บังคับเมื่อ Feature `Story` เปิด) และเพิ่มสัตว์/ไข่โซน 3–8 ใน Phase 7 เป็นแถว Config.

## แนวทางต่อเนื้อเรื่อง เควส บอส และ Phase 7

1. Phase 6 core ผ่าน 51 checks; อ่าน `docs/phase6_validation.md` ก่อนแก้เนื้อเรื่อง/เควส/บอส. QuestService เป็นเจ้าของเควสหลัก/รายวัน/สัปดาห์/Index, StoryService เป็นเจ้าของ NPC/ศาลเจ้า/ปลดโซน/วาร์ป, BossService เป็นเจ้าของผู้พิทักษ์. Progress ใช้คีย์สตริง (`Progress.Bosses["1"]`, `Progress.Shrines["1"]`).
2. ขั้นเควสแบบนับต้องอ่านส่วนต่างของ `Stats.*` — ระบบใหม่ที่อยากให้เควสนับ ให้เพิ่ม Stats ด้วย `Data.Increment` แล้วเพิ่มแถวใน Config.Story ไม่ต้องเรียก QuestService ตรง. เควสรายวัน/สัปดาห์สุ่มจาก UTC key เท่านั้น.
3. สูตรบอสอยู่ที่ `Balance.BossHP/BossRequiredPower` (BalanceConfig `BossHPMult/BossRewardMult` ตรงกับ `balance_sim.py`). บอสถูกสร้างเฉพาะโซน `built=true` — Phase 7 แค่เปลี่ยน `built` และสร้างโซน บอส/บท/วาร์ปจะทำงานเอง แต่ต้องเพิ่มไข่/สัตว์/บทพูดของโซนนั้น.
4. ประตูโซนเปิดที่ client จาก `Progress.UnlockedZones`; รางวัลทุกอย่างต้องตรวจ `Run.CanAccess` ที่ server เสมอ. UI ใหม่ที่ฝั่งขวาต้องไม่ชนพยากรณ์อากาศ (y 120–180) และ Run panel; ตัวติดตามเควสอยู่ซ้าย (y 475).

## แนวทางที่ ArmZ อนุญาต (รายละเอียด)

ArmZ อนุญาตเมื่อ 2026-10-01 ให้เลือกของจาก Creator Store ที่เห็นว่าเหมาะสมและช่วยให้งานง่ายขึ้น แล้วนำมาใช้ในโปรเจกต์ได้เลย ไม่ต้องถามอนุญาตซ้ำสำหรับการนำ asset ที่เข้าถึงได้มาใช้ตามงานที่สั่ง แนวทางนี้แทนข้อกำหนดเดิมที่ให้สร้างโมเดลทุกชิ้นจาก Part เอง

เลือกใช้โมเดล ต้นไม้ หิน อาคาร ของตกแต่ง วัสดุ เสียง แอนิเมชัน หรือโมดูลที่ช่วยลดงานและเข้ากับธีม fantasy anime / low-poly ของเกม ปรับสี ขนาด และรายละเอียดให้กลมกลืนกับแมพ รักษาชื่อ เรื่องราว และเอกลักษณ์ของ Chop a Tree

## วิธีนำมาใช้

1. อ่าน `docs/HANDOFF.md` และส่วนที่เกี่ยวข้องของ `docs/plan.md` เพื่อรู้ระบบและผังปัจจุบัน เลือก asset ที่แก้ความต้องการของงานนั้นได้จริง ถ้าไม่เหมาะให้ใช้ของเดิมหรือสร้างเอง
2. ตรวจชื่อ ผู้สร้าง ชนิด และ asset ID จากผลค้นหาก่อนใส่ใน Studio ตรวจ descendant และโค้ดของ asset ในพื้นที่พักที่ไม่รันสคริปต์ก่อนย้ายเข้าแมพ ใช้เฉพาะโค้ดที่เข้าใจและจำเป็นกับงานนั้น
3. ปรับ Anchored, collision, ขนาด และจำนวน Part ให้เหมาะกับการเดินและ Streaming ของเกม เก็บ tags/attributes และโครงที่ระบบใช้อยู่ เช่น Tree, Zone, Tier, ChestSpot และ PlayerBase เมื่อนำโมเดลใหม่มาแทนของเดิม
4. ทำให้สร้างแมพซ้ำได้: เก็บต้นแบบที่ตรวจแล้วใน ServerStorage และอ้างอิงจากตัวสร้างแมพเมื่อใช้กับแมพที่สร้างด้วย MapBuilder บันทึก asset ID, ผู้สร้าง, ตำแหน่งต้นแบบ และสิ่งที่ปรับในเอกสารของงาน
5. ทดสอบส่วนที่ asset กระทบใน Play และตรวจ Output; ถ้าเปลี่ยนพื้นที่เดินให้ตรวจเส้นทางด้วย `tools/map/ValidateRoutes.luau` อัปเดต HANDOFF และ commit/push ตามแนวทางโปรเจกต์

การอนุญาตนี้ครอบคลุมการเลือกและนำ asset มาใช้ในงาน ไม่ใช่การซื้อของด้วย Robux หรือการ Publish เกมจริงโดยอัตโนมัติ
