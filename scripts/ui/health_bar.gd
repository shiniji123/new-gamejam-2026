extends TextureProgressBar

# วิธีใช้งาน: 
# 1. สร้างโหนด TextureProgressBar ในโหมด 2D
# 2. ใส่ภาพหลอดเลือดเปล่าๆ ลงในช่อง Textures -> Under
# 3. ใส่ภาพเส้นสีเขียว (Pixel) ลงในช่อง Textures -> Progress
# 4. ลากสคริปต์นี้ใส่โหนด TextureProgressBar ครับ

func _ready():
	add_to_group("player_health_bar")
	# ตั้งค่าให้ตอนเปิดเกมมา หลอดเลือดเต็มพอดี
	value = max_value

# ฟังก์ชันนี้เอาไว้เรียกใช้ตอนที่ตัวละครโดนโจมตี หรือได้ฮีลเลือดครับ
func update_health(current_hp: float, max_hp: float):
	# อัปเดตค่า Max เผื่อมีการอัปเกรดเลือดสูงสุด
	max_value = max_hp
	
	# สร้าง Tween เพื่อให้เวลาเลือดลด มันจะค่อยๆ ไหลลดลงอย่างนุ่มนวล (ไม่ได้หายวับไปทันที)
	var tween = create_tween()
	tween.tween_property(self, "value", current_hp, 0.25)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
