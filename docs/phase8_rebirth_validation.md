# Phase 8a — Rebirth และต้นไม้ทักษะ (core)

ทำและทดสอบใน Studio PlaceId `93479990217075` วันที่ 2026-10-01; ยังไม่ได้ Publish place. Phase 8 ส่วนอื่นยังไม่ทำ.

## ระบบและค่าตั้งต้น

1. RebirthService ตรวจบอสของวัฏจักรปัจจุบัน: ครั้งแรกโซน 4, แล้ว 5/6/7/8 และใช้โซน 8 ต่อไป. ต้องจบ Run ก่อน, ไม่ถือไข่, ไม่มีไข่ของตัวเองที่กำลังถูกขโมย และตัวละครยังมีชีวิต. Coins ขั้นต่ำ = `1e9 × 100^(requiredZone−4) × 10^R`; ได้ Token = `R+1`. ค่าปรับใน Config.Rebirth; จำกัด 280 วัฏจักรตามขอบเขตตัวเลขในแผน.
2. รีเซ็ต Coins/Wood, เงินค้างในคอก, Progress.Zone/UnlockedZones/Bosses/Shrines/StoryChapter และเควสหลัก, อัปเกรด lock/incubator/pen และ Garden.slots→6. คง weapons/chests/eggs/pets/seeds/fruits, Gems/เงินอื่น, Index, Stats, เควสรายวัน/สัปดาห์, crops, skills และ cosmetics. ไม่ย้อนเควสรายวันเพื่อรับรางวัลซ้ำ. พากลับ VillageSpawn และลงจากสัตว์ขี่.
3. สัตว์เกินความจุคอก/พกจะกลับกระเป๋าโดยไม่ลบ UID. ช่องสวนที่มีต้นปลูกไว้เกิน 6 ยังแสดงและเก็บผล/รดน้ำ/ตัดได้; ต้องซื้อช่องคืนก่อนปลูกใหม่. GardenState ส่ง visible `slots` และ purchased `unlockedSlots` แยกกัน. ต้นไม้เดิมและ provenance ไม่ถูกรีเซ็ต.
4. Schema v1 Reconcile เพิ่ม `Rebirth.skills`; RebirthTokens เป็น currency เดิม. ไม่มีการรีเซ็ตเซฟหรือเปลี่ยน ProfileStore. RebirthMath อ่านค่าจาก profile/Config และ skill effects เปิดเมื่อ Feature Rebirth=true.
5. ทักษะ 5 สาย: AutoCut 4 ขั้น เพิ่ม reward 0.05/ขั้นจาก .55→.75; PetSlots 3 ขั้น +1/ขั้น (cap 6); ChestLevel 5 ขั้น +1/ขั้นสำหรับหีบที่เก็บใน Run; Wood/Coins 2 ขั้น +.5/ขั้นถึง ×2. ค่า Token ต่อขั้น = baseCost × next rank (AutoCut/ChestLevel=1, อีกสามสาย=2). ค่าตั้งต้นสำหรับจูน Phase 10; Lucky/โบนัส Index/ช่องจากเควสยังไม่ต่อ.
6. Run.Award รวม Wood จาก friend/weather/pet/skill แล้ว cap ×4; Coins จาก friend/skill cap ×4. ตัวคูณรางวัลบอส ×20 แยกจากเพดานบัฟ. AutoCut reward ใช้กับ EXP/Wood/Coins; seed drop เดิม. Pet.EquipCap รวม skill; level boost อยู่ใน Run.CollectChest ไม่ย้อนแก้หีบเก่า. พลัง ×1.5^R/Rot ×10^R ใช้ Balance เดิม.
7. RebirthAction มี Sync/Prepare/Confirm/Buy เท่านั้น. Prepare ออก token ผูกกับผู้เล่นและ R ใช้ได้ครั้งเดียวภายใน 30 วิ; Confirm ตรวจเงื่อนไขซ้ำ. Buy ส่ง id + expected rank ป้องกัน replay ที่เผลอซื้อขั้นต่อไป; server rate limit .25 วิ. การแก้ข้อมูลธุรกรรมไม่มี yield; force อยู่เฉพาะคำสั่งแอดมิน.
8. RebirthController มีปุ่มขวาบน, แผงทักษะที่อัปเดตปุ่มเดิม, ข้อความบอกสิ่งที่จะรีเซ็ตและหน้าต่างยืนยัน/ยกเลิก. ปรับขนาดตาม viewport. Forest HUD แสดงเปอร์เซ็นต์ AutoCut ที่ใช้จริง. Tree tint สีม่วงตาม R เป็นภาพเฉพาะ client; Bram เพิ่มประโยควัฏจักรใหม่.
9. Admin แท็บ Rebirth มี 5 คำสั่ง: force (ยืนยัน 2 ชั้น), +100 Token, ปลดทักษะทั้งหมด, reset skills ไม่คืน Token (ยืนยัน 1 ชั้น), ตั้ง R ด้วยจำนวนในช่องคำสั่ง (0–280; ไม่เพิ่ม Token/ไม่รีเซ็ตของ). คำสั่งระบุ marksTarget เพื่อแยกของแอดมินตามระบบเดิม. Server order ต่อท้าย StoryService ด้วย RebirthService.

