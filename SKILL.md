---
name: chop-a-tree-assets
description: Maintain the Chop a Tree plan, skill, and handoff together when updating project work; follow its gameplay-system seams including rebirth, rewards, Index buffs and achievements; choose and integrate Roblox Creator Store assets for its map, visuals, or gameplay systems.
---

# Creator Store สำหรับ Chop a Tree

## การอัปเดตเอกสารโปรเจกต์

ทุกครั้งที่อัปเดตงาน ให้ปรับทั้ง `docs/plan.md`, `SKILL.md` และ `docs/HANDOFF.md` ในงานเดียวกันให้สอดคล้องกับข้อมูลล่าสุด: plan บันทึกแผนและสถานะ, skill บันทึกแนวทางทำงานและข้อกำหนด, handoff บันทึกงานที่ทำแล้ว ผลตรวจ และงานถัดไป ตรวจทั้งสามไฟล์ให้ตรงกันก่อนสรุปว่างานเสร็จ (ArmZ สั่งเมื่อ 2026-10-01).

## ภาพและข้อความ Game Pass

ชุด 10 Pass ตาม plan 17.2 อยู่ที่ `assets/monetization/`: `icons/` เป็น PNG 512×512 วงกลม alpha โปร่งใส, `README.md`/`gallery.html` มีชื่อและคำอธิบายไทย/อังกฤษ, `passes.json` มีข้อมูลราคาในแผนและไฟล์ภาพ. สร้างภาพแยกหนึ่งภาพต่อ Pass ใช้เอกลักษณ์ป่า/สวน/ไข่/ขวานของ Chop a Tree; เก็บ prompt และตรวจขนาด/alpha ใน `prompts.json`/`validation.json`. ข้อความเป็นร่างสำหรับสิทธิ์ตามแผน: permanent bonus ชนิดเดียวกันใช้ค่าสูงสุด, Lucky เพิ่มจากโอกาสเดิมและไม่รับประกันดรอป, วาร์ปเคารพการปลดล็อก/ข้อจำกัดถือไข่. ก่อนใช้ขายต้องต่อและตรวจ entitlement จริง; ห้ามใส่ ID สมมติหรือถือว่าทำภาพแล้วระบบซื้อเสร็จ. งานชุดนี้ไม่ได้เปิด Shop/สร้าง Pass/เปิด Sales/Publish.

## ภาพและข้อความ Developer Product

เมื่อทำสินค้าแบบซื้อซ้ำตาม plan 17.3 ให้อ่าน `assets/monetization/developer-products/README.md` และ `products.json`: ชุด 17 รายการแยก Gems 4 แพ็ก, Wood/Coins/EXP/Luck 15/30 นาที 8 แบบ, server Luck 15 นาที, instant hatch/grow, key และ base lock. ใช้ `icons/` PNG 512×512 alpha และ prompt/validation ในโฟลเดอร์เดียวกัน. ราคา Beta กำหนดแล้วใน products.json/plan 17.3.1; ID เป็น null จนมีข้อมูลจริง; copy เป็นร่างที่ต้องตรวจผลและ receipt ก่อนขาย. จ่ายรางวัลจาก receipt ฝั่ง server แบบไม่ซ้ำ; ซื้อบูสต์ซ้ำต่อเวลาและเคารพเพดานเกม. เวลา server Luck 15 นาทีตามแผน; instant hatch/grow ใช้เป้าหมายที่รองรับ, key ต้องมีหีบ, base lock รีเซ็ตคูลดาวน์ของตัวเอง. งานภาพไม่ได้เปิด Shop หรือ Publish. ราคาในไฟล์เป็นราคาฐาน; ร้านเกมอ่านราคาจริงจาก MarketplaceService ฝั่ง client เมื่อรองรับ Managed Pricing ตามเอกสาร Roblox. ตรวจและปรับราคาเมื่อมีข้อมูล balance/ยอดซื้อจริง.

## Season Pass Premium

