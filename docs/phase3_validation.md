# Phase 3 — หีบ + อาวุธ

ทำและทดสอบใน Studio เมื่อ 2026-10-01, PlaceId 93479990217075. ยังไม่ Publish place.

## สิ่งที่ใช้งานได้

1. Config.Weapons ทั้ง 100 ชิ้นเข้ามาใน Studio แล้ว. ไอเทมมี UID ถาวร, definition ID, IL, ดาว, Giant, Rot ตอนดรอป และ admin provenance.
2. หีบ 5 ระดับจาก ChestSpot ตามความลึก; เก็บ LEVEL/โซน/Rot ตอนรับและ settle ผ่าน End Run. หีบเก่าที่ไม่มี UID เติมให้เมื่อโหลดหรือ Sync กระเป๋า.
3. เปิดทีละใบที่ ChestAltar หลังจบ Run. เซิร์ฟเวอร์ตรวจความเป็นเจ้าของ ระยะ สถานะตัวละคร Feature Flag และช่องกระเป๋า ก่อนสุ่มและหักหีบ. ไม่มี yield ระหว่างหักหีบกับสร้างอาวุธ.
4. Inventory HUD แสดงหีบซ้อน จำนวน LEVEL/IL และอัตราดรอปจริง; อาวุธมีภาพ preview, Power, ดาวและ Giant. เปิดหีบมีภาพหมุนและหน้าผลรางวัล; Giant สั่นกล้องและประกาศทั้งเซิร์ฟ.
5. สวมใส่จากกระเป๋า; Tool และ Run Power เปลี่ยนตามอาวุธ. Speed เป็นจำนวนฟันต่อวินาที; Area เป็นรัศมีฟันหมู่รอบต้นหลัก ทุกต้นยังตรวจโซน, Power, ความสูง และ line of sight. Giant ขนาด ×3, Power ×5, Area ×2.
6. Fuse ของเหมือนกัน 3 ชิ้น (definition/IL/ดาว/Giant/Rot เดียวกัน) เพิ่ม 1 ดาว สูงสุด ★5. ดาวใช้สูตร Balance เดิม +50% ต่อดาว. เก็บ UID ของชิ้นที่เลือกไว้และย้าย equipped มายังผลลัพธ์เมื่อกินชิ้นที่สวมใส่.
7. ทิ้งอาวุธเพื่อคืนช่องกระเป๋า; UI ต้องกดยืนยันซ้ำ. ถ้าทิ้งชิ้นที่สวมใส่ระหว่าง Run จะได้ขวานเริ่มต้นกลับมา. เปิด/ปิด Chests flag ก็เปลี่ยน Tool และ Power ตามระบบที่เปิดอยู่.
8. หีบฟรี Common ทุก 15 นาทีที่ออนไลน์ในเซิร์ฟ. Admin แท็บ chests ให้หีบทดสอบทุก rarity; weapons ให้ของซ้ำและ Giant Mythic พร้อม provenance.

## ค่าตั้งต้นที่เพิ่มใน Config.Chests

แผนมีอัตรา Common เลเวลต่ำและ Giant แต่ยังไม่มีตารางหีบระดับสูง/ค่า Fuse จึงกำหนดค่าทดสอบที่ปรับต่อได้:

| หีบ | Common | Rare | Epic | Legendary | Mythic |
|---|---:|---:|---:|---:|---:|
| Common | 70 | 25 | 5 | 0 | 0 |
| Rare | 25 | 55 | 18 | 2 | 0 |
| Epic | 0 | 20 | 60 | 18 | 2 |
| Legendary | 0 | 0 | 25 | 65 | 10 |
| Mythic | 0 | 0 | 10 | 30 | 60 |

