# Phase 8e — อีเวนต์เทศกาล

ทดสอบ 2026-10-02 (เวลาไทย), Studio PlaceId `93479990217075`. Scenario **15/15**, regression Weather **38/38**; ยังไม่ได้ Publish.

## ระบบที่ใช้ได้

1. `Config.Events` ตั้งวันเริ่ม/จบเป็น UTC ล่วงหน้า (plan 4.12.6): ฮาโลวีน 2026-10-25→11-02 (Bloodmoon ทุกคืน 18:00–06:00 UTC), ลอยกระทง 2026-11-23→26 (Aurora กลางคืน; วันตามจันทรคติ ต้องตรวจทุกปี), คริสต์มาส/ปีใหม่ 2026-12-20→2027-01-03 (หิมะทั้งวัน), สงกรานต์ 2027-04-12→17 (ฝนทั้งวัน + Mutation **Splash** ×6 แทน Wet โอกาส 25%).
2. WeatherService ซ้อนชั้นเทศกาลบนตาราง UTC (ลำดับ: Live Event → override เซิร์ฟ → เทศกาล/UTC). เปลี่ยนเฉพาะ Clear และอากาศธรรมดา; อากาศหายากและ RotInvasion คงเดิม. eventKey ขึ้นต้น `fest:<id>:` จึงสุ่ม mutation ใหม่ทุกช่วง; forecast แสดงอากาศหลังแปลง. ผลป่า/สวน/ไข่ใช้ seam เดิม เช่น Bloodmoon ฮาโลวีนได้รางวัล ×4 และรังไข่ Secret ทุกคืน.
3. `Weather.Def(state)` แทน mutation/chance ตามเทศกาล; `Weather.AtTime(now)` ใช้กับ forecast/เทสต์. Splash เข้า catalog Index (mutation รวม 17); completion marker เดิมคงอยู่ตามกฎ Phase 8c.
4. Feature `Festivals` เปิด. Admin แท็บอากาศ: `festival.<id>` ทดลองเทศกาลเฉพาะเซิร์ฟ 10 นาที และ `festival.clear`; garden admin มี `garden.Splash` อัตโนมัติ. Badge พยากรณ์ขึ้นต้น "เทศกาล <ชื่อ>".

## ผลตรวจ

1. `tools/tests/Phase8FestivalScenario.server.luau` 15/15: config, ทั้งวันสงกรานต์ทุกนาที (ฝน/คงหายากและ Rot/forecast/Splash), ฮาโลวีนคืน-วัน, นอกช่วง, preview/flag/clear, Balance SelfTest. ไม่แตะ profile.
2. GUI: client `AdminRun festival.winter` → badge "เทศกาล คริสต์มาส/ปีใหม่ • หิมะตก", id=Snow; `festival.clear` คืนตารางปกติ.
3. Regression `Phase8WeatherScenario` 38/38 หลังปรับ fixture จำนวน mutation 15→16 และ union 16→17 (เพิ่ม Splash จริง). Source 6/6 ตรง Studio Edit, startup ไม่มี error, ไม่มี test Script ค้าง.

## ข้อจำกัด

1. ของตกแต่งเทศกาล (ปืนฉีดน้ำ, ฟักทองยักษ์ให้ฟัน, ต้นสนของขวัญ, โคมลอย) และของสะสมเฉพาะเทศกาลยังไม่ทำ — ต่อ Phase 10 หรือเมื่อ ArmZ ต้องการ. Splash ยังไม่มีเวอร์ชันสัตว์.
2. Preview เป็น local ต่อเซิร์ฟ; การเปลี่ยนกลางคืน/กลางวันระหว่างช่วงอากาศเดียวกันอาจทำให้ forecast ไม่ตรงชั่วคราว. ตั้งวันปีถัดไปต้องเพิ่มแถวใหม่ใน Config.Events.
