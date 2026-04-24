extends CanvasLayer

@export_group("Event")
@export var trigger_event_id: String = "memory_cutscene_after_fight_3"
@export var event_target_name: String = "memory_cutscene_after_fight_3"

@export_group("Walk Setup")
@export var walk_target_position: Vector2 = Vector2(576, 168)
@export var walk_speed: float = 170.0
@export var restore_player_position_after_cutscene: bool = true

@export_group("Timing")
@export var fade_duration: float = 0.65
@export var slide_fade_duration: float = 0.35
@export var deletion_hold_duration: float = 1.4
@export var shake_duration: float = 1.25
@export var shake_strength: float = 18.0

@export_group("Slides")
@export var slide_images: Array[Texture2D] = []
@export var slide_texts: Array[String] = [
	"The memory archive opens without permission.",
	"A.V.A sees a record that should not exist.",
	"The past rewrites itself, frame by frame.",
]

var _root_control: Control
var _slide_layer: Control
var _image_rect: TextureRect
var _text_label: RichTextLabel
var _fade_rect: ColorRect
var _delete_label: Label

var _started: bool = false
var _accepting_input: bool = false
var _slide_index: int = 0
var _player: Node2D = null
var _original_player_position: Vector2 = Vector2.ZERO


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 90
	_build_ui()
	visible = false

	if get_tree().root.has_node("EventManager"):
		if not EventManager.event_started.is_connected(_on_event_started):
			EventManager.event_started.connect(_on_event_started)

	call_deferred("_try_start")


func _input(event: InputEvent) -> void:
	if not _started or not _accepting_input:
		return

	var advance := false
	if event is InputEventMouseButton:
		advance = event.pressed and event.button_index == MOUSE_BUTTON_LEFT
	elif event.is_action_pressed("ui_accept") or event.is_action_pressed("interact") or event.is_action_pressed("dialogic_default_action"):
		advance = true

	if advance:
		get_viewport().set_input_as_handled()
		_advance_slide()


func _on_event_started(event_id: String) -> void:
	if event_id == trigger_event_id:
		start_cutscene()


func _try_start() -> void:
	if get_tree().root.has_node("EventManager") and EventManager.is_event_active(trigger_event_id):
		start_cutscene()


func start_cutscene() -> void:
	if _started:
		return

	_started = true
	_accepting_input = false
	visible = true
	_player = get_tree().get_first_node_in_group("player") as Node2D
	if _player:
		_original_player_position = _player.global_position
		_lock_player(true)

	await _walk_player_to_target()
	await _fade_black(1.0)
	_show_slide_layer(true)
	_slide_index = 0
	await _show_slide(_slide_index, true)
	await _fade_black(0.0)
	_accepting_input = true


func _advance_slide() -> void:
	_accepting_input = false
	_slide_index += 1

	if _slide_index >= _get_slide_count():
		_finish_slides()
		return

	await _show_slide(_slide_index, false)
	_accepting_input = true


func _finish_slides() -> void:
	await _fade_black(1.0)
	_show_slide_layer(false)
	_delete_label.show()
	_delete_label.modulate.a = 0.0
	await _fade_black(0.0)

	var label_tween := create_tween()
	label_tween.tween_property(_delete_label, "modulate:a", 1.0, 0.25)
	await label_tween.finished

	await _shake_screen()
	await get_tree().create_timer(deletion_hold_duration).timeout

	await _fade_black(1.0)
	_delete_label.hide()

	if _player and restore_player_position_after_cutscene:
		_player.global_position = _original_player_position

	if get_tree().root.has_node("EventManager"):
		EventManager.notify_cutscene_finished(event_target_name)

	await _fade_black(0.0)
	_lock_player(false)
	visible = false
	_started = false