เมื่อสร้างหรือแก้ listing ซีซัน อ่าน `assets/monetization/season-premium/product.json`/README ตาม plan 17.4: ภาพ PREMIUM PNG 512×512 alpha, ราคา 499 Robux, copy ไทย-อังกฤษระบุสิทธิ์เฉพาะซีซันและเล่นเก็บเลเวล. ID 3715870274 (`Products.SeasonPremium`). ระบบอยู่ `SeasonService`/`Config/Season.luau`/`SeasonController`: เพิ่มซีซันใหม่ = เพิ่มแถวใน `Seasons` (id ใหม่ห้ามซ้ำ). XP มาจาก Stats delta ผ่าน DataService.Changed ซึ่งเป็น deferred → เทสต้อง `task.wait()` ก่อนอ่าน. Receipt ต้องไม่ yield; Premium ผูก `pendingFor` จาก prompt. ทดสอบด้วย `tools/tests/Phase8SeasonScenario.server.luau`; ข้อความไม่ได้รับประกันผ่านตัวกรอง Roblox.

## แนวทางต่อระบบอาวุธและ UI

1. อ่าน `docs/phase3_validation.md` ก่อนแก้ inventory/หีบ/อาวุธ. ให้ WeaponService เป็นเจ้าของการสุ่ม สวมใส่ หลอม และทิ้ง; ใช้ Loot + Balance คำนวณ Power และอัตราดรอปทั้ง UI/server จาก Config เดียวกัน.
2. เมื่อนำโมเดลอาวุธใหม่มาแทน procedural visuals ให้รองรับทั้ง Tool และ viewport preview; เก็บ Handle, WeaponId และ ForestAxe attributes, ขนาด Giant ×3 และไม่เปลี่ยน UID/definition ID ของของที่เซฟไว้.
3. ทดสอบเศรษฐกิจจาก Script ใน Play ที่ใช้ require cache เดียวกับเกม; snapshot/restore profile ทุกครั้ง เพราะ Studio เปิด DataStore จริง. อย่า require DataService ผ่าน MCP เพื่ออ่าน live state.
4. UI ที่อ้างไอเทมใหม่ต้องรองรับ DataPatch มาถึงหลัง RemoteFunction response. ตรวจปุ่ม modal ด้วย mouse จริง รวม ZIndex, การยืนยัน Fuse/Delete และการไม่ชน CoreGUI hotbar.
5. แยกงานภาพสุดท้ายไว้ใน Phase 10 ตามแผน: โมเดล/แสง/เสียง/VFX และปรับปรุง UI ทุกหน้าบนคอมพิวเตอร์/มือถือ. บันทึกข้อจำกัดของภาพปัจจุบันและสิ่งที่ยังไม่ได้ทดสอบให้ตรงกับ handoff.

## แนวทางต่อสวน อากาศ และ Phase 5

1. Phase 4 core ผ่าน 55 checks; อ่าน `docs/phase4_validation.md` ก่อนต่อไข่/สัตว์/ฐาน. GardenService จัด OwnerUserId/BaseIndex ของ 7 ฐานและสร้าง GardenSlots runtime 30 ช่อง; ใช้ ownership นี้ต่อ ไม่สร้างเจ้าของฐานอีกชุด.
2. สวนใช้ seed UID/source zone/Rot/admin และ timestamp ใน profile. รักษา offline growth แบบปกติ, ไม่มี mutation offline และไม่สะสม harvest หลายรอบย้อนหลัง. Inventory.Seeds/Fruits กับ Garden เพิ่มด้วย Reconcile v1 โดยไม่รีเซ็ตเซฟเดิม.
3. WeatherSchedule เป็นฟังก์ชัน UTC day/seed; ตรวจ midnight และ nextAt ด้วยตารางจริงเมื่อแก้ schedule. local admin override ต้องกลับ UTC ได้. อากาศทั้งหมด/Live Event ทุกเซิร์ฟต่อ Phase 8; art/เสียง/VFX และ **ปรับปรุง UI รวมสวน/อากาศ** ต่อ Phase 10.
4. สูตร mutation ยึดพิเศษสูงสุด × (1+ผลรวมค่าอื่น) ตาม plan 4.12.3; Apply รวม parent tags ก่อนคิดราคา. ห้ามเปลี่ยนสูตรจากคำบรรยาย ×2 โดยไม่ปรับ plan/report ให้ตรงกัน.
5. ทดสอบ Phase 4 ด้วย Script ใน VM เกมจริง และคืน profile/flags/อากาศ/Balance/anchor หลังจบ. GUIHarness ต้องสั่ง Finish ก่อน Stop. Regression Phase 2/3 ใช้ Clear เพื่อแยก weather จากสูตรที่กำลังตรวจ. อย่า overwrite ProfileStore ของ Studio.

## แนวทางต่อไข่ สัตว์ ฐาน และ Phase 6

