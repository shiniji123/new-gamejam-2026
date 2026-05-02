extends CanvasLayer
## ===================================================
## NotepadUI — ระบบอ่าน Note แบบมี 2 หน้า
## ===================================================
## หน้า 1: รายการ Note ทั้งหมด (มีจุดแดงบอก Note ใหม่)
## หน้า 2: เนื้อหาของ Note ที่เลือก
##
## วิธีใช้:
##   add_note("note_id", "หัวข้อ", "เนื้อเรื่อง")  → เพิ่ม Note ใหม่เข้าระบบ
##   open_notepad()                                  → เปิดหน้ารายการ Note

signal notepad_closed

# --- ข้อมูล Note ทั้งหมด ---
# แต่ละ Note เก็บเป็น Dictionary: { id, title, content, is_read }
var _notes: Array[Dictionary] = []

var _is_open: bool = false
var _current_view: String = "list"  # "list" หรือ "reading"
var _input_cooldown: float = 0.0

# ==== Node References ====
var _overlay: ColorRect
var _list_panel: PanelContainer
var _reading_panel: PanelContainer
var _note_list_container: VBoxContainer
var _reading_title: Label
var _reading_content: RichTextLabel
var _close_btn: Button
var _back_btn: Button
var _close_list_btn: Button
var _anim_player: AnimationPlayer

func _ready() -> void:
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_ui()

func _process(delta: float) -> void:
	if _input_cooldown > 0:
		_input_cooldown -= delta

func _unhandled_input(event: InputEvent) -> void:
	if not _is_open:
		return
	if _input_cooldown > 0:
		return
	if event.is_action_pressed("close_shop") or event.is_action_pressed("ui_cancel"):
		if _current_view == "reading":
			_show_list()
		else:
			_close_notepad()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("interact"):
		if _current_view == "list":
			_close_notepad()
			get_viewport().set_input_as_handled()

# ===========================================================
# PUBLIC API
# ===========================================================

func add_note(note_id: String, title: String, content: String) -> void:
	## เพิ่ม Note ใหม่เข้าระบบ (ถ้ามี id ซ้ำจะข้ามไป)
	for n in _notes:
		if n.id == note_id:
			return
	_notes.append({ "id": note_id, "title": title, "content": content, "is_read": false })

func open_notepad(note_id: String = "") -> void:
	## เปิดหน้ารายการ Note
	_rebuild_note_list()
	_current_view = "list"
	_list_panel.visible = true
	_reading_panel.visible = false
	visible = true
	_is_open = true
	_input_cooldown = 0.3
	get_tree().paused = true
	if note_id != "":
		var note_index := _find_note_index(note_id)
		if note_index != -1:
			_open_note(note_index)
			_input_cooldown = 0.3

func has_unread_notes() -> bool:
	for n in _notes:
		if not n.is_read:
			return true
	return false

func get_note_count() -> int:
	return _notes.size()


func get_save_data() -> Array[Dictionary]:
	var note_copy: Array[Dictionary] = []
	for note in _notes:
		note_copy.append(note.duplicate(true))
	return note_copy


func restore_from_save(data: Array) -> void:
	_notes.clear()
	for entry in data:
		if typeof(entry) != TYPE_DICTIONARY:
			continue
		_notes.append({
			"id": String(entry.get("id", "")),
			"title": String(entry.get("title", "")),
			"content": String(entry.get("content", "")),
			"is_read": bool(entry.get("is_read", false)),
		})
	if _is_open:
		_rebuild_note_list()

# ===========================================================
# INTERNAL
# ===========================================================

func _show_list() -> void:
	_current_view = "list"
	_list_panel.visible = true
	_reading_panel.visible = false
	_input_cooldown = 0.15

func _open_note(index: int) -> void:
	if index < 0 or index >= _notes.size():
		return
	_notes[index].is_read = true
	_reading_title.text = _notes[index].title
	_reading_content.text = _notes[index].content
	_reading_content.scroll_to_line(0)
	_current_view = "reading"
	_list_panel.visible = false
	_reading_panel.visible = true
	_input_cooldown = 0.15
	# อัปเดตจุดแดงในรายการ
	_rebuild_note_list()


