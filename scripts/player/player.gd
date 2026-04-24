extends CharacterBody2D

# --- การตั้งค่าที่ปรับแต่งได้ (Inspector) ---
@export_group("Movement")
@export var speed: float = 150.0             # ความเร็วพื้นฐานในการเดิน
@export var friction: float = 0.1             # ความหนืดในการหยุด (0.1 = ลื่นนิดๆ, 1.0 = หยุดทันที)

@export_group("Combat Effects")
@export var knockback_power: float = 150.0    # ความแรงเมื่อโดนดีด

@export_group("UI Interfaces")
# เปิดกว้างให้รองรับหลอดเลือดได้ทุกประเภท (Control แทนที่จะเจาะจง TextureProgressBar) ยืดหยุ่นกว่า!
@export var health_bar: Control              

@export_group("Audio")
@export var hit_sound: AudioStream            
# ------------------------------

# --- ตัวแปรภายใน ---
var last_dir: String = "down"                         
var is_dead: bool = false                      
var knockback_velocity: Vector2 = Vector2.ZERO 

# Camera Shake Variables
var shake_intensity: float = 0.0
var shake_duration: float = 0.0
var shake_timer: float = 0.0
var original_cam_pos: Vector2 = Vector2.ZERO

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

func _ready() -> void:
	add_to_group("player")
	
	# ตั้งค่ากล้องให้ติดตามตัวละครทันที
	if has_node("Camera2D"):
		var cam = $Camera2D
		cam.enabled = true
		cam.make_current()
	
	if has_node("HurtboxComponent"):
		var hurtbox = get_node("HurtboxComponent")
		if not hurtbox.died.is_connected(_on_died):
			hurtbox.died.connect(_on_died)
		if not hurtbox.took_damage.is_connected(_on_took_damage):
			hurtbox.took_damage.connect(_on_took_damage)
			
		call_deferred("_sync_initial_health")

func _sync_initial_health() -> void:
	if has_node("HurtboxComponent"):
		var hurtbox = get_node("HurtboxComponent")
		if not health_bar:
			var bars: Array = get_tree().get_nodes_in_group("player_health_bar")
			if bars.size() > 0:
				health_bar = bars[0]
		
		# เช็คให้ชัวร์ว่ามันมีฟังก์ชัน update_health ค่อยเรียก (กัน Error ล่ม)
		if health_bar and health_bar.has_method("update_health"):
			health_bar.update_health(hurtbox.current_hp, hurtbox.max_hp)

func _physics_process(_delta: float) -> void:
	if is_dead: return
	
	var direction: Vector2 = Input.get_vector("left", "right", "up", "down")
	
	velocity = (direction * speed) + knockback_velocity
	
	# [ระบบ AAA] นำเวลาแต่ละเฟรม (Delta) มารวมคำนวณ เพื่อให้จอ 60fps และ 144fps ลื่นไหลหนืดเท่ากัน 100%
	knockback_velocity = knockback_velocity.lerp(Vector2.ZERO, 1.0 - exp(-friction * 60.0 * _delta))
	
	move_and_slide()
	update_animation(direction)
	_process_camera_shake(_delta)

func _process_camera_shake(delta: float) -> void:
	if not has_node("Camera2D"): return
	var cam = $Camera2D
	
	if shake_timer > 0:
		shake_timer -= delta
		# สุ่มตำแหน่งขยับกล้อง
		var offset = Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)).normalized() * shake_intensity
		cam.offset = offset
		# ลดความแรงลงเรื่อยๆ
		shake_intensity = lerp(shake_intensity, 0.0, 5.0 * delta)
	else:
		cam.offset = Vector2.ZERO

func shake_camera(intensity: float = 15.0, duration: float = 0.5) -> void:
	shake_intensity = intensity
	shake_duration = duration
	shake_timer = duration

func update_animation(direction: Vector2):
	# ท่าทางหลักมีแค่ walk และ idle
	var anim_type = "walk" if direction != Vector2.ZERO else "idle"
	
	# กลับด้านภาพ (Flip) ตามทิศทางแนวนอน
	if direction.x < -0.1:
		animated_sprite.flip_h = false
	elif direction.x > 0.1:
		animated_sprite.flip_h = true
			
	# สั่งเล่นท่าทาง (เช่น walk หรือ idle)
	if animated_sprite.sprite_frames.has_animation(anim_type):
		animated_sprite.play(anim_type)

# --- ส่วนรับสัญญาณจากโหนดย่อย (Signals) ---

func _on_took_damage(current_hp, attacker_pos):
	print("Player took damage! HP เหลือ: ", current_hp)
	
	# เล่นเสียงร้องเจ็บปวด (ถ้าใส่ไฟล์เสียงไว้แล้ว)
	if hit_sound:
		AudioManager.play_sfx(hit_sound, true)
		
	# เช็คว่าถ้าผู้เล่นลืมโยงสายหลอดเลือด ก็ไปงมหาจากในฉากเองเลย!
	if not health_bar:
		var bars = get_tree().get_nodes_in_group("player_health_bar")
		if bars.size() > 0:
			health_bar = bars[0]
			print("[ระบบ] หาหลอดเลือดเจออัตโนมัติแล้ว!")
	
	# ส่งคำสั่งไปบอกหลอดเลือดให้อัปเดตลดลง
	if health_bar and has_node("HurtboxComponent"):
		health_bar.update_health(current_hp, get_node("HurtboxComponent").max_hp)
	else:
		print("[ความผิดพลาด] ไม่สามารถปรับหลอดเลือดได้เพราะหาไม่พบ!")
	
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
