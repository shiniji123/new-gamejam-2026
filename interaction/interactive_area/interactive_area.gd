extends Area2D
class_name InteractionArea

@export var action_name:= "interact"

var interact :Callable = func():
	pass

func _ready() -> void:
	# เชื่อมต่อระบบสัมผัสเป้าหมายอัตโนมัติ เผื่อผู้เล่นลืมโยงสาย (Signal) ในหน้าต่าง Inspector
	if not body_entered.is_connected(_on_body_body_entered):
		body_entered.connect(_on_body_body_entered)
	if not body_exited.is_connected(_on_body_body_exited):
		body_exited.connect(_on_body_body_exited)

func _on_body_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		InteractionManager.register_area(self)
	
func _on_body_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		InteractionManager.unregister_area(self)
