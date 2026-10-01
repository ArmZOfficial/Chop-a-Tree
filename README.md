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
| `tools/gen_config.py` | แปลง `data/*.json` → `src/shared/Config/*.luau` |
| `src/` | โค้ดเกม (เริ่มใน Phase 0, ซิงก์เข้า Studio ด้วย Rojo) |

## คำสั่งที่ใช้บ่อย

```bash
python3 tools/balance_sim.py > docs/balance_report.txt   # เช็ค Balance
python3 tools/gen_weapons.py                             # สร้างรายการอาวุธใหม่
```

## โครงโค้ด (Rojo)

| ในเกม | โฟลเดอร์ |
|---|---|
| `ReplicatedStorage.Shared` | `src/shared` — Config, NumberFormat, Balance, Net, UIKit |
| `ServerScriptService.Server` | `src/server` — Main, Services, AdminCommands, Packages (ProfileStore) |
| `ServerStorage.AdminUI` | `src/admin` — Admin Panel (ส่งให้เฉพาะคนมียศ) |
| `StarterPlayer.StarterPlayerScripts.Client` | `src/client` — ClientData, HUD, AdminEffects |

ซิงก์เข้า Studio: ลง [Rojo](https://rojo.space) แล้วรัน `rojo serve` ในโฟลเดอร์นี้ → กด Connect ใน Rojo plugin

แก้ `data/weapons.json` แล้วรัน `python3 tools/gen_config.py` เพื่อสร้าง `src/shared/Config/Weapons.luau` ใหม่

## สถานะ

Phase 0 (ฐานราก) เสร็จ — ถัดไป Phase 1: แมพโครง
