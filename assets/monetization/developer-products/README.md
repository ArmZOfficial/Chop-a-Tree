# Chop a Tree — Developer Products

ครบ 17 สินค้าตาม plan 17.3. ภาพ PNG 512×512 วงกลม พื้นหลังโปร่งใส. กำหนดราคาฐานเริ่มต้นแล้ว; Product ID ยังไม่ได้กำหนด; ยังไม่ได้สร้างสินค้า/ตั้งขาย/ต่อ receipt ในเกม. ข้อความเป็นร่างสำหรับผลที่จะทำจริง ควรตรวจการให้รางวัลและกติกาบูสต์ก่อนเปิดขาย.

เปิด `gallery.html` เพื่อดูภาพและคัดลอกชื่อ/คำอธิบายไทย-อังกฤษ. ใช้ `icons/` สำหรับอัปโหลด. `products.json` เก็บรายการ; `prompts.json` เก็บ prompt จาก built-in imagegen; `validation.json` เก็บผลตรวจขนาด/alpha/hash.

## ราคาฐานเริ่มต้น (Robux)

| สินค้า | Robux |
|---|---:|
| 100 Gems | 19 |
| 550 Gems | 79 |
| 1,200 Gems | 149 |
| 6,500 Gems | 699 |
| 2x Wood — 15 Minutes | 19 |
| 2x Wood — 30 Minutes | 29 |
| 2x Coins — 15 Minutes | 19 |
| 2x Coins — 30 Minutes | 29 |
| 2x EXP — 15 Minutes | 29 |
| 2x EXP — 30 Minutes | 49 |
| 2x Luck — 15 Minutes | 39 |
| 2x Luck — 30 Minutes | 69 |
| Server Luck Boost | 99 |
| Instant Hatch | 39 |
| Instant Grow | 19 |
| Special Chest Key | 29 |
| Instant Base Lock | 19 |

ราคาเริ่มต้นสำหรับ Beta: แพ็ก Gems ใหญ่คุ้มขึ้นต่อ Robux, บูสต์ 30 นาทีถูกกว่าสองขวด 15 นาที, server Luck ราคา 99 เพราะช่วยทั้งเซิร์ฟ. ยังไม่ผ่านข้อมูลยอดซื้อ/retention หรือ balance Phase 10; ปรับตามข้อมูลจริง. ราคาของ Pass คงตาม plan 17.2, Season Premium ตาม plan 17.4 = 499 Robux.

