extends CharacterBody2D

# --- การตั้งค่าที่ปรับแต่งได้ (Inspector) ---
@export_group("Movement")
@export var speed: float = 150.0             # ความเร็วพื้นฐานในการเดิน
@export var friction: float = 0.1             # ความหนืดในการหยุด (0.1 = ลื่นนิดๆ, 1.0 = หยุดทันที)

@export_group("Combat Effects")
@export var knockback_power: float = 150.0    # ความแรงเมื่อโดนดีด
# ------------------------------

# --- ตัวแปรภายใน ---
var last_dir = "down"                         # เอาไว้จำทิศทางล่าสุดสำหรับเล่นท่า Idle
var is_dead: bool = false                      # สถานะตาย
var knockback_velocity: Vector2 = Vector2.ZERO # แรงที่ได้รับจากการโดนโจมตี

@onready var animated_sprite = $AnimatedSprite2D

func _ready():
	# เพิ่มเข้ากลุ่ม player เพื่อลอจิกอื่นๆ เช่น กล้อง หรือ AI ศัตรู
	add_to_group("player")

func _physics_process(_delta):
	# ถ้าตายแล้ว ไม่ต้องทำอะไรต่อ
	if is_dead: return
	
	# 1. รับค่าการเคลื่อนที่จากปุ่มที่ตั้งไว้ใน Input Map (Project Settings)
	var direction = Input.get_vector("left", "right", "up", "down")
	
	# 2. คำนวณความเร็ว (Velocity)
	# รวมแรงเดินปกติ เข้ากับ แรงกระเด็น (Knockback)
	velocity = (direction * speed) + knockback_velocity
	
	# 3. จัดการความหนืดของแรงกระเด็น (Friction)
	# ทำให้แรงดีดค่อยๆ หายไปจนเป็น 0 อย่างนุ่มนวล
	knockback_velocity = knockback_velocity.lerp(Vector2.ZERO, friction)
	
	# 4. สั่งให้ตัวละครเคลื่อนที่ตามฟิสิกส์
	move_and_slide()
	
	# 5. อัปเดตท่าทางตามทิศทางที่กด
	update_animation(direction)

func update_animation(direction: Vector2):
	# ถ้าไม่มีการกดปุ่ม (เดินหยุดพัก) ให้ใช้ชื่อ prefix ว่า idle_
	var anim_type = "walk" if direction != Vector2.ZERO else "idle"
	
	if direction != Vector2.ZERO:
		# 1. คำนวณหาทิศทางแนวตั้ง (Vertical)
		var v_str = ""
		if direction.y > 0.1: v_str = "down"
		elif direction.y < -0.1: v_str = "up"
		
		# 2. คำนวณหาทิศทางแนวนอน (Horizontal)
		var h_str = ""
		if direction.x < -0.1: h_str = "left"
		elif direction.x > 0.1: h_str = "right"
		
		# 3. ประกอบร่างชื่อท่าทางให้ตรงกับที่เรามีใน AnimatedSprite2D
		# (เนื่องจากคุณไม่มี walk_left เฉยๆ ผมเลยต้องแมพให้มันไปใช้ _down หรือ _up แทนครับ)
		if h_str != "" and v_str != "":
			last_dir = h_str + "_" + v_str
		elif h_str != "":
			last_dir = h_str + "_down" # สุ่มเลือกเป็น down เมื่อเดินแนวนอนตรงๆ
		elif v_str != "":
			last_dir = v_str
			
	# สั่งเล่นท่าทาง เช่น walk_left_down หรือ idle_up
	var final_anim_name = anim_type + "_" + last_dir
	if animated_sprite.sprite_frames.has_animation(final_anim_name):
		animated_sprite.play(final_anim_name)

# --- ส่วนรับสัญญาณจากโหนดย่อย (Signals) ---

func _on_took_damage(current_hp, attacker_pos):
	print("Player took damage! HP เหลือ: ", current_hp)
	
	# คำนวณทิศทางที่ต้องกระเด็น (ดีดตัวออกจากตำแหน่งผู้โจมตี)
	var knockback_dir = attacker_pos.direction_to(global_position)
	knockback_velocity = knockback_dir * knockback_power
	
	# สั่งรันเอฟเฟกต์แฟลชขาว (ถ้ามีโหนดนี้เป็นลูก)
	if has_node("FlashEffects"):
		get_node("FlashEffects").flash()

func _on_died():
	if is_dead: return
	is_dead = true
	
	print("Player is Dead!")
	# หยุดการเคลื่อนที่ทั้งหมด
	velocity = Vector2.ZERO
	knockback_velocity = Vector2.ZERO
	
	# สั่งให้เล่นท่าตายรอบเดียว (ห้ามวนลูป)
	if animated_sprite:
		var frames = animated_sprite.sprite_frames
		if frames.has_animation("dead"):
			frames.set_animation_loop("dead", false)
		animated_sprite.play("dead")

# --- การตั้งค่ากล้อง ---
func set_camera_limits(rect: Rect2):
	# ฟังก์ชันนี้จะถูกเรียกจาก FightScene เพื่อจำกัดขอบเขตกามเมร่า
	# เพื่อไม่ให้กล้องวิ่งออกไปนอกพื้นที่ภาพพื้นหลังครับ
	if has_node("Camera2D"):
		var cam = $Camera2D
		cam.limit_left = rect.position.x
		cam.limit_top = rect.position.y
		cam.limit_right = rect.end.x
		cam.limit_bottom = rect.end.y
