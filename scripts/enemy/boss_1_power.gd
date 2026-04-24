extends Node2D

@export var speed: float = 300.0
@export var damage: float = 20.0
@export var lifetime: float = 3.0
@export var homing_speed: float = 2.0 # ความเร็วในการหมุนหาเป้าหมาย

var target: Node2D = null
var velocity: Vector2 = Vector2.ZERO

func _ready() -> void:
	# ถ้าไม่มีเป้าหมาย ให้ทำลายตัวเองหลังจากผ่านไป
	get_tree().create_timer(lifetime).timeout.connect(queue_free)
	
	# ถ้ายิงออกมาแล้วยังไม่มีเป้าหมาย ให้พุ่งไปทางซ้ายเป็นค่าเริ่มต้น
	if target == null:
		velocity = Vector2.LEFT * speed

func set_target(new_target: Node2D) -> void:
	target = new_target
	if is_instance_valid(target):
		velocity = global_position.direction_to(target.global_position) * speed

func _process(delta: float) -> void:
	if is_instance_valid(target):
		# กระสุนติดตาม: ค่อยๆ หันไปหาผู้เล่น
		var desired_direction = global_position.direction_to(target.global_position)
		var current_direction = velocity.normalized()
		var new_direction = current_direction.lerp(desired_direction, homing_speed * delta).normalized()
		velocity = new_direction * speed
		
	global_position += velocity * delta

func _on_hitbox_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		if body.has_node("HurtboxComponent"):
			body.get_node("HurtboxComponent").take_damage(damage, global_position)
		queue_free()


func _on_body_entered(body: Node2D) -> void:
	pass # Replace with function body.