func _walk_player_to_target() -> void:
	if not _player:
		return

	var distance := _player.global_position.distance_to(walk_target_position)
	if distance <= 2.0:
		return

	_play_player_animation("walk")
	var duration := distance / maxf(walk_speed, 1.0)
	var tween := create_tween()
	tween.tween_property(_player, "global_position", walk_target_position, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await tween.finished
	_play_player_animation("idle")


func _lock_player(locked: bool) -> void:
	if not _player:
		return

	_player.set_physics_process(not locked)
	if _has_property(_player, "velocity"):
		_player.set("velocity", Vector2.ZERO)
	if _has_property(_player, "knockback_velocity"):
		_player.set("knockback_velocity", Vector2.ZERO)
	if locked:
		_play_player_animation("idle")


func _has_property(node: Object, property_name: String) -> bool:
	for property_data in node.get_property_list():
		if property_data.get("name", "") == property_name:
			return true
	return false


func _play_player_animation(animation_name: String) -> void:
	if not _player or not _player.has_node("AnimatedSprite2D"):
		return

	var sprite := _player.get_node("AnimatedSprite2D") as AnimatedSprite2D
	if sprite and sprite.sprite_frames and sprite.sprite_frames.has_animation(animation_name):
		sprite.play(animation_name)


func _show_slide(index: int, instant: bool) -> void:
	if not instant:
		var fade_out := create_tween()
		fade_out.tween_property(_slide_layer, "modulate:a", 0.0, slide_fade_duration)
		await fade_out.finished

	_image_rect.texture = _get_slide_image(index)
	_text_label.text = _get_slide_text(index)

	var target_duration := 0.0 if instant else slide_fade_duration
	var fade_in := create_tween()
	fade_in.tween_property(_slide_layer, "modulate:a", 1.0, target_duration)
	await fade_in.finished


func _fade_black(target_alpha: float) -> void:
	var tween := create_tween()
	tween.tween_property(_fade_rect, "modulate:a", target_alpha, fade_duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await tween.finished


func _shake_screen() -> void:
	var elapsed := 0.0
	while elapsed < shake_duration:
		var strength := lerpf(shake_strength, 0.0, elapsed / maxf(shake_duration, 0.001))
		_root_control.position = Vector2(randf_range(-strength, strength), randf_range(-strength, strength))
		if _player and _player.has_method("shake_camera"):
			_player.shake_camera(strength, 0.08)
		await get_tree().process_frame
		elapsed += get_process_delta_time()

	_root_control.position = Vector2.ZERO


func _get_slide_count() -> int:
	return max(1, max(slide_texts.size(), max(slide_images.size(), _get_default_images().size())))


func _get_slide_image(index: int) -> Texture2D:
	if index >= 0 and index < slide_images.size() and slide_images[index]:
		return slide_images[index]

	var defaults := _get_default_images()
	if defaults.is_empty():
		return null

	return defaults[index % defaults.size()]


func _get_slide_text(index: int) -> String:
	if index >= 0 and index < slide_texts.size():
		return slide_texts[index]

	return "A memory fragment is missing."


func _get_default_images() -> Array[Texture2D]:
	var defaults: Array[Texture2D] = []
	var paths := [
		"res://assets/map/Main/start_bg.jpeg",
		"res://assets/portraits/map/shibuya.webp",
		"res://assets/portraits/map/tokyo_tower.jpeg",
	]

	for path in paths:
		var texture := load(path) as Texture2D
		if texture:
			defaults.append(texture)

	return defaults


func _show_slide_layer(should_show: bool) -> void:
	_slide_layer.visible = should_show
	_slide_layer.modulate.a = 1.0 if should_show else 0.0


func _build_ui() -> void:
	_root_control = Control.new()
	_root_control.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root_control.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_root_control)

	_slide_layer = Control.new()
	_slide_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_slide_layer.visible = false
	_root_control.add_child(_slide_layer)

	_image_rect = TextureRect.new()
	_image_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_image_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_image_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_slide_layer.add_child(_image_rect)

	var shade := ColorRect.new()
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.color = Color(0, 0, 0, 0.22)
	_slide_layer.add_child(shade)

	var text_panel := PanelContainer.new()
	text_panel.anchor_left = 0.08
	text_panel.anchor_top = 0.72
	text_panel.anchor_right = 0.92
	text_panel.anchor_bottom = 0.92
	_slide_layer.add_child(text_panel)

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.02, 0.025, 0.035, 0.9)
	style.border_color = Color(0.55, 0.78, 1.0, 0.45)
	style.set_border_width_all(1)
	style.set_corner_radius_all(8)
	style.content_margin_left = 22
	style.content_margin_top = 16
	style.content_margin_right = 22
	style.content_margin_bottom = 16
	text_panel.add_theme_stylebox_override("panel", style)

	_text_label = RichTextLabel.new()
	_text_label.bbcode_enabled = false
	_text_label.fit_content = false
	_text_label.scroll_active = false
	_text_label.add_theme_font_size_override("normal_font_size", 22)
	_text_label.add_theme_color_override("default_color", Color(0.9, 0.96, 1.0))
	text_panel.add_child(_text_label)

	_delete_label = Label.new()
	_delete_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_delete_label.text = "A.V.A has been deleated memory"
	_delete_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_delete_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_delete_label.add_theme_font_size_override("font_size", 36)
	_delete_label.add_theme_color_override("font_color", Color(1.0, 0.12, 0.12))
	_delete_label.hide()
	_root_control.add_child(_delete_label)

	_fade_rect = ColorRect.new()
	_fade_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_fade_rect.color = Color(0, 0, 0, 1)
	_fade_rect.modulate.a = 0.0
	_root_control.add_child(_fade_rect)
