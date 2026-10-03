"""Authored Thai for the October UI polish; run after locale_extract.py."""
import csv
from pathlib import Path

path=Path(__file__).resolve().parents[2]/'assets/localization/strings.csv'
translations={
    'After the daily limit: {1}× value':'หลังขายครบโควตารายวัน: รับมูลค่า {1} เท่า',
    'Arrives in {1} • Stays 10 min':'มาถึงใน {1} • อยู่ 10 นาที',
    'Come back later for special items':'กลับมาอีกครั้งเพื่อดูสินค้าพิเศษ',
    'Fruit selling':'ขายผลไม้',
    'Full-price sales left today':'โควตาขายเต็มราคาที่เหลือวันนี้',
    'Meet in Rootfall Village':'พบกันที่หมู่บ้านรูทฟอล',
    'Merchant is here':'พ่อค้ามาถึงแล้ว',
    'Merchant is on the way':'พ่อค้ากำลังเดินทางมา',
    'Merchant is resting':'พ่อค้ากำลังพัก',
    'No seeds yet':'ยังไม่มีเมล็ด',
    'Restocks in {1}':'เติมสินค้าใน {1}',
    'Seed shop':'ร้านเมล็ด',
    'Sold out':'ขายหมดแล้ว',
    'Special seeds, eggs and chests':'เมล็ด ไข่ และหีบพิเศษ',
    'Stock {1}':'เหลือ {1}',
    'Waiting for a base':'กำลังรอฐานว่าง',
    'Your garden opens when a base is free':'สวนจะพร้อมเมื่อมีฐานว่าง',
    '{1} • Stock {2}':'{1} • เหลือ {2}',
    'Chest chances':'โอกาสได้รับจากหีบ',
    'Drop chances':'โอกาสได้รับ',
    'One weapon per chest • Giant is a separate roll':'หีบละ 1 อาวุธ • สุ่มยักษ์แยกต่างหาก',
    'Find mutations':'ค้นหากลายพันธุ์',
    'Hatch eggs':'ฟักไข่',
    'Not found':'ยังไม่พบ',
    'Open forest chests':'เปิดหีบจากป่า',
    'Page {1} / {2}':'หน้า {1} / {2}',
    'Plant seeds':'ปลูกเมล็ด',
    '+1 Gem per discovery • Full set +50':'พบใหม่ +1 เพชร • ครบชุด +50',
    'No weapons yet':'ยังไม่มีอาวุธ',
    'Collect forest chests, then open them in the village':'เก็บหีบจากป่า แล้วเปิดที่หมู่บ้าน',
    'No chests yet':'ยังไม่มีหีบ',
    'Weapon stats':'ข้อมูลอาวุธ',
    'Equipped • Stats':'สวมอยู่ • ดูข้อมูล',
    'Fuse: combine 3 matching weapons':'หลอม: ใช้อาวุธแบบเดียวกัน 3 ชิ้น',
    'Max stars reached':'ดาวเต็มแล้ว',
    'Fuse cost':'ค่าหลอม',
    'Area':'ระยะฟัน',
    'Level':'เลเวล',
    'Rot':'พลังร็อต',
    'Stars':'ดาว',
    'Weapon level {1} • Giant is a separate roll':'อาวุธเลเวล {1} • สุ่มยักษ์แยกต่างหาก',
    'Tier {1} • {2}':'ดาว {1} • {2}',
}
internal={'Restock','Previous','Bottom','Position','Size','Top','Visible','{1}Edges'}
rows=list(csv.DictReader(path.open(encoding='utf-8')))
for row in rows:
    if row['key'] in translations: row['th']=translations[row['key']]
    if row['key'] in internal: row['note']='config';row['th']=row['key']
with path.open('w',encoding='utf-8',newline='') as stream:
    writer=csv.DictWriter(stream,fieldnames=['key','en','th','context','note'])
    writer.writeheader();writer.writerows(rows)