เป็นราคาฐานสำหรับตั้งใน Creator Dashboard; หากเปิด Managed Pricing ราคาที่ผู้เล่นเห็นอาจต่างกัน ใช้ราคาจริงจาก MarketplaceService ในร้านเกม ([เอกสาร Roblox](https://create.roblox.com/docs/production/monetization/regional-pricing)).

## 100 Gems

ภาพ: [icons/01-gems-100.png](icons/01-gems-100.png)

**ไทย:** รับ Gems 100 เม็ดสำหรับใช้ใน Chop a Tree! เติมอัญมณีไว้ใช้กับระบบที่รองรับในเกม

**English:** Receive 100 Gems to spend in supported Chop a Tree systems!

## 550 Gems

ภาพ: [icons/02-gems-550.png](icons/02-gems-550.png)

**ไทย:** รับ Gems 550 เม็ดสำหรับใช้ใน Chop a Tree! เติมอัญมณีไว้ใช้กับระบบที่รองรับในเกม

**English:** Receive 550 Gems to spend in supported Chop a Tree systems!

## 1,200 Gems

ภาพ: [icons/03-gems-1200.png](icons/03-gems-1200.png)

**ไทย:** รับ Gems 1,200 เม็ดสำหรับใช้ใน Chop a Tree! เติมอัญมณีไว้ใช้กับระบบที่รองรับในเกม

**English:** Receive 1,200 Gems to spend in supported Chop a Tree systems!

## 6,500 Gems

ภาพ: [icons/04-gems-6500.png](icons/04-gems-6500.png)

**ไทย:** รับ Gems 6,500 เม็ดสำหรับใช้ใน Chop a Tree! เติมอัญมณีไว้ใช้กับระบบที่รองรับในเกม

**English:** Receive 6,500 Gems to spend in supported Chop a Tree systems!

## 2x Wood — 15 Minutes

ภาพ: [icons/05-wood-15.png](icons/05-wood-15.png)

**ไทย:** เปิดบูสต์ Wood ×2 เป็นเวลา 15 นาทีใน Chop a Tree! ซื้อซ้ำเพื่อต่อเวลา ไม่คูณความแรงซ้ำ ใช้ตามเพดานและกติกาบูสต์ของเกม

**English:** Activate a 2x Wood boost for 15 minutes in Chop a Tree! Repeat purchases extend duration rather than multiply boost strength. Game boost caps and rules apply.

## 2x Wood — 30 Minutes

ภาพ: [icons/06-wood-30.png](icons/06-wood-30.png)

**ไทย:** เปิดบูสต์ Wood ×2 เป็นเวลา 30 นาทีใน Chop a Tree! ซื้อซ้ำเพื่อต่อเวลา ไม่คูณความแรงซ้ำ ใช้ตามเพดานและกติกาบูสต์ของเกม

**English:** Activate a 2x Wood boost for 30 minutes in Chop a Tree! Repeat purchases extend duration rather than multiply boost strength. Game boost caps and rules apply.

## 2x Coins — 15 Minutes

ภาพ: [icons/07-coins-15.png](icons/07-coins-15.png)

**ไทย:** เปิดบูสต์ Coins ×2 เป็นเวลา 15 นาทีใน Chop a Tree! ซื้อซ้ำเพื่อต่อเวลา ไม่คูณความแรงซ้ำ ใช้ตามเพดานและกติกาบูสต์ของเกม

**English:** Activate a 2x Coins boost for 15 minutes in Chop a Tree! Repeat purchases extend duration rather than multiply boost strength. Game boost caps and rules apply.

## 2x Coins — 30 Minutes

ภาพ: [icons/08-coins-30.png](icons/08-coins-30.png)

**ไทย:** เปิดบูสต์ Coins ×2 เป็นเวลา 30 นาทีใน Chop a Tree! ซื้อซ้ำเพื่อต่อเวลา ไม่คูณความแรงซ้ำ ใช้ตามเพดานและกติกาบูสต์ของเกม

**English:** Activate a 2x Coins boost for 30 minutes in Chop a Tree! Repeat purchases extend duration rather than multiply boost strength. Game boost caps and rules apply.

## 2x EXP — 15 Minutes

ภาพ: [icons/09-exp-15.png](icons/09-exp-15.png)

**ไทย:** เปิดบูสต์ EXP ×2 เป็นเวลา 15 นาทีใน Chop a Tree! ซื้อซ้ำเพื่อต่อเวลา ไม่คูณความแรงซ้ำ ใช้ตามเพดานและกติกาบูสต์ของเกม

**English:** Activate a 2x EXP boost for 15 minutes in Chop a Tree! Repeat purchases extend duration rather than multiply boost strength. Game boost caps and rules apply.

## 2x EXP — 30 Minutes

ภาพ: [icons/10-exp-30.png](icons/10-exp-30.png)

**ไทย:** เปิดบูสต์ EXP ×2 เป็นเวลา 30 นาทีใน Chop a Tree! ซื้อซ้ำเพื่อต่อเวลา ไม่คูณความแรงซ้ำ ใช้ตามเพดานและกติกาบูสต์ของเกม

**English:** Activate a 2x EXP boost for 30 minutes in Chop a Tree! Repeat purchases extend duration rather than multiply boost strength. Game boost caps and rules apply.

## 2x Luck — 15 Minutes

ภาพ: [icons/11-luck-15.png](icons/11-luck-15.png)

**ไทย:** เปิดบูสต์ Luck ×2 เป็นเวลา 15 นาทีใน Chop a Tree! ซื้อซ้ำเพื่อต่อเวลา ไม่คูณความแรงซ้ำ ใช้ตามเพดานและกติกาบูสต์ของเกม ไม่รับประกันของหายาก

**English:** Activate a 2x Luck boost for 15 minutes in Chop a Tree! Repeat purchases extend duration rather than multiply boost strength. Game boost caps and rules apply. Rare drops are not guaranteed.

## 2x Luck — 30 Minutes

ภาพ: [icons/12-luck-30.png](icons/12-luck-30.png)

**ไทย:** เปิดบูสต์ Luck ×2 เป็นเวลา 30 นาทีใน Chop a Tree! ซื้อซ้ำเพื่อต่อเวลา ไม่คูณความแรงซ้ำ ใช้ตามเพดานและกติกาบูสต์ของเกม ไม่รับประกันของหายาก

**English:** Activate a 2x Luck boost for 30 minutes in Chop a Tree! Repeat purchases extend duration rather than multiply boost strength. Game boost caps and rules apply. Rare drops are not guaranteed.

## Server Luck Boost

ภาพ: [icons/13-server-luck.png](icons/13-server-luck.png)

**ไทย:** ส่งบูสต์ Luck ×2 ให้ทุกคนในเซิร์ฟเป็นเวลา 15 นาที พร้อมประกาศชื่อผู้ซื้อ! ช่วยเพื่อนร่วมป่าใน Chop a Tree ไม่รับประกันของหายาก

**English:** Give everyone in your server a 2x Luck boost for 15 minutes, with an announcement crediting you! Help your fellow forest adventurers. Rare drops are not guaranteed.

## Instant Hatch

ภาพ: [icons/14-instant-hatch.png](icons/14-instant-hatch.png)

**ไทย:** ข้ามเวลารอของไข่ที่เลือกในตู้ฟักและฟักทันที! ต้องมีไข่ที่รองรับอยู่ในตู้ฟัก การฟักทันทีไม่เปลี่ยนโอกาสได้สัตว์แต่ละชนิด

**English:** Skip the remaining wait for one selected eligible incubator egg! An eligible egg is required. Instant hatching does not change pet odds.

## Instant Grow

ภาพ: [icons/15-instant-grow.png](icons/15-instant-grow.png)

**ไทย:** ข้ามเวลารอเติบโตของต้นปลูกที่เลือกและให้โตทันที! ต้องมีต้นปลูกที่รองรับในสวน ไม่รับประกัน Mutation หายาก

**English:** Skip the remaining growth wait for one selected eligible garden crop! An eligible crop is required. Rare mutations are not guaranteed.

## Special Chest Key

ภาพ: [icons/16-chest-key.png](icons/16-chest-key.png)

**ไทย:** รับกุญแจหีบพิเศษ 1 ดอกใน Chop a Tree! ใช้เปิดหีบที่รองรับตามกติกาเกม ต้องมีหีบให้เปิด กุญแจไม่รับประกันของหายาก

**English:** Receive one Special Chest Key in Chop a Tree! Use it on a compatible chest under game rules. A chest is required. Rare rewards are not guaranteed.

## Instant Base Lock

ภาพ: [icons/17-base-lock.png](icons/17-base-lock.png)

**ไทย:** รีเซ็ตคูลดาวน์ล็อกฐานของคุณเพื่อให้ล็อกฐานได้อีกทันที! ใช้กับฐานของตัวเองตามกติกาเกม ไม่ใช่การล็อกถาวร

**English:** Reset your own base-lock cooldown so you can lock your base again immediately! Normal base-lock rules apply. This is not a permanent lock.
