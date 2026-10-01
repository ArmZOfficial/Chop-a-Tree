# Phase 4 — สวน + อากาศพื้นฐาน

ทำและทดสอบ 2026-10-01 ใน Studio PlaceId `93479990217075`. ไม่ได้ Publish place. ผลตรวจ 55/55 อยู่ใน `phase4_test_results.json`; โค้ดที่เพิ่ม/แก้ 21 ไฟล์ตรง Studio Edit ตาม `phase4_source_checksums.json`.

## ระบบที่ใช้ได้

1. GardenService จัดเจ้าของฐาน 7 ฐานตาม BaseIndex; สวนเริ่ม 6 ช่อง เพิ่มครั้งละ 6 สูงสุด 30. กริด runtime อยู่ด้านหลังฐานเดิม ไม่เปลี่ยนผังทวีปหรือ MapBuilder. ต้นสวนไม่มี tag Tree และไม่ขวางการเดิน/การฟันในป่า.
2. เมล็ด 8 ชนิดใน Config.Seeds โต 5 นาที–24 ชั่วโมง. ให้ Sunapple 3 เมล็ดครั้งแรก; เมล็ดจากต้นป่าสะสมใน Run.Seeds แล้วเข้า Inventory.Seeds เมื่อ End Run พร้อม provenance โซน/Rot/admin. เปิดหีบมีโอกาสให้เมล็ดเพิ่ม.
3. ปลูก/รดน้ำ/เก็บผล/ตัดต้น/อัปเกรด ตรวจเจ้าของ ระยะ ตัวละครมีชีวิต Feature Flag และต้องอยู่นอก Run. รดได้ครั้งเดียวก่อนโต +10%; มี WateringCan และปุ่ม UI. ตัดต้องโตเต็ม ได้ Wood และมีโอกาสเมล็ดหายาก; UI ยืนยันซ้ำ.
4. โตตาม timestamp แม้ออฟไลน์. ต้นโตเต็มให้ผลหนึ่งรอบพร้อมเก็บ แล้วรอรอบใหม่หลังเก็บ; ไม่สะสมผลย้อนหลังหลายรอบขณะออฟไลน์. ช่วง offline โตปกติ ไม่มี weather mutation. Lumora ให้ EXP +5% ทั้งเซิร์ฟขณะยังปลูกอยู่ รวมสูงสุด +25% เฉพาะสวนของผู้เล่นในเซิร์ฟ.
5. ผลซ้อนตามชนิด/โซน/Rot/mutation/admin; ขายทั้งหมดที่ SeedShop. ราคาใช้ Balance.ZoneScale และ Rot ตอนดรอป. การหักของและจ่ายเงินไม่มี yield; ขาย/ตัด/End Run ซ้ำไม่เพิ่มรางวัล.
6. ร้านเมล็ด restock ทุก 300 วินาที UTC; ทุกเซิร์ฟคำนวณ stock เดียวกัน. จำนวนที่ซื้อของผู้เล่นต่อ epoch เก็บใน profile กันออกเข้า/ย้ายเซิร์ฟเพื่อเติม stock. ซื้อด้วย Coins ตามโซนสูงสุดที่ปลดล็อก; ระยะร้าน 26 studs.
7. Garden HUD มีแท็บสวน/เมล็ด/ร้าน ปุ่มปลูก รด เก็บ ตัด ขาย เพิ่มช่อง และข้อความผลลัพธ์จากเซิร์ฟเวอร์. เปิดสวน/กระเป๋าแล้วปิดอีกหน้าหนึ่ง. รองรับการเปลี่ยน viewport; การจัดวางทุกหน้าบนมือถือจริงยังต้องตรวจใน Phase 10.
8. Schema v1 เพิ่ม Garden, Inventory.Seeds/Fruits และ Run.Seeds ด้วย Reconcile; ไม่รีเซ็ตอาวุธหรือเงินเดิม. เก็บ profile เป็นแหล่งจริง ไม่คัดลอก state จาก UI กลับเซิร์ฟเวอร์.

## อากาศและ Mutation

| อากาศ | เวลา | ผลที่เชื่อมแล้ว |
|---|---:|---|
| Rain | 5 นาที | สวนโต ×1.5, Wood ป่า ×1.25, ลุ้น Wet 25% |
| Storm | 4 นาที | ฟ้าผ่าเลือกต้นป่าทุก 15 วิ; ผู้ร่วมฟันล่าสุด/ผู้เล่น Run ใกล้ 75 studs ได้รางวัล ×3, ลุ้น Shocked 3% |
| Snow | 5 นาที | EXP ป่า ×1.5, HP/Power ขั้นต่ำของต้นป่า ×1.25, ลุ้น Chilled 20% |
| Golden | 4 นาที | หีบที่เก็บช่วงอากาศนี้ LEVEL +5, ลุ้น Golden 1%; พยากรณ์ซ่อนเป็น ??? |

