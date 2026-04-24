extends CanvasLayer

@export var menu_button: Button
@export var overlay: ColorRect
@export var panel: Control
@export var save_button: Button
@export var load_button: Button
@export var close_button: Button
@export var summary_label: Label
@export var status_label: Label

var _exploration_scene: Node


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = true

	if menu_button and not menu_button.pressed.is_connected(_toggle_menu):
		menu_button.pressed.connect(_toggle_menu)

	if save_button and not save_button.pressed.is_connected(_on_save_pressed):
		save_button.pressed.connect(_on_save_pressed)

	if load_button and not load_button.pressed.is_connected(_on_load_pressed):
		load_button.pressed.connect(_on_load_pressed)

	if close_button and not close_button.pressed.is_connected(_close_menu):
		close_button.pressed.connect(_close_menu)

	if overlay:
		overlay.visible = false

	if panel:
		panel.visible = false
		panel.scale = Vector2(0.96, 0.96)

	if not SaveManager.save_completed.is_connected(_on_save_completed):
		SaveManager.save_completed.connect(_on_save_completed)
	if not SaveManager.load_completed.is_connected(_on_load_completed):
		SaveManager.load_completed.connect(_on_load_completed)
	if not SaveManager.save_failed.is_connected(_on_save_failed):
		SaveManager.save_failed.connect(_on_save_failed)
	if not SaveManager.load_failed.is_connected(_on_load_failed):
		SaveManager.load_failed.connect(_on_load_failed)

	call_deferred("_resolve_exploration_scene")
	_refresh_ui_state()


func _process(_delta: float) -> void:
	_resolve_exploration_scene()
	var has_modal := _has_blocking_modal()
	if menu_button:
		menu_button.visible = not has_modal


func _unhandled_input(event: InputEvent) -> void:
	if not _is_menu_open():
		return

	if event.is_action_pressed("ui_cancel") or event.is_action_pressed("close_shop"):
		get_viewport().set_input_as_handled()
		_close_menu()


func _resolve_exploration_scene() -> void:
	if is_instance_valid(_exploration_scene):
		return

	var current_scene := get_tree().current_scene
	if current_scene and current_scene.scene_file_path == SaveManager.EXPLORATION_SCENE_PATH:
		_exploration_scene = current_scene


func _toggle_menu() -> void:
	if _is_menu_open():
		_close_menu()
	else:
		_open_menu()


func _open_menu() -> void:
	_resolve_exploration_scene()
	if not is_instance_valid(_exploration_scene):
		_set_status("Exploration Scene is not ready yet.", Color(1.0, 0.55, 0.55))
		return

	get_tree().paused = true
	_refresh_ui_state()

	if overlay:
		overlay.visible = true
	if panel:
		panel.visible = true
		panel.modulate.a = 0.0
		panel.scale = Vector2(0.96, 0.96)
		var tween := create_tween()
		tween.bind_node(self)
		tween.parallel().tween_property(panel, "modulate:a", 1.0, 0.18)
		tween.parallel().tween_property(panel, "scale", Vector2.ONE, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _close_menu() -> void:
	if not _is_menu_open():
		return

	var tween := create_tween()
	tween.bind_node(self)
	if panel:
		tween.parallel().tween_property(panel, "modulate:a", 0.0, 0.14)
		tween.parallel().tween_property(panel, "scale", Vector2(0.96, 0.96), 0.14).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	await tween.finished

	if overlay:
		overlay.visible = false
	if panel:
		panel.visible = false
	get_tree().paused = false


func _on_save_pressed() -> void:
	_resolve_exploration_scene()
	if not is_instance_valid(_exploration_scene):
		_set_status("Exploration Scene is not available.", Color(1.0, 0.55, 0.55))
		return

	SaveManager.save_exploration_scene(_exploration_scene)
	_refresh_ui_state()


func _on_load_pressed() -> void:
	_resolve_exploration_scene()
	if not is_instance_valid(_exploration_scene):
		_set_status("Exploration Scene is not available.", Color(1.0, 0.55, 0.55))
		return

	var was_loaded := SaveManager.load_exploration_scene(_exploration_scene)
	_refresh_ui_state()
	if was_loaded:
		await get_tree().process_frame
		_close_menu()


func _refresh_ui_state() -> void:
	var summary := SaveManager.get_save_summary()
	if load_button:
		load_button.disabled = summary.is_empty()

	if summary_label:
		if summary.is_empty():
			summary_label.text = "No save file yet."
		else:
			summary_label.text = "Last save: %s" % String(summary.get("saved_at_text", "Unknown"))

	if status_label and status_label.text.is_empty():
		_set_status("Save and load are available only in Exploration.", Color(0.73, 0.82, 0.96))


func _is_menu_open() -> bool:
	return panel != null and panel.visible


func _has_blocking_modal() -> bool:
	if _is_menu_open():
		return true

	var current_scene := get_tree().current_scene
	if current_scene == null:
		return false

	var shop_ui := current_scene.get_node_or_null("ShopUI")
	if shop_ui and shop_ui.visible:
		return true

	var notepad_ui := current_scene.get_node_or_null("NotepadUI")
	if notepad_ui and notepad_ui.visible:
		return true

	return false


func _set_status(message: String, color: Color) -> void:
	if status_label:
		status_label.text = message
		status_label.modulate = color


func _on_save_completed(metadata: Dictionary) -> void:
	_set_status("Saved successfully at %s" % String(metadata.get("saved_at_text", "")), Color(0.55, 1.0, 0.7))
	_refresh_ui_state()


func _on_load_completed(metadata: Dictionary) -> void:
	_set_status("Loaded save from %s" % String(metadata.get("saved_at_text", "")), Color(0.55, 0.9, 1.0))
	_refresh_ui_state()


func _on_save_failed(message: String) -> void:
	_set_status(message, Color(1.0, 0.55, 0.55))


func _on_load_failed(message: String) -> void:
	_set_status(message, Color(1.0, 0.55, 0.55))