1. Phase 5 core ผ่าน 81 checks; อ่าน `docs/phase5_validation.md` ก่อนแก้ไข่/สัตว์/ขโมย. PetService เป็นเจ้าของไข่ ตู้ฟัก สัตว์ คอก บัฟ Mount และสายพาน; StealService เป็นเจ้าของขโมย ล็อกฐาน โล่ และบอททดสอบ; NestService เป็นเจ้าของรังป่าและผู้พิทักษ์. ใช้ ownership ฐานของ GardenService (`Garden.BaseIndex/BaseById/OwnerOf`) ไม่สร้างชุดใหม่.
2. ไข่ที่ถูกขโมยต้องอยู่ใน profile เจ้าของ (`carriedBy`) จนส่งถึงฐานคนขโมย แล้วย้ายในเธรดเดียวไม่มี yield. ห้ามลบไข่ตอนเริ่มขโมย. ไข่ที่ถือจากรังจะได้ก็ต่อเมื่อถึงหินวาร์ปหรือกดปุ่ม End Run (`Run.End(player,true)`); ตาย/ออก/จบแบบอื่นคืนรัง.
3. บัฟสัตว์ผ่าน `Pet.Mult` เท่านั้น (Power เข้า `Balance.CutPower` petMult, Wood/EXP เข้า `Run.Award`) และต้องเคารพเพดาน ×4/×1.5. ความเร็วเดินคำนวณที่ `Pet.ApplySpeed` จาก AdminSpeed × Mount × บัฟ × CarryMult — ระบบใหม่ที่เปลี่ยน WalkSpeed ต้องผ่านจุดนี้.
4. UI ที่รีเฟรชจาก state packet ต้องอัปเดตปุ่มเดิมแทนการสร้างใหม่ (ดู `reuse` ใน PetController) ไม่งั้นคลิกหายระหว่างรีเฟรช. Humanoid.WalkSpeed เป็น float32 — เทียบในเทสต์ด้วย tolerance ≥1e-3.
5. ทดสอบขโมยด้วยฐานบอท/บอทขโมยจาก PetCommands จนกว่าจะมีผู้เล่นจริงหลายบัญชี; บันทึกผลหลายบัญชีลง handoff เมื่อได้ทดสอบ. Phase 6 ใช้ `Progress.StoryChapter` เปิดการขี่บทที่ 2 (บังคับเมื่อ Feature `Story` เปิด) และเพิ่มสัตว์/ไข่โซน 3–8 ใน Phase 7 เป็นแถว Config.

## แนวทางต่อเนื้อเรื่อง เควส บอส และ Phase 7

1. Phase 6 core ผ่าน 51 checks; อ่าน `docs/phase6_validation.md` ก่อนแก้เนื้อเรื่อง/เควส/บอส. QuestService เป็นเจ้าของเควสหลัก/รายวัน/สัปดาห์/Index, StoryService เป็นเจ้าของ NPC/ศาลเจ้า/ปลดโซน/วาร์ป, BossService เป็นเจ้าของผู้พิทักษ์. Progress ใช้คีย์สตริง (`Progress.Bosses["1"]`, `Progress.Shrines["1"]`).
2. ขั้นเควสแบบนับต้องอ่านส่วนต่างของ `Stats.*` — ระบบใหม่ที่อยากให้เควสนับ ให้เพิ่ม Stats ด้วย `Data.Increment` แล้วเพิ่มแถวใน Config.Story ไม่ต้องเรียก QuestService ตรง. เควสรายวัน/สัปดาห์สุ่มจาก UTC key เท่านั้น.
3. สูตรบอสอยู่ที่ `Balance.BossHP/BossRequiredPower` (BalanceConfig `BossHPMult/BossRewardMult` ตรงกับ `balance_sim.py`). บอสถูกสร้างเฉพาะโซน `built=true` — Phase 7 แค่เปลี่ยน `built` และสร้างโซน บอส/บท/วาร์ปจะทำงานเอง แต่ต้องเพิ่มไข่/สัตว์/บทพูดของโซนนั้น.
4. ประตูโซนเปิดที่ client จาก `Progress.UnlockedZones`; รางวัลทุกอย่างต้องตรวจ `Run.CanAccess` ที่ server เสมอ. UI ใหม่ที่ฝั่งขวาต้องไม่ชนพยากรณ์อากาศ (y 120–180) และ Run panel; ตัวติดตามเควสอยู่ซ้าย (y 475).

## แนวทางต่อโซน 3–8 และ Phase 8

