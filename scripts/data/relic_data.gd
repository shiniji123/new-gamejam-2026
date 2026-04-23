class_name RelicData
extends Resource

# รหัสอ้างอิงของ Relic (ห้ามซ้ำ)
@export var id: StringName
# ชื่อ Relic (อาร์ติแฟกต์คำสาป/ของขลัง)
@export var title: String
# คำอธิบายถึงข้อดีและข้อเสีย (Trade-offs)
@export_multiline var description: String
# ไอคอนแสดงใน UI
@export var icon: Texture2D
# ความหายาก
@export var rarity: int = 1

# โบนัสที่ได้รับในเชิงบวก (เช่น เพิ่มพลังโจมตี)
@export var positive_modifiers: Dictionary = {}
# บทลงโทษ หรือข้อเสียของคำสาป (เช่น ลดเลือดสูงสุด)
@export var negative_modifiers: Dictionary = {}

# เงื่อนไขที่จะทำให้เกิดผลลัพธ์อัตโนมัติ (เช่น "on_low_hp", "on_enemy_killed")
@export var triggers: Array[StringName] = []
# อนุญาตให้เก็บสะสมไอเท็มนี้ทับซ้อนกันได้หรือไม่
@export var stackable: bool = false
