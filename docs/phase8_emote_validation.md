# Phase 8f — Emote / Photo mode

ทดสอบ 2026-10-02 (เวลาไทย), Studio PlaceId `93479990217075`. Server scenario **5/5** + input จริงครบ; ยังไม่ได้ Publish.

## ระบบที่ใช้ได้

1. **วงล้อท่าทาง** (`EmoteController`, ปุ่ม "ท่าทาง (G)" คอลัมน์ซ้ายที่สอง x=200 y=245 หรือกด G): โบกมือ, เต้น, เต้น 2, ดีใจ, หัวเราะ, นั่ง, โชว์อาวุธ. ใช้แอนิเมชันจาก Animate script มาตรฐานของตัวละคร (replicate เอง); เต้นวนซ้ำและหยุดเมื่อเดิน.
2. **โชว์อาวุธ**: เล่นท่าดีใจ + ส่ง `EmoteAction("Showcase")`; EmoteService สร้างออร่า particle + แสงสีตามธาตุอาวุธที่สวม (ไม่มีธาตุใช้สีความหายาก, ไม่มีอาวุธเป็นสีขาว) นาน 3 วิ คูลดาวน์ 4 วิ; server เลือกสีเอง client ส่งแค่ action.
3. **โหมดถ่ายรูป** (ปุ่ม "ถ่ายรูป (P)" หรือกด P): ซ่อน ScreenGui ทั้งหมดและ CoreGui, กรอบขาว + ชื่อ "CHOP A TREE", ฟิลเตอร์ ปกติ/อนิเมะ/ซีเปีย/กลางคืน (ColorCorrection ฝั่ง client), กล้องอิสระ WASD/QE + คลิกขวาหมุน + Shift เร็ว (บล็อกการเดินระหว่างนั้น), H ซ่อนปุ่ม, P หรือปุ่มออก คืนสภาพเดิม.
4. Feature `Emotes` เปิด (ปิดแล้วซ่อนปุ่มและออกจากโหมดถ่ายรูป). Admin แท็บผู้เล่น `emote.aura` ทดสอบออร่ากับเป้าหมาย.

## ผลตรวจ

1. `tools/tests/Phase8EmoteScenario.server.luau` 5/5: สีตามอาวุธ, ออร่าเกิด, คูลดาวน์, หายใน 3 วิ, flag ปิด. ไม่เขียน profile.
2. Input จริง: G + คลิกเต้น ได้ track Action วนซ้ำ, กด W แล้วหยุด; คลิกโชว์อาวุธ ได้ CheerAnim + ออร่า replicate ถึง client; P เหลือแค่ PhotoHUD, CoreGui ปิด, กล้อง Scriptable, W/E ย้ายกล้อง 15.2 studs ตัวละครไม่ขยับ, คลิกฟิลเตอร์อนิเมะได้ค่าตรง; P อีกครั้งคืน ScreenGui 14 ตัวเดิม/CoreGui/กล้อง Custom. Admin `emote.aura` ผ่าน AdminRun. `phase8_emote_test_results.json`.
3. Source 7/7 ตรง Studio Edit, console ไม่มี error, ไม่มี test Script ค้าง.

## ข้อจำกัด

1. ท่าทางทุกท่าใช้ฟรี ยังไม่มีระบบปลดล็อก (หีบ/เควส/PvP/Season Pass/ร้าน) — เพิ่มพร้อมร้าน/Season Pass. ท่าโชว์เฉพาะ Legendary/Mythic และการหมุนอาวุธยังไม่ทำ (Phase 10).
2. มือถือใช้วงล้อและโหมดถ่ายรูปได้ แต่กล้องยังเป็นแบบหมุนรอบตัวปกติ (ไม่มี free cam บน touch). ยังไม่ได้ทดสอบอุปกรณ์จริง/gamepad. ไม่มีปุ่มบันทึกภาพ (ใช้ screenshot ของ Roblox).
