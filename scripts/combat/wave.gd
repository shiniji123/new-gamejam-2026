extends Node
## ===================================================
## WaveManager — จัดการคลื่นศัตรู (ระบบโหนดลูก)
## ===================================================
## วิธีใช้งานที่ "ง่ายที่สุด":
##   1. คลิกขวาที่โหนด WaveManager -> Add Child Node
##   2. สร้างโหนด Node (หรือโหนดอะไรก็ได้) แล้วตั้งชื่อเช่น "Wave 1"
##   3. เอาสคริปต์ "wave_item.gd" ไปแปะที่โหนดนั้น
##   4. กรอกจำนวนศัตรูที่ต้องการใน Inspector ของโหนดลูกได้เลย!
##
##   * สามารถลากสลับลำดับโหนดลูกเพื่อเปลี่ยนลำดับ Wave ได้เลย

signal wave_cleared(wave_index: int)

@export_group("Enemy Scenes (ลากไฟล์ .tscn มาใส่)")
@export var normal_scene: PackedScene
@export var elite_scene: PackedScene
@export var boss_scene: PackedScene

# --- ตัวแปรภายใน ---
var waves: Array[WaveItem] = []
var current_wave_index: int = -1
var enemies_left: int = 0

@onready var spawner: Node2D = get_node("../Spawner")


func _ready() -> void:
	# ค้นหาโหนดลูกที่เป็น WaveItem ทั้งหมด
	_refresh_waves_from_children()
	
	if waves.is_empty():
		push_warning("[WaveManager] ยังไม่มี Wave! กรุณาเพิ่มโหนดลูกแล้วแปะสคริปต์ wave_item.gd")
		return

	# เริ่ม Wave แรกหลังจากหน่วงเวลาของ Wave นั้นๆ
	print("🎮 WaveManager พร้อมแล้ว! พบทั้งหมด %d Wave" % waves.size())
	await get_tree().create_timer(waves[0].start_delay).timeout
	start_next_wave()


func _refresh_waves_from_children() -> void:
	waves.clear()
	for child in get_children():
		if child is WaveItem:
			waves.append(child)


func start_next_wave() -> void:
	current_wave_index += 1

	if current_wave_index >= waves.size():
		print("🎉 ชนะแล้ว! ผ่านทุก %d Wave!" % waves.size())
		return

	var wave_data: WaveItem = waves[current_wave_index]
	RunManager.current_wave = current_wave_index + 1

	print("⚔️  เริ่ม %s (%d/%d) — ศัตรูทั้งหมด: %d ตัว" % [
		wave_data.name, 
		current_wave_index + 1, 
		waves.size(), 
		wave_data.get_total_enemies()
	])

	await _spawn_wave(wave_data)


func _spawn_wave(wave_data: WaveItem) -> void:
	enemies_left = wave_data.get_total_enemies()

	if enemies_left == 0:
		push_warning("[WaveManager] Wave นี้ไม่มีศัตรู — ข้ามไป Wave ถัดไป")
		wave_cleared.emit(current_wave_index)
		await get_tree().create_timer(2.0).timeout
		start_next_wave()
		return

	for _i in range(wave_data.normal_count):
		await _spawn_one(normal_scene, wave_data.spawn_interval)

	for _i in range(wave_data.elite_count):
		await _spawn_one(elite_scene, wave_data.spawn_interval)

	for _i in range(wave_data.boss_count):
		await _spawn_one(boss_scene, wave_data.spawn_interval)


func _spawn_one(scene: PackedScene, delay: float) -> void:
	if not scene:
		enemies_left -= 1
		if enemies_left <= 0:
			wave_cleared.emit(current_wave_index)
		return

	await get_tree().create_timer(delay).timeout

	if not is_instance_valid(spawner):
		push_error("[WaveManager] ไม่พบโหนด Spawner!")
		return

	var instance: Node2D = await spawner.spawn_enemy(scene)
	if instance:
		instance.tree_exited.connect(_on_enemy_cleared)


func _on_enemy_cleared() -> void:
	if not is_inside_tree():
		return

	enemies_left -= 1
	if enemies_left <= 0:
		print("✅ Wave %d เคลียร์! (รอตัวเลือกรางวัล...)" % (current_wave_index + 1))
		wave_cleared.emit(current_wave_index)
		# หมายเหตุ: ระบบจะรอการเรียก start_next_wave() จากที่อื่น (เช่น RewardUI) 
		# หรือคุณสามารถเปิด auto-start ได้ถ้าต้องการ
