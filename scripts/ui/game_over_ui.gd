extends CanvasLayer

const MENU_SCENE_PATH := "res://scenes/menu.tscn"

var _panel: PanelContainer


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 120
	_build_ui()
	_play_intro()


func _build_ui() -> void:
	var overlay := ColorRect.new()
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.color = Color(0.02, 0.0, 0.0, 0.82)
	add_child(overlay)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(center)

	_panel = PanelContainer.new()
	_panel.custom_minimum_size = Vector2(420, 260)
	center.add_child(_panel)

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.015, 0.02, 0.96)
	style.border_color = Color(0.85, 0.08, 0.09, 0.8)
	style.set_border_width_all(2)
	style.set_corner_radius_all(8)
	style.content_margin_left = 34
	style.content_margin_top = 28
	style.content_margin_right = 34
	style.content_margin_bottom = 28
	_panel.add_theme_stylebox_override("panel", style)

	var box := VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 18)
	_panel.add_child(box)

	var title := Label.new()
	title.text = "GAME OVER"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 42)
	title.add_theme_color_override("font_color", Color(1.0, 0.2, 0.18))
	box.add_child(title)

	var subtitle := Label.new()
	subtitle.text = "The current fight has collapsed."
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", 16)
	subtitle.add_theme_color_override("font_color", Color(0.95, 0.82, 0.82))
	box.add_child(subtitle)

	var buttons := HBoxContainer.new()
	buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	buttons.add_theme_constant_override("separation", 14)
	box.add_child(buttons)

	var retry_button := _create_button("Retry")
	retry_button.pressed.connect(_retry_fight)
	buttons.add_child(retry_button)

	var menu_button := _create_button("Main Menu")
	menu_button.pressed.connect(_go_to_main_menu)
	buttons.add_child(menu_button)

	retry_button.grab_focus()


func _create_button(text: String) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(150, 44)
	button.add_theme_font_size_override("font_size", 16)
	button.add_theme_color_override("font_color", Color(1.0, 0.92, 0.92))

	var normal := StyleBoxFlat.new()
	normal.bg_color = Color(0.32, 0.03, 0.045, 0.95)
	normal.set_corner_radius_all(6)
	button.add_theme_stylebox_override("normal", normal)

	var hover := normal.duplicate() as StyleBoxFlat
	hover.bg_color = Color(0.56, 0.06, 0.08, 1.0)
	button.add_theme_stylebox_override("hover", hover)

	var pressed := normal.duplicate() as StyleBoxFlat
	pressed.bg_color = Color(0.82, 0.09, 0.11, 1.0)
	button.add_theme_stylebox_override("pressed", pressed)

	return button


func _play_intro() -> void:
	_panel.scale = Vector2(0.94, 0.94)
	_panel.modulate.a = 0.0
	var tween := create_tween()
	tween.set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(_panel, "scale", Vector2.ONE, 0.25)
	tween.tween_property(_panel, "modulate:a", 1.0, 0.25)


func _retry_fight() -> void:
	get_tree().paused = false
	Autoload.player_current_hp = -1.0

	var current_scene := get_tree().current_scene
	var scene_path := current_scene.scene_file_path if current_scene else "res://scenes/fight_scene/fight_scene.tscn"
	if get_tree().root.has_node("SceneManager"):
		SceneManager.change_scene(scene_path, 0.35, 0.05)
	else:
		get_tree().change_scene_to_file(scene_path)


func _go_to_main_menu() -> void:
	get_tree().paused = false
	Autoload.player_current_hp = -1.0

	if get_tree().root.has_node("SceneManager"):
		SceneManager.change_scene(MENU_SCENE_PATH, 0.35, 0.05)
	else:
		get_tree().change_scene_to_file(MENU_SCENE_PATH)
