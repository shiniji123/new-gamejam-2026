extends Node

signal save_completed(metadata: Dictionary)
signal load_completed(metadata: Dictionary)
signal save_failed(message: String)
signal load_failed(message: String)
signal active_slot_changed(slot_id: int)

const SAVE_VERSION := 2
const AUTO_SAVE_SLOT_ID := 0
const DEFAULT_MANUAL_SLOT_ID := 1
const INVALID_SLOT_ID := -1
const MANUAL_SLOT_IDS := [1, 2, 3]
const EXPLORATION_SCENE_PATH := "res://scenes/exploration_scene/exploration_scene.tscn"
const MENU_SCENE_PATH := "res://scenes/menu.tscn"

var active_manual_slot_id: int = DEFAULT_MANUAL_SLOT_ID
var _pending_load_slot_id: int = INVALID_SLOT_ID
var _pending_new_game_bootstrap: bool = false


func get_manual_slot_ids() -> Array[int]:
	var slot_ids: Array[int] = []
	for slot_id in MANUAL_SLOT_IDS:
		slot_ids.append(slot_id)
	return slot_ids


func get_slot_label(slot_id: int) -> String:
	if slot_id == AUTO_SAVE_SLOT_ID:
		return "Auto Save"
	if _is_manual_slot(slot_id):
		return "Slot %d" % slot_id
	return "Unknown Slot"


func get_active_manual_slot_id() -> int:
	return active_manual_slot_id


func set_active_manual_slot_id(slot_id: int) -> void:
	if not _is_manual_slot(slot_id):
		return

	if active_manual_slot_id == slot_id:
		return

	active_manual_slot_id = slot_id
	active_slot_changed.emit(active_manual_slot_id)


func begin_new_game(slot_id: int = DEFAULT_MANUAL_SLOT_ID) -> void:
	set_active_manual_slot_id(slot_id)
	_pending_load_slot_id = INVALID_SLOT_ID
	_pending_new_game_bootstrap = true
	Autoload.player_current_hp = -1.0
	RunManager.start_new_run()
	EventManager.restore_from_save({
		"current_event_index": 0,
		"is_game_completed": false,
	})


func queue_load_from_slot(slot_id: int) -> bool:
	if not has_save(slot_id):
		return false

	if _is_manual_slot(slot_id):
		set_active_manual_slot_id(slot_id)

	_pending_new_game_bootstrap = false
	_pending_load_slot_id = slot_id
	return true


func apply_pending_state_if_available(exploration_scene: Node) -> bool:
	if _pending_load_slot_id != INVALID_SLOT_ID:
		var queued_slot_id := _pending_load_slot_id
		_pending_load_slot_id = INVALID_SLOT_ID
		_pending_new_game_bootstrap = false
		return load_exploration_scene(exploration_scene, queued_slot_id)

	if _pending_new_game_bootstrap:
		_pending_new_game_bootstrap = false
		EventManager.start_current_event()
		return true

	return false


func autosave_exploration_scene(exploration_scene: Node) -> bool:
	return save_exploration_scene(exploration_scene, AUTO_SAVE_SLOT_ID)


func has_save(slot_id: int = DEFAULT_MANUAL_SLOT_ID) -> bool:
	if not _is_valid_slot(slot_id):
		return false
	return FileAccess.file_exists(_get_slot_path(slot_id))


func get_save_summary(slot_id: int = DEFAULT_MANUAL_SLOT_ID) -> Dictionary:
	if not has_save(slot_id):
		return {}

	var snapshot := _read_snapshot(slot_id)
	if snapshot.is_empty():
		return {}

	return _build_summary(snapshot, slot_id)


func list_slot_summaries(include_auto: bool = true) -> Array[Dictionary]:
	var summaries: Array[Dictionary] = []
	if include_auto:
		summaries.append(get_save_summary(AUTO_SAVE_SLOT_ID))

	for slot_id in MANUAL_SLOT_IDS:
		summaries.append(get_save_summary(slot_id))

	return summaries


func format_summary_text(summary: Dictionary, include_empty_text: bool = true) -> String:
	if summary.is_empty():
		return "Empty slot" if include_empty_text else ""

	return "%s\n%s\nCoins: %d   Wave: %d" % [
		String(summary.get("saved_at_text", "Unknown time")),
		String(summary.get("progress_text", "No progress data")),
		int(summary.get("run_coin", 0)),
		int(summary.get("current_wave", 0)),
	]


