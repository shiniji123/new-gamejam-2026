extends Node
## ===================================================
## EventManager — ระบบจัดการลำดับเหตุการณ์ทั้งเกม
## ===================================================
## รองรับ complete_condition หลายแบบ:
##   - "interact"          → ผู้เล่นเข้าไปเจอ TransitionArea ที่ตั้ง target ตรงกัน
##   - "all_waves_cleared" → ชนะการต่อสู้ทุก wave
##   - "dialogue"          → จบบทสนทนา
##   - "notepad_read"      → ผู้เล่นอ่าน notepad จบ

signal event_started(event_id: String)
signal event_completed(event_id: String)
signal all_events_completed

var event_timeline: Array[Dictionary] = [
	{
		"id": "intro_talk_auto",
		"type": "exploration",
		"scene": "res://scenes/exploration_scene/exploration_scene.tscn",
		"complete_condition": "dialogue",
		"description": "เริ่มเรื่อง: NPC ทักทายผู้เล่นอัตโนมัติเมื่อเริ่มเกม",
	},
	{
		"id": "start_game_notepad",
		"type": "exploration",
		"scene": "res://scenes/exploration_scene/exploration_scene.tscn",
		"complete_condition": "interact",
		"complete_target": "first_notepad",
		"description": "คำสั่งจาก NPC: ให้อ่าน Notepad ใกล้ๆ",
	},
	{
		"id": "talk_after_read",
		"type": "exploration",
		"scene": "res://scenes/exploration_scene/exploration_scene.tscn",
		"complete_condition": "interact",
		"complete_target": "village_npc",
		"description": "กลับไปรายงาน NPC ว่าอ่านเสร็จแล้ว",
	},
	{
		"id": "go_to_combat",
		"type": "exploration",
		"scene": "res://scenes/exploration_scene/exploration_scene.tscn",
		"complete_condition": "interact",
		"complete_target": "green_circle",
		"description": "เดินเข้าวงกลมเพื่อต่อสู้",
	},
	{
		"id": "fight_wave_1",
		"type": "fight",
		"scene": "res://scenes/fight_scene/fight_scene.tscn",
		"complete_condition": "all_waves_cleared",
		"description": "การต่อสู้ครั้งที่ 1",
	},
	{
		"id": "talk_after_win",
		"type": "exploration",
		"scene": "res://scenes/exploration_scene/exploration_scene.tscn",
		"complete_condition": "interact",
		"complete_target": "village_npc",
		"description": "หลังสู้: กลับมาคุยกับ NPC",
	},
	{
		"id": "read_notepad_1",
		"type": "exploration",
		"scene": "res://scenes/exploration_scene/exploration_scene.tscn",
		"complete_condition": "interact",
		"complete_target": "second_notepad",
		"description": "อ่านบันทึกฉบับที่สองเพื่อหาต้นตอของสัญญาณผิดปกติ",
	},
	{
		"id": "talk_after_read_2",
		"type": "exploration",
		"scene": "res://scenes/exploration_scene/exploration_scene.tscn",
		"complete_condition": "interact",
		"complete_target": "village_npc",
		"description": "กลับมาคุยกับ NPC หลังอ่านบันทึกฉบับที่สอง",
	},
	{
		"id": "go_to_combat_2",
		"type": "exploration",
		"scene": "res://scenes/exploration_scene/exploration_scene.tscn",
		"complete_condition": "interact",
		"complete_target": "green_circle_2",
		"description": "เข้าสู่ลานประลองครั้งที่สองเพื่อทดสอบบอส",
	},
	{
		"id": "fight_wave_2",
		"type": "fight",
		"scene": "res://scenes/fight_scene/fight_scene.tscn",
		"complete_condition": "all_waves_cleared",
		"description": "Fight 2: Boss 2 test",
	},
	{
		"id": "talk_after_boss_win",
		"type": "exploration",
		"scene": "res://scenes/exploration_scene/exploration_scene.tscn",
		"complete_condition": "interact",
		"complete_target": "village_npc",
		"description": "Report back after Boss 2",
	},
	{
		"id": "read_notepad_2",
		"type": "exploration",
		"scene": "res://scenes/exploration_scene/exploration_scene.tscn",
		"complete_condition": "interact",
		"complete_target": "third_notepad",
		"description": "Read the third note before Boss 3",
	},
	{
		"id": "talk_after_read_3",
		"type": "exploration",
		"scene": "res://scenes/exploration_scene/exploration_scene.tscn",
		"complete_condition": "interact",
		"complete_target": "village_npc",
		"description": "Talk to NPC after the third note",
	},
	{
		"id": "go_to_combat_3",
		"type": "exploration",
		"scene": "res://scenes/exploration_scene/exploration_scene.tscn",
		"complete_condition": "interact",
		"complete_target": "green_circle_3",
		"description": "Enter the arena for Boss 3",
	},
	{
		"id": "fight_wave_3",
		"type": "fight",
		"scene": "res://scenes/fight_scene/fight_scene.tscn",
		"complete_condition": "all_waves_cleared",
		"description": "Fight 3: Boss 3 test",
	},
	{
		"id": "memory_cutscene_after_fight_3",
		"type": "cutscene",
		"scene": "res://scenes/exploration_scene/exploration_scene.tscn",
		"complete_condition": "cutscene",
		"complete_target": "memory_cutscene_after_fight_3",
		"description": "A.V.A memory deletion cutscene",
	},
	{
		"id": "talk_after_memory_cutscene",
		"type": "exploration",
		"scene": "res://scenes/exploration_scene/exploration_scene.tscn",
		"complete_condition": "interact",
		"complete_target": "village_npc",
		"description": "Return to normal story flow after the memory cutscene",
	},
	{
		"id": "read_final_notepad",
		"type": "exploration",
		"scene": "res://scenes/exploration_scene/exploration_scene.tscn",
		"complete_condition": "interact",
		"complete_target": "final_notepad",
		"description": "Read the final note before Mother",
	},
	{
		"id": "talk_after_final_note",
		"type": "exploration",
		"scene": "res://scenes/exploration_scene/exploration_scene.tscn",
		"complete_condition": "interact",
		"complete_target": "village_npc",
		"description": "Talk to NPC before Final Boss",
	},
	{
		"id": "go_to_final_boss",
		"type": "exploration",
		"scene": "res://scenes/exploration_scene/exploration_scene.tscn",
		"complete_condition": "interact",
		"complete_target": "final_boss_circle",
		"description": "Enter Mother's arena",
	},
	{
		"id": "fight_final_boss",
		"type": "fight",
		"scene": "res://scenes/fight_scene/fight_scene.tscn",
		"complete_condition": "all_waves_cleared",
		"description": "Final Boss: Mother",
	},
	{
		"id": "mother_final_choice",
		"type": "ending_choice",
		"scene": "res://scenes/cutscene/final_mother_choice.tscn",
		"complete_condition": "choice",
		"description": "Talk with Mother and choose an ending",
	}
]

