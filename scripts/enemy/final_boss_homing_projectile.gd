extends Area2D

@export var damage: float = 34.0
@export var windup_time: float = 0.58
@export var dash_duration: float = 0.92
@export var retry_delay: float = 0.58
@export var dash_speed: float = 560.0
@export var recover_speed: float = 145.0
@export var windup_drift_speed: float = 70.0
@export var dash_turn_rate: float = 1.35
@export var recover_turn_rate: float = 2.4
@export var max_lifetime: float = 24.0

@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var core: Polygon2D = $Core
@onready var warning_ring: Line2D = $WarningRing

enum State { WINDUP, DASH, RECOVER }

var _target: Node2D = null
var _owner_boss: Node = null
var _direction: Vector2 = Vector2.RIGHT
var _state: State = State.WINDUP
var _state_timer: float = 0.0
var _life_timer: float = 0.0
var _has_hit: bool = false


func setup(spawn_position: Vector2, target: Node2D, owner_boss: Node = null, attack_damage: float = -1.0) -> void:
	global_position = spawn_position
	_target = target
	_owner_boss = owner_boss
	if attack_damage >= 0.0:
		damage = attack_damage

	if is_instance_valid(_target):
		_direction = global_position.direction_to(_target.global_position)
		if _direction == Vector2.ZERO:
			_direction = Vector2.RIGHT


func _ready() -> void:
	add_to_group("final_boss_projectile")

	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)

	_set_collision_active(false)
	_apply_state_visuals()


func _physics_process(delta: float) -> void:
	if _has_hit:
		return

	_life_timer += delta
	if _life_timer >= max_lifetime or _should_vanish():
		queue_free()
		return

	_state_timer += delta

	match _state:
		State.WINDUP:
			_update_direction(delta, recover_turn_rate)
			global_position += _direction * windup_drift_speed * delta
			if _state_timer >= windup_time:
				_enter_dash()
		State.DASH:
			_update_direction(delta, dash_turn_rate)
			global_position += _direction * dash_speed * delta
			if _state_timer >= dash_duration:
				_enter_recover()
		State.RECOVER:
			_update_direction(delta, recover_turn_rate)
			global_position += _direction * recover_speed * delta
			if _state_timer >= retry_delay:
				_enter_windup()

	rotation = _direction.angle()


func _enter_windup() -> void:
	_state = State.WINDUP
	_state_timer = 0.0
	_set_collision_active(false)
	_apply_state_visuals()


func _enter_dash() -> void:
	_state = State.DASH
	_state_timer = 0.0
	_update_direction(1.0, 999.0)
	_set_collision_active(true)
	_apply_state_visuals()


func _enter_recover() -> void:
	_state = State.RECOVER
	_state_timer = 0.0
	_set_collision_active(false)
	_apply_state_visuals()


func _update_direction(delta: float, turn_rate: float) -> void:
	if not is_instance_valid(_target):
		return

	var desired := global_position.direction_to(_target.global_position)
	if desired == Vector2.ZERO:
		return

	var current_angle := _direction.angle()
	var desired_angle := desired.angle()
	var new_angle := _rotate_angle_toward(current_angle, desired_angle, turn_rate * delta)
	_direction = Vector2.RIGHT.rotated(new_angle)


func _rotate_angle_toward(from_angle: float, to_angle: float, max_delta: float) -> float:
	var difference := wrapf(to_angle - from_angle, -PI, PI)
	return from_angle + clampf(difference, -max_delta, max_delta)


func _set_collision_active(value: bool) -> void:
	monitoring = value
	if collision_shape:
		collision_shape.set_deferred("disabled", not value)


func _apply_state_visuals() -> void:
	if core:
		match _state:
			State.WINDUP:
				core.color = Color(1.0, 0.36, 0.22, 0.75)
			State.DASH:
				core.color = Color(1.0, 0.92, 0.55, 0.95)
			State.RECOVER:
				core.color = Color(0.95, 0.2, 0.45, 0.45)

	if warning_ring:
		warning_ring.visible = _state != State.DASH
		warning_ring.default_color = Color(1.0, 0.22, 0.2, 0.45)


func _should_vanish() -> bool:
	if not is_instance_valid(_target):
		return true
	if bool(_target.get("is_dead")):
		return true
	if is_instance_valid(_owner_boss) and bool(_owner_boss.get("is_dead")):
		return true
	return false


func _on_body_entered(body: Node2D) -> void:
	if _state != State.DASH or _has_hit:
		return
	if not body.is_in_group("player"):
		return
	if not body.has_node("HurtboxComponent"):
		return

	_has_hit = true
	body.get_node("HurtboxComponent").take_damage(damage, global_position)
	queue_free()