func save_exploration_scene(exploration_scene: Node, slot_id: int = INVALID_SLOT_ID) -> bool:
	var target_slot_id := active_manual_slot_id if slot_id == INVALID_SLOT_ID else slot_id
	if not _is_valid_slot(target_slot_id):
		save_failed.emit("Invalid save slot.")
		return false

	var scene_error := _validate_exploration_scene(exploration_scene)
	if scene_error != "":
		save_failed.emit(scene_error)
		return false

	if _is_manual_slot(target_slot_id):
		set_active_manual_slot_id(target_slot_id)

	var snapshot := _build_snapshot(exploration_scene, target_slot_id)
	var file := FileAccess.open(_get_slot_path(target_slot_id), FileAccess.WRITE)
	if file == null:
		save_failed.emit("Cannot open save file for writing.")
		return false

	file.store_string(JSON.stringify(snapshot, "\t"))

	var metadata := _build_summary(snapshot, target_slot_id)
	save_completed.emit(metadata)
	return true


func load_exploration_scene(exploration_scene: Node, slot_id: int = INVALID_SLOT_ID) -> bool:
	var target_slot_id := active_manual_slot_id if slot_id == INVALID_SLOT_ID else slot_id
	if not _is_valid_slot(target_slot_id):
		load_failed.emit("Invalid save slot.")
		return false

	var scene_error := _validate_exploration_scene(exploration_scene)
	if scene_error != "":
		load_failed.emit(scene_error)
		return false

	if not has_save(target_slot_id):
		load_failed.emit("%s is empty." % get_slot_label(target_slot_id))
		return false

	var snapshot := _read_snapshot(target_slot_id)
	if snapshot.is_empty():
		load_failed.emit("Save file is empty or invalid.")
		return false

	if String(snapshot.get("scene_path", "")) != EXPLORATION_SCENE_PATH:
		load_failed.emit("Save file was not created in Exploration Scene.")
		return false

	if _is_manual_slot(target_slot_id):
		set_active_manual_slot_id(target_slot_id)

	_apply_snapshot(exploration_scene, snapshot)
	var metadata := _build_summary(snapshot, target_slot_id)
	load_completed.emit(metadata)
	return true


func _validate_exploration_scene(exploration_scene: Node) -> String:
	if exploration_scene == null:
		return "Exploration Scene is not available."

	if String(exploration_scene.scene_file_path) != EXPLORATION_SCENE_PATH:
		return "Save and load are only available in Exploration Scene."

	return ""


func _build_snapshot(exploration_scene: Node, slot_id: int) -> Dictionary:
	var player = exploration_scene.get_node_or_null("Player")
	var hurtbox = player.get_node_or_null("HurtboxComponent") if player else null
	var notepad_ui = exploration_scene.get_node_or_null("NotepadUI")
	var shop_ui = exploration_scene.get_node_or_null("ShopUI")
	var now_unix := Time.get_unix_time_from_system()

	return {
		"version": SAVE_VERSION,
		"slot_id": slot_id,
		"slot_label": get_slot_label(slot_id),
		"scene_path": EXPLORATION_SCENE_PATH,
		"saved_at_unix": now_unix,
		"saved_at_text": Time.get_datetime_string_from_system(false, true),
		"autoload": {
			"current_state": int(Autoload.current_state),
			"player_current_hp": float(Autoload.player_current_hp),
		},
		"player": {
			"position": _vector2_to_dict(player.global_position if player else Vector2.ZERO),
			"current_hp": float(hurtbox.current_hp if hurtbox else Autoload.player_current_hp),
		},
		"event": EventManager.get_save_data(),
		"run": RunManager.get_save_data(),
		"notes": notepad_ui.get_save_data() if notepad_ui and notepad_ui.has_method("get_save_data") else [],
		"shop": shop_ui.get_save_data() if shop_ui and shop_ui.has_method("get_save_data") else {},
	}


