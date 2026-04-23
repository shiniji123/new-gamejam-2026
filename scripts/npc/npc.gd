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

# ติดตามว่ากำลังคุยอยู่หรือเปล่า (ป้องกัน trigger ซ้ำ)
var _is_talking: bool = false


func _ready() -> void:
	# ผูก Interaction Area
	if interaction_area:
		interaction_area.action_name = "Talk"
		interaction_area.interact = Callable(self, "_on_interact")
	else:
		push_warning("[NPC] ไม่พบ InteractionArea ($InteractiveArea) — กรุณาเพิ่มโหนดนี้")

	# เริ่มเล่น animation (ใช้ export var ถ้ามี, ไม่งั้นใช้โหนดภายใน)
	var sprite := animated_sprite if animated_sprite else _sprite_node
	if sprite:
		sprite.play()


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

	# show_dialogue_balloon() return Node ทันที (ไม่ใช่ coroutine)
	# ต้อง await signal dialogue_ended แทนเพื่อรอให้บทสนทนาจบจริงๆ
	DialogueManager.show_dialogue_balloon(dialogue_resource, start_title)
	await DialogueManager.dialogue_ended

	# คืนการเดินให้ Player หลังปิด Dialogue
	if is_instance_valid(player):
		player.set_physics_process(true)

	_is_talking = false
