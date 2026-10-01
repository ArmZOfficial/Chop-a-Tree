# Chop a Tree

เกม Roblox แนวฟันต้นไม้ + ปลูกสวน + ขโมยไข่ มีเนื้อเรื่อง แมพเดียวขนาดใหญ่ไต่ขึ้นเขา 8 โซน

## ไฟล์ในนี้

| ที่อยู่ | คืออะไร |
|---|---|
| `docs/plan.md` | แผนเกมหลัก (ทุกระบบ, แมพ, เนื้อเรื่อง, Balance, เติมเงิน, Milestone) |
| `docs/weapons.md` | รายชื่ออาวุธ 100 ชิ้น |
| `docs/balance_report.txt` | ผลจำลองตัวเลขล่าสุด |
| `data/weapons.json` | ข้อมูลอาวุธ (ต้นทางของ Config ในเกม) |
| `tools/balance_sim.py` | ตัวจำลอง Balance — รันใหม่ทุกครั้งที่แก้ตัวเลข |
| `tools/gen_weapons.py` | สร้าง `docs/weapons.md` + `data/weapons.json` |
| `src/` | โค้ดเกม (เริ่มใน Phase 0, ซิงก์เข้า Studio ด้วย Rojo) |

## คำสั่งที่ใช้บ่อย

```bash
python3 tools/balance_sim.py > docs/balance_report.txt   # เช็ค Balance
python3 tools/gen_weapons.py                             # สร้างรายการอาวุธใหม่
```

## สถานะ

ร่างแผนครบ (ร่างที่ 5) — ขั้นต่อไป Phase 0: ฐานราก (Config Registry, ระบบเซฟ, Rojo)