func _apply_snapshot(exploration_scene: Node, snapshot: Dictionary) -> void:
	get_tree().paused = false

	Autoload.current_state = Autoload.State.EXPLORE
	var autoload_data: Dictionary = snapshot.get("autoload", {})
	Autoload.player_current_hp = float(autoload_data.get("player_current_hp", -1.0))

	var run_data: Dictionary = snapshot.get("run", {})
	RunManager.restore_from_save(run_data)

	var event_data: Dictionary = snapshot.get("event", {})
	EventManager.restore_from_save(event_data)

	var player_data: Dictionary = snapshot.get("player", {})
	var player = exploration_scene.get_node_or_null("Player")
	if player:
		player.global_position = _dict_to_vector2(player_data.get("position", {}))
		player.velocity = Vector2.ZERO
		player.knockback_velocity = Vector2.ZERO
		player.is_dead = false
		if player.has_node("AnimatedSprite2D"):
			player.get_node("AnimatedSprite2D").play("idle")
		player.set_physics_process(true)

		var hurtbox = player.get_node_or_null("HurtboxComponent")
		if hurtbox:
			var saved_hp := float(player_data.get("current_hp", hurtbox.max_hp))
			hurtbox.current_hp = clampf(saved_hp, 0.0, hurtbox.max_hp)
			Autoload.player_current_hp = hurtbox.current_hp
			hurtbox.took_damage.emit(hurtbox.current_hp, player.global_position)

	var notes_data = snapshot.get("notes", [])
	var notepad_ui = exploration_scene.get_node_or_null("NotepadUI")
	if notepad_ui and notepad_ui.has_method("restore_from_save"):
		notepad_ui.restore_from_save(notes_data)

	var shop_data: Dictionary = snapshot.get("shop", {})
	var shop_ui = exploration_scene.get_node_or_null("ShopUI")
	if shop_ui and shop_ui.has_method("restore_from_save"):
		shop_ui.restore_from_save(shop_data)


func _build_summary(snapshot: Dictionary, slot_id: int) -> Dictionary:
	var event_data: Dictionary = snapshot.get("event", {})
	var run_data: Dictionary = snapshot.get("run", {})
	var event_index := int(event_data.get("current_event_index", 0))
	var event_id := _get_event_id_from_index(event_index)

	return {
		"slot_id": slot_id,
		"slot_label": get_slot_label(slot_id),
		"is_auto": slot_id == AUTO_SAVE_SLOT_ID,
		"version": int(snapshot.get("version", 0)),
		"saved_at_unix": int(snapshot.get("saved_at_unix", 0)),
		"saved_at_text": String(snapshot.get("saved_at_text", "")),
		"event_index": event_index,
		"event_id": event_id,
		"progress_text": _format_progress_text(event_index, event_id),
		"run_coin": int(run_data.get("run_coin", 0)),
		"current_wave": int(run_data.get("current_wave", 0)),
	}


func _format_progress_text(event_index: int, event_id: String) -> String:
	if event_id != "":
		return "Objective: %s" % event_id
	if event_index >= EventManager.event_timeline.size():
		return "Objective: Completed"
	return "Objective: Start"


func _read_snapshot(slot_id: int) -> Dictionary:
	var file := FileAccess.open(_get_slot_path(slot_id), FileAccess.READ)
	if file == null:
		return {}

	var content := file.get_as_text()
	if content.is_empty():
		return {}

	var parsed = JSON.parse_string(content)
	if typeof(parsed) != TYPE_DICTIONARY:
		return {}

	return parsed


func _get_slot_path(slot_id: int) -> String:
	if slot_id == AUTO_SAVE_SLOT_ID:
		return "user://save_auto.json"
	return "user://save_slot_%d.json" % slot_id


func _vector2_to_dict(value: Vector2) -> Dictionary:
	return {
		"x": value.x,
		"y": value.y,
	}


func _dict_to_vector2(data: Variant) -> Vector2:
	if typeof(data) != TYPE_DICTIONARY:
		return Vector2.ZERO

	return Vector2(
		float(data.get("x", 0.0)),
		float(data.get("y", 0.0))
	)


func _get_event_id_from_index(event_index: int) -> String:
	if event_index >= 0 and event_index < EventManager.event_timeline.size():
		return String(EventManager.event_timeline[event_index].get("id", ""))
	if event_index >= EventManager.event_timeline.size():
		return "completed"
	return ""


func _is_manual_slot(slot_id: int) -> bool:
	return MANUAL_SLOT_IDS.has(slot_id)


func _is_valid_slot(slot_id: int) -> bool:
	return slot_id == AUTO_SAVE_SLOT_ID or _is_manual_slot(slot_id)
