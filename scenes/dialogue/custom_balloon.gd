extends CanvasLayer
## Custom dialogue balloon with full-art character portraits (Visual Novel style).
## Layout: NPC portrait on left, Player portrait on right, text box at bottom.
##
## ── การใช้ใน .dialogue file ──────────────────────────────────────
##   do set_portrait("left", "npc", "default")      ← ตั้งค่า portrait ซ้าย
##   do set_portrait("right", "player", "happy")     ← ตั้งค่า portrait ขวา
##   do hide_portrait("left")                        ← ซ่อน portrait ซ้าย
##   do hide_portrait("all")                         ← ซ่อนทั้งหมด
## ─────────────────────────────────────────────────────────────────

# ─── Portrait Settings ───────────────────────────────────────────

## Pattern path สำหรับโหลดรูป portrait
## {character} = ชื่อ folder,  {pose} = ชื่อไฟล์ก่อน .png
@export var portrait_path_pattern: String = "res://assets/portraits/{character}/{pose}.png"

# ─── Dialogue Manager Required Exports ──────────────────────────

## The dialogue resource
@export var dialogue_resource: DialogueResource

## Start from a given title when using balloon as a [Node] in a scene.
@export var start_from_title: String = ""

## If running as a [Node] in a scene then auto start the dialogue.
@export var auto_start: bool = false

## If all other input is blocked as long as dialogue is shown.
@export var will_block_other_input: bool = true

## The action to use for advancing the dialogue
@export var next_action: StringName = &"ui_accept"

## The action to use to skip typing the dialogue
@export var skip_action: StringName = &"ui_cancel"

# ─── Audio ───────────────────────────────────────────────────────

@onready var audio_stream_player: AudioStreamPlayer = %AudioStreamPlayer

# ─── State ───────────────────────────────────────────────────────

var temporary_game_states: Array = []
var is_waiting_for_input: bool = false
var will_hide_balloon: bool = false
var locals: Dictionary = {}
var _locale: String = TranslationServer.get_locale()

# ─── Portrait Tracking ───────────────────────────────────────────

## ชื่อตัวละครที่แสดงอยู่แต่ละด้าน (ใช้ match กับ dialogue_line.character เพื่อ dim)
var _left_char: String = ""
var _right_char: String = ""

# ─── Portrait Nodes ──────────────────────────────────────────────

@onready var left_portrait: TextureRect = %LeftPortrait
@onready var right_portrait: TextureRect = %RightPortrait

# ─── Balloon Nodes ───────────────────────────────────────────────

var dialogue_line: DialogueLine:
	set(value):
		if value:
			dialogue_line = value
			apply_dialogue_line()
		else:
			# Dialogue finished — ซ่อน balloon และ portrait
			_hide_all_portraits()
			if owner == null:
				queue_free()
			else:
				hide()
	get:
		return dialogue_line

var mutation_cooldown: Timer = Timer.new()

@onready var balloon: Control = %Balloon
@onready var character_label: RichTextLabel = %CharacterLabel
@onready var dialogue_label: DialogueLabel = %DialogueLabel
@onready var responses_menu: DialogueResponsesMenu = %ResponsesMenu
@onready var progress: Polygon2D = %Progress


func _ready() -> void:
	balloon.hide()
	left_portrait.hide()
	right_portrait.hide()

	Engine.get_singleton("DialogueManager").mutated.connect(_on_mutated)

	if responses_menu.next_action.is_empty():
		responses_menu.next_action = next_action

	mutation_cooldown.timeout.connect(_on_mutation_cooldown_timeout)
	add_child(mutation_cooldown)

	if auto_start:
		if not is_instance_valid(dialogue_resource):
			assert(false, DMConstants.get_error_message(DMConstants.ERR_MISSING_RESOURCE_FOR_AUTOSTART))
		start()


func _process(_delta: float) -> void:
	if is_instance_valid(dialogue_line):
		progress.visible = not dialogue_label.is_typing and dialogue_line.responses.size() == 0 and not dialogue_line.has_tag("voice")


func _unhandled_input(_event: InputEvent) -> void:
	if will_block_other_input:
		get_viewport().set_input_as_handled()


func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSLATION_CHANGED and _locale != TranslationServer.get_locale() and is_instance_valid(dialogue_label):
		_locale = TranslationServer.get_locale()
		var visible_ratio: float = dialogue_label.visible_ratio
		dialogue_line = await dialogue_resource.get_next_dialogue_line(dialogue_line.id)
		if visible_ratio < 1:
			dialogue_label.skip_typing()


## Start some dialogue
func start(with_dialogue_resource: DialogueResource = null, title: String = "", extra_game_states: Array = []) -> void:
	temporary_game_states = [self] + extra_game_states
	is_waiting_for_input = false
	if is_instance_valid(with_dialogue_resource):
		dialogue_resource = with_dialogue_resource
	if not title.is_empty():
		start_from_title = title
	dialogue_line = await dialogue_resource.get_next_dialogue_line(start_from_title, temporary_game_states)
	show()


