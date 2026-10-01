# Phase 8d3 — Ambient zone mutations, พ่อค้าเร่กระรอก, เพดานขายผลหายากต่อวัน

ทดสอบ 2026-10-02 (เวลาไทย), Studio PlaceId `93479990217075`. Scenario **30/30**, regression Phase4 **55/55**; ยังไม่ได้ Publish.

## ระบบที่ใช้ได้

1. **Ambient zone mutation** (`Config.Garden.Ambient`): ต้นในสวนที่ปลูกจากเมล็ดโซน 3/5/6 สุ่ม Misty/Wet/Chilled โอกาส 5% ครั้งเดียวต่อรอบผล (`plot.ambientSeen = nextFruitAt`) เฉพาะตอนเจ้าของออนไลน์. ไม่มี roll ออฟไลน์. ใช้ Mutation ID เดิม จึงไม่เปลี่ยน catalog Index (16 IDs). Combo เดิมทำงานต่อ เช่น Wet โซน 5 + Snow = Frozen. Zone 4 ซากุระไม่มีใน plan 4.12.1 ข้อ 7 จึงไม่ใส่.
2. **พ่อค้าเร่กระรอก** (MerchantService + Config.Merchant + MerchantMath): มาทุกชั่วโมง UTC นาทีที่ 30–40 (ไม่ชน RotInvasion นาที 0–10 ของทุก 2 ชม.). สินค้า 4 ชิ้นสุ่มแบบ deterministic จาก visit seed: เมล็ด Epic+ (Coins × ราคาร้าน × 1.5–2 ตามโซนร้าน), ไข่ Sunburst/Starlit/Mist (Coins × 1.2–1.5), หีบ Epic/Legendary LEVEL 10 (40/120 Gems). จำกัดต่อคนต่อ visit 1–2 ชิ้น. Server ตรวจ flag/stock/ระยะ 16 studs/นอก Run/ที่ว่างไข่/เงิน แล้ว marker+debit+grant ในเธรดเดียวไม่ yield; ledger `Merchant.bought[visitKey]` prune เกิน 2 วัน; คง admin provenance. NPC เป็น Part placeholder ที่ (-712, ground, 284) โผล่/หายตาม visit พร้อม ProximityPrompt; ประกาศ Notify ตอนมาถึง.
3. UI อยู่ใน Garden panel แท็บ "พ่อค้าเร่" (กด E ที่พ่อค้าเปิดแท็บนี้), ซื้อผ่าน `GardenAction("MerchantBuy", id)` ไม่เพิ่ม remote ใหม่. Feature `Merchant` เปิด. Admin แท็บอากาศ: `merchant.summon` (เฉพาะเซิร์ฟ 10 นาที, ของรอบใหม่) และ `merchant.dismiss`.
4. **เพดานขายผลต่อวัน** (`Config.Garden.SellCaps`): ผลที่มี mutation ในชุด Cosmic 5 / Celestial 10 / Rainbow 10 / Aurora 15 / Electrified 15 ต่อวัน UTC ได้ราคาเต็ม; เกินได้ ×0.1. ผลนับตาม mutation ที่ค่าสูงสุดในชุด. `GardenMath.SellQuote` ใช้ร่วม server/UI; `Garden.sellDay/sold` รีเซ็ตเมื่อวันเปลี่ยน. ผลที่ไม่มี mutation ในชุดราคาเดิมทุกอย่าง. แท็บร้านแสดงโควตาเหลือ.
5. Schema v1 เติม `Garden.sellDay/sold` และ `Merchant.bought` ด้วย Reconcile; ไม่เปลี่ยน store.

## ผลตรวจและหลักฐาน

1. `tools/tests/Phase8MerchantScenario.server.luau` 30/30: schema, ตาราง 2 วันทุกนาที/ไม่ชน Rot/next arrival, stock deterministic, cap key/quote/วันใหม่/วันเดิม, ambient ออฟไลน์/โอกาส/โซน 1/ครั้งเดียวต่อรอบ, merchant flag/summon/ระยะ/stock ผิด/id ผิด/Run/ราคา/grant/limit/provenance/เงินไม่พอไม่มี marker/prune/dismiss และ Balance SelfTest. `phase8_merchant_test_results.json`.
2. Regression Phase4 (สวน/อากาศ) 55/55 — `phase8_merchant_regression_results.json`. ชุดอื่นไม่ได้รันซ้ำเพราะไม่แตะโค้ดส่วนนั้น (Pet/Weapon ถูกเรียกผ่าน API เดิมเท่านั้น).
3. GUI จริง: summon ผ่าน client `AdminRun` (Owner), กด E เปิดแท็บพ่อค้า, คลิก Sunburst 3 ครั้ง ได้ไข่ 2 ใบ หัก 12,000 Coins ครั้งที่ 3 ถูกปฏิเสธ; ขาย Cosmic 7 ลูกได้ +78,520 (5 เต็ม + 2 × 0.1) โควตา Cosmic 5/5→0/5. Harness Finish คืน profile ไม่ต่าง. `phase8_merchant_gui_results.json`.
4. Source 11/11 ตรง Studio Edit (`phase8_merchant_source_checksums.json`), startup smoke ไม่มี error, ไม่มี test Script ค้าง. ไม่แก้สูตร Balance จึงไม่ต้องรัน balance_sim.py ใหม่. ระหว่างทดสอบเคย require MerchantService จาก MCP โดยตรงแล้ว error (cache แยก — ตามคำเตือนใน HANDOFF) ไม่ได้แตะข้อมูล.

## ข้อจำกัดและงานถัดไป

1. Summon เป็น local ต่อเซิร์ฟ ไม่ broadcast; ตาราง UTC ตรงกันทุกเซิร์ฟเอง. ซื้อแล้ว server hop ใน visit เดียวกันยังโดน limit เพราะ ledger อยู่ profile.
2. โมเดลกระรอก/บทพูดต่อราคา/เสียง/VFX, ราคาและอัตราสุ่ม, ค่า cap/×0.1 เป็นค่าเริ่มต้นรอจูน Phase 10. Ambient ยังไม่มีผลกับไข่/สัตว์.
3. หลายบัญชี/มือถือ/gamepad/reconnect ยังไม่ได้ตรวจ. งาน Phase 8 ที่เหลือ: อีเวนต์เทศกาล, ร้านเติมเงิน + Season Pass, Emote/Photo.