1. WeatherSchedule ใช้ UTC day + seed คงที่; ไม่สุ่มแยกเซิร์ฟเวอร์. ทดสอบทุกนาทีในหนึ่งวันและช่วงเที่ยงคืนหลายวันว่า forecast ชี้ event ที่เกิดจริง. ยังไม่ได้ทดสอบด้วยเซิร์ฟเวอร์จริงหลายเครื่องพร้อมกัน.
2. เว้นฟ้าใส 5–8 นาที **หลังจบ** event เพื่อให้มีเวลาปกติประมาณ 58%; น้ำหนัก event Rain/Storm/Snow/Golden = 50/20/25/5. เริ่มวัน UTC ใหม่ด้วยช่วงฟ้าใส; event ใกล้เที่ยงคืนอาจสั้นลง. ช่วง heartbeat online คิด bonus ย้อนหลังไม่เกิน 5 วิ เพื่อลดการคิดอากาศย้อนหลังขณะ offline.
3. Mutation ลุ้นเฉพาะผลพร้อมเก็บของผู้เล่นออนไลน์ ครั้งเดียวต่อ weather event. Wet+Chilled → Frozen, Wet+Shocked → Electrified; เมื่อรวมคอมโบลบ parent tags. หลังเก็บผลเริ่ม mutation ของรอบใหม่ แต่ไม่ reroll อากาศ event เดิม.
4. ราคาใช้สูตรชัดเจนใน plan 4.12.3: ตัวพิเศษสูงสุด × (1 + ผลรวมค่า mutation อื่น). ค่า Golden20, Shocked15, Wet2 ให้ตัวอย่าง raw tags ×360. Wet อย่างเดียวตามสูตรนี้ ×3; ตัวเลข ×2 ในคำบรรยายเดิมไม่ตรงสูตร จึงยึดสูตรและตัวอย่างหลัก. การ Apply Wet+Shocked จริงรวมเป็น Electrified ก่อนคำนวณ.
5. Client มีแสงตามอากาศ อนุภาคฝน/หิมะ หิมะบน Roof ที่ stream เข้ามา ลำแสงฟ้าผ่า ป้ายพยากรณ์/นับถอยหลัง. เป็น VFX พื้นฐาน; โมเดลต้นไม้/บัวรดน้ำ เสียง แอนิเมชัน และภาพ UI สุดท้ายอยู่ Phase 10. ไม่ได้เพิ่ม Creator Store asset ใหม่ในรอบนี้.
6. Admin แท็บ garden มีให้เมล็ด โตทันทีและ mutation; weather บังคับ 5 แบบในเซิร์ฟนี้ 5 นาที/กลับ UTC. ตรวจ catalog 14 คำสั่ง และเรียก Storm/กลับ UTC ผ่าน AdminRun จริง. Live Event ทุกเซิร์ฟและอากาศชุดที่เหลืออยู่ Phase 8.

## ค่าตั้งต้นและผลตรวจ

1. Tree seed chance 12% (AutoCut คูณ 0.55), chest seed 20%, ตัดสวน seed 8%; เลือก seed ตาม tier ของต้นป่า ส่วนหีบ/ตัดสวนลุ้นทั้งหมด. ค่าเหล่านี้และ seed prices/yields/intervals เป็นค่าตั้งต้นสำหรับ balance Phase 10.
2. เพิ่มช่องใช้ Wood `500 × (slots/6)^2`; ค่าครั้งแรก 500 จากนั้น 2K/4.5K/8K. ราคาเมล็ดไม่คูณ Rot; ผลและ Wood คูณ Rot ตอนเมล็ดดรอป.
3. `Phase4Scenario.server.luau` ผ่าน **55/55**: ownership/ระยะ/ช่องปิด/Feature Flag/Run, consume ครั้งเดียว, water, offline, recurring harvest, sell/buy/stock, upgrade cap, provenance, reconcile เซฟเก่า, EXP buff cap, mutation/combos, UTC forecast, weather reward, lightning และ Snow HP/Power.
4. GUI กด mouse จริง: เลือกเมล็ด → ปลูก → รด → เก็บ 3 ผล → เพิ่มเป็น 12 ช่อง → ขาย 300 Coins → ซื้อ 100 Coins → ตัดยืนยันสองครั้ง. หลังคลิกครั้งแรกต้นยังอยู่ หลังครั้งที่สองต้นหาย. ใช้ GUIHarness สำหรับ setup และคืนข้อมูลด้วย Finish.
5. Snow แสดง roof covers 3 ชิ้นในพื้นที่ที่ stream มา; เปลี่ยน Golden ลบ covers และปิดอนุภาคพร้อมเปลี่ยน Brightness เป็น 3. Storm อนุภาค Rate 140. ภาพ `screens/phase4_garden.jpg`, `phase4_snow.jpg`, `phase4_golden.jpg` เป็นภาพระหว่าง Play ทดสอบ.
6. Phase 2 regression **23/23**, Phase 3 regression **36/36**. ชุดเดิมบังคับ Clear ระหว่างทดสอบและคืนอากาศเดิม เพื่อไม่ให้ผลสุ่มของอากาศทำให้ assertion รางวัลเปลี่ยน. `python -X utf8 tools/balance_sim.py` รันสำเร็จ; ตัวจำลองนี้ตรวจสูตรหลักเดิม ยังไม่ได้จำลองเศรษฐกิจสวนครบวง.
7. ทุกรอบ snapshot/restore profile จริง เพราะ API services เปิด. Test Script ต้องใช้ require cache เดียวกับเกม; MCP VM อ่าน DataService live ไม่ได้. ตัวทดสอบ Snow ใช้ Tier2 (Tier1 ไม่มี Power gate) และ anchor ตัวละครระหว่างเก็บ damage สองค่า เพื่อไม่ให้การเดิน/ตกทำให้ Out of range; คืน anchor/Power/overrides หลังทดสอบ.
8. Studio กลับ Edit ไม่มี test Script ค้าง; ยังไม่ได้ Publish. ยังต้องทดสอบหลายบัญชีพร้อมกัน เซฟแล้ว reconnect ข้ามเซิร์ฟจริง มือถือ/gamepad และ balance รายได้ระยะยาว. งานถัดไป Phase 5 ไข่/สัตว์/ขโมย/ล็อกฐาน/โล่ AFK.
