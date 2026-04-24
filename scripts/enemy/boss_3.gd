extends BaseEnemy
## ===================================================
## boss_3.gd — บอสตัวที่ 3 (จอมเวทย์อมตะ)
## ===================================================

@export_group("Boss 3 Config")
@export var base_hp: float = 2000.0
@export var damage_multiplier: float = 3.0
@export var speed_multiplier: float = 1.2
@export var boss_reward_money: int = 500

@export_group("Attack Settings")
@export var attack_cooldown: float = 3.5
@export var dash_speed: float = 800.0

enum State { VULNERABLE, DASHING, CASTING }
var current_state: State = State.VULNERABLE
var attack_timer: float = 0.0
var dash_dir: Vector2 = Vector2.ZERO

var attack_scenes: Array = []

func _ready() -> void:
	super._ready()
	
	damage *= damage_multiplier
	speed *= speed_multiplier
	knockback_resistance = 1.0 # ไม่ชะงัก
	reward_money = boss_reward_money
	
	if has_node("HurtboxComponent"):
		var hurtbox = get_node("HurtboxComponent")
		hurtbox.max_hp = base_hp
		hurtbox.current_hp = base_hp

	# โหลดฉากโจมตีล่วงหน้า (ถ้ามีไฟล์ .tscn ค่อยใช้ ไม่งั้นจะเตือนไว้ก่อน)
	for i in range(1, 5):
		var path = "res://scenes/enemy/boss_3_attack_%d.tscn" % i
		if ResourceLoader.exists(path):
			attack_scenes.append(load(path))
		else:
			push_warning("[Boss 3] ยังไม่ได้สร้างไฟล์ท่าโจมตี: " + path)

	await get_tree().create_timer(spawn_delay).timeout
	_shake_camera(30.0, 1.5)

func _physics_process(delta: float) -> void:
	if is_dead or is_spawning: return
	
	if not is_instance_valid(player):
		var players = get_tree().get_nodes_in_group("player")
		if players.size() > 0: player = players[0]
		else: return
		
	if player.has_method("is_dead") and player.is_dead: 
		if animated_sprite: animated_sprite.play("idle")
		return

	var move_direction: Vector2 = global_position.direction_to(player.global_position)
	
	match current_state:
		State.VULNERABLE:
			# ช่วงนี้โดนตีเข้า (เปิด Collision)
			_set_invincibility(false)
			
			velocity = (move_direction * speed) + knockback_velocity
			if animated_sprite:
				animated_sprite.flip_h = move_direction.x > 0
				animated_sprite.play("walk")
			
			attack_timer += delta
			if attack_timer >= attack_cooldown:
				_choose_random_attack()
				
		State.DASHING:
			# อมตะตอนพุ่ง
			_set_invincibility(true)
			velocity = dash_dir * dash_speed + knockback_velocity
			if animated_sprite:
				animated_sprite.flip_h = dash_dir.x > 0
				animated_sprite.play("walk")
				
		State.CASTING:
			# อมตะตอนร่ายเวทย์
			_set_invincibility(true)
			velocity = knockback_velocity
			if animated_sprite:
				animated_sprite.flip_h = move_direction.x > 0
				animated_sprite.play("idle")

	knockback_velocity = knockback_velocity.lerp(Vector2.ZERO, 1.0 - exp(-friction * 60.0 * delta))
	move_and_slide()
	_check_player_collision()

func _set_invincibility(is_invincible: bool) -> void:
	if has_node("HurtboxArea/CollisionShape2D"):
		$HurtboxArea/CollisionShape2D.set_deferred("disabled", is_invincible)
	elif has_node("CollisionShape2D"):
		# ถ้าไม่มี HurtboxArea ให้ปิดที่ CollisionShape หลักแทน (แต่ระวังตกแมพ)
		pass

func _choose_random_attack() -> void:
	attack_timer = 0.0
	var attack_type = randi() % 2 # สุ่มระหว่างพุ่งตัว หรือ ใช้เวทย์
	
	if attack_type == 0:
		_start_dash_attack()
	else:
		_start_magic_attack()

func _start_dash_attack() -> void:
	current_state = State.CASTING
	await get_tree().create_timer(0.5).timeout # หน่วงเวลาก่อนพุ่ง
	
	if is_dead: return
	if is_instance_valid(player):
		dash_dir = global_position.direction_to(player.global_position)
	else:
		dash_dir = Vector2.LEFT
		
	current_state = State.DASHING
	await get_tree().create_timer(1.0).timeout # เวลาที่พุ่ง
	
	if is_dead: return
	current_state = State.VULNERABLE

func _start_magic_attack() -> void:
	current_state = State.CASTING
	
	if attack_scenes.size() > 0:
		var magic = attack_scenes.pick_random().instantiate()
		
		# ท่าไม้ตายให้เกิดตรงที่ผู้เล่นยืนพอดี
		if is_instance_valid(player):
			magic.global_position = player.global_position
		else:
			magic.global_position = global_position
			
		get_tree().current_scene.add_child(magic)
		
	await get_tree().create_timer(1.5).timeout # ใช้เวลาร่าย
	
	if is_dead: return
	current_state = State.VULNERABLE

func _check_player_collision() -> void:
	for i in get_slide_collision_count():
		var collision = get_slide_collision(i)
		var collider = collision.get_collider()
		if collider and collider.is_in_group("player"):
			if collider.has_node("HurtboxComponent"):
				var final_dmg = damage * 2.0 if current_state == State.DASHING else damage
				collider.get_node("HurtboxComponent").take_damage(final_dmg, global_position)

func _shake_camera(intensity: float, duration: float) -> void:
	if is_instance_valid(player) and player.has_method("shake_camera"):
		player.shake_camera(intensity, duration)
