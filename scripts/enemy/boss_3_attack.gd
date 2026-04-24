extends Area2D

@export var damage: float = 30.0
@export var damage_start_frame: int = 2 # เริ่มทำดาเมจตั้งแต่เฟรมที่ 3 (index 2) เป็นต้นไป

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

var has_damaged: bool = false
var players_in_area: Array[Node2D] = []

func _ready() -> void:
	if animated_sprite:
		animated_sprite.frame_changed.connect(_on_frame_changed)
		animated_sprite.animation_finished.connect(_on_animation_finished)
		animated_sprite.play("default")
	else:
		# ถ้าไม่ได้ใช้ AnimatedSprite2D ให้ทำลายตัวเองใน 2 วิ
		get_tree().create_timer(2.0).timeout.connect(queue_free)

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		players_in_area.append(body)

func _on_body_exited(body: Node2D) -> void:
	if body in players_in_area:
		players_in_area.erase(body)

func _on_frame_changed() -> void:
	# ถ้าถึงเฟรมที่กำหนด และยังไม่เคยทำดาเมจ
	if animated_sprite.frame >= damage_start_frame and not has_damaged:
		has_damaged = true
		_deal_damage()

func _deal_damage() -> void:
	for player in players_in_area:
		if is_instance_valid(player) and player.has_node("HurtboxComponent"):
			player.get_node("HurtboxComponent").take_damage(damage, global_position)

func _on_animation_finished() -> void:
	queue_free() # เล่นจบแล้วทำลายทิ้ง
