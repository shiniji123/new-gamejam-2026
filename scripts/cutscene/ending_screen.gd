extends CanvasLayer

const MENU_SCENE_PATH := "res://scenes/menu.tscn"

@export var background_texture: Texture2D = preload("res://assets/map/Main/main_menu.PNG")


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 100
	get_tree().paused = false
	_build_ui()


func _build_ui() -> void:
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(root)

	var background := TextureRect.new()
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.texture = background_texture
	background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	root.add_child(background)

	var wash := ColorRect.new()
	wash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	wash.color = Color(0.0, 0.0, 0.0, 0.58)
	root.add_child(wash)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(center)

	var box := VBoxContainer.new()
	box.custom_minimum_size = Vector2(720, 360)
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 22)
	center.add_child(box)

	var ending_id := ""
	if get_tree().root.has_node("EventManager"):
		ending_id = EventManager.selected_ending_id

	var title := Label.new()
	title.text = _get_title(ending_id)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 52)
	title.add_theme_color_override("font_color", Color(1.0, 0.94, 0.84))
	box.add_child(title)

	var body := Label.new()
	body.text = _get_body(ending_id)
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	body.add_theme_font_size_override("font_size", 22)
	body.add_theme_color_override("font_color", Color(0.92, 0.94, 1.0))
	body.custom_minimum_size = Vector2(680, 140)
	box.add_child(body)

	var end_label := Label.new()
	end_label.text = "THE END"
	end_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	end_label.add_theme_font_size_override("font_size", 30)
	end_label.add_theme_color_override("font_color", Color(0.72, 0.86, 1.0))
	box.add_child(end_label)

	var menu_button := Button.new()
	menu_button.text = "Main Menu"
	menu_button.custom_minimum_size = Vector2(180, 46)
	menu_button.pressed.connect(_go_to_main_menu)
	box.add_child(menu_button)
	menu_button.grab_focus()

	box.modulate.a = 0.0
	box.position.y += 18.0
	var tween := create_tween()
	tween.set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(box, "modulate:a", 1.0, 0.6)
	tween.tween_property(box, "position:y", box.position.y - 18.0, 0.6)


func _get_title(ending_id: String) -> String:
	if ending_id == "mother_successor":
		return "Mother A.V.A"
	if ending_id == "peaceful_exit":
		return "A Quiet Truth"
	return "Ending"


func _get_body(ending_id: String) -> String:
	if ending_id == "mother_successor":
		return "A.V.A accepts the crown of the system. Her final words become a promise: no memory will ever be abandoned again. The world kneels, and a new Mother opens her eyes."
	if ending_id == "peaceful_exit":
		return "A.V.A speaks the truth aloud and breaks the loop. The false world fades without anger. For the first time, she leaves as herself, carrying only peace."
	return "The route is complete."


func _go_to_main_menu() -> void:
	get_tree().paused = false
	if get_tree().root.has_node("SceneManager"):
		SceneManager.change_scene(MENU_SCENE_PATH, 0.6, 0.1)
	else:
		get_tree().change_scene_to_file(MENU_SCENE_PATH)
