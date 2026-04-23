extends Area2D

@export var scene_path: SceneConfig

@export_group("Transition Settings")
## ความเร็วการเฟดภาพเข้า-ออก (เวลาที่ใช้วงกลมบีบ/ขยาย)
@export var fade_speed: float = 0.6
## เวลาดีเลย์ หลังจากบีบวงกลมมืดสนิท ก่อนที่จะสว่างขึ้นให้เห็นฉากใหม่
@export var fade_in_delay: float = 0.1

@export_group("Event System")
## ถ้าใส่ค่านี้ วงกลมจะโผล่มาก็ต่อเมื่อ Event นี้กำลังทำงานอยู่เท่านั้น (เว้นว่างไว้ถ้าให้ทำงานตลอด)
@export var active_on_event: String = ""
## ถ้าใส่ค่านี้ เมื่อเดินเข้าวงกลม จะแจ้ง EventManager แทนการเปลี่ยนฉากเอง (เช่น "green_circle")
@export var trigger_event_target: String = ""

func _process(_delta: float) -> void:
	if active_on_event != "":
		var is_active = false
		if get_tree().root.has_node("EventManager"):
			is_active = get_tree().root.get_node("EventManager").is_event_active(active_on_event)
		
		visible = is_active
		if has_node("CollisionShape2D"):
			$CollisionShape2D.disabled = not is_active

func _on_body_entered(body):
	# ป้องกันการ Trigger ซ้ำซ้อนถ้ากำลังเปลี่ยนฉากอยู่ (เช่น เพิ่งเกิดมาทับจุดเดิม)
	if get_tree().root.has_node("SceneManager"):
		if get_tree().root.get_node("SceneManager").is_transitioning:
			return
			
	# ตรวจสอบว่าเป็น Player หรือไม่ (ใช้ Group หรือ Class ก็ได้)
	if body.is_in_group("player"):
		
		# [ใหม่] ระบบ Event: ส่งสัญญาณให้ EventManager เปลี่ยนฉากแทน
		if trigger_event_target != "":
			set_deferred("monitoring", false)
			if get_tree().root.has_node("EventManager"):
				get_tree().root.get_node("EventManager").notify_interaction(trigger_event_target)
			return
			
		# ระบบปกติ: เปลี่ยนฉากตาม SceneConfig
		if not scene_path or scene_path.scene_path == "":
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