## ผลตรวจ

1. `tools/tests/Phase8RebirthScenario.server.luau` ผ่าน **41/41**: reconcile, เงื่อนไขบอส/Coins/Run/ไข่, confirmation ปลอม/กดซ้ำ/ตรวจเงื่อนไขซ้ำ, exact reset/preservation, คง crops ช่อง 18 และเก็บผลได้หลัง reset, replant ปฏิเสธ, excess pets กลับกระเป๋า, ซื้อทักษะ/Token/replay/cap, ช่องพก 6, reward และ chest boost ผ่าน Run จริง, skill reset/feature off, cap Wood ×4, วัฏจักรถัดไปต้องล้มบอสใหม่, numeric limit และ Balance SelfTest. Snapshot/restore profile, weather, flag, anchor และตำแหน่ง.
2. GUI mouse จริง: เปิดแผง, ซื้อ AutoCut 0→1 ใช้ 1 Token, Prepare→Cancel ไม่เปลี่ยน R, Prepare→Confirm เปลี่ยน R 0→1 เงิน Coins/Wood=0 ทักษะที่ซื้อคงอยู่และ Token กลับ 100 จาก 99+1 (ตรวจ profile ใน VM เกมจริง). ตรวจหลังแก้ชั้นภาพอีกครั้ง: หน้าต่างยืนยันอ่านได้และยืนยันสำเร็จ (+1 Token). ปล่อยเกิน 30 วิแล้ว Confirm ปฏิเสธตามการหมดอายุ. Harness คืน profile ทุกครั้ง.
3. ตรวจพบ/แก้ระหว่าง QA: confirmation background ZIndex 30 บังข้อความ/ปุ่ม ZIndex 1; ปรับลูกของ modal เป็น 31 แล้วตรวจภาพจริง. ปุ่มและข้อความแสดงครบ. Remote `Force` ของ client ปฏิเสธ; AdminRun __init พบคำสั่งครบทั้ง 5 และระดับยืนยัน 2/1 ตามที่กำหนด.
4. `python -X utf8 tools/balance_sim.py` ผ่าน; เป็น simulation สูตรฐานเดิม ไม่ใช่การจูน economy/skill tree ครบวงจร. ราคากับ Token/อันดับทักษะต้องเก็บข้อมูลผู้เล่นจริงใน Phase 10.
5. Regression ในรอบนี้: Phase 2 **23/23**, Phase 4 **55/55**, Phase 5 **81/81**, Phase 6 **51/51**. หลักฐานแต่ละ check อยู่ `phase8_rebirth_regression_results.json`; profile/ตำแหน่ง/flags/weather คืนหลังแต่ละ scenario.
6. Source เพิ่ม/แก้ 17 ไฟล์ตรง repo กับ Studio Edit หลังแก้ GUI ตาม `phase8_rebirth_source_checksums.json` (UTF-8 LF byte length และ hash31 mod 2147483647). `git diff --check` ผ่าน. Output มีเฉพาะ server ready/Balance OK/ProfileStore/scenario passed ไม่มี error; กลับ Edit แล้ว Feature Rebirth=true และ ServerScriptService ไม่มี test Script ค้าง.

## ข้อจำกัดและงานถัดไป

1. Phase 8 ที่เหลือ: Daily login/Codes/Leaderboard, โบนัส Index/Achievements, อากาศครบ/บอสโลก/อีเวนต์/Live Event, ร้านเติมเงิน/Season Pass และ Emote/Photo. ไม่ได้สร้างหรือขาย Game Pass/Dev Product จริง.
2. ยังไม่ได้ทดสอบ reconnect หลัง Rebirth ด้วยผู้เล่นจริง, หลายบัญชี/หลายเซิร์ฟ, มือถือ/gamepad หรือเล่นวน 280 ครั้ง. ซื้อทักษะและ rebirth ใช้ session profile เดิม; ทดสอบ snapshots ไม่ทิ้งการเปลี่ยนเซฟจริงของผู้ใช้.
3. เงินค้างคอกรีเซ็ตเพื่อไม่ใช้หลบการรีเซ็ต Coins; ผลไม้/หีบ/ของเดิมคงอยู่ตาม inventory. แสดง crops เหนือ purchased capacity ได้ แต่ UI สวนยังมีข้อจำกัดเดิมเรื่องสร้างปุ่มใหม่ทุก 2 วิ. ภาพ/เสียง/อนิเมชัน Rebirth และ UI ขั้นสุดท้ายต่อ Phase 10.
