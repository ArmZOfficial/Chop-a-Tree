# เอกสารอ้างอิง — อ่านเฉพาะงาน

เริ่มทุกงาน: [HANDOFF](HANDOFF.md) → [plan](plan.md) + [SKILL](../SKILL.md).
เลือกแถวที่เกี่ยวข้องแล้วอ่าน validation นั้น; ไม่โหลด docs ทั้งโฟลเดอร์/JSON ผลตรวจทั้งหมด.

| งาน | อ่านก่อนแก้ |
|---|---|
| แมพ/route/tags | [map](map_validation.md), [8 โซน](phase7_validation.md) |
| Run/Auto Cut/ต้นไม้ | [Phase 2](phase2_validation.md) |
| อาวุธ/หีบ/fuse | [Phase 3](phase3_validation.md), [weapon design](weapons.md) |
| สวน/mutation | [Phase 4](phase4_validation.md) |
| ไข่/สัตว์/ขโมย/ฐาน/Mount | [Phase 5](phase5_validation.md) |
| เควส/NPC/ศาลเจ้า/boss/warp | [Phase 6](phase6_validation.md) |
| Rebirth/reset/skills | [8a](phase8_rebirth_validation.md) |
| Daily/Codes/Boost/Leaderboard | [8b](phase8_rewards_validation.md) |
| Index/Achievements | [8c](phase8_collections_validation.md) |
| Weather/Live Event/global delivery | [8d1](phase8_weather_validation.md) |
| Stardust/weather eggs/world boss | [8d2](phase8_encounters_validation.md) |
| Ambient/merchant/rare fruit daily cap | [8d3](phase8_merchant_validation.md) |
| เทศกาล | [8e](phase8_festival_validation.md) |
| Emote/Photo | [8f](phase8_emote_validation.md) |
| ร้าน/receipt/Premium/ซีซัน | [8g](phase8_shop_season_validation.md); Config/Products, Config/Season |
| Balance | src/shared/Balance.luau + Config/BalanceConfig.luau; tools/balance_sim.py; [report](balance_report.txt) |
| ภาพ/listing/ราคาฐาน | [Pass](../assets/monetization/README.md), [Products](../assets/monetization/developer-products/README.md), [Premium](../assets/monetization/season-premium/README.md); ID จริงดู Config/Products |

## เมื่อรายละเอียดข้างบนไม่พอ

- [Design snapshot](archive/design-reference-2026-10-02.md): ค้นหัวข้อด้วย rg; หมวดเดิม §3 แมพ, §4 gameplay, §9 extras, §14 balance, §15 extension, §16 milestones, §17 monetization, §18 admin.
- [Technical guidance snapshot](archive/skill-reference-2026-10-02.md): seams/gotchas เฉพาะระบบ; เลือก heading ที่เกี่ยวข้อง.
- [History snapshot](archive/handoff-history-2026-10-02.md): สืบประวัติ/ผลรอบเก่าเท่านั้น.
- Snapshot เก็บต้นฉบับครบ; status เก่าอาจขัดกัน. สถานะปัจจุบันใช้ HANDOFF/โค้ด, intent ใช้ plan. เส้นทางใน snapshot อ้าง root เดิมของไฟล์ก่อนย้าย.
- JSON test results/checksums/screens อ่านเมื่อจำเป็นตรวจหลักฐาน; ไม่ใช่ startup context.
