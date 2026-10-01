# Phase 8c — Index buffs, Achievements และฉายา

ตรวจใน Studio PlaceId `93479990217075` วันที่ 2026-10-01. Phase 8c core เสร็จ; ยังไม่ถือว่าจบ Phase 8 ทั้งหมด และยังไม่ได้ Publish.

## พฤติกรรมที่ทำแล้ว

1. Index ครบอาวุธได้ Power +10%, สัตว์ได้ Coins +25%, เมล็ดได้ Wood +25%, Mutation ได้โอกาส Epic+ ในหีบ +25%. Wood/Coins เพิ่มจาก Rebirth แบบบวกและถาวรไม่เกิน ×2; timed/friend/weather/pet ตาม seam เดิมรวมไม่เกิน ×4. Power รวม pet/Index cap ×4 ก่อนตัวคูณวัฏจักร. Coins/ Wood นี้ใช้กับรางวัล Run; ไม่เพิ่มราคาขายสวนหรือรายได้คอก.
2. `CollectionMath` ใช้ catalog ID จริงร่วมกันทั้ง server/UI. ID ปลอมและของ `admin_spawned` ไม่ทำให้สะสมครบ. Profile เก่าที่สะสมครบแต่ไม่มี `Index.done` จะเติม marker และจ่าย completion 50 Gems ครั้งเดียว แม้ไม่มีไอเทมใหม่. Marker ที่ปลดแล้วคงผ่าน Rebirth และการขยาย catalog; การเติมของใหม่ยังให้ 1 Gem ต่อรายการตามระบบเดิม.
3. Luck เพิ่มสัดส่วน Epic/Legendary/Mythic รวมแบบสัมพัทธ์ เช่น Common level 1 จาก 5% → 6.25%; ไม่ใช่เพิ่ม 25 จุดเปอร์เซ็นต์. รักษาสัดส่วนภายในกลุ่ม Epic+ และ Common/Rare, cap 100%, ไม่เปลี่ยน Giant. Rebirth เพิ่มทักษะ Luck 2 ขั้น (+12.5% ต่อขั้น ราคา 2/4 Tokens); รวม Index cap +25%. การปิด flag ตัดเฉพาะผลของ source นั้น.
4. `Config.Progression` มี Achievements 9 แถว: ตัด 100/1,000/10,000 ต้น, เปิด 25 หีบ, เก็บผล 50 ครั้ง, ฟัก 20 ไข่, ฆ่าบอส 8 ครั้ง, Rebirth 1 ครั้ง, Index ครบ 4 หมวด. แถวแต่ละแถวมี Gems และฉายา; ตรวจ Stats/Progress/Index ที่ server. Claim จ่ายครั้งเดียวและเลือกฉายาแรกอัตโนมัติ, Claim ครั้งถัดไปคงฉายาที่เลือก. Equip ได้เฉพาะฉายาที่รับแล้ว; ส่งค่าว่างเพื่อถอด.
5. `AchievementService` เป็นเจ้าของ claim/equip/ฉายา BillboardGui และ Player attribute; CharacterAdded/profile snapshot/flag change เรียก RefreshTitle. Remote `AchievementAction` รับ Sync/Claim/Equip เท่านั้นและมี rate limit; ไม่มี public Force. Schema v1 เพิ่ม `Achievements.claimed/equipped` โดย Reconcile ไม่เปลี่ยน store หรือรีเซ็ตของเดิม.
6. StoryHUD มีแท็บความสำเร็จและรายละเอียดบัฟ Index; update ปุ่มเดิมระหว่าง refresh. Inventory แสดง odds ด้วยสูตร Luck เดียวกับ server และอัปเดตเมื่อ Index/Rebirth/flags เปลี่ยน. Admin แท็บโซน & เนื้อเรื่องเพิ่ม unlockall/reset 2 คำสั่ง `marksTarget=true`; unlock ไม่เพิ่ม Gems, reset ไม่หัก Gems เดิมและมี confirm 1 ชั้น.

## ผลตรวจ

| ชุดตรวจ | ผล | หลักฐาน |
|---|---|---|
| Phase 8c VM เกมจริง | 55/55 | `phase8_collections_test_results.json` |
| หีบ/อาวุธเดิม | 36/36 | `phase8_collections_regression_results.json` |
| เนื้อเรื่อง/Index/บอสเดิม | 51/51 | ไฟล์ regression เดียวกัน |
| Rebirth เดิม | 41/41 | ไฟล์ regression เดียวกัน |
| Daily/Codes/Leaderboard เดิม | 45/45 | ไฟล์ regression เดียวกัน |
| Source repo ↔ Studio Edit | 15/15 ตรงกัน | `phase8_collections_source_checksums.json` |
| GUI เมาส์จริง / restore | ผ่าน | `phase8_collections_gui_results.json` |

