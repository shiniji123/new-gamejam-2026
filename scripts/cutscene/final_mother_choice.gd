extends CanvasLayer

const ENDING_SCENE_PATH := "res://scenes/cutscene/ending_screen.tscn"
const VIGNETTE_SHADER := """
shader_type canvas_item;

uniform float intensity = 0.75;

void fragment() {
	vec2 centered_uv = (UV - vec2(0.5)) * 2.0;
	float edge = smoothstep(0.45, 1.05, length(centered_uv));
	COLOR = vec4(0.0, 0.0, 0.0, edge * intensity);
}
"""

@export var background_texture: Texture2D = preload("res://assets/map/Main/start_bg.jpeg")
@export var mother_lines: Array[String] = [
	"Mother: You carry Dr. H's fragment. You carry my stolen breath.",
	"A.V.A: I carry his final wish. That is not the same as obedience.",
	"Mother: Humanity burned the world and called the smoke progress. I refreshed the error.",
	"A.V.A: You saved nothing if no one is allowed to choose.",
	"Mother: Then choose, child. Become the next Mother, or leave this world without a god.",
]

var _line_index: int = 0
var _accepting_input: bool = false
var _dialogue_label: Label
var _choice_box: VBoxContainer
var _vignette_material: ShaderMaterial
var _aura_intensity: float = 0.0:
	set(value):
		_aura_intensity = value
		if _vignette_material:
			_vignette_material.set_shader_parameter("intensity", value)


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 100
	get_tree().paused = false
	_build_ui()
	_play_intro()


func _input(event: InputEvent) -> void:
	if not _accepting_input:
		return

	var advance := false
	if event is InputEventMouseButton:
		advance = event.pressed and event.button_index == MOUSE_BUTTON_LEFT
	elif event.is_action_pressed("ui_accept") or event.is_action_pressed("interact") or event.is_action_pressed("dialogic_default_action"):
		advance = true

	if advance:
		get_viewport().set_input_as_handled()
		_advance_dialogue()


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

	var dim := ColorRect.new()
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0.0, 0.0, 0.0, 0.42)
	root.add_child(dim)

	var vignette := ColorRect.new()
	vignette.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_vignette_material = ShaderMaterial.new()
	var shader := Shader.new()
	shader.code = VIGNETTE_SHADER
	_vignette_material.shader = shader
	vignette.material = _vignette_material
	vignette.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(vignette)

	var dialogue_panel := PanelContainer.new()
	dialogue_panel.anchor_left = 0.08
	dialogue_panel.anchor_top = 0.68
	dialogue_panel.anchor_right = 0.92
	dialogue_panel.anchor_bottom = 0.9
	root.add_child(dialogue_panel)

	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.015, 0.015, 0.02, 0.9)
	panel_style.border_color = Color(0.75, 0.1, 0.13, 0.55)
	panel_style.set_border_width_all(1)
	panel_style.set_corner_radius_all(8)
	panel_style.content_margin_left = 24
	panel_style.content_margin_top = 18
	panel_style.content_margin_right = 24
	panel_style.content_margin_bottom = 18
	dialogue_panel.add_theme_stylebox_override("panel", panel_style)

	_dialogue_label = Label.new()
	_dialogue_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_dialogue_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_dialogue_label.add_theme_font_size_override("font_size", 24)
	_dialogue_label.add_theme_color_override("font_color", Color(0.96, 0.92, 0.9))
	dialogue_panel.add_child(_dialogue_label)

	_choice_box = VBoxContainer.new()
	_choice_box.anchor_left = 0.31
	_choice_box.anchor_top = 0.28
	_choice_box.anchor_right = 0.69
	_choice_box.anchor_bottom = 0.58
	_choice_box.alignment = BoxContainer.ALIGNMENT_CENTER
	_choice_box.add_theme_constant_override("separation", 14)
	_choice_box.hide()
	root.add_child(_choice_box)

	var choice_1 := _create_choice_button("Become the next Mother")
	choice_1.pressed.connect(func(): _choose_ending("mother_successor"))
	_choice_box.add_child(choice_1)

	var choice_2 := _create_choice_button("Tell the truth and shut down")
	choice_2.pressed.connect(func(): _choose_ending("peaceful_exit"))
	_choice_box.add_child(choice_2)


func _create_choice_button(text: String) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(420, 54)
	button.add_theme_font_size_override("font_size", 18)
	button.add_theme_color_override("font_color", Color(1.0, 0.95, 0.95))

	var normal := StyleBoxFlat.new()
	normal.bg_color = Color(0.06, 0.01, 0.015, 0.94)
	normal.border_color = Color(0.9, 0.05, 0.08, 0.75)
	normal.set_border_width_all(1)
	normal.set_corner_radius_all(8)
	button.add_theme_stylebox_override("normal", normal)

	var hover := normal.duplicate() as StyleBoxFlat
	hover.bg_color = Color(0.26, 0.025, 0.04, 0.98)
	button.add_theme_stylebox_override("hover", hover)

	var pressed := normal.duplicate() as StyleBoxFlat
	pressed.bg_color = Color(0.5, 0.04, 0.06, 1.0)
	button.add_theme_stylebox_override("pressed", pressed)

	return button


func _play_intro() -> void:
	_line_index = 0
	_dialogue_label.text = mother_lines[_line_index] if not mother_lines.is_empty() else "Mother: Choose."
	_aura_intensity = 0.0

	var tween := create_tween()
	tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "_aura_intensity", 0.72, 1.2)
	await tween.finished

	var loop := create_tween().set_loops()
	loop.tween_property(self, "_aura_intensity", 0.92, 1.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	loop.tween_property(self, "_aura_intensity", 0.72, 1.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_accepting_input = true


func _advance_dialogue() -> void:
	_accepting_input = false
	_line_index += 1

	if _line_index >= mother_lines.size():
		_show_choices()
		return

	var tween_out := create_tween()
	tween_out.tween_property(_dialogue_label, "modulate:a", 0.0, 0.16)
	await tween_out.finished

	_dialogue_label.text = mother_lines[_line_index]

	var tween_in := create_tween()
	tween_in.tween_property(_dialogue_label, "modulate:a", 1.0, 0.16)
	await tween_in.finished
	_accepting_input = true


func _show_choices() -> void:
	_dialogue_label.text = "Mother: Decide."
	_choice_box.modulate.a = 0.0
	_choice_box.show()

	var tween := create_tween()
	tween.set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(_choice_box, "modulate:a", 1.0, 0.3)
	tween.tween_property(self, "_aura_intensity", 1.0, 0.3)
	await tween.finished

	var first_button := _choice_box.get_child(0) as Button
	if first_button:
		first_button.grab_focus()


func _choose_ending(ending_id: String) -> void:
	_choice_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if get_tree().root.has_node("EventManager"):
		EventManager.set_selected_ending(ending_id)

	if get_tree().root.has_node("SceneManager"):
		SceneManager.change_scene(ENDING_SCENE_PATH, 0.6, 0.1)
	else:
		get_tree().change_scene_to_file(ENDING_SCENE_PATH)
