extends Area2D

@export var damage: float = 45.0
@export var line_length: float = 1150.0
@export var hit_width: float = 34.0
@export var telegraph_duration: float = 0.8
@export var active_duration: float = 0.28
@export var fade_duration: float = 0.16
@export var telegraph_color: Color = Color(1.0, 0.16, 0.18, 0.45)
@export var active_color: Color = Color(1.0, 0.92, 0.78, 0.9)

@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var telegraph_line: Line2D = $TelegraphLine
@onready var blade: Polygon2D = $Blade

var _direction: Vector2 = Vector2.RIGHT
var _is_active: bool = false
var _players_in_area: Array[Node2D] = []
var _damaged_players: Array[Node2D] = []


func setup(
	center_position: Vector2,
	attack_direction: Vector2,
	length: float,
	width: float,
	attack_damage: float,
	warning_time: float,
	live_time: float
) -> void:
	global_position = center_position
	_direction = attack_direction.normalized()
	if _direction == Vector2.ZERO:
		_direction = Vector2.RIGHT

	rotation = _direction.angle()
	line_length = length
	hit_width = width
	damage = attack_damage
	telegraph_duration = warning_time
	active_duration = live_time

	if is_inside_tree():
		_apply_geometry()


func _ready() -> void:
	var entered_callable := Callable(self, "_on_body_entered")
	if not body_entered.is_connected(entered_callable):
		body_entered.connect(entered_callable)

	var exited_callable := Callable(self, "_on_body_exited")
	if not body_exited.is_connected(exited_callable):
		body_exited.connect(exited_callable)

	_apply_geometry()
	_run_attack()


func _apply_geometry() -> void:
	if collision_shape:
		var shape := RectangleShape2D.new()
		shape.size = Vector2(line_length, hit_width)
		collision_shape.shape = shape
		collision_shape.disabled = false

	if telegraph_line:
		telegraph_line.points = PackedVector2Array([
			Vector2(-line_length * 0.5, 0.0),
			Vector2(line_length * 0.5, 0.0),
		])
		telegraph_line.width = maxf(4.0, hit_width * 0.35)
		telegraph_line.default_color = telegraph_color
		telegraph_line.visible = true

	if blade:
		var half_length := line_length * 0.5
		var half_width := hit_width * 0.5
		blade.polygon = PackedVector2Array([
			Vector2(-half_length, -half_width * 0.45),
			Vector2(half_length - hit_width, -half_width),
			Vector2(half_length, 0.0),
			Vector2(half_length - hit_width, half_width),
			Vector2(-half_length, half_width * 0.45),
		])
		blade.color = active_color
		blade.visible = false


func _run_attack() -> void:
	_is_active = false
	if telegraph_line:
		telegraph_line.visible = true
	if blade:
		blade.visible = false

	await get_tree().create_timer(telegraph_duration).timeout

	if not is_inside_tree():
		return

	_is_active = true
	if telegraph_line:
		telegraph_line.visible = false
	if blade:
		blade.visible = true

	_deal_damage_to_players()
	await get_tree().create_timer(active_duration).timeout

	if not is_inside_tree():
		return

	_is_active = false
	var tween := create_tween()
	tween.set_parallel(true)
	if blade:
		tween.tween_property(blade, "modulate:a", 0.0, fade_duration)
	if telegraph_line:
		tween.tween_property(telegraph_line, "modulate:a", 0.0, fade_duration)
	await tween.finished

	if is_inside_tree():
		queue_free()


func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return

	if not body in _players_in_area:
		_players_in_area.append(body)

	if _is_active:
		_deal_damage_to(body)


func _on_body_exited(body: Node2D) -> void:
	if body in _players_in_area:
		_players_in_area.erase(body)


func _deal_damage_to_players() -> void:
	for body in _players_in_area:
		_deal_damage_to(body)


func _deal_damage_to(body: Node2D) -> void:
	if not is_instance_valid(body) or body in _damaged_players:
		return

	if body.has_node("HurtboxComponent"):
		_damaged_players.append(body)
		body.get_node("HurtboxComponent").take_damage(damage, global_position)
