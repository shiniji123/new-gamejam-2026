extends Node2D

@onready var interaction_area: InteractionArea = $InteractiveArea
@onready var sprite = $Animatedsprite2D
@onready var greeting_label = $GreetingArea/Label


const lines: Array[String] = ["Hey There","Wutt sup","Talk to me"]

func _ready():
	if interaction_area:
		interaction_area.action_name = "Talk"
		interaction_area.interact = Callable(self, "_on_interact")
	else:
		push_warning("[DialogueNPC] ยังไม่ได้ใส่ InteractionArea! กรุณาลากมาใส่ใน Inspector ครับ")

	if animated_sprite:
		animated_sprite.play()

#===============================================
#GREETING

func _on_greeting_area_body_entered(body: Node2D) -> void:
	greeting_label.text = lines[randi() % lines.size()]

func _on_greeting_area_body_exited(body: Node2D) -> void:
	greeting_label.text = "..."
	
#func enter_interaction_area():
	#print("1")
	#greeting_label.hide()
#===============================================

#INTERACTION
@export var dialogue_resource: DialogueResource
## ชื่อ title ใน .dialogue ไฟล์ที่จะเริ่ม เช่น "start"
@export var start_title: String = "start"
@export_group("Visuals (ภาพ)")
@export var animated_sprite: AnimatedSprite2D

# ติดตามว่ากำลังพูดอยู่หรือเปล่า เพื่อไม่ให้ trigger ซ้ำ
var _is_talking: bool = false


func _on_interact() -> void:
	if not dialogue_resource:
		push_warning("[DialogueNPC] ยังไม่ได้ใส่ไฟล์ .dialogue! กรุณาสร้างและลากมาใส่ใน Inspector ครับ")
		return

	if _is_talking:
		return

	_is_talking = true

	# เรียก balloon ที่ตั้งค่าไว้ใน Project Settings → dialogue_manager → balloon_path
	# (ปัจจุบันชี้ไปที่ res://scenes/dialogue/balloon.tscn แล้ว)
	await DialogueManager.show_dialogue_balloon(dialogue_resource, start_title)

	_is_talking = false
