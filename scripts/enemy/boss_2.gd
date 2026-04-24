extends BaseEnemy
## ===================================================
## boss_2.gd — บอสตัวที่ 2 (แฝดนรก ความเร็วแสง)
## ===================================================

@export_group("Boss 2 Config")
@export var base_hp: float = 1500.0
@export var damage_multiplier: float = 2.5
@export var speed_multiplier: float = 3.0 # เคลื่อนที่ไวมากๆ
@export var boss_reward_money: int = 300

@export_group("Abilities")
@export var charge_speed: float = 600.0
@export var charge_cooldown: float = 3.0
@export var teleport_cooldown: float = 6.0

enum State { CHASE, PREPARE_CHARGE, DASHING, TELEPORTING }
var current_state: State = State.CHASE
var charge_timer: float = 0.0
var teleport_timer: float = 0.0
var dash_dir: Vector2 = Vector2.ZERO

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

	# สั่นกล้องตอนเกิด
	await get_tree().create_timer(spawn_delay).timeout
	_shake_camera(25.0, 1.2)

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
			
			charge_timer += delta
			teleport_timer += delta
			
			if teleport_timer >= teleport_cooldown:
				_start_teleport()
			elif charge_timer >= charge_cooldown:
				_start_charge()
				
		State.PREPARE_CHARGE:
			velocity = knockback_velocity
			if animated_sprite:
				animated_sprite.flip_h = move_direction.x > 0
				animated_sprite.play("idle")
				
		State.DASHING:
			velocity = dash_dir * charge_speed + knockback_velocity
			if animated_sprite:
				animated_sprite.flip_h = dash_dir.x > 0
				animated_sprite.play("walk")
				
		State.TELEPORTING:
			velocity = Vector2.ZERO
			# ห้ามโดนขัดขวางหรือทำดาเมจระหว่างวาร์ป (ปิด Collision ในฟังก์ชัน _start_teleport แล้ว)
			
	knockback_velocity = knockback_velocity.lerp(Vector2.ZERO, 1.0 - exp(-friction * 60.0 * delta))
	move_and_slide()
	_check_player_collision()

func _start_charge() -> void:
	current_state = State.PREPARE_CHARGE
	await get_tree().create_timer(0.5).timeout
	
	if is_dead: return
	if is_instance_valid(player):
		dash_dir = global_position.direction_to(player.global_position)
	else:
		dash_dir = Vector2.LEFT
		
	current_state = State.DASHING
	await get_tree().create_timer(0.8).timeout
	
	if is_dead: return
	current_state = State.CHASE
	charge_timer = 0.0

func _start_teleport() -> void:
	current_state = State.TELEPORTING
	teleport_timer = 0.0
	charge_timer = 0.0
	
	# เฟดหายไป (Alpha = 0)
	var tween_out = create_tween()
	tween_out.tween_property(self, "modulate:a", 0.0, 0.5)
	await tween_out.finished
	
	if is_dead: return
	
	# วาร์ปไปใกล้ผู้เล่น
	if is_instance_valid(player):
		var random_offset = Vector2(randf_range(-100, 100), randf_range(-100, 100))
		global_position = player.global_position + random_offset
	
	# เฟดกลับมา
	var tween_in = create_tween()
	tween_in.tween_property(self, "modulate:a", 1.0, 0.5)
	await tween_in.finished
	
	if is_dead: return
	current_state = State.CHASE

func _check_player_collision() -> void:
	if current_state == State.TELEPORTING: return
	
	for i in get_slide_collision_count():
		var collision = get_slide_collision(i)
		var collider = collision.get_collider()
		if collider and collider.is_in_group("player"):
			if collider.has_node("HurtboxComponent"):
				var final_dmg = damage * 1.5 if current_state == State.DASHING else damage
				collider.get_node("HurtboxComponent").take_damage(final_dmg, global_position)

func _shake_camera(intensity: float, duration: float) -> void:
	if is_instance_valid(player) and player.has_method("shake_camera"):
		player.shake_camera(intensity, duration)
