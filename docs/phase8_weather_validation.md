# Phase 8d1 — อากาศและ Live Event core

ตรวจ Studio PlaceId `93479990217075` จบรอบวันที่ 2026-10-02 เวลาไทย. Phase 8d1 core ทำแล้ว; ส่วนอากาศที่เป็น encounter/ของพิเศษยังค้าง Phase 8d2 และยังไม่ได้ Publish.

## สิ่งที่ทำแล้ว

1. Config.Weather ครบ 13 แถว: เพิ่ม Fog/Wind/Sakura/Meteor/Aurora/Bloodmoon/Rainbow/RotInvasion จาก 5 แบบเดิม. ตาราง UTC deterministic, rare weights ×2 วันเสาร์–อาทิตย์ UTC, Aurora/Bloodmoon เฉพาะกลางคืน UTC (18:00–06:00), Rainbow มีโอกาส 10% ต่อหลัง Rain. Rare forecast ยังซ่อนจนเริ่ม. RotInvasion เปิดด้วย manual/Live Event เท่านั้นจนกว่าจะมี world boss; ยังไม่เข้า schedule ทุก 2 ชม.
2. Wind เพิ่ม Area ×1.5; Sakura crit ×15; Aurora Wood/Coins ×1.5; Bloodmoon HP ×2 และรางวัล ×4 โดย Wood/Coins รวม timed/Index/skill ไม่เกิน ×4. Fog สร้าง chest spot เพิ่ม 1 จุดโซน 1, หายเมื่อจบอากาศ และใช้ Run provenance/collect-once เดิม. Storm/Rain/Snow/Golden เดิมผ่าน regression.
3. Mutation ผล 15 แบบ พร้อม Celestial+Aurora→Cosmic และ special สี Golden/Rainbow ใช้ค่าสูงสุด. สัตว์เพิ่ม Sakura/Celestial/Rainbow ตามอากาศตอนฟักออนไลน์; offline ไม่มี rare mutation. Index รวมผล/สัตว์เป็น 16 IDs; completion marker เดิมคงโบนัสเมื่อ catalog ขยาย. สวนใช้ growth/online mutation seam เดิม; Rotten ลด growth เป็น .75.
4. WeatherHUD รองรับ note/forecast/banner LIVE และ mood/particles ของอากาศใหม่; Aurora/Bloodmoon เปลี่ยน ClockTime ฝั่ง client แล้วคืนค่าเดิม. ภาพเป็นพื้นฐาน ยังไม่มีเสียง/งานศิลป์อากาศสุดท้าย.
5. LiveEventService เก็บลำดับอากาศกับเวลา UTC ใน MemoryStore current key (TTL 1 ชม.), เพิ่ม revision ด้วย UpdateAsync และแจ้งผ่าน MessagingService. Subscribe แจ้งให้ reread authoritative state; poll 30 วิรองรับ missed message/late join. Begin หน่วง 5 วิ, ไม่ restart ลำดับเมื่อ server เข้ามาทีหลัง; API failure ไม่รายงานสำเร็จ, notification failure หลัง commit รายงาน fallback polling. ยึด [MemoryStore UpdateAsync](https://create.roblox.com/docs/reference/engine/classes/MemoryStoreHashMap) และ [MessagingService](https://create.roblox.com/docs/reference/engine/classes/MessagingService/SubscribeAsync); การส่งข้อความเป็น best effort จึงไม่รับประกันว่าเซิร์ฟที่ API ขัดข้องจะเปลี่ยนพร้อมกันทันที.
6. Owner-only admin 4 คำสั่ง: preview เฉพาะเซิร์ฟ/หยุด preview/เริ่มทุกเซิร์ฟ/หยุดทุกเซิร์ฟ. Global start/stop ยืนยัน 2 ชั้น. Preset Sakura→Golden→Aurora อย่างละ 2 นาที (preview 20 วิ); ไม่มี public player remote หรือข้อความผู้เล่นส่งเข้าประกาศ. Studio แยก topic/store `_Studio`; feature LiveEvents/Weather ปิดผลได้. Live Event สูงกว่า local override และหมดอายุกลับ override/UTC เดิม.

## หลักฐาน

| ตรวจ | ผล |
|---|---|
| Scenario อากาศใหม่ ใน VM เกมจริง | 38/38 (`phase8_weather_test_results.json`) |
| สวนเดิม / สัตว์เดิม / เนื้อเรื่องเดิม | 55/81/51 (`phase8_weather_regression_results.json`) |
| หีบเดิม / Index-Achievements เดิม | 36/55 (ไฟล์ regression เดียวกัน) |
| Source repo ↔ Studio Edit | 16/16 (`phase8_weather_source_checksums.json`) |
| Mouse preview / confirm gate / restore | ผ่าน (`phase8_weather_gui_results.json`) |

1. `tools/tests/Phase8WeatherScenario.server.luau` ตรวจตาราง 30 วันทุกนาที, night gates/rare forecast, event boundaries/late join/expiry/flags, fake atomic store revisions/API failure/dropped notification, Run rewards/caps จริง, Sakura crit จริง, Fog chest lifecycle จริง, online/offline garden & hatch และ catalog expansion. ไม่ publish global event ทดสอบจริง. รอบแรกคาด union mutation ผิดเป็น 18; เปลี่ยน assertion เป็น 16 ตาม catalog จริง แล้วผ่าน. ไม่มีการลดเกณฑ์พฤติกรรม.
2. Regression รันทีละชุดโดยพัก Leaderboard/LiveEvents และแยก Index buffs จาก baseline; ชุด Collections เปิดบัฟเองและคืน flag. ทุกชุด snapshot/restore profile/flags/weather/anchor/ตำแหน่ง/Balance. GUIHarness Finish แล้วเทียบ Currencies/Inventory/Progress/Index/Achievements/Rebirth/Garden/Quests ไม่ต่าง.
3. เมาส์แอดมินจริงเริ่ม preview ได้; สังเกต Clear pending→Sakura→Golden→Aurora, LIVE forecast/particles และ Aurora ClockTime=0. คำขอ global start ที่ไม่ confirm ถูกปฏิเสธว่า "ต้องกดยืนยัน 2 ชั้น". Studio MemoryStore read status ready; ยังไม่ใช่หลักฐานว่า publish/subscribe/cancel ข้ามหลายเซิร์ฟจริงผ่าน.
4. balance_sim.py baseline และ diff --check ผ่าน. Startup smoke ใหม่ Output ไม่มี error, กลับ Edit ไม่มี harness/scenario ค้าง; ไม่ overwrite ProfileStore. Plan/SKILL/HANDOFF อัปเดตพร้อมกัน.

## ค้าง Phase 8d2 และข้อจำกัด

1. Fog rare nests, Aurora shop eggs, Bloodmoon Secret eggs, Meteor Stardust pickups/การใช้, Rot world boss ทุก 2 ชม., ambient zone mutation, merchant/เทศกาล และเพดานขาย rare fruit ต่อวันยังไม่ทำ. Meteor ตอนนี้ให้ garden/pet mutation และภาพพื้นฐาน; Rot ให้ Rotten/growth เท่านั้น. ห้ามอ้างว่า Phase 8 หรือผลตาม weather table ทุกช่องเสร็จแล้ว.
2. Global Publish/Subscribe/Cancel ในหลายเซิร์ฟจริง, lower-rank account authorization, disconnect/API outage ระยะยาว, mobile/gamepad, เสียง/VFX สุดท้าย และ balance ผู้เล่นจริงยังรอตรวจ. Wind Area เพิ่มใน Tree.Hit แล้ว แต่ยังไม่มี scenario เปรียบเทียบ radius จริงโดยเฉพาะ. Night eligibility ใช้ UTC; night-only manual/Live Event ทำงานได้ทุกเวลาโดยเป็น override.