ตัวเลขเป็นน้ำหนักที่ LEVEL 1. LEVEL boost = clamp(1+(level−1)/20,1,4); คูณน้ำหนักลำดับ rarity ด้วย boost^(index−1) แล้ว normalize. ไม่เพิ่ม rarity ที่น้ำหนักเป็นศูนย์. Giant ใช้ Rarities.GiantChance ของ **หีบ** × (1+0.01×(level−1)), cap 25%.

Spot weights = 75/20/4/0.9/0.1; ปรับตาม Depth ด้วย (1+Depth)^(index−1). Fuse Wood = 100 × ZoneScale(IL) × Rot(rebirthDrop) × ดาวปัจจุบัน. กระเป๋าอาวุธ cap 300. `Loot` เป็นที่เดียวที่อ่าน/คำนวณอัตรา UI และ server ใช้ร่วมกัน. Power ใช้ค่าของ definition ที่กระจาย ×1..×4 อยู่แล้ว ไม่สุ่มคูณ ×1..×4 ซ้ำอีก.

## ผลตรวจ

1. `tools/tests/Phase3Scenario.server.luau` ผ่าน **36 checks**: registry 100 ชิ้น, odds/20,000 seeded rolls, IL/Rot/Giant, open validation/consumption, equip ownership, provenance, feature flag, fuse validation/charge/duplicate/max stars, Tool scaling, Power/speed/area, delete/fallback และ Balance SelfTest.
2. GUI mouse จริง: เปิด 1 หีบเพิ่มอาวุธ 4→5; Fuse กดครั้งแรกยังไม่หัก, ครั้งที่สอง 5→3 และ Wood 1000→900; สวมใส่ผล ★2 Power 187.5 ถูกต้อง.
   กด E ที่ ChestAltar เปิดกระเป๋าได้; ปุ่มปิดผลรางวัลใช้ได้หลังแก้ ZIndex. ทิ้งอาวุธกดครั้งแรกจำนวนยัง 1, กดยืนยันครั้งที่สองเหลือ 0. แก้การเลือกไอเทมที่เพิ่งเปิดให้รอ DataPatch ได้ แม้ response มาก่อนข้อมูลกระเป๋า.
3. รัน `python -X utf8 tools/balance_sim.py` ผ่าน; สูตรเศรษฐกิจเดิมไม่เปลี่ยน. ตรวจ Luau syntax ทุกไฟล์ที่ sync.
4. ตัวทดสอบ snapshot/restore ข้อมูลผู้เล่น; UI demo ใช้ของ admin ชั่วคราวและคืนเซฟเดิมก่อนหยุด Play.
5. Phase 2 regression ผ่าน **23/23** หลังต่ออาวุธ; Console รอบสุดท้ายไม่มี error. ตรวจ source checksum ปัจจุบัน 14 ไฟล์ใน `phase3_source_checksums.json` (checksum Phase 2 เป็น snapshot เก่า).

## ขอบเขตภาพและงานต่อ

โมเดลอาวุธตอนนี้เป็น procedural silhouettes ตามชนิด/สี rarity รองรับอาวุธทั้ง 100 definition และ viewport/Tool; **ยังไม่ใช่งานโมเดลสุดท้าย 100 ชิ้น**. Art, element trails, ชื่อท่า/ร่างปลดผนึก, เสียงและ polish UI ต่อ Phase 10 ตามที่ ArmZ ขอ.

Mobile layout สลับเป็นแท็บเมื่อ viewport แคบ แต่ยังต้องทดสอบบนมือถือจริง. หีบฟรี 15 นาทีมีระบบ timer แล้ว แต่ยังไม่ได้รอทดสอบครบ 15 นาที; หีบรายวัน/กลุ่ม/ไลก์ต่อ Phase 8. Seed/egg drops ต่อ Phase 4–5. ข้อจำกัด AFK ใน Phase 2 ยังเหมือนเดิม.

งานถัดไป **Phase 4 สวน + อากาศ**; อ่าน plan.md ก่อน. ห้ามแทนที่ ProfileStore ใน Studio ด้วยเวอร์ชัน repo.
