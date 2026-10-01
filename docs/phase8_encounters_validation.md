# Phase 8d2 — Stardust, special eggs, world boss

ทดสอบ 2026-10-02 (เวลาไทย), Studio PlaceId `93479990217075`. Scenario **59/59**; ยังไม่ได้ Publish.

## ระบบที่ใช้ได้

1. WeatherEncounterService: Meteor pickups โซน 1 ทุก 20 วิ, +5 Stardust, TTL 90 วิ, สูงสุด 12 จุด. เก็บด้วย E/server prompt ระหว่าง Run ต้อง alive/ใกล้ 10 studs/ปลดโซน/อยู่โซน/event key ปัจจุบัน. ลบก่อนจ่ายโดยไม่ yield; bank ทันทีและคงเมื่อ Run ล้ม/Rebirth. เมื่ออากาศจบ/feature off/TTL หมด ลบ pickups. ภาพเป็นลูกทรงกลม Neon ชั่วคราว.
2. Inventory UI ที่แท่น: แลก 20 Stardust = Rare LEVEL 1 IL 1 ผ่าน Weapon.GrantChest. ตรวจ Chests/Weather/WeatherEncounters/profile/ระยะ/นอก Run ก่อน debit. Server เลือกราคา/รางวัลทั้งหมด, คง admin provenance. Public EncounterAction มี Exchange เท่านั้น, throttle 0.35 วิ.
3. Fog และ Bloodmoon เพิ่ม weather spot ในรังโซน 1 ที่มี guardian เดิม; ใช้ Take/carry/ช้า/Drop/Secure/End Run. Capture definition ตอนหยิบ; retire เมื่ออากาศจบแต่ยังส่งไข่ที่ถือได้ และ Drop ไม่เติม expired spot คืน. Fog pool Legendary/Mythic/Secret; Bloodmoon pool Secret เท่านั้น (Lumora Kit/Blood Raven). ไข่พิเศษไม่เข้า normal belt/nest pools. Pets catalog เพิ่ม 42→43; completion markers ที่ได้รับแล้วคงเดิม.
4. Aurora Egg ที่สายพาน: 100K Coins, hatch 30 นาที, หนึ่งใบต่อ event key. ตรวจอากาศ/ระยะ/นอก Run/พื้นที่ไข่/Coins ก่อน marker+debit+GrantEgg ไม่มี yield. Pets.weatherBought แยกจาก numeric beltBought, คงหลัง reload/Rebirth, prune อายุเกิน 7 วัน. ไข่ carry ใช้ admin provenance เดิม.
5. Rot UTC: ทุก 2 ชม. นาน 10 นาที, overlay ตาราง deterministic (weight=0). Forecast/endAt ถูกตัดตามรอบ Rot และ rare ซ่อน ???; Live Event/local override ยังมี priority เดิม. World boss ใช้ลาน guardian โซน 1 (suppress normal tag/collision/ภาพ) ชั่วคราวและคืนหลังจบ. HP = Balance.BossHP(1,R) ×8, shared normalized ratio ต่อเซิร์ฟ; manual CHOP/AutoAttack ใช้ cooldown/Run/alive/access/ระยะจริง.
6. World reward pool = 1,000 Gems/100 Stardust, share ขั้นต่ำ 0.1%, floor ตามดาเมจ normalized ที่ clip ถึง HP เหลือ. ผู้เล่นต้อง loaded และยังอยู่ Run เดิมตอน defeat. paid marker ก่อนจ่าย, world spawn ครั้งเดียวต่อ event key; ไม่รีเซ็ตจาก flag toggle. Stats.WorldBossKills แยกจาก BossKills/Progress.Bosses จึงไม่ปลด shrine/เรื่อง/Rebirth แทน guardian.
7. Schema v1 เพิ่ม Pets.weatherBought/Stats.WorldBossKills ด้วย Reconcile; ไม่เปลี่ยน store. Feature WeatherEncounters เปิด. Owner weather commands `encounters.refresh`, `stardust.give` (+20, usesTarget/marksTarget). ค่าราคา/ดรอป/HP/รางวัลเป็นค่าเริ่มต้นสำหรับ Phase 10.

