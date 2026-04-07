extends Area2D

# --- การตั้งค่าภายใน ---
var speed: float = 400.0             # ความเร็วที่ได้รับจาก CombatSystem
var damage: float = 20.0            # ดาเมจที่ได้รับจาก CombatSystem
var direction: Vector2 = Vector2.ZERO # ทิศทางที่จะวิ่งไป
var lifetime: float = 5.0           # วินาที: ลบตัวเองทิ้งถ้าไม่ชนอะไรเลย เพื่อประหยัดแรม

func _ready():
	# เชื่อมต่อสัญญาณ "ชน" อัตโนมัติ (ไม่ต้องลากสายใน Editor)
	# ให้เรียกว่า: "เมื่อตัวฉัน (Area2D) เข้าไปแตะอะไรเข้า (area_entered) ให้รันฟังก์ชัน _on_area_entered นะ"
	area_entered.connect(_on_area_entered)

# --- ฟังก์ชันเริ่มต้น (ตั้งค่าทิศทาง) ---
func setup(target_dir: Vector2, proj_speed: float, proj_damage: float):
	direction = target_dir.normalized() # ปรับความยาวให้เป็น 1 (ทิศอย่างเดียว)
	speed = proj_speed
	damage = proj_damage
	
	# หมุนตัวหัวลูกไฟให้หันไปทางที่จะวิ่ง
	rotation = direction.angle()

func _physics_process(delta):
	# เคลื่อนที่ตามทิศทางคูณด้วยความเร็ว
	position += direction * speed * delta
	
	# นับถอยหลังอายุของกระสุน
	lifetime -= delta
	if lifetime <= 0:
		queue_free() # สั่งลบทิ้งจากหน่วยความจำ

# --- ฟังก์ชันเมื่อเกิดการปะทะ (Collision) ---
func _on_area_entered(area):
	# สมมติฐาน: คุณได้สร้าง "HurtboxArea" (Area2D) ไว้ในลูกของตัวละคร
	# ดังนั้น "get_parent" ของ Area ที่ชน คือตัวละคร (Enemy หรือ Player) ครับ
	var body = area.get_parent()
	
	# ตรวจสอบว่าชนศัตรูใช่ไหม?
	if body.is_in_group("enemy"):
		# เช็คว่ามีระบบเลือด (HurtboxComponent) หรือไม่
		if body.has_node("HurtboxComponent"):
			# สั่งลดเลือดศัตรู และส่งตำแหน่งปัจจุบันของเราไปเพื่อทำแรงดีด (Knockback)
			body.get_node("HurtboxComponent").take_damage(damage, global_position)
			
			# เมื่อทำดาเมจสำเร็จแล้ว ให้ลบกระสุนทิ้งทันที
			queue_free()