1. อ่าน `docs/phase7_validation.md` ก่อนต่อ Phase 8. โซนทั้ง 8 เปิดใช้งานแล้ว; ไข่โซน 3–8 มาจากรัง/หีบ (`belt=0`). Catalog เดิม 42 ตัว; Phase 8d2 เพิ่ม Blood Raven เป็น 43 ตัว. บท 3–8 เล่นได้ด้วยแม่แบบเดิม; NPC เพิ่มเติม/บทพูดเฉพาะบท/คัตซีนยังค้างตาม validation.
2. ต้นไม้โซน 3–8 ใช้ `ServerStorage.MapAssets.Trees.<ZoneKey>` จาก `tools/map/AssetPrototypes.luau`; เก็บต้นแบบที่ตรวจแล้วใน place. ก่อนสร้างซ้ำจาก place ใหม่ ให้ใส่ asset ID ตาม `Prototypes.Sources` ใน `ServerStorage.AssetStaging`, เรียก Build/Report และยืนยัน scripts=0. ถ้าไม่มีต้นแบบ MapBuilder จะใช้ต้นไม้ Part เดิม.
3. รักษา Trunk โปร่งใสเป็น PrimaryPart/collider และ Look เป็นภาพที่ไม่ชน; ตรวจซ่อน/เกิดใหม่ด้วย TreeService. `BossArena.GuardianOffset` เลื่อนบอส 26 studs ไปด้านที่ห่างจากแนวทางเดิน (โซน 8 ไปด้านข้าง Lumora); BossService ใช้ offset นี้. ตรวจเส้นทางทั้ง Edit และ Play เพราะบอสเกิดตอน Play และรากอาจขวางทางแม้ Edit ผ่าน.
4. ZoneAmbience เป็น particle ฝั่ง client ตาม footprint เดียวกับ RunService.ZoneAt; ไม่แก้ Lighting หรือ mutation. รูปลักษณ์/เสียงเฉพาะโซนและอุปกรณ์จริงยังต้องตรวจใน Phase 10.

## แนวทาง Rebirth (Phase 8a)

1. อ่าน `docs/phase8_rebirth_validation.md` ก่อนต่อ Phase 8. RebirthService เป็นเจ้าของธุรกรรมวัฏจักร/ซื้อทักษะ; สูตรและราคาอยู่ RebirthMath + Config.Rebirth. บอสต้องเป็นผลงานในวัฏจักรปัจจุบัน; รีเซ็ตเควสหลักผ่าน Quest.ResetStory โดยคง Stats/Index/รายวัน/สัปดาห์.
2. ใช้ Prepare token ผูกผู้เล่น/R หมดอายุ 30 วิและใช้ครั้งเดียว; Confirm ตรวจเงื่อนไขซ้ำ. ซื้อทักษะส่ง expected rank ป้องกัน replay. Force ผ่าน AdminService เท่านั้น; ห้ามเพิ่ม yield ระหว่างเปลี่ยนเงิน/Token/ทักษะ/วัฏจักร.
3. คง UID ของ inventory/crops เมื่อรีเซ็ตความจุ. Pet.Trim ย้ายสัตว์เกินความจุกลับกระเป๋า; GardenState แยก visible slots จาก unlockedSlots. ต้นปลูกเหนือความจุยังเก็บผลได้ แต่ server ห้ามปลูกใหม่จนซื้อช่องคืน.
4. รวมบัฟ Wood friend/weather/pet/skill ไม่เกิน ×4 และ Coins friend/skill ไม่เกิน ×4; rewardMult ของบอสแยกจากเพดานบัฟ. AutoCut reward/ChestLevel ใช้ RunService เป็นจุดเดียว. ทักษะถาวรคงอยู่ทุกวัฏจักร; ราคาเป็นค่าตั้งต้นรอจูน Phase 10.
5. เทสต์ผ่าน Script ใน VM เกมจริงและ snapshot/restore profile/flags/weather/anchor; GUIHarness ต้อง Finish ก่อน Stop. ตรวจ modal ZIndex ด้วยภาพและคลิกจริง. Phase 8a ผ่าน 41 checks; Daily login/Codes/Leaderboard ทำแล้วใน Phase 8b ตามแนวทางด้านล่าง ยังไม่ถือว่าจบทั้ง Phase 8.

## แนวทางต่อ Daily, Codes, Leaderboard และ Phase 8c

