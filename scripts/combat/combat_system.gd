extends Node2D
class_name CombatSystem

# --- การตั้งค่าที่ปรับแต่งได้ (Inspector) ---
@export_group("Projectile Settings")
@export var projectile_scene: PackedScene      # ลากไฟล์ .tscn ของกระสุนมาใส่ที่นี่
@export var projectile_speed: float = 500.0    # ความเร็วลูกไฟ

@export_group("Stats")
@export var damage: float = 25.0               # ดาเมจต่อหนึ่งนัด
@export var fire_rate: float = 1.0             # อัตราการยิง (นัดต่อวินาที)
# ------------------------------

# ตัวจับเวลาการยิงออโต้
@onready var fire_timer: Timer = Timer.new()

func _ready():
	# ตรวจสอบว่ามีกระสุนมาใส่หรือยัง เพื่อป้องกัน Error
	if projectile_scene == null:
		push_warning("คำเตือน: ยังไม่ได้ลากไฟล์กระสุนมาใส่ใน CombatSystem นะครับ!")
		return
		
	# ตั้งค่านาฬิกานับถอยหลังการยิง
	fire_timer.wait_time = 1.0 / fire_rate
	fire_timer.autostart = true
	fire_timer.timeout.connect(_on_fire_timer_timeout)
	add_child(fire_timer)

func _on_fire_timer_timeout():
	# 1. ค้นหาเป้าหมายที่อยู่ใกล้ที่สุด
	var target = get_closest_enemy()
	
	# 2. ถ้าเจอเป้าหมาย ให้ยิงทันที
	if target:
		fire_at_target(target)

func get_closest_enemy():
	# ดึงร่ายชื่อศัตรูทั้งหมดที่อยู่ในกลุ่ม "enemy"
	var enemies = get_tree().get_nodes_in_group("enemy")
	var closest_enemy = null
	var min_distance = INF
	
	for enemy in enemies:
		# ต้องเช็คด้วยว่าศัตรูนั้นยังมีชีวิตอยู่ (ตัวแปร is_dead ต้องเป็น false)
		if "is_dead" in enemy and enemy.is_dead: 
			continue
		
		# คำนวณระยะห่างระหว่างเรากับศัตรู
		var dist = global_position.distance_to(enemy.global_position)
		if dist < min_distance:
			min_distance = dist
			closest_enemy = enemy
			
	return closest_enemy

func fire_at_target(target):
	# 1. เสก (Instantiate) กระสุนออกมาจากไฟล์ต้นฉบับ
	var proj = projectile_scene.instantiate()
	
	# 2. นำกระสุนไปแปะไว้ที่ Root ของเกม 
	# (เพื่อให้กระสุนวิ่งเป็นอิสระ ไม่ได้วิ่งติดไปกับตัวละครเราครับ)
	get_tree().root.add_child(proj)
	
	# 3. กำหนดตำแหน่งเริ่มต้นให้เริ่มที่ตัวเรา
	proj.global_position = global_position
	
	# 4. ส่งข้อมูลทิศทางไปให้กระสุนเพื่อเริ่มการทำงาน
	var target_dir = target.global_position - global_position
	proj.setup(target_dir, projectile_speed, damage)
