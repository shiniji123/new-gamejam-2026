extends BaseEnemy

@export_group("Final Boss Config")
@export var base_hp: float = 4500.0
@export var damage_multiplier: float = 4.0
@export var speed_multiplier: float = 0.85
@export var boss_reward_money: int = 1000

@export_group("Mother Phases")
@export var phase_2_ratio: float = 0.66
@export var phase_3_ratio: float = 0.33
@export var pulse_cooldown: float = 2.4
@export var pulse_damage: float = 28.0
@export var pulse_radius: float = 180.0
@export var dash_cooldown: float = 4.5
@export var dash_speed: float = 760.0
@export var dash_duration: float = 0.65

enum State { CHASE, PULSE, DASH }

var current_state: State = State.CHASE
var current_phase: int = 1
var pulse_timer: float = 0.0
var dash_timer: float = 0.0
var dash_direction: Vector2 = Vector2.ZERO


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

	_play_phase_animation()

	await get_tree().create_timer(spawn_delay).timeout
	_shake_camera(35.0, 1.0)


func _physics_process(delta: float) -> void:
	if is_dead or is_spawning:
		return

	_refresh_player()
	if not is_instance_valid(player):
		return

	if _has_property(player, "is_dead") and bool(player.get("is_dead")):
		velocity = Vector2.ZERO
		return

	_update_phase()

	var move_direction := global_position.direction_to(player.global_position)

	match current_state:
		State.CHASE:
			pulse_timer += delta
			dash_timer += delta
			velocity = (move_direction * speed * _phase_speed_bonus()) + knockback_velocity

			if dash_timer >= dash_cooldown:
				_start_dash(move_direction)
			elif pulse_timer >= pulse_cooldown:
				_start_pulse()

		State.PULSE:
			velocity = knockback_velocity

		State.DASH:
			velocity = (dash_direction * dash_speed) + knockback_velocity

	knockback_velocity = knockback_velocity.lerp(Vector2.ZERO, 1.0 - exp(-friction * 60.0 * delta))
	if animated_sprite:
		animated_sprite.flip_h = move_direction.x > 0
	move_and_slide()
	_check_player_collision()


func _refresh_player() -> void:
	if is_instance_valid(player):
		return

	var players := get_tree().get_nodes_in_group("player")
	for candidate in players:
		if candidate is CharacterBody2D:
			player = candidate
			return


func _update_phase() -> void:
	if not has_node("HurtboxComponent"):
		return

	var hurtbox := get_node("HurtboxComponent") as HurtboxComponent
	var hp_ratio := hurtbox.current_hp / maxf(hurtbox.max_hp, 1.0)
	var next_phase := 1
	if hp_ratio <= phase_3_ratio:
		next_phase = 3
	elif hp_ratio <= phase_2_ratio:
		next_phase = 2

	if next_phase == current_phase:
		return

	current_phase = next_phase
	_play_phase_animation()
	_shake_camera(25.0 + (current_phase * 8.0), 0.7)


func _phase_speed_bonus() -> float:
	return 1.0 + float(current_phase - 1) * 0.18


func _start_pulse() -> void:
	current_state = State.PULSE
	pulse_timer = 0.0
	_play_phase_animation()
	_shake_camera(18.0, 0.35)

	await get_tree().create_timer(0.4).timeout
	if is_dead:
		return

	if is_instance_valid(player) and global_position.distance_to(player.global_position) <= pulse_radius:
		if player.has_node("HurtboxComponent"):
			player.get_node("HurtboxComponent").take_damage(pulse_damage * current_phase, global_position)

	await get_tree().create_timer(0.35).timeout
	if is_dead:
		return

	current_state = State.CHASE


func _start_dash(direction: Vector2) -> void:
	current_state = State.DASH
	dash_timer = 0.0
	dash_direction = direction.normalized()
	_shake_camera(12.0, 0.25)

	await get_tree().create_timer(dash_duration).timeout
	if is_dead:
		return

	current_state = State.CHASE


func _check_player_collision() -> void:
	for i in get_slide_collision_count():
		var collision := get_slide_collision(i)
		var collider := collision.get_collider()
		if collider and collider.is_in_group("player") and collider.has_node("HurtboxComponent"):
			var final_damage := damage
			if current_state == State.DASH:
				final_damage *= 1.8
			collider.get_node("HurtboxComponent").take_damage(final_damage, global_position)


func _play_phase_animation() -> void:
	if not animated_sprite:
		return

	var animation_name := "phase_%d" % current_phase
	if animated_sprite.sprite_frames.has_animation(animation_name):
		animated_sprite.play(animation_name)


func _shake_camera(intensity: float, duration: float) -> void:
	if is_instance_valid(player) and player.has_method("shake_camera"):
		player.shake_camera(intensity, duration)


func _has_property(node: Object, property_name: String) -> bool:
	for property_data in node.get_property_list():
		if property_data.get("name", "") == property_name:
			return true
	return false
