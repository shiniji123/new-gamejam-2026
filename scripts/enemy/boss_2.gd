extends BaseEnemy

@export_group("Boss 2 Config")
@export var base_hp: float = 1500.0
@export var damage_multiplier: float = 2.5
@export var speed_multiplier: float = 3.2
@export var boss_reward_money: int = 300

@export_group("Twin Sync")
@export var pair_group: StringName = &"boss_2_pair"
@export var pair_attack_interval: float = 2.4
@export var wait_for_twin_before_first_attack: bool = true

@export_group("Charge Attack")
@export var charge_prepare_time: float = 0.45
@export var charge_speed: float = 720.0
@export var charge_duration: float = 0.75
@export var charge_recovery_time: float = 0.35

@export_group("Teleport Strike")
@export var teleport_fade_time: float = 0.35
@export var teleport_distance_from_player: float = 125.0
@export var teleport_strike_speed: float = 760.0
@export var teleport_strike_duration: float = 0.42
@export var teleport_recovery_time: float = 0.45

@export_group("Spawn Feedback")
@export var spawn_shake_intensity: float = 25.0
@export var spawn_shake_duration: float = 1.2

enum State { CHASE, WINDUP, DASHING, TELEPORTING, RECOVER }
enum PairAttack { CHARGE, TELEPORT }

static var _pair_busy: bool = false
static var _pair_timer: float = 0.0
static var _pair_next_attack: int = PairAttack.CHARGE
static var _pair_serial: int = 0
static var _pair_has_had_two_members: bool = false

var current_state: State = State.CHASE
var dash_dir: Vector2 = Vector2.ZERO
var _current_dash_speed: float = 0.0
var _visual_animation: StringName = &"boss_2_1"
var _did_first_pair_wait: bool = false


func _ready() -> void:
	super._ready()
	add_to_group(pair_group)

	damage *= damage_multiplier
	speed *= speed_multiplier
	knockback_resistance = 1.0
	reward_money = boss_reward_money

	if has_node("HurtboxComponent"):
		var hurtbox := get_node("HurtboxComponent") as HurtboxComponent
		hurtbox.max_hp = base_hp
		hurtbox.current_hp = base_hp

	if _get_active_pair_members().size() <= 1:
		_pair_busy = false
		_pair_timer = 0.0
		_pair_next_attack = PairAttack.CHARGE
		_pair_has_had_two_members = false

	_select_twin_animation()
	_play_motion_animation()

	await get_tree().create_timer(spawn_delay).timeout
	_shake_camera(spawn_shake_intensity, spawn_shake_duration)


func _physics_process(delta: float) -> void:
	if is_dead or is_spawning:
		return

	_acquire_player()
	if not is_instance_valid(player) or _is_player_dead():
		velocity = Vector2.ZERO
		_play_motion_animation()
		return

	var move_direction := global_position.direction_to(player.global_position)

	match current_state:
		State.CHASE:
			_update_pair_leader(delta)
			velocity = (move_direction * speed) + knockback_velocity
			_set_facing(move_direction)
			_play_motion_animation()
		State.WINDUP:
			velocity = knockback_velocity
			_set_facing(move_direction)
			_play_motion_animation()
		State.DASHING:
			velocity = (dash_dir * _get_active_dash_speed()) + knockback_velocity
			_set_facing(dash_dir)
			_play_motion_animation()
		State.TELEPORTING:
			velocity = Vector2.ZERO
		State.RECOVER:
			velocity = knockback_velocity
			_play_motion_animation()

	knockback_velocity = knockback_velocity.lerp(Vector2.ZERO, 1.0 - exp(-friction * 60.0 * delta))
	move_and_slide()
	_check_player_collision()


func _update_pair_leader(delta: float) -> void:
	if _pair_busy:
		return

	var members := _get_active_pair_members()
	if members.is_empty() or members[0] != self:
		return

	if members.size() >= 2:
		_pair_has_had_two_members = true

	if wait_for_twin_before_first_attack and not _pair_has_had_two_members and not _did_first_pair_wait:
		return

	_did_first_pair_wait = true
	_pair_timer += delta

	if _pair_timer < pair_attack_interval:
		return

	var attack_kind := _pair_next_attack
	_pair_next_attack = PairAttack.TELEPORT if attack_kind == PairAttack.CHARGE else PairAttack.CHARGE
	_command_pair_attack(members, attack_kind)


func _command_pair_attack(members: Array, attack_kind: int) -> void:
	_pair_busy = true
	_pair_timer = 0.0
	_pair_serial += 1
	var serial := _pair_serial

	for i in range(members.size()):
		var member = members[i]
		if not is_instance_valid(member) or member.is_dead:
			continue

		if attack_kind == PairAttack.CHARGE:
			member._begin_charge_attack()
		else:
			member._begin_teleport_strike(i, members.size())

	var lock_time := _get_pair_lock_time(attack_kind)
	await get_tree().create_timer(lock_time).timeout

	if serial == _pair_serial:
		_pair_busy = false


