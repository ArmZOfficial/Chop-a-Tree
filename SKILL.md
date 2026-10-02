---
name: chop-a-tree-assets
description: Work on Chop a Tree gameplay, Roblox assets, and project documentation.
---

# Chop a Tree — กฎทำงานสำหรับ AI

## เริ่มงานและจบงาน

1. อ่าน `docs/HANDOFF.md` (สถานะ), `docs/plan.md` (ขอบเขต); เลือกอ่านเอกสารเฉพาะงานจาก `docs/INDEX.md`.
2. ทุกงานอัปเดต **plan + SKILL + handoff ในงานเดียวกัน** (ArmZ 2026-10-01): เปลี่ยนเฉพาะข้อที่เกี่ยวข้อง ไม่เติมประวัติซ้ำ. handoff เก็บสถานะล่าสุด/ผลตรวจ/งานถัดไป; รายละเอียดผลตรวจอยู่ validation.
3. Commit/push งานที่จบตามสิทธิ์เดิม. **ไม่ซื้อ Robux/asset เสียเงิน และไม่ Publish โดยไม่มีคำสั่ง**. คอสเมติกให้รอ ArmZ สั่ง.
4. อ่าน systems เฉพาะ heading ของงาน; design เป็น spec snapshot ไม่ใช่สถานะล่าสุด. จบงานตรวจลิงก์และความสอดคล้องสามไฟล์.
5. ArmZ เปิด ponytail full + caveman full (2026-10-02): ใช้ของเดิม/stdlib, diff เล็ก, รายงานไทยสั้น; เอกสาร/โค้ดเขียนปกติ. ซีซันใหม่ใช้ ID ใหม่และช่วง UTC ต่อเนื่อง (มีถึง s3 จบ 2027-01-01 UTC); ทดสอบ rollover, pending receipt ข้ามซีซัน และวันหมดซีซันสุดท้ายด้วย scenario เดิม.

## กฎที่ใช้ทุกระบบ

- Server ตรวจ owner/access/ระยะ/ราคา/รางวัล; client ส่ง intent. ใช้ Service เจ้าของระบบเดิม และ Config/Balance เดิม.
- คง schema/UID/stable ID; เติมเซฟผ่าน Reconcile. ธุรกรรมย้ายของ/จ่ายรางวัลไม่ yield; receipt ตอบ Granted หลังยืนยันเซฟ และป้องกันจ่ายซ้ำ.
- ทดสอบ service ใน Script ของ VM เกม; MCP execute_luau ตอนนี้ require ModuleScript เกมไม่ได้ (Capabilities) ใช้ RemoteFunction ตรงจาก Client หรือวาง test Script ใน Edit; **อย่า require DataService ผ่าน MCP** (cache แยก). Snapshot/restore profile, flags, weather, Balance, anchor/ตำแหน่ง; GUIHarness Finish ก่อน Stop; ลบ test scripts. Run baseline แยก Pass/boost จากบัญชีจริงและปิด autosave/leaderboard. Import เรียก Pet.Advance แบบ deferred แม้ Eggs ปิด: รอ handler แล้วคืน Pets snapshot ก่อนตรวจ restore. **อย่า overwrite ProfileStore**.
- Studio API บันทึกข้อมูลจริง. ก่อนเขียน list Studios/ตรวจ PlaceId `93479990217075`; ID Studio เปลี่ยนได้. Sync ผ่าน MCP multi_edit แล้วเทียบ source checksum; Rojo ยังไม่ได้ใช้. ReceiptPersistenceScenario ใช้ Save → reconnect → Replay; เก็บ OriginalData นอก Play และยืนยัน SaveAndWait หลังคืนข้อมูล. Synthetic receipt ไม่ใช่ paid purchase.
- GUI ตรวจคลิกจริง/ZIndex/DataPatch มาช้า; state refresh ใช้ปุ่มเดิม. Inventory ต้องรับทั้ง `Purchases.passes` และ path ลูกเพื่ออัปเดต OpenTen ขณะเปิดอยู่. ตรวจ capacity ด้วย ShopGUIHarness.SetFreeSlots: หีบ/อาวุธ/Stats ต้องเปลี่ยนเท่าจำนวนที่เปิดได้จริง. DataService.Changed deferred: รอ handler ก่อน assert.
- เปลี่ยนสูตร/ตัวเลขรัน `tools/balance_sim.py`; ทดสอบส่วนที่กระทบและบันทึกสิ่งที่ยังไม่พิสูจน์. ใช้ RegressionHarness.Prepare/Finish ครอบ scenario เก่า (baseline ไม่มี Pass/boost); คืนข้อมูลแม้ test fail. Festival query เวลาอนาคตต้องไม่ล้าง preview ปัจจุบัน. ระบบใหม่เพิ่ม AdminService.Register และ Feature Flag.
- Auto Cut ฟรี; permanent bonus ชนิดเดียวกันใช้ค่าสูงสุด/เพดานร่วมกับทางฟรี. ใช้ seam Run.Award/Pet.Mult/Balance; รายละเอียด cap อ่าน validation ของระบบ.

