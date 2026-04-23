extends Node
## ===================================================
## EventManager — ระบบจัดการลำดับเหตุการณ์ทั้งเกม
## ===================================================

signal event_started(event_id: String)
signal event_completed(event_id: String)
signal all_events_completed

var event_timeline: Array[Dictionary] = [
	{
		"id": "intro_talk",
		"type": "exploration",
		"scene": "res://scenes/exploration_scene/exploration_scene.tscn",
		"complete_condition": "interact",
		"complete_target": "village_npc",
		"description": "เริ่มเรื่อง: คุยกับ NPC ในหมู่บ้าน",
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
	}
]

var current_event_index: int = 0
var is_game_completed: bool = false

func _ready() -> void:
	pass

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
