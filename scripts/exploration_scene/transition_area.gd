extends Area2D

@export var scene_path: SceneConfig

func _on_body_entered(body):
	# ตรวจสอบว่าเป็น Player หรือไม่ (ใช้ Group หรือ Class ก็ได้)
	if body.is_in_group("player"):
		if scene_path.scene_path == "":
			print("NO Destination!")
			return
		call_deferred("_change_scene")
		call_deferred("_change_state")
		
func _change_scene():
	get_tree().change_scene_to_file(scene_path.scene_path)
	
func _change_state():
	var scene_state = scene_path.scene_state
	Autoload.current_state = scene_state
	print(scene_state)
