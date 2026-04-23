class_name PerkData
extends Resource

# รหัสอ้างอิงที่ไม่ซ้ำกัน
@export var id: StringName
# ชื่อที่แสดงผลใน UI
@export var title: String
# คำอธิบายคุณสมบัติเมื่อรับ Perk นี้
@export_multiline var description: String
# ระดับความหายากของ Perk ปัจจุบันใช้เป็นตัวเลข (เช่น 1 = ทั่วไป, 2 = หายาก, ...)
@export var rarity: int = 1
# Tags สำหรับจัดหมวดหมู่ หรือกรอง (เช่น "fire", "utility")
@export var tags: Array[StringName] = []
# ภาพไอคอนที่แสดงผลใน UI
@export var icon: Texture2D
# รูปแบบ Modifier เช่น {"damage_multiplier": 0.2, "fire_rate_multiplier": 0.15}
@export var modifiers: Dictionary = {}
# รายชื่อ Perk ที่ไม่สามารถมีครอบครองร่วมกันได้เพื่อป้องกันบัค หรือรักษาสมดุล
@export var exclusive_with: Array[StringName] = []
# จำนวนครั้งสะสมซ้ำกันที่เก็บ Perk ชนิดนี้ได้
@export var max_stack: int = 1