## Apply any changes to the balloon given a new [DialogueLine].
func apply_dialogue_line() -> void:
	mutation_cooldown.stop()

	progress.hide()
	is_waiting_for_input = false
	balloon.focus_mode = Control.FOCUS_ALL
	balloon.grab_focus()

	character_label.visible = not dialogue_line.character.is_empty()
	character_label.text = tr(dialogue_line.character, "dialogue")

	dialogue_label.hide()
	dialogue_label.dialogue_line = dialogue_line

	responses_menu.hide()
	responses_menu.responses = dialogue_line.responses

	balloon.show()
	will_hide_balloon = false

	# อัปเดต dim/highlight portrait ตามว่าใครพูด
	_update_portrait_dim()

	dialogue_label.show()
	if not dialogue_line.text.is_empty():
		dialogue_label.type_out()
		await dialogue_label.finished_typing

	if dialogue_line.has_tag("voice"):
		audio_stream_player.stream = load(dialogue_line.get_tag_value("voice"))
		audio_stream_player.play()
		await audio_stream_player.finished
		next(dialogue_line.next_id)
	elif dialogue_line.responses.size() > 0:
		balloon.focus_mode = Control.FOCUS_NONE
		responses_menu.show()
	elif dialogue_line.time != "":
		var time: float = dialogue_line.text.length() * 0.02 if dialogue_line.time == "auto" else dialogue_line.time.to_float()
		await get_tree().create_timer(time).timeout
		next(dialogue_line.next_id)
	else:
		is_waiting_for_input = true
		balloon.focus_mode = Control.FOCUS_ALL
		balloon.grab_focus()


## Go to the next line
func next(next_id: String) -> void:
	dialogue_line = await dialogue_resource.get_next_dialogue_line(next_id, temporary_game_states)


# ─── Portrait System (เรียกจาก .dialogue ด้วย do) ──────────────


## ตั้งค่า portrait ฝั่งใดฝั่งหนึ่ง
## เรียกใน .dialogue: do set_portrait("left", "npc", "happy")
## side     : "left" หรือ "right"
## character: ชื่อ folder ใน assets/portraits/ เช่น "player", "npc", "guard"
## pose     : ชื่อไฟล์ (ไม่มี .png) เช่น "default", "happy", "angry"
func set_portrait(side: String, character: String, pose: String = "default") -> void:
	var path: String = portrait_path_pattern\
		.replace("{character}", character)\
		.replace("{pose}", pose)

	print("[Balloon] set_portrait called! side=", side, " char=", character, " pose=", pose, " path=", path)

	var portrait_node: TextureRect = left_portrait if side == "left" else right_portrait

	if not ResourceLoader.exists(path) and not FileAccess.file_exists(path):
		push_warning("[Balloon] Portrait not found: %s" % path)
		return

	var tex = load(path)
	if tex == null:
		push_warning("[Balloon] Failed to load portrait: %s" % path)
		return

	portrait_node.texture = tex
	portrait_node.show()
	print("[Balloon] portrait node shown!")

	if side == "left":
		_left_char = character.to_lower()
	else:
		_right_char = character.to_lower()

	_update_portrait_dim()


## ซ่อน portrait
## เรียกใน .dialogue: do hide_portrait("left") / do hide_portrait("right") / do hide_portrait("all")
func hide_portrait(side: String = "all") -> void:
	match side:
		"left":
			left_portrait.hide()
			_left_char = ""
		"right":
			right_portrait.hide()
			_right_char = ""
		_:
			_hide_all_portraits()


func _hide_all_portraits() -> void:
	left_portrait.hide()
	right_portrait.hide()
	_left_char = ""
	_right_char = ""


## Dim ตัวละครที่ไม่ได้พูด และ highlight ตัวที่กำลังพูด
func _update_portrait_dim() -> void:
	if not is_instance_valid(dialogue_line):
		return

	var speaker: String = dialogue_line.character.to_lower()

	# ถ้าไม่รู้ว่าใครพูด (narrator) → ไม่ dim ใคร
	if speaker.is_empty():
		left_portrait.modulate = Color.WHITE
		right_portrait.modulate = Color.WHITE
		return

	# ระบบจับคู่ชื่อ (Alias) เผื่อชื่อที่พิมพ์ใน Dialogue ไม่ตรงกับชื่อโฟลเดอร์ภาพ
	var ref_speaker: String = speaker
	if speaker in ["ava", "ผู้เล่น", "player"]:
		ref_speaker = "player"
	elif speaker in ["eve", "???", "npc", "villager"]:
		ref_speaker = "npc"

	var DIM := Color(0.45, 0.45, 0.5, 0.85)

	# Match ด้วย contains เผื่อชื่อใน dialogue และชื่อ folder ตรงกันบางส่วน
	var left_speaking: bool  = _left_char.is_empty()  or ref_speaker.contains(_left_char)  or _left_char.contains(ref_speaker)
	var right_speaking: bool = _right_char.is_empty() or ref_speaker.contains(_right_char) or _right_char.contains(ref_speaker)

	left_portrait.modulate  = Color.WHITE if left_speaking  else DIM
	right_portrait.modulate = Color.WHITE if right_speaking else DIM


#region Signals

func _on_mutation_cooldown_timeout() -> void:
	if will_hide_balloon:
		will_hide_balloon = false
		balloon.hide()


func _on_mutated(mutation: Dictionary) -> void:
	if not mutation.is_inline:
		is_waiting_for_input = false
		will_hide_balloon = true
		mutation_cooldown.start(0.1)


func _on_balloon_gui_input(event: InputEvent) -> void:
	if dialogue_label.is_typing:
		var mouse_was_clicked: bool = event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.is_pressed()
		var skip_button_was_pressed: bool = event.is_action_pressed(skip_action)
		if mouse_was_clicked or skip_button_was_pressed:
			get_viewport().set_input_as_handled()
			dialogue_label.skip_typing()
			return

	if not is_waiting_for_input: return
	if dialogue_line.responses.size() > 0: return

	get_viewport().set_input_as_handled()

	if event is InputEventMouseButton and event.is_pressed() and event.button_index == MOUSE_BUTTON_LEFT:
		next(dialogue_line.next_id)
	elif event.is_action_pressed(next_action) and get_viewport().gui_get_focus_owner() == balloon:
		next(dialogue_line.next_id)


func _on_responses_menu_response_selected(response: DialogueResponse) -> void:
	next(response.next_id)

#endregion