1. ชุดใหม่ใช้ `tools/tests/Phase8CollectionsScenario.server.luau`: additive schema, catalog/provenance/marker, reward caps ผ่าน Run จริง, Luck purchase/replay, odds ทั้ง 5 rarities, seeded real rolls 20,000 ครั้ง, Weapon.Open รับ Luck ที่ server คำนวณ, claim/duplicate/equip/feature/title/import/admin helper และคงข้อมูลผ่าน Rebirth. ใช้ Script ใน VM เกมจริง, snapshot/restore profile/flags/weather/anchor/ตำแหน่ง; ไม่ require live DataService ผ่าน MCP.
2. Regression ปิด IndexBonuses/Achievements เพื่อพิสูจน์พฤติกรรมเดิมโดยแยกจากบัฟใหม่ และพัก Leaderboard ระหว่างจำลอง profile; เปิดคืนหลังจบ. รอบแรกพบ zero-Luck ทำให้ floating-point baseline เปลี่ยนเล็กน้อย; แก้ให้ Luck=0 ข้าม reweight และทดสอบเดิมผ่านโดยไม่แก้ assertion. รอบแรกของชุดใหม่ใช้ CFrame บน Model แท่นหีบผิด; แก้ harness เป็น GetPivot แล้วรันใหม่ผ่าน.
3. GUIHarness แยกการจ่าย achievement จากเควสหลัก: ใช้ main chapter ที่จบแล้วชั่วคราวและคืน snapshot. เมาส์รับ trees100 ได้ 20 Gems; ถอด/เลือกฉายาไม่จ่ายซ้ำ; ฉายาสีทองแสดงบนหัว. Index เมล็ดแสดง 8/8 + Wood 25%. ซื้อ Luck rank 1 ด้วยเมาส์แล้วข้อความเป็น 1/2 และราคา rank ถัดไป 4 Tokens; หีบ Common แสดง Epic 5.6% (5.625% ปัดหนึ่งตำแหน่ง). Remote Force ถูกปฏิเสธ; metadata admin พบ 2 คำสั่ง.
4. ตรวจ profile หลัง Finish เทียบ snapshot Currencies/Inventory/Progress/Index/Achievements/Rebirth/Boosts/Codes/Garden/Quests ไม่ต่าง, flags คืน true. balance_sim.py และ git diff --check ผ่าน; ตัวจำลองยังเป็น baseline economy ไม่ได้จำลอง Index/Luck/achievement ทุกกรณี. ทดสอบโบนัสจริงใน Luau ตามรายการด้านบน.
5. เคยพบข้อมูล source ถูกตัดระหว่าง sync รวมก้อน; ซิงก์ใหม่ทีละไฟล์จาก source เต็มและตรวจ UTF-8/LF length/hash ทั้ง 15 ไฟล์ก่อนจบ. ไม่แก้ ProfileStore ใน Studio. Startup smoke รอบใหม่ไม่มี test Script ใน Edit และไม่มี error.

## ข้อจำกัดและงานถัดไป

1. Profile import และ Rebirth ผ่าน; ยังไม่ได้ reconnect ผ่าน DataStore จริง, respawn ตัวละครจริง, หลายบัญชี/หลายเซิร์ฟ, มือถือ/gamepad หรือ UI ที่ catalog ใหญ่กว่านี้. ทดสอบการสร้าง title ใหม่ด้วย RefreshTitle หลังลบ BillboardGui แล้วเท่านั้น; CharacterAdded ต้องตรวจจริงในรอบอุปกรณ์/หลายบัญชี.
2. ค่าบัฟ/เป้า achievement/ราคา Luck เป็นค่าตั้งต้นใน Config รอจูน Phase 10; rarity balance สำหรับผู้เล่นจริงและงานภาพ/UI สุดท้ายยังค้าง.
3. ถัดไป Phase 8d อากาศครบทุกแบบและ Live Event ตาม plan 4.12/5.7 โดยใช้ WeatherSchedule/Garden/Pet seams เดิม. บอสโลก/เทศกาล/ร้านเติมเงิน/Season Pass/Emote-Photo ยังไม่ทำ; PvP รอ Phase 9. Plan, SKILL.md และ HANDOFF อัปเดตพร้อมกันตามคำสั่ง ArmZ.