1. อ่าน `docs/phase8_rewards_validation.md` ก่อนแก้รางวัล/อันดับ. DailyService เป็นเจ้าของวัน UTC/streak/claim, CodeService เป็นเจ้าของ normalize/expiry/stable redemption ID, RewardService เป็นจุดให้ Gems/หีบ/บูสต์; client ห้ามกำหนดเวลา/ราคา/รางวัล. เก็บ marker และรางวัลใน profile เดียว ไม่มี yield ระหว่างธุรกรรม.
2. Daily นับวันล็อกอินแม้ไม่รับของ; รับได้เฉพาะวันปัจจุบัน ไม่ย้อนหลัง, ขาดวันเริ่มใหม่และหลังวันที่ 7 วนรางวัล. Codes อยู่ Server.Config.Codes; เพิ่มโค้ดด้วย stable ID ใหม่และ UTC expiry. ห้าม reuse ID เก่าเพื่อให้ผู้เล่นรับซ้ำโดยไม่ตั้งใจ.
3. Boosts เป็น UTC expiry ใน profile และคงผ่าน Rebirth/reconnect; ต่อเวลา ไม่คูณ magnitude ซ้ำ. ผ่าน Run.Award และรวม Wood/Coins cap ×4. EXP/Luck ต้องต่อ seam ของระบบนั้นก่อนเพิ่ม row แจกบูสต์.
4. Leaderboard server-owned: อ่าน Stats/Progress/Pet.Income, ตัด Meta.AdminTouched, integer log encoding ใน LeaderboardMath และแสดง Global ≈. Score 0 เป็น tombstone ของ season; UpdateAsync ต้องรักษา 0 จาก stale writes. ไม่ล้าง provenance เพื่อให้คนกลับเข้าอันดับ. Client ขอ cache เท่านั้น; ห้ามให้ remote เปิดงาน DataStore refresh ตามการกด.
5. Studio ใช้ ChopBoards_Studio_v1_ แยกเกมจริง. ทดสอบ tombstone/failed API ด้วย fake store ไม่เขียนคะแนนทดสอบหรือ tombstone บัญชีจริงใน production. เทสต์ profile ต้อง snapshot/restore และ GUIHarness Finish ก่อน Stop. AttributeChanged เป็น deferred; รอ handler ทำงานก่อนตรวจจอ/ปุ่มที่เปลี่ยนตาม flag.
6. Phase 8b ผ่าน 45 checks + GUI และ Global API Studio; อ่าน validation สำหรับ regression/ข้อจำกัด. Phase 8c บัฟ Index/Achievements ทำแล้วตามแนวทางด้านล่าง; PvP ranking รอ Phase 9, UI/ภาพและ balance รอบใหญ่รอ Phase 10.

## แนวทาง Index buffs, Achievements และ Phase 8d

1. อ่าน `docs/phase8_collections_validation.md` ก่อนแก้ collection/Luck/title. QuestService เป็นเจ้าของ discovery และ completion marker; CollectionMath + Config.Progression เป็นสูตร/catalog ร่วม UI/server; AchievementService เป็นเจ้าของ Claim/Equip/RefreshTitle. สะสม ID จริงที่ไม่ใช่ admin_spawned เท่านั้น; คง marker ที่ปลดแล้วเมื่อขยาย catalog และเติม marker ที่หายของเซฟเก่าครบหมวดด้วยรางวัลครั้งเดียว.
2. Run.Power/Award และ Weapon.Open เป็นจุดใช้บัฟ. Wood/Coins รวม Index กับ Rebirth แบบบวก cap ×2 ถาวร ก่อนบัฟรวม ×4; Power รวม pet/Index cap ×4. Luck เพิ่มโอกาส Epic+ แบบสัมพัทธ์ cap +25%, probability ≤100%, Giant เดิม. Luck=0 ต้องคง baseline แบบตรงตัว; UI หีบใช้สูตรเดียวกัน.
3. Achievements.claimed/equipped อยู่ profile เดียวกับ Gems. ตรวจเกณฑ์ที่ server และบันทึก marker/เงินโดยไม่ yield; public remote รับ Sync/Claim/Equip เท่านั้น. ชื่อ title มาจาก Config, เลือกเฉพาะที่ claim แล้ว; RefreshTitle หลัง snapshot/CharacterAdded/flag change. Admin unlock/reset marksTarget; unlock ไม่จ่าย Gems.
4. Phase 8c ผ่าน 55 checks และ GUI เมาส์จริง; regression 36/51/41/45. VM scenario/GUIHarness ต้อง snapshot/restore และ Finish ก่อน Stop. พัก Leaderboard ระหว่างจำลอง profile; แยกเควสหลักเมื่อวัด Gems จาก achievement. Sync source ทีละไฟล์แล้วตรวจ UTF-8/LF length/hash เพื่อจับ output truncation ก่อน Play.
5. Phase 8d1 อากาศ/Live Event และ Phase 8d2 Stardust/ไข่พิเศษ/บอสโลกทำแล้วตามแนวทางด้านล่าง. Phase 8d3 ambient mutation/merchant/rare fruit daily cap ทำแล้ว; เทศกาล/ร้าน/Season Pass/Emote-Photo ยังเป็นงานค้าง Phase 8. Reconnect/respawn จริง/หลายบัญชี/มือถือ/gamepad และ balance ผู้เล่นจริงยังรอตรวจ.

