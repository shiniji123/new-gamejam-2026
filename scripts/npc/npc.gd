extends Node2D
## ===================================================
## npc.gd — ตัวละคร NPC พร้อมระบบ Dialogue
## ===================================================

@onready var interaction_area: InteractionArea = $InteractiveArea
@onready var _sprite_node: AnimatedSprite2D = $Animatedsprite2D
@onready var greeting_label: Label = $GreetingArea/Label

## ไฟล์ .dialogue ที่จะเปิดตอนคุย
@export var dialogue_resource: DialogueResource
## ชื่อ Title เริ่มต้นใน .dialogue (เช่น "start")
@export var start_title: String = "start"

@export_group("Visuals")
## AnimatedSprite2D ของ NPC (ถ้าไม่ใส่ จะใช้โหนด $AnimatedSprite2D อัตโนมัติ)
@export var animated_sprite: AnimatedSprite2D

## ข้อความทักทายสุ่ม (ปรับได้จากตรงนี้โดยไม่ต้องแก้ฟังก์ชัน)
@export var greeting_lines: Array[String] = ["Hey There!", "Wutt sup~", "Talk to me!"]

@export_group("Event System")
## ชื่อเป้าหมายที่ EventManager จะตรวจสอบ (เช่น "village_npc")
@export var event_target_name: String = "village_npc"

# ตัวแปรภายใน
var _is_talking: bool = false
var _exclamation_mark: Label

func _ready() -> void:
	print("[NPC] _ready started for ", name)
	# บังคับให้ปรากฎตัวและอยู่บนสุด
	visible = true
	visibility_layer = 1
	light_mask = 1
	z_index = 100
	scale = Vector2(3, 3) # ขยายขนาดให้เท่ากับ Player เพื่อให้เห็นชัดๆ
	
	# สร้างเครื่องหมายตกใจสีแดง (!) ลอยบนหัว NPC
	_exclamation_mark = Label.new()
	_exclamation_mark.text = "!"
	_exclamation_mark.add_theme_font_size_override("font_size", 48)
	_exclamation_mark.add_theme_color_override("font_color", Color.RED)
	_exclamation_mark.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_exclamation_mark.position = Vector2(-20, -60) # ปรับพิกัดใหม่เพราะเราคูณ scale NPC แล้ว
	_exclamation_mark.hide()
	add_child(_exclamation_mark)
	
	# แอนิเมชันให้เครื่องหมายกระโดดดึ๋งๆ
	var tween = create_tween().set_loops()
	tween.tween_property(_exclamation_mark, "position:y", -70.0, 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(_exclamation_mark, "position:y", -60.0, 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	# ผูก Interaction Area
	if interaction_area:
		print("[NPC] Found InteractionArea")
		interaction_area.action_name = "Talk"
		interaction_area.interact = Callable(self , "_on_interact")
	else:
		push_warning("[NPC] ไม่พบ InteractionArea ($InteractiveArea) — กรุณาเพิ่มโหนดนี้")

	# เริ่มเล่น animation
	var sprite := animated_sprite if animated_sprite else _sprite_node
	if sprite:
		print("[NPC] Found Sprite node, playing animation")
		sprite.play()
		sprite.visibility_layer = 1
		sprite.light_mask = 1
	else:
		print("[NPC] Sprite node NOT found!")

	# เช็คว่าต้องทักทายอัตโนมัติไหมเมื่อเริ่มเกม
	call_deferred("_check_auto_talk")

func _check_auto_talk() -> void:
	if not Autoload.has_node("/root/EventManager"): return
	var current_event = EventManager.get_current_event()
	if current_event.get("id", "") == "intro_talk_auto":
		# หน่วงเวลานิดนึงเพื่อให้ฉากโหลดเสร็จ
		await get_tree().create_timer(1.0).timeout
		_on_interact()

func _process(_delta: float) -> void:
	# คอยอัปเดตว่าจะโชว์เครื่องหมายตกใจบนหัวไหม
	if not Autoload.has_node("/root/EventManager"): return
	if _is_talking:
		_exclamation_mark.hide()
		return
		
	var current_event = EventManager.get_current_event()
	var show_mark = false
	
	# โชว์ถ้า Event ถัดไปบอกให้คุยกับ NPC ตัวนี้
	if current_event.get("complete_target", "") == event_target_name:
		show_mark = true
	# หรือถ้าเป็น Event อัตโนมัติที่เพิ่งเข้ามา
	elif current_event.get("id", "") == "intro_talk_auto" or current_event.get("id", "") == "talk_after_read":
		show_mark = true
		
	_exclamation_mark.visible = show_mark

func _on_greeting_area_body_entered(_body: Node2D) -> void:
	if greeting_lines.is_empty():
		return
	greeting_label.text = greeting_lines[randi() % greeting_lines.size()]


func _on_greeting_area_body_exited(_body: Node2D) -> void:
	greeting_label.text = "..."


func _on_interact() -> void:
	if not dialogue_resource:
		push_warning("[NPC] ยังไม่ได้ใส่ dialogue_resource ใน Inspector!")
		return

	if _is_talking:
		return

	_is_talking = true

	# หยุดการเดินของ Player ขณะคุย (ปิด physics ชั่วคราว)
	var player := get_tree().get_first_node_in_group("player")
	if player:
		player.set_physics_process(false)
		player.velocity = Vector2.ZERO
		# ถ้าฉากเปลี่ยนไประหว่างคุย ให้ปลดล็อคอัตโนมัติเพื่อป้องกัน freeze
		if not tree_exiting.is_connected(_on_tree_exiting_unlock_player):
			tree_exiting.connect(_on_tree_exiting_unlock_player)

	DialogueManager.show_dialogue_balloon(dialogue_resource, start_title)
	await DialogueManager.dialogue_ended

	# [Fix] แจ้ง EventManager ว่าคุยจบแล้ว เพื่อให้ลำดับเหตุการณ์ (Event Timeline) เดินต่อ
	if Autoload.has_node("/root/EventManager"):
		EventManager.notify_interaction(event_target_name)
		# ถ้าเป็น Event แรก (intro) ให้แจ้งจบ dialogue ด้วย
		EventManager.notify_dialogue_ended()

	# คืนการเดินให้ Player หลังปิด Dialogue
	if is_instance_valid(player):
		player.set_physics_process(true)

	_is_talking = false

func _on_tree_exiting_unlock_player() -> void:
	## ถูกเรียกอัตโนมัติเมื่อ NPC ถูกลบออกจากฉาก (เช่น เปลี่ยนฉาก)
	## ป้องกัน player ค้างแม้ dialogue ยังไม่จบ
	var player := get_tree().get_first_node_in_group("player")
	if is_instance_valid(player):
		player.set_physics_process(true)
