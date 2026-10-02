# Localization glossary (EN → TH)

ใช้คำเดียวกันทั้งเกม. แหล่งจริงของคำแปล: `assets/localization/strings.csv` (UI) + ฟิลด์ `.thai` ใน Config (อาวุธ/สัตว์/เมล็ด/ไข่/โซน). เพิ่ม/แก้ → `python3 tools/locale_extract.py --check` (ต้อง missing_th=0) → `python3 tools/gen_strings.py` → sync `Config.Strings` เข้า Studio.

| English | ไทย | หมายเหตุ |
|---|---|---|
| Chest | หีบ | "{rarity} Chest" = หีบ{rarity} |
| Chest Altar / village station | แท่นหีบ / แท่นในหมู่บ้าน | |
| Fuse | หลอม | |
| Giant | ยักษ์ | GIANT! = ยักษ์! |
| Rarity: Common / Rare / Epic / Legendary / Mythic | ธรรมดา / หายาก / มหากาพย์ / ตำนาน / เทพนิยาย | |
| Power | พลัง | |
| Item Level (IL) | IL | คงตัวย่อ |
| Wood / Coins / Gems / Stardust | ไม้ / เหรียญ / เพชร / ผงดาว | |
| Run / Forest Run / End Run | ออกป่า / ออกป่า / จบรอบ | |
| Rebirth / Cycle | เกิดใหม่ / วัฏจักร | |
| Pet / Egg / Incubator / Pen | สัตว์เลี้ยง / ไข่ / ตู้ฟัก / คอก | |
| Mount / Dismount | ขี่ / ลงจากหลัง | |
| Garden / Seed / Plot / Harvest | สวน / เมล็ด / แปลง / เก็บเกี่ยว | |
| Mutation | การกลายพันธุ์ | |
| Index | สมุดสะสม | |
| Shrine / Warp stone | ศาลเจ้า / หินวาร์ป | |
| Rot | ความเน่า | Rot (ตัวคูณ) คงเป็น Rot |
| Boss / World Boss | บอส / บอสโลก | |
| Base / Lock Base | ฐาน / ล็อกฐาน | |
| Sprint | วิ่ง | Hold = กดค้าง, Toggle = กดสลับ |
| Auto Attack / Auto Cut | โจมตีอัตโนมัติ / ฟันอัตโนมัติ | |
| Season Pass / Premium | ซีซันพาส / พรีเมียม | |
| Game Pass | เกมพาส | ชื่อสินค้าใน Roblox ไม่ถูกแปลอัตโนมัติ |
| Arena / Ranked / Casual | สนามประลอง / จัดอันดับ / ทั่วไป | |
| Lumora | ลูมอรา | ชื่อเฉพาะ |
| Rootfall Village | หมู่บ้านรูทฟอลล์ | |
| Zones 1–8 | ทุ่งหญ้าแสงแดด, ป่าอำพัน, บึงเห็ดเรืองแสง, ที่ราบสูงซากุระ, ป่าไผ่สายฟ้า, หุบเขาน้ำแข็ง, สันเขาคริสตัล, ที่ราบสูงลูมอรา | จาก Config/Zones `.thai` |

ตัวเลข/สกุลเงิน/เวลาใช้ NumberFormat เดียวกันทั้งสองภาษา (5.19M, 3:01). ไม่แปลชื่อผู้เล่นหรือ stable ID.
