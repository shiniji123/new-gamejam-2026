extends Area2D

@export_file var target_scene_path: String

func _on_body_entered(body):
	# ตรวจสอบว่าเป็น Player หรือไม่ (ใช้ Group หรือ Class ก็ได้)
	if body.is_in_group("player"):
		if target_scene_path == "":
			print("ไม่ได้เลือกฉากปลายทางไว้!")
			return
			
		call_deferred("_change_scene")

func _change_scene():
	get_tree().change_scene_to_file(target_scene_path)
