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

@export_group("Economy (ระบบเงินทอง)")
@export var reward_money: int = 15          # เงินที่จะดรอปเมื่อมอนสเตอร์ตัวนี้ตาย
# ------------------------------

@export_group("Audio")
@export var death_sound: AudioStream = preload("res://assets/new_sound/enemy_died.wav")
@export var hit_sound: AudioStream            # ลากไฟล์เสียงตอนถูกตีมาใส่
# ------------------------------

# --- ตัวแปรภายใน ---
var player: CharacterBody2D = null           # บังคับประเภทผู้เล่นให้เป็นแพทเทิร์นชัดเจน
var is_spawning: bool = true                
var is_dead: bool = false                    
var knockback_velocity: Vector2 = Vector2.ZERO 

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

func _ready() -> void:
	add_to_group("enemy")
	
	if animated_sprite and animated_sprite.sprite_frames:
		if animated_sprite.sprite_frames.has_animation("idle"):
			animated_sprite.play("idle")
		else:
			var animation_names := animated_sprite.sprite_frames.get_animation_names()
			if animation_names.size() > 0:
				animated_sprite.play(animation_names[0])
	
	get_tree().create_timer(spawn_delay).timeout.connect(func(): is_spawning = false)
	
	if has_node("HurtboxComponent"):
		var hurtbox = get_node("HurtboxComponent")
		hurtbox.died.connect(_on_died)
		hurtbox.took_damage.connect(_on_took_damage)

func _physics_process(_delta: float) -> void:
	if is_dead or is_spawning: 
		return
	
	if not is_instance_valid(player):
		var players: Array = get_tree().get_nodes_in_group("player")
		for p in players:
			if p is CharacterBody2D:
				player = p
				break
	
	# ป้องกันเกมพังกรณีผู้เล่นโดนลบทิ้งกะทันหัน
	if not is_instance_valid(player): 
		return 
	
	if player.has_method("is_dead") and player.is_dead: 
		if animated_sprite: animated_sprite.play("idle")
		return
		
	var move_direction: Vector2 = global_position.direction_to(player.global_position)
	
	velocity = (move_direction * speed) + knockback_velocity
	
	# [ระบบ AAA] นำเวลา Delta มาคำนวณความหนืด (เฟรม 60Hz และ 144Hz จะหนืดเท่ากัน!)
	knockback_velocity = knockback_velocity.lerp(Vector2.ZERO, 1.0 - exp(-friction * 60.0 * _delta))
	
	if animated_sprite:
		animated_sprite.flip_h = move_direction.x > 0
		animated_sprite.play("enemy_1")
		
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
	# เล่นเสียงร้องเจ็บปวด
	if hit_sound:
		AudioManager.play_sfx(hit_sound, true)
		
	# คำนวณทิศแรงดีด (ดีดตัวออกจากตำแหน่งกระสุน)
	var knockback_dir = _attacker_pos.direction_to(global_position)
	
	# คำนวณแรงดีดโดยหักลบค่า "ความต้านทาน" (Resistance) ออกครับ
	var final_knockback = knockback_power * (1.0 - knockback_resistance)
	knockback_velocity = knockback_dir * final_knockback
	
	# สั่งรันเอฟเฟกต์แฟลชขาว (ถ้ามีโหนดนี้เป็นลูก)
	if has_node("FlashEffects"):
		get_node("FlashEffects").flash()

func _on_died() -> void:
	if is_dead: return
	is_dead = true

	if death_sound:
		AudioManager.play_sfx(death_sound, true)
	
	velocity = Vector2.ZERO
	knockback_velocity = Vector2.ZERO
	
	# ใช้ StatCalculator เพื่อคำนวณเงินรางวัลรวม (รองรับ gold_multiplier จาก Perk/Relic)
	RunManager.add_coin(StatCalculator.get_enemy_reward(reward_money))
	
	if animated_sprite:
		var frames: SpriteFrames = animated_sprite.sprite_frames
		if frames.has_animation("dead"):
			frames.set_animation_loop("dead", false)
		animated_sprite.play("dead")

		await get_tree().create_timer(2.0).timeout
		
		# [ระบบ AAA] เช็คว่าออบเจกต์นี้ยังมีชีวิตรอดบนจออยู่ไหมก่อนจะสั่งลบ! (ป้องกันแคลชตอนเปลี่ยนฉาก)
		if is_instance_valid(self):
			queue_free()