func _find_note_index(note_id: String) -> int:
	for i in range(_notes.size()):
		if String(_notes[i].get("id", "")) == note_id:
			return i
	return -1

func _close_notepad() -> void:
	if not _is_open:
		return
	_is_open = false
	visible = false
	get_tree().paused = false
	notepad_closed.emit()

func _rebuild_note_list() -> void:
	# ล้างรายการเก่า
	for child in _note_list_container.get_children():
		child.queue_free()
	
	if _notes.size() == 0:
		var empty_label = Label.new()
		empty_label.text = "No notes yet"
		empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty_label.add_theme_color_override("font_color", Color(0.5, 0.45, 0.65, 0.7))
		_note_list_container.add_child(empty_label)
		return
	
	for i in range(_notes.size()):
		var note = _notes[i]
		var btn_container = HBoxContainer.new()
		btn_container.add_theme_constant_override("separation", 8)
		
		# จุดแดง (ถ้ายังไม่เคยอ่าน)
		if not note.is_read:
			var dot = Label.new()
			dot.text = "🔴"
			dot.add_theme_font_size_override("font_size", 10)
			dot.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			btn_container.add_child(dot)
		else:
			var spacer = Control.new()
			spacer.custom_minimum_size = Vector2(18, 0)
			btn_container.add_child(spacer)
		
		# ปุ่มเลือก Note
		var btn = Button.new()
		btn.text = note.title
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.custom_minimum_size = Vector2(0, 40)
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		
		# สไตล์ปุ่ม
		var normal_style = StyleBoxFlat.new()
		normal_style.bg_color = Color(0.15, 0.12, 0.25, 0.8)
		normal_style.corner_radius_top_left = 8
		normal_style.corner_radius_top_right = 8
		normal_style.corner_radius_bottom_left = 8
		normal_style.corner_radius_bottom_right = 8
		normal_style.content_margin_left = 12
		normal_style.content_margin_right = 12
		btn.add_theme_stylebox_override("normal", normal_style)
		
		var hover_style = StyleBoxFlat.new()
		hover_style.bg_color = Color(0.35, 0.25, 0.6, 1.0)
		hover_style.corner_radius_top_left = 8
		hover_style.corner_radius_top_right = 8
		hover_style.corner_radius_bottom_left = 8
		hover_style.corner_radius_bottom_right = 8
		hover_style.content_margin_left = 12
		hover_style.content_margin_right = 12
		btn.add_theme_stylebox_override("hover", hover_style)
		
		var pressed_style = StyleBoxFlat.new()
		pressed_style.bg_color = Color(0.5, 0.35, 0.8, 1.0)
		pressed_style.corner_radius_top_left = 8
		pressed_style.corner_radius_top_right = 8
		pressed_style.corner_radius_bottom_left = 8
		pressed_style.corner_radius_bottom_right = 8
		pressed_style.content_margin_left = 12
		pressed_style.content_margin_right = 12
		btn.add_theme_stylebox_override("pressed", pressed_style)
		
		btn.add_theme_color_override("font_color", Color(0.9, 0.85, 1.0))
		btn.add_theme_font_size_override("font_size", 14)
		
		var idx = i
		btn.pressed.connect(func(): _open_note(idx))
		btn_container.add_child(btn)
		
		_note_list_container.add_child(btn_container)

# ===========================================================
# BUILD UI (สร้าง UI ทั้งหมดผ่านโค้ด)
# ===========================================================

