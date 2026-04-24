extends BaseEnemy
## ===================================================
## boss_1.gd — บอสตัวที่ 1 (สายยิงต่อเนื่อง)
## ===================================================

@export_group("Boss 1 Config")
@export var base_hp: float = 1200.0
@export var damage_multiplier: float = 2.0
@export var speed_multiplier: float = 1.8 # พุ่งไวกว่า Elite (Elite = 1.5)
@export var boss_reward_money: int = 200

@export_group("Attack Settings")
@export var attack_cooldown: float = 4.0
@export var burst_count: int = 5         # จำนวนกระสุนที่ยิงเป็นชุด
@export var burst_delay: float = 0.2     # เวลาระหว่างกระสุนแต่ละนัด

# พลังของบอส
var power_scene: PackedScene

enum State { CHASE, ATTACK }
var current_state: State = State.CHASE
var attack_timer: float = 0.0

func _ready() -> void:
	super._ready()
	
	# ตั้งค่าสถิติ
	damage *= damage_multiplier
	speed *= speed_multiplier
	knockback_resistance = 1.0 # บอสไม่ชะงักเด็ดขาด
	reward_money = boss_reward_money
	
	if has_node("HurtboxComponent"):
		var hurtbox = get_node("HurtboxComponent")
		hurtbox.max_hp = base_hp
		hurtbox.current_hp = base_hp
		
	# ลองโหลดฉากพลัง (ผู้เล่นต้องสร้างไฟล์ res://scenes/enemy/boss_1_power.tscn ไว้)
	if ResourceLoader.exists("res://scenes/enemy/boss_1_power.tscn"):
		power_scene = load("res://scenes/enemy/boss_1_power.tscn")
	else:
		push_warning("[Boss 1] ไม่พบไฟล์ boss_1_power.tscn! บอสจะยิงไม่ได้")

	# สั่นกล้องตอนเกิด (เรียกผ่านผู้เล่น)
	await get_tree().create_timer(spawn_delay).timeout
	_shake_camera(20.0, 1.0)

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
		State.CHASE:
			velocity = (move_direction * speed) + knockback_velocity
			
			if animated_sprite:
				animated_sprite.flip_h = move_direction.x > 0
				animated_sprite.play("walk")
			
			attack_timer += delta
			if attack_timer >= attack_cooldown:
				_start_attack()
				
		State.ATTACK:
			# หยุดเดินตอนยิง
			velocity = knockback_velocity
			if animated_sprite:
				animated_sprite.flip_h = move_direction.x > 0
				animated_sprite.play("idle")
				
	knockback_velocity = knockback_velocity.lerp(Vector2.ZERO, 1.0 - exp(-friction * 60.0 * delta))
	move_and_slide()
	_check_player_collision()

func _start_attack() -> void:
	current_state = State.ATTACK
	attack_timer = 0.0
	
	# ยิงเป็นชุด
	for i in range(burst_count):
		if is_dead: break
		_shoot_projectile()
		await get_tree().create_timer(burst_delay).timeout
		
	if not is_dead:
		current_state = State.CHASE

func _shoot_projectile() -> void:
	if not power_scene: return
	
	var proj = power_scene.instantiate()
	proj.global_position = global_position
	# โยน Player ไปให้กระสุนติดตาม
	if proj.has_method("set_target"):
		proj.set_target(player)
		
	get_tree().current_scene.add_child(proj)

func _check_player_collision() -> void:
	for i in get_slide_collision_count():
		var collision = get_slide_collision(i)
		var collider = collision.get_collider()
		if collider and collider.is_in_group("player"):
			if collider.has_node("HurtboxComponent"):
				collider.get_node("HurtboxComponent").take_damage(damage, global_position)

func _shake_camera(intensity: float, duration: float) -> void:
	if is_instance_valid(player) and player.has_method("shake_camera"):
		player.shake_camera(intensity, duration)