## แนวทางอากาศ/Live Event หลัง Phase 8d1

1. อ่าน `docs/phase8_weather_validation.md` และ `docs/phase8_encounters_validation.md` ก่อนแก้อากาศ. WeatherSchedule เป็น UTC deterministic; rare forecast ซ่อน, night-only ใช้ UTC 18–06, Rainbow ต่อ Rain, weekend ใช้ UTC. RotInvasion เป็น overlay 10 นาทีแรกของทุก UTC block 2 ชม. ตาม Config.WeatherEncounters; weight=0 เพื่อไม่สุ่มซ้ำ ตรวจ forecast/midnight เมื่อแก้ตาราง.
2. WeatherService เป็นจุด resolve: feature Weather → Live Event → local override → UTC. LiveEventService owns MemoryStore current record/revision และ MessagingService reread + polling; late join อ่านขั้นตามเวลาเดิม. Studio แยก topic/store. Owner global start/stop confirm 2 ชั้นผ่าน AdminService; public remote ไม่มี Force และข้อความเป็น preset ที่เชื่อถือได้.
3. Wood/Coins อากาศรวม cap ×4 ผ่าน Run.Award; Area/crit/HP ผ่าน Tree.Hit, Fog chest ใช้ Run.CollectChest/provenance เดิม. Mutation สวนผ่าน GardenMath/Config.Mutations, hatch ผ่าน Pet.Advance online เท่านั้น; Index ใช้ union IDs ของผล/สัตว์และคง earned completion marker เมื่อขยาย catalog.
4. Phase 8d1 ผ่าน 38 checks, regression 55/81/51/36/55 และ mouse preview. API global transaction/missed-message ทดสอบ fake store; Studio read ready ไม่ใช่ proof broadcast หลายเซิร์ฟ. ก่อนสรุป global ready ต้องตรวจจริงหลายเซิร์ฟพร้อม API outage/cancel. Scenario/GUIHarness snapshot/restore, Finish ก่อน Stop, source checksum 16 ไฟล์ตรง Edit.
5. Phase 8d2 ผ่าน 59 checks และ GUI จริง; regression 36/81/51/23/55/38. Phase 8d3 ทำแล้วตามแนวทางด้านล่าง; เทศกาล/ร้าน/Season Pass/Emote และเสียง/ภาพ/VFX ยังแยกงานค้าง. ปรับ plan, SKILL, handoff พร้อมกันตามกฎเดิม.

## แนวทาง Stardust, ไข่พิเศษ และบอสโลก (Phase 8d2)