## ผลตรวจและหลักฐาน

1. `tools/tests/Phase8EncounterScenario.server.luau` 59/59: reconcile/catalog/Secret-only, UTC overlay 2 วันทุกนาที/forecast จริง, payout budget/invalid share, pickup ระยะ/Run/access/replay/expired key/TTL/cap/feature/failed Run, exchange insufficient/range/active/ราคา/provenance/feature, held egg expiry/secure/drop/stale request, Aurora price/capacity/active/replay/reload/Rebirth/feature, world share/cooldown/kill/reward once/story isolation/cleanup และ Balance SelfTest. `phase8_encounters_test_results.json`.
2. Regression เดิม: Phase3 **36/36**, Phase5 **81/81**, Phase6 **51/51**, Phase7 **23/23**, Phase8Collections **55/55**, Phase8Weather **38/38**. Phase7 count fixture เปลี่ยน 42→43 เพราะเพิ่ม pet จริง; assertions พฤติกรรมเดิมคงไว้. Weather เดิมตรวจตาราง 30 UTC วันรวม midnight/night gates/Rainbow และ forecast. `phase8_encounters_regression_results.json`.
3. GUI จริง: mouse แลก 20→0 Dust + Rare 1, ซื้อ Aurora 100K→0 Coins + egg_aurora 1; คลิกซ้ำยัง 1 ใบ/ไม่ debit. Keyboard E เก็บดาว +5; mouse CHOP ทำ world ratio 1→0.9999791666666666 และ bar แสดง 48M HP. Public Force rejected; Owner grant +20/Meta.AdminTouched และ usesTarget metadata ผ่าน actual InvokeServer. Capture IDs ใน `phase8_encounters_gui_results.json`.
4. GUIHarness Finish คืนข้อมูลแล้ว เทียบ Currencies/Inventory/Pets/Progress/Index/Achievements/Rebirth/Garden/Quests/Meta ไม่ต่าง. คืน flags/weather/ตำแหน่ง/anchor/Balance/กล้อง. Tests ใช้ game VM require cache; ไม่ require DataService ผ่าน MCP และไม่ overwrite ProfileStore. เพิ่ม remote assertions ครั้งแรกผิดที่อ่าน OnServerInvoke (Roblox setter-only); ย้าย proof เป็น actual client InvokeServer แทน, scenario 59 ข้อเดิมผ่าน.
5. Source 18/18 UTF-8/LF length/hash ตรง Studio Edit; `phase8_encounters_source_checksums.json`. Fresh startup smoke ไม่มี error และไม่มี test Script ค้าง. balance_sim.py baseline/diff --check ผ่าน. Plan ร่าง 14, SKILL และ HANDOFF อัปเดตพร้อมกัน.

## ข้อจำกัดและงานถัดไป

1. บอสโลก/รางวัลเป็นต่อเซิร์ฟ; ไม่มี shared HP ข้ามเซิร์ฟ. ผู้เล่น disconnect/จบ Run/เริ่ม Run ใหม่ก่อน defeat ไม่รับ payout ของ Run เก่า และไม่มี pending reward สำหรับ disconnect. Server restart ได้ world state ใหม่; ยังไม่ได้ทดสอบ server-hop/หลายบัญชี/ต่าง Rebirth/ออกระหว่างจ่ายจริง. Pure math split + hit/payout ในหนึ่งบัญชีผ่าน ไม่ใช่ proof multiplayer production.
2. Reload/Rebirth ผ่านจาก profile import/service จริง; reconnect/respawn จริง/mobile/gamepad ยังไม่ได้ตรวจ. Global Live Event broadcast/API outage หลายเซิร์ฟยังค้างตาม Phase8d1. Meteor เป็น pickups ในโซน 1, world ใช้โมเดล guardian เดิม; art/เสียง/VFX/ห้องบอสเฉพาะ/UX อุปกรณ์จริงและ economy ผู้เล่นจริงรอ Phase10.
3. ต่อ **Phase 8d3 ambient zone mutations/merchant/rare fruit daily cap**. เทศกาล/ร้าน/Season Pass/Emote-Photo ยังแยกงานค้าง Phase8; ไม่ถือว่าจบทั้ง Phase.