var current_event_index: int = 0
var is_game_completed: bool = false
var selected_ending_id: String = ""

func _ready() -> void:
	if get_tree().root.has_node("RunManager"):
		RunManager.start_new_run()

	# ไม่ให้เริ่ม Event อัตโนมัติเมื่อเปิดเกม เพื่อให้แสดงหน้า Menu ก่อน
	# call_deferred("start_current_event")

func start_current_event() -> void:
	if current_event_index >= event_timeline.size():
		is_game_completed = true
		all_events_completed.emit()
		print("🎉 จบเกม! ทุก Event เสร็จสิ้นแล้ว")
		return

	var event = event_timeline[current_event_index]
	print("🎬 เริ่ม Event: %s (%s)" % [event.id, event.description])
	event_started.emit(event.id)
	
	var current_scene_path = ""
	if get_tree().current_scene:
		current_scene_path = get_tree().current_scene.scene_file_path
		
	if event.scene != current_scene_path:
		if SceneManager:
			SceneManager.change_scene(event.scene)
		else:
			get_tree().change_scene_to_file(event.scene)
	else:
		print("⚡ เปลี่ยน Event ในฉากเดิม (ข้ามการโหลดฉากซ้ำ)")

func complete_current_event() -> void:
	if current_event_index >= event_timeline.size():
		return

	var event = event_timeline[current_event_index]
	print("✅ Event สำเร็จ: %s" % event.id)
	event_completed.emit(event.id)
	
	current_event_index += 1
	start_current_event()

func notify_interaction(target_name: String) -> void:
	var event = get_current_event()
	if not event: return
	
	if event.complete_condition == "interact" and event.complete_target == target_name:
		complete_current_event()

func notify_fight_cleared() -> void:
	var event = get_current_event()
	if not event: return
	
	if event.complete_condition == "all_waves_cleared":
		complete_current_event()

func notify_cutscene_finished(target_name: String) -> void:
	var event = get_current_event()
	if not event: return
	
	if event.complete_condition == "cutscene" and event.get("complete_target", "") == target_name:
		complete_current_event()

func set_selected_ending(ending_id: String) -> void:
	selected_ending_id = ending_id
	complete_current_event()

func notify_dialogue_ended() -> void:
	var event = get_current_event()
	if not event: return
	
	if event.complete_condition == "dialogue":
		complete_current_event()

func get_current_event() -> Dictionary:
	if current_event_index < event_timeline.size():
		return event_timeline[current_event_index]
	return {}

func is_event_active(event_id: String) -> bool:
	var event = get_current_event()
	return event.get("id", "") == event_id

func is_event_reached(event_id: String) -> bool:
	## ตรวจสอบว่า Event นี้ถูก "ถึง" แล้วหรือยัง (กำลังทำอยู่ หรือผ่านไปแล้ว)
	## ใช้สำหรับ Notepad ที่ต้องการให้โผล่มาตลอดหลังจากถึง Event นั้นๆ
	for i in range(event_timeline.size()):
		if event_timeline[i].get("id", "") == event_id:
			return current_event_index >= i
	return false


func get_save_data() -> Dictionary:
	return {
		"current_event_index": current_event_index,
		"is_game_completed": is_game_completed,
		"selected_ending_id": selected_ending_id,
	}


func restore_from_save(data: Dictionary) -> void:
	current_event_index = clampi(int(data.get("current_event_index", 0)), 0, event_timeline.size())
	is_game_completed = bool(data.get("is_game_completed", current_event_index >= event_timeline.size()))
	selected_ending_id = String(data.get("selected_ending_id", ""))
