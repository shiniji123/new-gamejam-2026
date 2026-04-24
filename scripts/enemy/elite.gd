extends BaseEnemy
## ===================================================
## elite.gd — ศัตรู Elite (ดัดแปลงมาจาก BaseEnemy)
## ===================================================
## ปรับค่าต่างๆ ได้โดยตรงใน Inspector โดยไม่ต้องแก้โค้ด

@export_group("Elite Configuration")
@export var base_hp: float = 300.0
@export var damage_multiplier: float = 1.5
@export var speed_multiplier: float = 1.5 # เดินไวกว่าปกติ
@export var elite_reward_money: int = 30
@export var elite_knockback_resistance: float = 1.0 # ไม่ชะงัก (Unstaggerable)

@export_group("Charge Attack")
@export var charge_speed: float = 400.0
@export var charge_prep_time: float = 1.0
@export var charge_duration: float = 0.5
@export var charge_cooldown: float = 3.0

enum State { CHASE, PREPARE_CHARGE, DASHING }
var current_state: State = State.CHASE
var charge_timer: float = 0.0
var dash_dir: Vector2 = Vector2.ZERO

func _ready() -> void:
	super._ready()

	# ปรับสถิติตาม multiplier
	damage *= damage_multiplier
	speed *= speed_multiplier
	knockback_resistance = elite_knockback_resistance
	reward_money = elite_reward_money

	if has_node("HurtboxComponent"):
		var hurtbox := get_node("HurtboxComponent") as HurtboxComponent
		hurtbox.max_hp = base_hp
		hurtbox.current_hp = base_hp

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
	var distance_to_player = global_position.distance_to(player.global_position)
	
	match current_state:
		State.CHASE:
			velocity = (move_direction * speed) + knockback_velocity
			_play_movement_anim(move_direction)
			
			# สุ่มใช้ท่า Charge เมื่ออยู่ใกล้
			charge_timer += delta
			if charge_timer >= charge_cooldown and distance_to_player < 250.0:
				if randf() > 0.5: # โอกาส 50% ทุกๆ Cooldown
					_start_charge_prep()
				else:
					charge_timer = 0.0 # เริ่มนับคูลดาวน์ใหม่ถ้าไม่ติด
					
		State.PREPARE_CHARGE:
			# หยุดเดิน เตรียมพุ่ง
			velocity = knockback_velocity
			if animated_sprite: animated_sprite.play("idle")
			
		State.DASHING:
			velocity = dash_dir * charge_speed + knockback_velocity
			_play_movement_anim(dash_dir)
			
	# ระบบคำนวณความหนืด (AAA)
	knockback_velocity = knockback_velocity.lerp(Vector2.ZERO, 1.0 - exp(-friction * 60.0 * delta))
	
	move_and_slide()
	_check_player_collision()

func _play_movement_anim(dir: Vector2) -> void:
	if not animated_sprite: return
	if dir.x < 0:
		animated_sprite.play("walk_left")
		animated_sprite.flip_h = false # เผื่อไว้
	else:
		animated_sprite.play("walk_right")
		animated_sprite.flip_h = false # ไม่ต้อง Flip เพราะมีท่าแยก

func _start_charge_prep() -> void:
	current_state = State.PREPARE_CHARGE
	await get_tree().create_timer(charge_prep_time).timeout
	
	if is_dead: return
	
	# เล็งเป้าหมายตอนพุ่ง
	if is_instance_valid(player):
		dash_dir = global_position.direction_to(player.global_position)
	else:
		dash_dir = Vector2.LEFT # พุ่งซ้ายสุ่มๆ ถ้าไม่เจอผู้เล่น
		
	current_state = State.DASHING
	await get_tree().create_timer(charge_duration).timeout
	
	if is_dead: return
	current_state = State.CHASE
	charge_timer = 0.0

func _check_player_collision() -> void:
	for i in get_slide_collision_count():
		var collision = get_slide_collision(i)
		var collider = collision.get_collider()
		if collider and collider.is_in_group("player"):
			if collider.has_node("HurtboxComponent"):
				# สร้างดาเมจแรงขึ้นถ้ากำลังพุ่ง
				var final_dmg = damage * 2.0 if current_state == State.DASHING else damage
				collider.get_node("HurtboxComponent").take_damage(final_dmg, global_position)