- Player-facing text must be English (ArmZ 2026-10-02): menus, NPC dialogue, map signs, prompts, notifications, Admin and Arena. Keep legacy `.thai` metadata and Thai element keys for compatibility; display `.name`. Do not translate player names or stable IDs. Phase 10 artwork: `assets/ui/woodland-icons-v2.png`, imported image `121083844656821`; use per-icon bounds in Config/UIIcons (uploaded 1024 texture), never source-size grid guesses. Check actual Play screenshots, contrast/cropping/overlap and clicks before claiming visual completion.
- System UI uses shared UIKit.Window (wood/rim/heading/red X), live labels and modal blur; preserve server intents. Shop art/prices use GetProductInfo with atlas fallback; Index rebuilds on collection changes. Sound mute must restore original Volume, including new sounds; local Sound fixtures only. UI proof/remaining art in `docs/systems.md#phase-10-ui`.
- UI art assembly: read `assets/ui/elements-v1/UX.md` for screen coverage/layout/state rules; use sprites.json bounds and actual uploaded dimensions. Keep generated concepts as references, live labels/data separate; verify imported art in Play before claiming integration.
- Concept-matched UI parts: `assets/ui/elements-v2/README.md` + sprites.json; source dimensions vary by image. Bind pet/weapon illustrations to their listed IDs; retain real previews for the unillustrated catalog. Preserve alpha and use measured crops.

## Creator Store / ภาพ

- ArmZ อนุญาตเลือกและใช้ asset ที่เข้าถึงได้ตามงาน (2026-10-01), ปรับให้เข้าธีม; ตรวจผู้สร้าง/ID/descendants/scripts ใน staging ก่อนใช้งาน.
- คง tags/attributes/collider/ownership; เก็บ prototype ใน ServerStorage ให้ MapBuilder สร้างซ้ำได้. เปลี่ยนทางเดินตรวจ Edit+Play ด้วย `tools/map/ValidateRoutes.luau`.
- ภาพสินค้าอยู่ `assets/monetization/`; PNG 512×512 alpha, หนึ่งภาพต่อสินค้า. โค้ด Config/Products เป็นแหล่ง ID/รายการจริง; JSON/gallery เป็น listing assets อาจเป็น snapshot. ไม่รับประกันผ่าน text filter.
- Arena: Arena PlaceId ตั้งแล้ว (Universe เดียวกัน); คง PvP ปิดจนทดสอบ 2 บัญชีจริงผ่าน. TeleportData เป็น hint ไม่ใช่หลักฐานสิทธิ์/รางวัล; รางวัล Arena ผ่าน ledger `ArenaPending_v1` ที่เกมหลักจ่ายครั้งเดียวต่อ match id, Arena ไม่แตะ ProfileStore. Lobby test ใช้ RunArenaLobby.ps1 + Luau CLI; Place Arena (`135249057761883`) MCP inject/require ตอน Play ไม่ได้ ให้วาง test Script ใน Edit แล้ว Play; teleport จริงตรวจใน Player หลังได้รับคำสั่ง Publish.
- แนวทางเฉพาะระบบ: `docs/systems.md` (เลือก heading). Raw validation/history เรียก Git 5d09e37 เมื่อจำเป็น; docs คงเฉพาะ reference ที่ใช้งาน ไม่เพิ่ม archive ซ้ำ.
