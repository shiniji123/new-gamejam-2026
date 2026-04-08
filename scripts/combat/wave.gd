extends Node

# --- การโหลด Scene ต่างๆ ---
@export_group("Enemy Scenes")
@export var normal_scene: PackedScene
@export var elite_scene: PackedScene
@export var boss_scene: PackedScene

# --- ตัวแปรกำกับ Wave ---
var current_wave: int = 0
var enemies_alive: int = 0

@onready var spawner = get_node("../SpawnEnemy") # สมมติว่าวางไว้คู่กันใน Scene ครับ

func _ready():
	# เริ่มด่านทันที (คุณสามารถเปลี่ยนไปเรียกใช้ผ่านปุ่มกดก็ได้ครับ)
	await get_tree().create_timer(2.0).timeout # รอแป๊บนึงให้เกมเริ่ม
	start_next_wave()

func start_next_wave():
	current_wave += 1
	print("--- เริ่ม Wave: ", current_wave, " ---")
	
	match current_wave:
		1:
			# Wave 1: ศัตรูปกติ 5 ตัว
			spawn_set(5, 0, 0)
		2:
			# Wave 2: ศัตรูปกติ 4 ตัว + Elite 1 ตัว
			spawn_set(4, 1, 0)
		3:
			# Wave 3: ศัตรูปกติ 4 ตัว + Boss 1 ตัว
			spawn_set(4, 0, 1)
		_:
			print("จบเกม! ชนะแล้วครับ")

# ฟังก์ชันสั่ง Spawner ให้เสกของตามจำนวน
func spawn_set(normal_count: int, elite_count: int, boss_count: int):
	enemies_alive = normal_count + elite_count + boss_count
	
	# เสกตัวธรรมดา
	for i in range(normal_count):
		var e = spawner.spawn_enemy(normal_scene)
		connect_enemy(e)
		
	# เสกตัว Elite
	for i in range(elite_count):
		var e = spawner.spawn_enemy(elite_scene)
		connect_enemy(e)
		
	# เสก Boss
	for i in range(boss_count):
		var e = spawner.spawn_enemy(boss_scene)
		connect_enemy(e)

# ฟังก์ชันเชื่อมต่อสัญญาณเพื่อให้รู้ว่าศัตรูตายแล้ว
func connect_enemy(enemy_node: Node):
	if not enemy_node: return
	
	# เมื่อโหนดถูกลบออกจากฉาก (ตายครบ 2 วินาที)
	enemy_node.tree_exited.connect(_on_enemy_cleared)

func _on_enemy_cleared():
	enemies_alive -= 1
	print("ศัตรูตาย! เหลืออีก: ", enemies_alive)
	
	# ถ้าตายหมดกองแล้ว ให้เริ่ม Wave ถัดไป
	if enemies_alive <= 0:
		print("Wave เคลียร์!")
		await get_tree().create_timer(2.0).timeout # พักหายใจก่อน Wave ใหม่
		start_next_wave()