1. WeatherEncounterService owns runtime Stardust/world boss/weather nest lifecycle; Config.WeatherEncounters + EncounterMath ownsค่าเริ่มต้นและ payout. Stardust เก็บเข้าธนาคารทันทีด้วย server distance/Run/access/event key/TTL; ลบ pickup ก่อนจ่ายโดยไม่ yield. Exchange ที่แท่นใช้ Weapon.GrantChest และ Meta.AdminTouched provenance; public EncounterAction รับ Exchange เท่านั้น.
2. PetService owns Aurora purchase: ตรวจอากาศ/สายพาน/Coins/ความจุก่อนบันทึก marker + debit + GrantEgg ในเธรดเดียว. ใช้ Pets.weatherBought แยกจาก beltBought ซึ่งมี numeric epoch cleanup. Ledger คงผ่าน Rebirth/reload; ล้าง marker เก่ากว่า 7 วันเท่านั้น.
3. Nest.AddSpot/RemoveSpot ใช้ guardian เดิม. Take จับ definition ไว้กับ carrier และตรวจ WeatherKey ที่ server. เมื่ออากาศจบ retire spot; held egg ยัง Secure ด้วย ID เดิมได้, Drop ลบ spot. Callback refill ต้องตรวจ generation/registration/retired เพื่อไม่สร้างไข่หมดอายุคืนมา.
4. World boss ใช้ลานโซน 1 และ suppress guardian เดิมชั่วคราว; restore เมื่อจบ/ปิด flag. Boss.CreateWorld แยกจาก Boss.Get/Progress.Bosses. รางวัลตาม share ที่ clip ถึง HP เหลือ, paid marker ก่อนจ่าย, เฉพาะผู้เล่น loaded ที่ยังอยู่ Run เดิม; บันทึก Stats.WorldBossKills แยกจาก BossKills. บอสเกิดครั้งเดียวต่อ event key แม้ toggle flag; HP แยกตาม Rebirth ผ่าน Balance.BossHP.
5. ทดสอบ RemoteFunction ผ่าน InvokeServer จาก client จริง: Roblox อ่าน OnServerInvoke callback กลับไม่ได้. เทสต์ profile ใน Script VM พร้อม snapshot/restore และพัก AutoSave/Leaderboard; GUIHarness Finish ก่อน Stop. Source checksum 18 ไฟล์ตรง Edit; หลายบัญชี/reconnect จริง/แชร์ดาเมจต่าง Rebirth/มือถือ/ภาพสุดท้ายยังต้องตรวจตาม validation.

## แนวทางพ่อค้าเร่, ambient mutation และเพดานขายผล (Phase 8d3)

1. อ่าน `docs/phase8_merchant_validation.md` ก่อนแก้. MerchantService เป็นเจ้าของ visit/stock/ราคา/limit; MerchantMath + Config.Merchant ใช้ร่วม UI/server และเป็น UTC deterministic (นาที 30–40 ทุกชั่วโมง เพื่อไม่ชน RotInvasion). เพิ่มสินค้าด้วย offer id ใหม่ ห้าม reuse id. Summon ของแอดมินเป็น local ต่อเซิร์ฟ.
2. UI พ่อค้าอยู่ในแท็บของ Garden panel; GardenService รับ provider ผ่าน `Garden.SetMerchant` (Merchant โหลดหลัง Pet/Weapon เพื่อเลี่ยง require วน) และ forward `GardenAction("MerchantBuy")`. Buy ตรวจครบก่อนแล้ว marker+debit+grant ไม่ yield; ledger `Merchant.bought[visitKey]` prune เกิน 2 วัน.
3. Ambient roll อยู่ใน `Garden.Advance` ใช้ `plot.ambientSeen=nextFruitAt` ให้สุ่มครั้งเดียวต่อรอบผล ออนไลน์เท่านั้น และใช้ Mutation ID เดิม (เพิ่ม ID ใหม่ต้องดู catalog Index/completion marker).
4. ราคาขายผลต้องผ่าน `GardenMath.SellQuote` เท่านั้น (เพดานต่อวัน UTC ตาม mutation ที่ค่าสูงสุดใน `Config.Garden.SellCaps`, เกินได้ `OverCapMult`); `Garden.sellDay/sold` รีเซ็ตเมื่อวันเปลี่ยน. ห้ามเพิ่มทางขายผลที่ข้าม quote นี้.
5. ทดสอบด้วย Script ใน VM เกม + snapshot/restore; อย่า require service จาก MCP (cache แยก, เคยพลาดในรอบนี้). ค่าราคา/โอกาส/cap เป็นค่าเริ่มต้นรอ Phase 10.

## แนวทางเทศกาล (Phase 8e)

1. อ่าน `docs/phase8_festival_validation.md`. เทศกาลเป็นแถวใน `Config.Events` (UTC startsAt/endsAt, weather, nightOnly, mutation/chance); เพิ่มปีใหม่ด้วยแถวใหม่ ห้ามแก้วันย้อนหลัง. ลอยกระทงต้องตรวจวันตามจันทรคติ.
2. WeatherService เป็นจุดเดียวที่แปลงอากาศ (`festive` ใน `Weather.AtTime`): เปลี่ยนเฉพาะ Clear/อากาศธรรมดา, คงอากาศหายากและ RotInvasion, eventKey ขึ้นต้น `fest:`. Live Event และ override เซิร์ฟมาก่อนเทศกาล. ระบบใหม่ที่อ่าน mutation อากาศต้องใช้ `Weather.Def()` ไม่อ่าน Config.Weather ตรง.
3. Mutation ใหม่ของเทศกาลขยาย catalog Index; ปรับ fixture จำนวนในเทสต์เดิมให้ตรงข้อมูลจริงและคง completion marker. ของตกแต่ง/ของสะสมเทศกาลยังค้าง.

