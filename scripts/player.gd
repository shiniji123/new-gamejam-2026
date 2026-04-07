extends CharacterBody2D

@export var speed: float = 200.0
@onready var animated_sprite = $AnimatedSprite2D

var last_dir = "down"

func _physics_process(_delta):
	# 1. รับค่า Input
	var direction = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	
	# 2. เคลื่อนที่
	velocity = direction * speed
	move_and_slide()
	
	# 3. จัดการ Animation
	update_animation(direction)

func update_animation(dir: Vector2):
	var anim_type = "idle"
	var dir_name = last_dir
	
	if dir != Vector2.ZERO:
		anim_type = "walk"
		# ตัดสินใจทิศทางจาก 8 ทิศทาง
		if dir.y < 0: # ขึ้น
			if dir.x < -0.1: dir_name = "left_up"
			elif dir.x > 0.1: dir_name = "right_up"
			else: dir_name = "up"
		elif dir.y > 0: # ลง
			if dir.x < -0.1: dir_name = "left_down"
			elif dir.x > 0.1: dir_name = "right_down"
			else: dir_name = "down"
		else: # เดินทางราบ (ซ้าย/ขวา) - ถ้าไม่มีซ้ายขวาตรงๆ ให้เลือกใช้เฉียงๆ แทน
			if dir.x < 0: dir_name = "left_down"
			elif dir.x > 0: dir_name = "right_down"
		
		last_dir = dir_name
	
	# เล่น Animation เช่น "walk_down" หรือ "idle_down"
	var final_anim = anim_type + "_" + dir_name
	
	# ตรวจสอบว่ามีท่าทางนี้ไหมก่อนเล่น (กันเหนียว)
	if animated_sprite.sprite_frames.has_animation(final_anim):
		animated_sprite.play(final_anim)
	else:
		# ถ้าไม่มีท่าทิศทางนั้น ให้ใช้ท่าพื้นฐาน (Down)
		animated_sprite.play(anim_type + "_down")

func set_camera_limits(rect: Rect2):
	var camera = $Camera2D
	camera.limit_left = rect.position.x
	camera.limit_top = rect.position.y
	camera.limit_right = rect.end.x
	camera.limit_bottom = rect.end.y