func _begin_charge_attack() -> void:
	current_state = State.WINDUP
	await get_tree().create_timer(charge_prepare_time).timeout

	if is_dead:
		return

	_acquire_player()
	dash_dir = global_position.direction_to(player.global_position) if is_instance_valid(player) else Vector2.LEFT
	_current_dash_speed = charge_speed
	current_state = State.DASHING
	_shake_camera(12.0, 0.18)
	await get_tree().create_timer(charge_duration).timeout

	if is_dead:
		return

	current_state = State.RECOVER
	await get_tree().create_timer(charge_recovery_time).timeout

	if not is_dead:
		current_state = State.CHASE


func _begin_teleport_strike(slot: int, total_members: int) -> void:
	current_state = State.TELEPORTING
	dash_dir = Vector2.ZERO
	_set_targetable(false)

	var fade_out := create_tween()
	fade_out.tween_property(self, "modulate:a", 0.0, teleport_fade_time).set_trans(Tween.TRANS_SINE)
	await fade_out.finished

	if is_dead:
		return

	_acquire_player()
	if is_instance_valid(player):
		global_position = _get_teleport_position(slot, total_members)
		dash_dir = global_position.direction_to(player.global_position)
	else:
		dash_dir = Vector2.LEFT

	var fade_in := create_tween()
	fade_in.tween_property(self, "modulate:a", 1.0, teleport_fade_time).set_trans(Tween.TRANS_SINE)
	await fade_in.finished

	if is_dead:
		return

	_set_targetable(true)
	_current_dash_speed = teleport_strike_speed
	current_state = State.DASHING
	_shake_camera(16.0, 0.2)
	await get_tree().create_timer(teleport_strike_duration).timeout

	if is_dead:
		return

	current_state = State.RECOVER
	await get_tree().create_timer(teleport_recovery_time).timeout

	if not is_dead:
		current_state = State.CHASE


func _get_pair_lock_time(attack_kind: int) -> float:
	if attack_kind == PairAttack.CHARGE:
		return charge_prepare_time + charge_duration + charge_recovery_time + 0.1

	return teleport_fade_time * 2.0 + teleport_strike_duration + teleport_recovery_time + 0.1


func _get_active_dash_speed() -> float:
	return _current_dash_speed


func _get_teleport_position(slot: int, total_members: int) -> Vector2:
	if not is_instance_valid(player):
		return global_position

	var total: int = maxi(1, total_members)
	var base_angle := TAU * float(slot) / float(total)
	var angle := base_angle + randf_range(-0.18, 0.18)
	var offset := Vector2.RIGHT.rotated(angle) * teleport_distance_from_player
	return player.global_position + offset


func _get_active_pair_members() -> Array:
	var members: Array = []
	for node in get_tree().get_nodes_in_group(pair_group):
		if is_instance_valid(node) and node is BaseEnemy and not node.is_dead:
			members.append(node)

	members.sort_custom(func(a, b): return a.get_instance_id() < b.get_instance_id())
	return members


func _select_twin_animation() -> void:
	var members := _get_active_pair_members()
	var index := members.find(self)
	_visual_animation = &"boss_2_1" if index % 2 == 0 else &"boss_2_2"


func _play_motion_animation() -> void:
	if not animated_sprite or not animated_sprite.sprite_frames:
		return

	if animated_sprite.sprite_frames.has_animation(_visual_animation):
		animated_sprite.play(_visual_animation)
	elif animated_sprite.sprite_frames.has_animation(&"boss_2_1"):
		animated_sprite.play(&"boss_2_1")


func _set_facing(direction: Vector2) -> void:
	if animated_sprite and absf(direction.x) > 0.05:
		animated_sprite.flip_h = direction.x > 0.0


func _set_targetable(value: bool) -> void:
	if has_node("HurtboxArea/CollisionShape2D"):
		$HurtboxArea/CollisionShape2D.set_deferred("disabled", not value)

	if has_node("CollisionShape2D"):
		$CollisionShape2D.set_deferred("disabled", not value)

	if has_node("HurtboxComponent"):
		var hurtbox := get_node("HurtboxComponent") as HurtboxComponent
		hurtbox.set_forced_invincible(not value)


func _acquire_player() -> void:
	if is_instance_valid(player):
		return

	var players := get_tree().get_nodes_in_group("player")
	if players.size() > 0 and players[0] is CharacterBody2D:
		player = players[0]


func _is_player_dead() -> bool:
	return is_instance_valid(player) and bool(player.get("is_dead"))


func _check_player_collision() -> void:
	if current_state == State.TELEPORTING:
		return

	for i in get_slide_collision_count():
		var collision := get_slide_collision(i)
		var collider := collision.get_collider()
		if collider and collider.is_in_group("player") and collider.has_node("HurtboxComponent"):
			var final_damage := damage
			if current_state == State.DASHING:
				final_damage = damage * 1.7
			collider.get_node("HurtboxComponent").take_damage(final_damage, global_position)


func _shake_camera(intensity: float, duration: float) -> void:
	_acquire_player()
	if is_instance_valid(player) and player.has_method("shake_camera"):
		player.shake_camera(intensity, duration)
