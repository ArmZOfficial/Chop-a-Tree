# Docs — อ่านเฉพาะงาน

เริ่ม: [HANDOFF](HANDOFF.md) → [plan](plan.md) + [SKILL](../SKILL.md). อย่าโหลดเอกสารทั้งหมดพร้อมกัน.

| ไฟล์ | ใช้เมื่อ |
|---|---|
| [HANDOFF](HANDOFF.md) | สถานะ/ผลตรวจล่าสุด/งานถัดไป |
| [plan](plan.md) | scope/backlog/กฎ product |
| [systems](systems.md) | seam/gotcha ของระบบที่จะเปลี่ยน; เลือก heading |
| [Map scripting](map-systems.md) | Zones/ประตู/แผนที่/วาร์ป/DayCycle/Explorer v3, balance, ผล Studio QA/7ฐาน, mock mode และข้อจำกัด |
| [Shop + Season](phase8_shop_season_validation.md) | receipt/Premium/ซีซันและข้อจำกัดล่าสุด |
| [design](design.md) | ต้องการ spec เต็ม/การตัดสินใจเดิม; ค้นหัวข้อ §3/4/9/14–18 |
| [weapons](weapons.md) | design อาวุธ100ชิ้น; runtimeดู Config/Weapons |
| [localization glossary](localization-glossary.md) | คำศัพท์ไทย/อังกฤษ + ขั้นตอนเพิ่มข้อความ |
| [balance report](balance_report.txt) | ผลจำลอง; regenerateด้วย tools/balance_sim.py |
| [sword-pack-migration](sword-pack-migration.md) | ตาราง legacy wpn → swd (แทร็ก B) |
| [UX audit](../assets/ui/UX-audit.md) | ผลตรวจ UI 4 ขนาดจอ/จอย/ไทย + สิ่งที่ค้าง (แทร็ก C) |
| [elements-v3](../assets/ui/elements-v3/README.md) | หีบ 5 ระดับ/ไอคอน/บันได asset 2D (แทร็ก D/E) |

Config/Service/Scenarioใน src/ และ tools/tests/ เป็น implementation/วิธีตรวจ. IDจริงดู Config/Products.
ภาพ/listing: assets/monetization/ (Pass), developer-products/, season-premium/.
Raw JSON/screens/validationเก่าก่อน cleanupเรียกจาก Git commit `5d09e37` เฉพาะเมื่อสืบหลักฐาน. ไม่เก็บ archiveซ้ำใน docs.
