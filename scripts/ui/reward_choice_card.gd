extends Control
# แนะนำให้กางเป็น Button หรือ PanelContainer ในหน้าต่าง 2D Editor
# สคริปต์นี้เอาไว้ใส่บนการ์ดแต่ละใบ เพื่อให้สามารถกดเลือกและแสดงไอคอนได้เอง

signal card_selected(perk: PerkData)

@export var title_label: Label
@export var description_label: Label
@export var icon_rect: TextureRect
@export var trigger_button: Button
@export var hover_sound: AudioStream = preload("res://assets/new_sound/before_select.wav")
@export var select_sound: AudioStream = preload("res://assets/new_sound/select.wav")

var _current_perk: PerkData
var tween_hover: Tween

func _ready() -> void:
	# ตั้งจุดหมุน (Pivot) ไว้ตรงกลางการ์ด เพื่อให้เวลาย่อขยาย (Scale) มันสมมาตร
	pivot_offset = size / 2.0
	
	if trigger_button:
		trigger_button.pressed.connect(_on_pressed)
		trigger_button.focus_mode = Control.FOCUS_NONE
		
		# ดักจับเมาส์เข้า/ออกที่ปุ่ม เพื่อทำ Animation
		trigger_button.mouse_entered.connect(_on_mouse_entered)
		trigger_button.mouse_exited.connect(_on_mouse_exited)
		
		# เปลี่ยนเมาส์เป็นรูปนิ้วชี้
		trigger_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND

func setup_card(perk: PerkData) -> void:
	_current_perk = perk
	if title_label:
		title_label.text = perk.title
	if description_label:
		description_label.text = perk.description
	if icon_rect and perk.icon:
		icon_rect.texture = perk.icon

func _on_mouse_entered() -> void:
	if hover_sound:
		AudioManager.play_sfx(hover_sound)

	if tween_hover: tween_hover.kill()
	tween_hover = create_tween()
	tween_hover.bind_node(self)
	tween_hover.set_parallel(true) \
		.set_trans(Tween.TRANS_SPRING) \
		.set_ease(Tween.EASE_OUT)
	
	# ขยายการ์ดใหญ่ขึ้น 10%
	tween_hover.tween_property(self, "scale", Vector2(1.1, 1.1), 0.3)
	# ดันการ์ดลอยขึ้นนิดนึง
	tween_hover.tween_property(self, "position:y", -15.0, 0.3)
	# เปลี่ยนสีให้สว่างขึ้น (Glow effect)
	tween_hover.tween_property(self, "modulate", Color(1.2, 1.2, 1.3, 1.0), 0.2)

func _on_mouse_exited() -> void:
	if tween_hover: tween_hover.kill()
	tween_hover = create_tween()
	tween_hover.bind_node(self)
	tween_hover.set_parallel(true) \
		.set_trans(Tween.TRANS_SINE) \
		.set_ease(Tween.EASE_OUT)
	
	# กลับสู่สภาพเดิม
	tween_hover.tween_property(self, "scale", Vector2.ONE, 0.2)
	tween_hover.tween_property(self, "position:y", 0.0, 0.2)
	tween_hover.tween_property(self, "modulate", Color.WHITE, 0.2)

func _on_pressed() -> void:
	if not _current_perk: return

	if select_sound:
		AudioManager.play_sfx(select_sound)
	
	# แอนิเมชันตอนกด (หดตัวอย่างรวดเร็ว)
	if tween_hover: tween_hover.kill()
	var click_tween = create_tween()
	click_tween.bind_node(self)
	click_tween.set_trans(Tween.TRANS_CUBIC) \
		.set_ease(Tween.EASE_OUT)
	click_tween.tween_property(self, "scale", Vector2(0.9, 0.9), 0.1)
	click_tween.tween_callback(func(): card_selected.emit(_current_perk))
