extends BaseEnemy

@export_group("Final Boss Config")
@export var base_hp: float = 4200.0
@export var damage_multiplier: float = 3.0
@export var speed_multiplier: float = 0.85
@export var boss_reward_money: int = 900
@export var preferred_distance: float = 310.0
@export var close_distance: float = 190.0

@export_group("Thread Line Attack")
@export var line_attack_scene: PackedScene = preload("res://scenes/enemy/final_boss_line_attack.tscn")
@export var line_attack_cooldown: float = 3.1
@export var line_damage: float = 48.0
@export var line_length: float = 1250.0
@export var line_width: float = 34.0
@export var line_telegraph_time: float = 0.82
@export var line_active_time: float = 0.28
@export var lines_per_wave: int = 4
@export var line_waves: int = 3
@export var line_wave_interval: float = 0.42
@export var line_cross_spread: float = 130.0

@export_group("Phase 3 Homing Projectile")
@export var homing_projectile_scene: PackedScene = preload("res://scenes/enemy/final_boss_homing_projectile.tscn")
@export var homing_projectile_cooldown: float = 2.4
@export var homing_projectile_damage: float = 34.0
@export var homing_projectile_spawn_distance: float = 185.0
@export var homing_projectile_max_active: int = 2

@export_group("Spawn Feedback")
@export var spawn_shake_intensity: float = 34.0
@export var spawn_shake_duration: float = 1.6

enum State { CHASE, ATTACKING, RECOVER }

var current_state: State = State.CHASE
var attack_timer: float = 0.0
var homing_projectile_timer: float = 0.0
var _phase: int = 1


func _ready() -> void:
	super._ready()

	damage *= damage_multiplier
	speed *= speed_multiplier
	knockback_resistance = 1.0
	reward_money = boss_reward_money

	if has_node("HurtboxComponent"):
		var hurtbox := get_node("HurtboxComponent") as HurtboxComponent
		hurtbox.max_hp = base_hp
		hurtbox.current_hp = base_hp

	_update_phase_animation()

	await get_tree().create_timer(spawn_delay).timeout
	_shake_camera(spawn_shake_intensity, spawn_shake_duration)


func _physics_process(delta: float) -> void:
	if is_dead or is_spawning:
		return

	_acquire_player()
	if not is_instance_valid(player) or _is_player_dead():
		velocity = Vector2.ZERO
		_update_phase_animation()
		return

	_update_phase_from_health()
	_update_phase_animation()
	_update_phase_three_projectiles(delta)

	match current_state:
		State.CHASE:
			velocity = _get_chase_velocity() + knockback_velocity
			attack_timer += delta
			if attack_timer >= _get_current_cooldown():
				_begin_thread_barrage()
		State.ATTACKING:
			velocity = knockback_velocity
		State.RECOVER:
			velocity = knockback_velocity

	var face_direction := global_position.direction_to(player.global_position)
	if animated_sprite and absf(face_direction.x) > 0.05:
		animated_sprite.flip_h = face_direction.x > 0.0

	knockback_velocity = knockback_velocity.lerp(Vector2.ZERO, 1.0 - exp(-friction * 60.0 * delta))
	move_and_slide()
	_check_player_collision()


func _get_chase_velocity() -> Vector2:
	if not is_instance_valid(player):
		return Vector2.ZERO

	var to_player := global_position.direction_to(player.global_position)
	var distance := global_position.distance_to(player.global_position)

	if distance > preferred_distance:
		return to_player * speed
	if distance < close_distance:
		return -to_player * speed * 0.8

	return to_player.orthogonal() * speed * 0.55


func _begin_thread_barrage() -> void:
	attack_timer = 0.0
	current_state = State.ATTACKING

	var wave_count: int = _get_current_line_wave_count()
	for wave_index in range(wave_count):
		if is_dead:
			return

		_spawn_line_wave(wave_index)
		_shake_camera(8.0 + float(_phase) * 2.0, 0.12)
		await get_tree().create_timer(line_wave_interval).timeout

	if is_dead:
		return

	current_state = State.RECOVER
	await get_tree().create_timer(0.65).timeout

	if not is_dead:
		current_state = State.CHASE


