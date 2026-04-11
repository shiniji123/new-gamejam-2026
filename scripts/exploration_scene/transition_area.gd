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
	# เรียกใช้ระบบใหม่ที่หล่อเท่ (ถ้าลงทะเบียน Autoload ไว้แล้วนะ!)
	if get_tree().root.has_node("SceneManager"):
		var sm = get_tree().root.get_node("SceneManager")
		sm.change_scene(scene_path.scene_path)
	else:
		# ถ้ายังไม่ได้ลงทะเบียน ก็ใช้ของเก่าไปก่อนกัน Error
		get_tree().change_scene_to_file(scene_path.scene_path)
	
func _change_state():
	var scene_state = scene_path.scene_state
	Autoload.current_state = scene_state
	print(scene_state)
