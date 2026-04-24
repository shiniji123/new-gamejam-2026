class_name FullscreenStripPlayer
extends CanvasLayer

signal finished

@export var strip_texture: Texture2D
@export var frame_count: int = 1
@export var frames_per_second: float = 10.0
@export var hold_last_frame: float = 0.0
@export var fade_in_duration: float = 0.0
@export var fade_out_duration: float = 0.0
@export var autoplay: bool = false

var _root: Control
var _image_rect: TextureRect
var _atlas_texture: AtlasTexture = AtlasTexture.new()
var _is_playing: bool = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 120
	_build_ui()

	if autoplay and strip_texture:
		play()


func setup(
	texture: Texture2D,
	frames: int,
	fps: float = 10.0,
	hold_time: float = 0.0,
	fade_in: float = 0.0,
	fade_out: float = 0.0
) -> void:
	strip_texture = texture
	frame_count = maxi(frames, 1)
	frames_per_second = maxf(fps, 0.01)
	hold_last_frame = maxf(hold_time, 0.0)
	fade_in_duration = maxf(fade_in, 0.0)
	fade_out_duration = maxf(fade_out, 0.0)


func play() -> void:
	if _is_playing:
		return
	if not strip_texture:
		finished.emit()
		queue_free()
		return

	_is_playing = true
	_build_ui()
	visible = true
	_root.modulate.a = 0.0 if fade_in_duration > 0.0 else 1.0

	_set_frame(0)
	if fade_in_duration > 0.0:
		await _fade_to(1.0, fade_in_duration)

	var frame_time := 1.0 / maxf(frames_per_second, 0.01)
	for frame_index in range(frame_count):
		_set_frame(frame_index)
		await get_tree().create_timer(frame_time, true).timeout
		if not is_inside_tree():
			return

	if hold_last_frame > 0.0:
		await get_tree().create_timer(hold_last_frame, true).timeout
		if not is_inside_tree():
			return

	if fade_out_duration > 0.0:
		await _fade_to(0.0, fade_out_duration)

	finished.emit()
	queue_free()


func _build_ui() -> void:
	if _root:
		return

	_root = Control.new()
	_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_root)

	var background := ColorRect.new()
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.color = Color.BLACK
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(background)

	_image_rect = TextureRect.new()
	_image_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_image_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_image_rect.stretch_mode = TextureRect.STRETCH_SCALE
	_image_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(_image_rect)


func _set_frame(frame_index: int) -> void:
	if not strip_texture or not _image_rect:
		return

	var safe_frame_count: int = maxi(frame_count, 1)
	var frame_width := float(strip_texture.get_width()) / float(safe_frame_count)
	var frame_height := float(strip_texture.get_height())
	var clamped_index := clampi(frame_index, 0, safe_frame_count - 1)

	_atlas_texture.atlas = strip_texture
	_atlas_texture.region = Rect2(frame_width * clamped_index, 0.0, frame_width, frame_height)
	_image_rect.texture = _atlas_texture


func _fade_to(target_alpha: float, duration: float) -> void:
	var tween := create_tween()
	tween.tween_property(_root, "modulate:a", target_alpha, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await tween.finished