func _spawn_line_wave(wave_index: int) -> void:
	if not line_attack_scene:
		return

	_acquire_player()
	var target_position := global_position
	if is_instance_valid(player):
		target_position = player.global_position

	var count := _get_current_lines_per_wave()
	var base_angle := randf() * TAU + float(wave_index) * 0.37
	if _phase == 1 and is_instance_valid(player):
		base_angle = global_position.direction_to(player.global_position).angle()

	for i in range(count):
		var angle := base_angle + (TAU * float(i) / float(count)) + randf_range(-0.22, 0.22)
		if _phase == 1:
			angle = base_angle + (PI * 0.5 * float(i)) + randf_range(-0.08, 0.08)

		var direction := Vector2.RIGHT.rotated(angle)
		var perpendicular := direction.orthogonal()
		var cross_offset := randf_range(-line_cross_spread, line_cross_spread)
		if _phase == 1:
			cross_offset = randf_range(-45.0, 45.0)
		var center := target_position + perpendicular * cross_offset

		var attack := line_attack_scene.instantiate()
		if attack.has_method("setup"):
			attack.setup(
				center,
				direction,
				line_length,
				_get_current_line_width(),
				_get_current_line_damage(),
				_get_current_telegraph_time(),
				line_active_time
			)
		else:
			attack.global_position = center

		get_tree().current_scene.add_child(attack)


func _get_current_cooldown() -> float:
	if _phase == 1:
		return line_attack_cooldown * 0.9
	if _phase == 3:
		return maxf(2.25, line_attack_cooldown - 0.25)
	return line_attack_cooldown


func _get_current_line_wave_count() -> int:
	if _phase == 1:
		return 1
	return line_waves


func _get_current_lines_per_wave() -> int:
	if _phase == 1:
		return 2
	return lines_per_wave


func _get_current_line_width() -> float:
	if _phase == 1:
		return maxf(18.0, line_width * 0.8)
	return line_width


func _get_current_line_damage() -> float:
	if _phase == 1:
		return line_damage * 0.72
	return line_damage


func _get_current_telegraph_time() -> float:
	if _phase == 1:
		return line_telegraph_time + 0.18
	return line_telegraph_time


func _update_phase_three_projectiles(delta: float) -> void:
	if _phase != 3:
		homing_projectile_timer = 0.0
		return
	if current_state == State.ATTACKING:
		return
	if not homing_projectile_scene or not is_instance_valid(player):
		return
	if _get_active_homing_projectile_count() >= homing_projectile_max_active:
		return

	homing_projectile_timer += delta
	if homing_projectile_timer < homing_projectile_cooldown:
		return

	homing_projectile_timer = 0.0
	_spawn_homing_projectile()


func _spawn_homing_projectile() -> void:
	var projectile := homing_projectile_scene.instantiate()
	var toward_player := global_position.direction_to(player.global_position)
	if toward_player == Vector2.ZERO:
		toward_player = Vector2.RIGHT

	var side := toward_player.orthogonal() * randf_range(-homing_projectile_spawn_distance, homing_projectile_spawn_distance)
	var spawn_position := global_position - toward_player * 75.0 + side

	if projectile.has_method("setup"):
		projectile.setup(spawn_position, player, self, homing_projectile_damage)
	else:
		projectile.global_position = spawn_position

	get_tree().current_scene.add_child(projectile)
	_shake_camera(9.0, 0.12)


func _get_active_homing_projectile_count() -> int:
	var count := 0
	for node in get_tree().get_nodes_in_group("final_boss_projectile"):
		if is_instance_valid(node):
			count += 1
	return count


func _clear_homing_projectiles() -> void:
	for node in get_tree().get_nodes_in_group("final_boss_projectile"):
		if is_instance_valid(node):
			node.queue_free()


func _update_phase_from_health() -> void:
	if not has_node("HurtboxComponent"):
		return

	var hurtbox := get_node("HurtboxComponent") as HurtboxComponent
	var hp_ratio := hurtbox.current_hp / maxf(1.0, hurtbox.max_hp)

	if hp_ratio <= 0.33:
		_phase = 3
	elif hp_ratio <= 0.66:
		_phase = 2
	else:
		_phase = 1


func _update_phase_animation() -> void:
	if not animated_sprite or not animated_sprite.sprite_frames:
		return

	var animation_name := StringName("phase_%d" % _phase)
	if animated_sprite.sprite_frames.has_animation(animation_name):
		animated_sprite.play(animation_name)


func _acquire_player() -> void:
	if is_instance_valid(player):
		return

	var players := get_tree().get_nodes_in_group("player")
	if players.size() > 0 and players[0] is CharacterBody2D:
		player = players[0]


func _is_player_dead() -> bool:
	return is_instance_valid(player) and bool(player.get("is_dead"))


func _check_player_collision() -> void:
	for i in get_slide_collision_count():
		var collision := get_slide_collision(i)
		var collider := collision.get_collider()
		if collider and collider.is_in_group("player") and collider.has_node("HurtboxComponent"):
			collider.get_node("HurtboxComponent").take_damage(damage, global_position)


func _on_died() -> void:
	_clear_homing_projectiles()
	super._on_died()


func _shake_camera(intensity: float, duration: float) -> void:
	_acquire_player()
	if is_instance_valid(player) and player.has_method("shake_camera"):
		player.shake_camera(intensity, duration)
