extends CharacterBody2D
class_name BaseEnemy

# --- การตั้งค่าที่ปรับแต่งได้ (Inspector) ---
@export_group("AI Settings")
@export var speed: float = 80.0             # ความเร็วที่เดินตามผู้เล่น
@export var spawn_delay: float = 1.0        # เวลารอก่อนจะเริ่มขยับหลังจากเกิด

@export_group("Combat")
@export var damage: float = 10.0            # ดาเมจที่ทำใส่ผู้เล่นเมื่อชน
@export var knockback_power: float = 150.0  # แรงกระเด็นเมื่อศัตรูโดนโจมตี
@export var friction: float = 0.1           # ความหนืดเมื่อกระเด็น (0.1 = ลื่นนิดๆ, 1.0 = หยุดทันที)
@export var knockback_resistance: float = 0.0 # ความต้านทานแรงดีด (0.0 = กระเด็นปกติ, 1.0 = บอสตัวแข็งไม่ขยับเลย)
# ------------------------------

# --- ตัวแปรภายใน ---
var player: CharacterBody2D = null          # ตัวแปรเก็บตำแหน่งผู้เล่น
var is_spawning: bool = true                # สถานะกำลังเกิด (ยังไม่ขยับ)
var is_dead: bool = false                    # สถานะตาย
var knockback_velocity: Vector2 = Vector2.ZERO # แรงที่ได้รับจากการโดนยิง

@onready var animated_sprite = $AnimatedSprite2D

func _ready():
	# เพิ่มเข้ากลุ่มเพื่อให้ระบบยิงอัตโนมัติหาเจอ
	add_to_group("enemy")
	
	# 1. เล่นท่า Idle (ท่ายืน) ทันทีที่เกิด
	if animated_sprite:
		animated_sprite.play("idle")
	
	# 2. เริ่มนับเวลาหน่วงการเกิด
	get_tree().create_timer(spawn_delay).timeout.connect(func(): is_spawning = false)
	
	# 3. เชื่อมต่อระบบเลือด (ถ้าใน Editor มีการแปะ HurtboxComponent ไว้)
	if has_node("HurtboxComponent"):
		var hurtbox = get_node("HurtboxComponent")
		hurtbox.died.connect(_on_died)
		hurtbox.took_damage.connect(_on_took_damage)

func _physics_process(_delta):
	# ไม่ทำอะไรต่อถ้าตายแล้ว หรือยังอยู่ในช่วงดีเลย์การเกิด
	if is_dead or is_spawning: 
		return
	
	# 1. ค้นหา Player ในกลุ่ม "player" (ทำครั้งแรกครั้งเดียว)
	if not player:
		var players = get_tree().get_nodes_in_group("player")
		if players.size() > 0:
			player = players[0]
	
	if not player: 
		return # ถ้าไม่เจอผู้เล่นในฉาก ก็ไม่ต้องเดิน
	
	# 2. ป้องกันศัตรูขยับต่อถ้าผู้เล่นตายไปแล้ว
	if player.has_method("is_dead") and player.is_dead: 
		if animated_sprite: animated_sprite.play("idle")
		return
		
	# 3. คำนวณทิศทางเพื่อมุ่งหน้าหา Player
	var move_direction = global_position.direction_to(player.global_position)
	
	# 4. คำนวณความเร็ว (Velocity)
	# รวมแรงเดินปกติ เข้ากับ แรงกระเด็นจากกระสุน (Knockback)
	velocity = (move_direction * speed) + knockback_velocity
	
	# 5. จัดการความหนืดของแรงกระเด็น
	knockback_velocity = knockback_velocity.lerp(Vector2.ZERO, friction)
	
	# 6. จัดการการหันหน้าของภาพ (Flip) 
	if animated_sprite:
		if move_direction.x > 0:
			animated_sprite.flip_h = true 
		else:
			animated_sprite.flip_h = false
		
		# 7. สั่งเคลื่อนที่และเล่นท่าเดิน
		animated_sprite.play("walk")
		
	move_and_slide()
		
	# 8. ตรวจสอบการเดินชนผู้เล่นเพื่อทำดาเมจ
	for i in get_slide_collision_count():
		var collision = get_slide_collision(i)
		var collider = collision.get_collider()
		if collider.is_in_group("player"):
			# ถ้าชนผู้เล่นสำเร็จ ให้สั่งผู้เล่นลดเลือด
			if collider.has_node("HurtboxComponent"):
				collider.get_node("HurtboxComponent").take_damage(damage, global_position)

# --- ส่วนรับสัญญาณจากโหนดย่อย (Signals) ---

func _on_took_damage(_hp, _attacker_pos):
	# คำนวณทิศแรงดีด (ดีดตัวออกจากตำแหน่งกระสุน)
	var knockback_dir = _attacker_pos.direction_to(global_position)
	
	# คำนวณแรงดีดโดยหักลบค่า "ความต้านทาน" (Resistance) ออกครับ
	var final_knockback = knockback_power * (1.0 - knockback_resistance)
	knockback_velocity = knockback_dir * final_knockback
	
	# สั่งรันเอฟเฟกต์แฟลชขาว (ถ้ามีโหนดนี้เป็นลูก)
	if has_node("FlashEffects"):
		get_node("FlashEffects").flash()

func _on_died():
	if is_dead: return
	is_dead = true
	
	# หยุดการเคลื่อนที่ทั้งหมด
	velocity = Vector2.ZERO
	knockback_velocity = Vector2.ZERO
	
	# เล่นท่าตายรอบเดียว (ห้ามวนลูป)
	if animated_sprite:
		var frames = animated_sprite.sprite_frames
		if frames.has_animation("dead"):
			frames.set_animation_loop("dead", false)
		animated_sprite.play("dead")

		# รอ 2 วินาทีเพื่อให้เห็นท่าตายก่อนหายไป
		await get_tree().create_timer(2.0).timeout
		queue_free()
