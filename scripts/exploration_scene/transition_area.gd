extends Area2D

@export var scene_path: SceneConfig

@export_group("Transition Settings")
## ความเร็วการเฟดภาพเข้า-ออก (เวลาที่ใช้วงกลมบีบ/ขยาย)
@export var fade_speed: float = 0.6
## เวลาดีเลย์ หลังจากบีบวงกลมมืดสนิท ก่อนที่จะสว่างขึ้นให้เห็นฉากใหม่
@export var fade_in_delay: float = 0.1

func _on_body_entered(body):
	# ป้องกันการ Trigger ซ้ำซ้อนถ้ากำลังเปลี่ยนฉากอยู่ (เช่น เพิ่งเกิดมาทับจุดเดิม)
	if get_tree().root.has_node("SceneManager"):
		if get_tree().root.get_node("SceneManager").is_transitioning:
			return
			
	# ตรวจสอบว่าเป็น Player หรือไม่ (ใช้ Group หรือ Class ก็ได้)
	if body.is_in_group("player"):
		if scene_path.scene_path == "":
			print("NO Destination!")
			return
			
		# [ไฮไลท์!] ปิด Trigger ชั่วคราวเพื่อป้องกันบั๊กดับเบิลชนแน่นอน 100%
		set_deferred("monitoring", false)
		
		call_deferred("_change_scene")
		call_deferred("_change_state")

func _change_scene():
	# เรียกใช้ระบบใหม่ที่หล่อเท่ พร้อมใส่ตัวแปรความเร็ว/ดีเลย์
	if get_tree().root.has_node("SceneManager"):
		var sm = get_tree().root.get_node("SceneManager")
		sm.change_scene(scene_path.scene_path, fade_speed, fade_in_delay)
	else:
		# ถ้ายังไม่ได้ลงทะเบียน ก็ใช้ของเก่าไปก่อนกัน Error
		get_tree().change_scene_to_file(scene_path.scene_path)
	
func _change_state():
	var scene_state = scene_path.scene_state
	Autoload.current_state = scene_state
	print(scene_state)
