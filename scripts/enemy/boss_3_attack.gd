extends Area2D

@export var damage: float = 30.0
@export var animation_name: StringName = &"boss_3_attack_1"
@export var damage_start_frame: int = 2
@export var fallback_lifetime: float = 2.2

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

var _is_damage_active: bool = false
var _players_in_area: Array[Node2D] = []
var _damaged_players: Array[Node2D] = []


func setup(new_animation_name: StringName, new_damage: float, new_damage_start_frame: int = 2) -> void:
	animation_name = new_animation_name
	damage = new_damage
	damage_start_frame = new_damage_start_frame


func _ready() -> void:
	var entered_callable := Callable(self, "_on_body_entered")
	if not body_entered.is_connected(entered_callable):
		body_entered.connect(entered_callable)

	var exited_callable := Callable(self, "_on_body_exited")
	if not body_exited.is_connected(exited_callable):
		body_exited.connect(exited_callable)

	if not animated_sprite:
		get_tree().create_timer(fallback_lifetime).timeout.connect(queue_free)
		return

	var frames := animated_sprite.sprite_frames
	if frames and frames.has_animation(animation_name):
		frames.set_animation_loop(animation_name, false)
		animated_sprite.animation = animation_name
	elif frames and frames.has_animation(&"boss_3_attack_1"):
		animation_name = &"boss_3_attack_1"
		frames.set_animation_loop(animation_name, false)
		animated_sprite.animation = animation_name

	animated_sprite.frame = 0
	animated_sprite.frame_changed.connect(_on_frame_changed)
	animated_sprite.animation_finished.connect(_on_animation_finished)
	animated_sprite.play(animation_name)


func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return

	if not body in _players_in_area:
		_players_in_area.append(body)

	if _is_damage_active:
		_deal_damage_to(body)


func _on_body_exited(body: Node2D) -> void:
	if body in _players_in_area:
		_players_in_area.erase(body)


func _on_frame_changed() -> void:
	if animated_sprite.frame < damage_start_frame:
		return

	_is_damage_active = true
	_deal_damage_to_players()


func _deal_damage_to_players() -> void:
	for body in _players_in_area:
		_deal_damage_to(body)


func _deal_damage_to(body: Node2D) -> void:
	if not is_instance_valid(body) or body in _damaged_players:
		return

	if body.has_node("HurtboxComponent"):
		_damaged_players.append(body)
		body.get_node("HurtboxComponent").take_damage(damage, global_position)


func _on_animation_finished() -> void:
	queue_free()