## แนวทาง Emote/Photo (Phase 8f)

1. อ่าน `docs/phase8_emote_validation.md`. EmoteController (client) เป็นเจ้าของวงล้อและโหมดถ่ายรูป; ท่าทางใช้ Animation จาก Animate script มาตรฐาน (replicate เอง). เอฟเฟกต์ที่คนอื่นต้องเห็นต้องสร้างที่ server (EmoteService) และ server เลือกค่าทั้งหมด client ส่งแค่ action.
2. ScreenGui ใหม่จะถูกซ่อนอัตโนมัติในโหมดถ่ายรูปและคืนค่า Enabled เดิมตอนออก; คอลัมน์ปุ่มซ้ายที่สอง x=200 ใช้แล้วที่ y 245/305.
3. เมื่อทำร้าน/Season Pass ให้เพิ่มระบบปลดล็อกท่าทางเป็นข้อมูลใน profile และตรวจที่ server ก่อนเล่นท่าพิเศษ; ท่าพื้นฐานคงฟรี.

## แนวทางที่ ArmZ อนุญาต (รายละเอียด)

ArmZ อนุญาตเมื่อ 2026-10-01 ให้เลือกของจาก Creator Store ที่เห็นว่าเหมาะสมและช่วยให้งานง่ายขึ้น แล้วนำมาใช้ในโปรเจกต์ได้เลย ไม่ต้องถามอนุญาตซ้ำสำหรับการนำ asset ที่เข้าถึงได้มาใช้ตามงานที่สั่ง แนวทางนี้แทนข้อกำหนดเดิมที่ให้สร้างโมเดลทุกชิ้นจาก Part เอง

เลือกใช้โมเดล ต้นไม้ หิน อาคาร ของตกแต่ง วัสดุ เสียง แอนิเมชัน หรือโมดูลที่ช่วยลดงานและเข้ากับธีม fantasy anime / low-poly ของเกม ปรับสี ขนาด และรายละเอียดให้กลมกลืนกับแมพ รักษาชื่อ เรื่องราว และเอกลักษณ์ของ Chop a Tree

## วิธีนำมาใช้

1. อ่าน `docs/HANDOFF.md` และส่วนที่เกี่ยวข้องของ `docs/plan.md` เพื่อรู้ระบบและผังปัจจุบัน เลือก asset ที่แก้ความต้องการของงานนั้นได้จริง ถ้าไม่เหมาะให้ใช้ของเดิมหรือสร้างเอง
2. ตรวจชื่อ ผู้สร้าง ชนิด และ asset ID จากผลค้นหาก่อนใส่ใน Studio ตรวจ descendant และโค้ดของ asset ในพื้นที่พักที่ไม่รันสคริปต์ก่อนย้ายเข้าแมพ ใช้เฉพาะโค้ดที่เข้าใจและจำเป็นกับงานนั้น
3. ปรับ Anchored, collision, ขนาด และจำนวน Part ให้เหมาะกับการเดินและ Streaming ของเกม เก็บ tags/attributes และโครงที่ระบบใช้อยู่ เช่น Tree, Zone, Tier, ChestSpot และ PlayerBase เมื่อนำโมเดลใหม่มาแทนของเดิม
4. ทำให้สร้างแมพซ้ำได้: เก็บต้นแบบที่ตรวจแล้วใน ServerStorage และอ้างอิงจากตัวสร้างแมพเมื่อใช้กับแมพที่สร้างด้วย MapBuilder บันทึก asset ID, ผู้สร้าง, ตำแหน่งต้นแบบ และสิ่งที่ปรับในเอกสารของงาน
5. ทดสอบส่วนที่ asset กระทบใน Play และตรวจ Output; ถ้าเปลี่ยนพื้นที่เดินให้ตรวจเส้นทางด้วย `tools/map/ValidateRoutes.luau` อัปเดต HANDOFF และ commit/push ตามแนวทางโปรเจกต์

การอนุญาตนี้ครอบคลุมการเลือกและนำ asset มาใช้ในงาน ไม่ใช่การซื้อของด้วย Robux หรือการ Publish เกมจริงโดยอัตโนมัติ
