class_name ShopItemData
extends Resource
## ===================================================
## ShopItemData — ข้อมูลสินค้าในร้านค้า
## ===================================================
## วิธีใช้: สร้างไฟล์ .tres ใหม่ใน Godot แล้วลากใส่ Array shop_items ของ ShopUI
## ไม่ต้องแก้โค้ดเพื่อเพิ่ม/ลด สินค้าอีกต่อไป!

## รหัสอ้างอิงที่ไม่ซ้ำกัน (ใช้สำหรับนับจำนวนการซื้อ)
@export var id: StringName

## ชื่อสินค้าที่แสดงบนปุ่ม
@export var title: String = "ชื่อสินค้า"

## คำอธิบายผลของสินค้า (แสดงเป็น Tooltip)
@export_multiline var description: String = "คำอธิบายสินค้า"

## ไอคอนสินค้า (ลากรูปภาพมาใส่)
@export var icon: Texture2D

## ราคาสินค้า (เหรียญ)
@export var cost: int = 50

## ผลกระทบต่อสถิติผู้เล่น
## ใช้ key เดียวกับ PerkData และ RelicData เพื่อความสอดคล้อง:
##   "damage_multiplier"  — เพิ่มดาเมจเป็น %  (0.25 = +25%)
##   "flat_damage"        — เพิ่มดาเมจแบบคงที่
##   "max_hp_multiplier"  — เพิ่ม HP สูงสุดเป็น %
##   "flat_max_hp"        — เพิ่ม HP สูงสุดแบบคงที่
##   "projectile_count"   — เพิ่มจำนวนกระสุน
##   "pierce_bonus"       — เพิ่มการทะลุ
##   "gold_multiplier"    — เพิ่มเงินรางวัลจากศัตรู
@export var modifiers: Dictionary = {}

## จำนวนครั้งสูงสุดที่สามารถซื้อได้ (0 = ไม่จำกัด)
@export var max_purchases: int = 3
