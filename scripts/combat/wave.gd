extends Node

@export_group("Enemy Scenes")
@export var normal_scene: PackedScene
@export var elite_scene: PackedScene
@export var boss_scene: PackedScene

# --- ข้อมูล Wave (ปรับแต่งใน Inspector ได้เลยครับ) ---
@export var waves: Array[Dictionary] = [
	{"normal": 5, "elite": 0, "boss": 0}, # Wave 1
	{"normal": 4, "elite": 1, "boss": 0}, # Wave 2
	{"normal": 4, "elite": 0, "boss": 1}  # Wave 3
]

var current_wave_index: int = -1
var enemies_left: int = 0

@onready var spawner = get_node("../Spawner")

func _ready():
	await get_tree().create_timer(3.0).timeout
	start_next_wave()

func start_next_wave():
	current_wave_index += 1
	
	if current_wave_index >= waves.size():
		print("--- จบทุก Wave แล้ว! ชนะ! ---")
		return
		
	var wave_data = waves[current_wave_index]
	print("--- เริ่ม Wave: ", current_wave_index + 1, " ---")
	
	await spawn_set(
		wave_data.get("normal", 0), 
		wave_data.get("elite", 0), 
		wave_data.get("boss", 0)
	)

func spawn_set(n, e, b):
	enemies_left = n + e + b
	if enemies_left == 0: 
		start_next_wave()
		return

	for i in range(n): await spawn_one(normal_scene)
	for i in range(e): await spawn_one(elite_scene)
	for i in range(b): await spawn_one(boss_scene)

func spawn_one(scene):
	if not scene: 
		enemies_left -= 1
		return
		
	var instance = await spawner.spawn_enemy(scene)
	if instance:
		instance.tree_exited.connect(_on_enemy_cleared)

signal wave_cleared(wave_index: int)

func _on_enemy_cleared():
	# ป้องกัน Error ตอนเปลี่ยนฉาก หรือปิดเกมที่โหนดถูกลบไปแล้ว
	if not get_tree(): return
	
	enemies_left -= 1
	if enemies_left <= 0:
		print("Wave เคลียร์!")
		# ผู้จัดการ Wave จะไม่เล่นต่ออัตโนมัติ ให้ฉากต่อตู้หรือ RewardUI เป็นคนสั่งลุยเวฟต่อไป
		wave_cleared.emit(current_wave_index)