func _build_ui() -> void:
	# === พื้นหลังมืด ===
	_overlay = ColorRect.new()
	_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_overlay.color = Color(0, 0, 0, 0.65)
	add_child(_overlay)
	
	# === MarginContainer กลางจอ ===
	var margin = MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 160)
	margin.add_theme_constant_override("margin_top", 60)
	margin.add_theme_constant_override("margin_right", 160)
	margin.add_theme_constant_override("margin_bottom", 60)
	_overlay.add_child(margin)
	
	# ==========================================
	# หน้า 1: รายการ Note
	# ==========================================
	_list_panel = PanelContainer.new()
	_list_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_list_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var list_style = StyleBoxFlat.new()
	list_style.bg_color = Color(0.12, 0.10, 0.18, 0.95)
	list_style.border_color = Color(0.45, 0.35, 0.75, 0.8)
	list_style.set_border_width_all(2)
	list_style.set_corner_radius_all(16)
	list_style.shadow_color = Color(0.3, 0.2, 0.6, 0.3)
	list_style.shadow_size = 12
	_list_panel.add_theme_stylebox_override("panel", list_style)
	margin.add_child(_list_panel)
	
	var list_vbox = VBoxContainer.new()
	list_vbox.add_theme_constant_override("separation", 0)
	_list_panel.add_child(list_vbox)
	
	# --- Title Bar (รายการ) ---
	var list_title_panel = PanelContainer.new()
	var title_style = StyleBoxFlat.new()
	title_style.bg_color = Color(0.25, 0.18, 0.42, 1.0)
	title_style.corner_radius_top_left = 12
	title_style.corner_radius_top_right = 12
	list_title_panel.add_theme_stylebox_override("panel", title_style)
	list_vbox.add_child(list_title_panel)
	
	var title_hbox = HBoxContainer.new()
	title_hbox.add_theme_constant_override("separation", 12)
	list_title_panel.add_child(title_hbox)
	
	var icon_label = Label.new()
	icon_label.text = "📋"
	icon_label.add_theme_font_size_override("font_size", 20)
	title_hbox.add_child(icon_label)
	
	var list_title = Label.new()
	list_title.text = "NOTEPAD — Log List"
	list_title.add_theme_color_override("font_color", Color(0.9, 0.85, 1.0))
	list_title.add_theme_font_size_override("font_size", 18)
	list_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_hbox.add_child(list_title)
	
	# --- พื้นที่ Scroll รายการ Note ---
	var scroll_panel = PanelContainer.new()
	scroll_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var scroll_style = StyleBoxFlat.new()
	scroll_style.bg_color = Color(0.08, 0.06, 0.14, 0.9)
	scroll_style.set_border_width_all(1)
	scroll_style.border_color = Color(0.35, 0.25, 0.6, 0.4)
	scroll_style.set_corner_radius_all(8)
	scroll_style.content_margin_left = 16
	scroll_style.content_margin_top = 12
	scroll_style.content_margin_right = 16
	scroll_style.content_margin_bottom = 12
	scroll_panel.add_theme_stylebox_override("panel", scroll_style)
	list_vbox.add_child(scroll_panel)
	
	var scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll_panel.add_child(scroll)
	
	_note_list_container = VBoxContainer.new()
	_note_list_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_note_list_container.add_theme_constant_override("separation", 6)
	scroll.add_child(_note_list_container)
	
	# --- ปุ่มปิดรายการ ---
	var list_bottom = MarginContainer.new()
	list_bottom.add_theme_constant_override("margin_top", 12)
	list_bottom.add_theme_constant_override("margin_bottom", 12)
	list_bottom.add_theme_constant_override("margin_left", 16)
	list_bottom.add_theme_constant_override("margin_right", 16)
	list_vbox.add_child(list_bottom)
	
	var list_bottom_hbox = HBoxContainer.new()
	list_bottom_hbox.alignment = BoxContainer.ALIGNMENT_END
	list_bottom.add_child(list_bottom_hbox)
	
	var hint_label = Label.new()
	hint_label.text = "Select a Note to read"
	hint_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hint_label.add_theme_color_override("font_color", Color(0.5, 0.45, 0.65, 0.7))
	hint_label.add_theme_font_size_override("font_size", 11)
	list_bottom_hbox.add_child(hint_label)
	
	_close_list_btn = _create_styled_button("✖  Close")
	_close_list_btn.pressed.connect(_close_notepad)
	list_bottom_hbox.add_child(_close_list_btn)
	
	# ==========================================
	# หน้า 2: อ่าน Note
	# ==========================================
	_reading_panel = PanelContainer.new()
	_reading_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_reading_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_reading_panel.visible = false
	var reading_style = list_style.duplicate()
	_reading_panel.add_theme_stylebox_override("panel", reading_style)
	margin.add_child(_reading_panel)
	
	var read_vbox = VBoxContainer.new()
	read_vbox.add_theme_constant_override("separation", 0)
	_reading_panel.add_child(read_vbox)
	
	# --- Title Bar (อ่าน) ---
	var read_title_panel = PanelContainer.new()
	var read_title_style = title_style.duplicate()
	read_title_panel.add_theme_stylebox_override("panel", read_title_style)
	read_vbox.add_child(read_title_panel)
	
	var read_title_hbox = HBoxContainer.new()
	read_title_hbox.add_theme_constant_override("separation", 12)
	read_title_panel.add_child(read_title_hbox)
	
	var read_icon = Label.new()
	read_icon.text = "📖"
	read_icon.add_theme_font_size_override("font_size", 20)
	read_title_hbox.add_child(read_icon)
	
	_reading_title = Label.new()
	_reading_title.text = ""
	_reading_title.add_theme_color_override("font_color", Color(0.9, 0.85, 1.0))
	_reading_title.add_theme_font_size_override("font_size", 18)
	_reading_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	read_title_hbox.add_child(_reading_title)
	
	# --- เนื้อเรื่อง ---
	var content_panel = PanelContainer.new()
	content_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var content_style = scroll_style.duplicate()
	content_style.content_margin_left = 20
	content_style.content_margin_top = 16
	content_style.content_margin_right = 20
	content_style.content_margin_bottom = 16
	content_panel.add_theme_stylebox_override("panel", content_style)
	read_vbox.add_child(content_panel)
	
	_reading_content = RichTextLabel.new()
	_reading_content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_reading_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_reading_content.bbcode_enabled = true
	_reading_content.scroll_active = true
	_reading_content.add_theme_color_override("default_color", Color(0.82, 0.78, 0.92, 1))
	_reading_content.add_theme_font_size_override("normal_font_size", 14)
	content_panel.add_child(_reading_content)
	
	# --- ปุ่มกลับ + ปิด ---
	var read_bottom = MarginContainer.new()
	read_bottom.add_theme_constant_override("margin_top", 12)
	read_bottom.add_theme_constant_override("margin_bottom", 12)
	read_bottom.add_theme_constant_override("margin_left", 16)
	read_bottom.add_theme_constant_override("margin_right", 16)
	read_vbox.add_child(read_bottom)
	
	var read_bottom_hbox = HBoxContainer.new()
	read_bottom_hbox.alignment = BoxContainer.ALIGNMENT_END
	read_bottom.add_child(read_bottom_hbox)
	
	var read_hint = Label.new()
	read_hint.text = "Press ESC to go back"
	read_hint.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	read_hint.add_theme_color_override("font_color", Color(0.5, 0.45, 0.65, 0.7))
	read_hint.add_theme_font_size_override("font_size", 11)
	read_bottom_hbox.add_child(read_hint)
	
	_back_btn = _create_styled_button("◀  Back")
	_back_btn.pressed.connect(_show_list)
	read_bottom_hbox.add_child(_back_btn)
	
	var spacer = Control.new()
	spacer.custom_minimum_size = Vector2(8, 0)
	read_bottom_hbox.add_child(spacer)
	
	_close_btn = _create_styled_button("✖  Close")
	_close_btn.pressed.connect(_close_notepad)
	read_bottom_hbox.add_child(_close_btn)

func _create_styled_button(text: String) -> Button:
	var btn = Button.new()
	btn.text = text
	btn.custom_minimum_size = Vector2(100, 36)
	btn.add_theme_color_override("font_color", Color(0.95, 0.9, 1.0))
	btn.add_theme_font_size_override("font_size", 13)
	
	var normal = StyleBoxFlat.new()
	normal.bg_color = Color(0.35, 0.25, 0.6, 0.8)
	normal.set_corner_radius_all(8)
	btn.add_theme_stylebox_override("normal", normal)
	
	var hover = StyleBoxFlat.new()
	hover.bg_color = Color(0.5, 0.35, 0.8, 1.0)
	hover.set_corner_radius_all(8)
	btn.add_theme_stylebox_override("hover", hover)
	
	var pressed = StyleBoxFlat.new()
	pressed.bg_color = Color(0.6, 0.4, 0.9, 1.0)
	pressed.set_corner_radius_all(8)
	btn.add_theme_stylebox_override("pressed", pressed)
	
	return btn
