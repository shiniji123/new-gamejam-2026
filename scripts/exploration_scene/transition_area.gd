extends Area2D
## ===================================================
## TransitionArea — จุดเปลี่ยนฉาก / เปิด Notepad / แจ้ง Event
## ===================================================

@export var scene_path: SceneConfig

@export_group("Interaction & Visuals")
## ต้องกดปุ่ม E เพื่อทำงานหรือไม่? (ถ้าไม่ติ๊ก จะทำงานทันทีที่เดินชน)
@export var require_interact: bool = false
## ข้อความที่จะขึ้นตอนให้กด E (เช่น "อ่าน", "ต่อสู้", "เข้าประตู")
@export var action_name: String = "Explore"
## สีของวงกลม (สามารถปรับให้แต่ละจุดสีไม่เหมือนกันได้ เช่น เขียว=อ่าน, แดง=สู้)
@export var area_color: Color = Color(0.11, 1.0, 0.11, 0.3)
## เปิดใช้งานการซูมเข้า-ออกตลอดเวลา (เช่น สำหรับไอคอน My Computer)
@export var always_zoom: bool = false


@export_group("Transition Settings")
@export var fade_speed: float = 0.6
@export var fade_in_delay: float = 0.1

@export_group("Event System")
@export var active_on_event: String = ""
@export var trigger_event_target: String = ""

@export_group("Notepad Mode")
@export var is_notepad: bool = false
@export var notepad_title: String = "NOTEPAD"
@export_multiline var notepad_content: String = ""
@export var notepad_event_target: String = ""

var _notepad_ui: Node = null
var _zoom_tween: Tween
var _base_scale: Vector2 = Vector2.ZERO


# ตัวแปร Callable สำหรับเชื่อมกับ InteractionManager
var interact: Callable

var _exclamation_mark: Label

