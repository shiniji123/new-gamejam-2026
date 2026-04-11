extends Area2D

@export var hit_effect_scene: PackedScene # ลากไฟล์ hit_effect.tscn มาใส่ตรงนี้ใน Inspector ของ Projectile Scene ครับ

# --- การตั้งค่าภายใน ---
var speed: float = 400.0             # ความเร็วที่ได้รับจาก CombatSystem
var damage: float = 50.0          # ดาเมจที่ได้รับจาก CombatSystem
var pierce: int = 0               # จำนวนการทะลุ (0 = ไม่ทะลุ)
var direction: Vector2 = Vector2.ZERO # ทิศทางที่จะวิ่งไป
var lifetime: float = 5.0           # วินาที: ลบตัวเองทิ้งถ้าไม่ชนอะไรเลย เพื่อประหยัดแรม

# ป้องกันการยิงทะลุตัวเดิมซ้ำซ้อนในเฟรมเดียวกัน
var hit_objects: Array = []

func _ready():
	# เชื่อมต่อสัญญาณ "ชน" อัตโนมัติ (ไม่ต้องลากสายใน Editor)
	area_entered.connect(_on_area_entered)

# --- ฟังก์ชันเริ่มต้น (ตั้งค่าทิศทาง) ---
func setup(target_dir: Vector2, proj_speed: float, proj_damage: float, proj_pierce: int = 0):
	direction = target_dir.normalized() # ปรับความยาวให้เป็น 1 (ทิศอย่างเดียว)
	speed = proj_speed
	damage = proj_damage
	pierce = proj_pierce
	hit_objects.clear()
	
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
	var body = area.get_parent()
	
	# ตรวจสอบว่าชนศัตรูใช่ไหม และต้องไม่ใช่ตัวที่เคยโดนไปแล้ว
	if body.is_in_group("enemy") and not body in hit_objects:
		# เช็คว่ามีระบบเลือด (HurtboxComponent) หรือไม่
		if body.has_node("HurtboxComponent"):
			# จดจำว่าโดนตัวนี้แล้ว
			hit_objects.append(body)
			
			# สั่งลดเลือดศัตรู
			body.get_node("HurtboxComponent").take_damage(damage, global_position)
			
			# เสก Effect ระเบิดขึ้นมาในตำแหน่งที่ชน
			if hit_effect_scene:
				var effect = hit_effect_scene.instantiate()
				get_tree().current_scene.add_child(effect)
				effect.global_position = global_position
			
			# ระบบทะลุ: ถ้ายังมีแต้มทะลุเหลือ ให้ลดแต้มลง แต่ถ้าหมดแล้วให้ลบกระสุนทิ้ง
			if pierce > 0:
				pierce -= 1
			else:
				queue_free()
