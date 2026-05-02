extends BaseEnemy

@export_group("Boss 3 Config")
@export var base_hp: float = 2200.0
@export var damage_multiplier: float = 3.0
@export var speed_multiplier: float = 1.25
@export var boss_reward_money: int = 500

@export_group("Attack Settings")
@export var attack_cooldown: float = 2.9
@export var dash_windup_time: float = 0.55
@export var dash_speed: float = 820.0
@export var dash_duration: float = 0.72
@export var attack_recovery_time: float = 0.7
@export var magic_cast_time: float = 1.35
@export var magic_followup_delay: float = 0.32
@export var magic_damage: float = 38.0
@export_range(0.0, 1.0, 0.05) var magic_attack_chance: float = 0.75
@export var magic_burst_radius: float = 96.0

@export_group("Attack Scene")
@export var magic_attack_scene: PackedScene = preload("res://scenes/enemy/boss_3_attack_1.tscn")

@export_group("Spawn Feedback")
@export var spawn_shake_intensity: float = 30.0
@export var spawn_shake_duration: float = 1.5

enum State { VULNERABLE, WINDUP, DASHING, CASTING, RECOVER }

var current_state: State = State.VULNERABLE
var attack_timer: float = 0.0
var dash_dir: Vector2 = Vector2.ZERO
var _last_attack_was_dash: bool = false
var _attack_animations: Array[StringName] = [
	&"boss_3_attack_2",
	&"boss_3_attack_3",
	&"boss_3_attack_4",
]


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

	_set_attack_invincible(false)
	_play_body_animation()

	await get_tree().create_timer(spawn_delay).timeout
	_shake_camera(spawn_shake_intensity, spawn_shake_duration)


func _physics_process(delta: float) -> void:
	if is_dead or is_spawning:
		return

	_acquire_player()
	if not is_instance_valid(player) or _is_player_dead():
		velocity = Vector2.ZERO
		_play_body_animation()
		return

	var move_direction := global_position.direction_to(player.global_position)

	match current_state:
		State.VULNERABLE:
			_set_attack_invincible(false)
			velocity = (move_direction * speed) + knockback_velocity
			_set_facing(move_direction)
			_play_body_animation()

			attack_timer += delta
			if attack_timer >= attack_cooldown:
				_choose_random_attack()
		State.WINDUP:
			_set_attack_invincible(true)
			velocity = knockback_velocity
			_set_facing(move_direction)
			_play_body_animation()
		State.DASHING:
			_set_attack_invincible(true)
			velocity = (dash_dir * dash_speed) + knockback_velocity
			_set_facing(dash_dir)
			_play_body_animation()
		State.CASTING:
			_set_attack_invincible(true)
			velocity = knockback_velocity
			_set_facing(move_direction)
			_play_body_animation()
		State.RECOVER:
			_set_attack_invincible(true)
			velocity = knockback_velocity
			_play_body_animation()

	knockback_velocity = knockback_velocity.lerp(Vector2.ZERO, 1.0 - exp(-friction * 60.0 * delta))
	move_and_slide()
	_check_player_collision()


func _choose_random_attack() -> void:
	attack_timer = 0.0

	var should_dash := randf() > magic_attack_chance
	if _last_attack_was_dash:
		should_dash = false

	if should_dash:
		_last_attack_was_dash = true
		_begin_dash_attack()
	else:
		_last_attack_was_dash = false
		_begin_magic_attack()


func _begin_dash_attack() -> void:
	current_state = State.WINDUP
	await get_tree().create_timer(dash_windup_time).timeout

	if is_dead:
		return

	_acquire_player()
	dash_dir = global_position.direction_to(player.global_position) if is_instance_valid(player) else Vector2.LEFT
	current_state = State.DASHING
	_shake_camera(15.0, 0.2)
	await get_tree().create_timer(dash_duration).timeout

	if is_dead:
		return

	current_state = State.RECOVER
	await get_tree().create_timer(attack_recovery_time).timeout

	if not is_dead:
		current_state = State.VULNERABLE


func _begin_magic_attack() -> void:
	current_state = State.CASTING
	var center := _get_player_target_position()
	_spawn_magic_at_position(center, &"boss_3_attack_1")
	await get_tree().create_timer(magic_followup_delay).timeout

	if is_dead:
		return

	var offsets := [
		Vector2.ZERO,
		Vector2(magic_burst_radius, 0.0),
		Vector2(-magic_burst_radius, 0.0),
		Vector2(0.0, magic_burst_radius),
		Vector2(0.0, -magic_burst_radius),
	]
	for i in range(offsets.size()):
		_spawn_magic_at_position(center + offsets[i], _attack_animations[i % _attack_animations.size()])
		await get_tree().create_timer(0.08).timeout
		if is_dead:
			return

	await get_tree().create_timer(maxf(0.05, magic_cast_time - magic_followup_delay)).timeout

	if is_dead:
		return

	current_state = State.RECOVER
	await get_tree().create_timer(attack_recovery_time).timeout

	if not is_dead:
		current_state = State.VULNERABLE


func _get_player_target_position() -> Vector2:
	_acquire_player()
	return player.global_position if is_instance_valid(player) else global_position


func _spawn_magic_at_position(target_position: Vector2, animation_name: StringName) -> void:
	if not magic_attack_scene:
		return

	var magic := magic_attack_scene.instantiate()
	magic.global_position = target_position
	if magic.has_method("setup"):
		magic.setup(animation_name, magic_damage, 2)

	get_tree().current_scene.add_child(magic)


func _set_attack_invincible(value: bool) -> void:
	if has_node("HurtboxArea/CollisionShape2D"):
		$HurtboxArea/CollisionShape2D.set_deferred("disabled", value)

	if has_node("HurtboxComponent"):
		var hurtbox := get_node("HurtboxComponent") as HurtboxComponent
		hurtbox.set_forced_invincible(value)


func _play_body_animation() -> void:
	if not animated_sprite or not animated_sprite.sprite_frames:
		return

	if animated_sprite.sprite_frames.has_animation(&"walk") and current_state == State.VULNERABLE:
		animated_sprite.play(&"walk")
	elif animated_sprite.sprite_frames.has_animation(&"idle"):
		animated_sprite.play(&"idle")


func _set_facing(direction: Vector2) -> void:
	if animated_sprite and absf(direction.x) > 0.05:
		animated_sprite.flip_h = direction.x > 0.0


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
			var final_damage := damage
			if current_state == State.DASHING:
				final_damage = damage * 2.0
			collider.get_node("HurtboxComponent").take_damage(final_damage, global_position)


func _shake_camera(intensity: float, duration: float) -> void:
	_acquire_player()
	if is_instance_valid(player) and player.has_method("shake_camera"):
		player.shake_camera(intensity, duration)