func _ready() -> void:
	interact = Callable(self, "_execute_action")
	
	# อัปเดตสีของวงกลมให้ตรงกับที่ตั้งค่าใน Inspector
	if has_node("ColorRect"):
		$ColorRect.color = area_color
	
	# สร้างเครื่องหมายตกใจ (!) เพื่อบอกใบ้ให้ผู้เล่น
	if active_on_event != "":
		_exclamation_mark = Label.new()
		_exclamation_mark.text = "!"
		_exclamation_mark.add_theme_font_size_override("font_size", 48)
		_exclamation_mark.add_theme_color_override("font_color", Color(1.0, 0.9, 0.0)) # สีเหลือง
		_exclamation_mark.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_exclamation_mark.position = Vector2(-50, -70)
		_exclamation_mark.hide()
		_exclamation_mark.z_index = 200
		add_child(_exclamation_mark)
		# แอนิเมชันเด้งขึ้นลง
		var tween = create_tween().set_loops()
		tween.tween_property(_exclamation_mark, "position:y", -80.0, 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		tween.tween_property(_exclamation_mark, "position:y", -70.0, 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	
	# เชื่อมต่อ signal ออกตอนผู้เล่นเดินเข้า-ออก
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)
	if not body_exited.is_connected(_on_body_exited):
		body_exited.connect(_on_body_exited)
		
	# เริ่มเล่นแอนิเมชันซูมถ้าเป็นโหมด Notepad หรือตั้งค่าให้ซูมตลอดเวลา
	if is_notepad or always_zoom:
		_start_zoom_animation()



func _process(_delta: float) -> void:
	if active_on_event != "":
		var is_active = false
		if get_tree().root.has_node("EventManager"):
			var em = get_tree().root.get_node("EventManager")
			if is_notepad:
				is_active = em.is_event_reached(active_on_event)
			else:
				is_active = em.is_event_active(active_on_event)
		
		visible = is_active
		if has_node("CollisionShape2D"):
			$CollisionShape2D.disabled = not is_active
			
		# อัปเดตเครื่องหมายตกใจ: โชว์เฉพาะตอนที่ Area นี้เป็น objective ปัจจุบัน
		if _exclamation_mark:
			var is_current_target = false
			if get_tree().root.has_node("EventManager"):
				var em = get_tree().root.get_node("EventManager")
				# โชว์เมื่อ active และ event ตรงกับ active_on_event
				is_current_target = is_active and em.is_event_active(active_on_event)
			_exclamation_mark.visible = is_current_target
			
		# ถ้าระบบต้องการให้กด E แต่ Event หายไปแล้ว ก็ให้ถอดป้ายออก
		if not is_active and require_interact and get_tree().root.has_node("InteractionManager"):
			InteractionManager.unregister_area(self)

func _on_body_entered(body: Node2D) -> void:
	# ป้องกันการ Trigger ซ้ำซ้อนถ้ากำลังเปลี่ยนฉากอยู่
	if get_tree().root.has_node("SceneManager"):
		if get_tree().root.get_node("SceneManager").is_transitioning:
			return
			
	if body.is_in_group("player"):
		if require_interact:
			# ถ้าต้องกด E ให้ส่งตัวแปรไปที่ระบบ InteractionManager
			if get_tree().root.has_node("InteractionManager"):
				InteractionManager.register_area(self)
		else:
			# ถ้าไม่ต้องกด E ให้ทำงานทันที
			_execute_action()

func _on_body_exited(body: Node2D) -> void:
	if require_interact and body.is_in_group("player"):
		# เอาป้ายกด E ออกเมื่อเดินออกนอกวง
		if get_tree().root.has_node("InteractionManager"):
			InteractionManager.unregister_area(self)

func _execute_action() -> void:
	# --- โหมด Notepad ---
	if is_notepad:
		_open_notepad()
		return
	
	# หยุดซูมชั่วคราวตอนเปลี่ยนฉากหรือเกิด Event
	_stop_zoom_animation()

	
	# --- โหมด Event: ส่งสัญญาณให้ EventManager เปลี่ยนฉากแทน ---
	if trigger_event_target != "":
		set_deferred("monitoring", false)
		if require_interact and get_tree().root.has_node("InteractionManager"):
			InteractionManager.unregister_area(self)
			
		if get_tree().root.has_node("EventManager"):
			get_tree().root.get_node("EventManager").notify_interaction(trigger_event_target)
		return
		
	# --- โหมดปกติ: เปลี่ยนฉากตาม SceneConfig ---
	if not scene_path or scene_path.scene_path == "":
		print("NO Destination!")
		return
		
	set_deferred("monitoring", false)
	if require_interact and get_tree().root.has_node("InteractionManager"):
		InteractionManager.unregister_area(self)
		
	call_deferred("_change_scene")
	call_deferred("_change_state")

func _open_notepad() -> void:
	# หยุดแอนิเมชันซูมตอนกำลังอ่าน
	_stop_zoom_animation()
	
	if require_interact and get_tree().root.has_node("InteractionManager"):

		InteractionManager.unregister_area(self)
	
	_notepad_ui = get_tree().current_scene.get_node_or_null("NotepadUI")
	
	if not _notepad_ui:
		push_warning("[TransitionArea] ไม่พบ NotepadUI ในฉากนี้! กรุณาเพิ่ม NotepadUI node")
		return
	
	# เพิ่ม Note เข้าระบบ (ถ้ามี id ซ้ำจะข้ามไป ไม่ซ้ำซ้อน)
	var note_id = notepad_event_target if notepad_event_target != "" else notepad_title
	_notepad_ui.add_note(note_id, notepad_title, notepad_content)
	
	# Open this note directly so the Read prompt always shows content.
	_notepad_ui.open_notepad(note_id)
	
	# ฟังสัญญาณเมื่อปิด
	if not _notepad_ui.notepad_closed.is_connected(_on_notepad_closed):
		_notepad_ui.notepad_closed.connect(_on_notepad_closed, CONNECT_ONE_SHOT)

func _on_notepad_closed() -> void:
	# แจ้ง EventManager ว่าอ่านเสร็จแล้ว (ถ้าตั้งค่าไว้)
	if notepad_event_target != "":
		if get_tree().root.has_node("EventManager"):
			get_tree().root.get_node("EventManager").notify_interaction(notepad_event_target)
	
	# เปิด monitoring กลับเสมอ เพื่อให้อ่านซ้ำได้
	set_deferred("monitoring", true)
	
	# เริ่มเล่นแอนิเมชันซูมใหม่หลังจากอ่านจบ
	if is_notepad or always_zoom:
		_start_zoom_animation()



func _change_scene() -> void:
	if get_tree().root.has_node("SceneManager"):
		var sm = get_tree().root.get_node("SceneManager")
		sm.change_scene(scene_path.scene_path, fade_speed, fade_in_delay)
	else:
		get_tree().change_scene_to_file(scene_path.scene_path)
	
func _change_state() -> void:
	var scene_state = scene_path.scene_state
	Autoload.current_state = scene_state

# --- Helper functions สำหรับแอนิเมชัน ---
func _start_zoom_animation() -> void:
	var parent = get_parent()
	# ตรวจสอบว่าเป็น Sprite หรือไม่ (รองรับทั้ง Sprite2D และ AnimatedSprite2D)
	if parent is Sprite2D or parent is AnimatedSprite2D:
		if _base_scale == Vector2.ZERO:
			_base_scale = parent.scale
			
		if _zoom_tween and _zoom_tween.is_valid():
			_zoom_tween.kill()
			
		_zoom_tween = create_tween().set_loops()
		# ซูมเข้าเล็กน้อย (10%) แล้วกลับมาที่เดิม
		_zoom_tween.tween_property(parent, "scale", _base_scale * 1.08, 1.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		_zoom_tween.tween_property(parent, "scale", _base_scale, 1.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func _stop_zoom_animation() -> void:
	if _zoom_tween and _zoom_tween.is_valid():
		_zoom_tween.kill()
		
	var parent = get_parent()
	if (parent is Sprite2D or parent is AnimatedSprite2D) and _base_scale != Vector2.ZERO:
		# คืนค่า scale กลับไปเป็นค่าดั้งเดิมทันที
		parent.scale = _base_scale
