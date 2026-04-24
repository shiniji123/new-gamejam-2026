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
@export var normal_scenes: Array[PackedScene] = []
@export var elite_scene: PackedScene
@export var boss_scene: PackedScene # Boss 1
@export var boss_2_scene: PackedScene # Boss 2
@export var boss_3_scene: PackedScene # Boss 3
@export var final_boss_scene: PackedScene # Final Boss

@export_group("System Settings")
## หากตั้งเป็นปิด ฉากหลัก (FightScene) จะเป็นคนสั่งเริ่มทำงานเองตาม Event
@export var auto_start: bool = false
## ถ้าปิดไว้ Wave สุดท้ายจะจบด่านทันทีโดยไม่เปิดหน้ารางวัล
@export var reward_after_final_wave: bool = false

# --- ตัวแปรภายใน ---
var waves: Array[WaveItem] = []
var current_wave_index: int = -1
var enemies_left: int = 0
var _manager_started: bool = false

@onready var spawner: Node2D = get_node("../Spawner")


func _ready() -> void:
	# ค้นหาโหนดลูกที่เป็น WaveItem ทั้งหมด
	_refresh_waves_from_children()
	
	# ป้องกันการลืมใส่ Scene ศัตรูใน Inspector (โหลดค่าเริ่มต้นให้เลยถ้าว่าง)
	if normal_scenes.is_empty():
		var e1 = load("res://scenes/enemy/enemy_1.tscn")
		var e2 = load("res://scenes/enemy/enemy_2.tscn")
		if e1: normal_scenes.append(e1)
		if e2: normal_scenes.append(e2)
	
	if not elite_scene:
		elite_scene = load("res://scenes/enemy/elite.tscn")
	if not boss_scene:
		boss_scene = load("res://scenes/enemy/boss_1.tscn")
	if not boss_2_scene:
		boss_2_scene = load("res://scenes/enemy/boss_2.tscn")
	if not boss_3_scene:
		boss_3_scene = load("res://scenes/enemy/boss_3.tscn")
	if not final_boss_scene:
		final_boss_scene = load("res://scenes/enemy/final_boss.tscn")
	
	if waves.is_empty():
		push_warning("[WaveManager] ยังไม่มี Wave! กรุณาเพิ่มโหนดลูกแล้วแปะสคริปต์ wave_item.gd")
		return

	print("🎮 WaveManager เตรียมพร้อม! (Auto Start: %s)" % str(auto_start))
	if auto_start:
		start_manager()

func start_manager() -> void:
	if waves.is_empty() or _manager_started:
		return

	_manager_started = true
	print("▶️ เริ่มการทำงานของ WaveManager: ", self.name)
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
		# [เพิ่มใหม่] แจ้ง EventManager ว่าจบการต่อสู้ด่านนี้แล้ว เพื่อให้เกมดำเนินเนื้อเรื่องต่อ
		if Autoload.has_node("/root/EventManager"):
			EventManager.notify_fight_cleared()
		return

	var wave_data: WaveItem = waves[current_wave_index]
	RunManager.current_wave = current_wave_index + 1

	print("⚔️  เริ่ม %s (%d/%d) — ศัตรูทั้งหมด: %d ตัว" % [
		wave_data.name,
		current_wave_index + 1,
		waves.size(),
		wave_data.get_total_enemies()
	])

	if wave_data.start_delay > 0.0:
		await get_tree().create_timer(wave_data.start_delay).timeout
		if not is_inside_tree():
			return

	await _spawn_wave(wave_data)


func _spawn_wave(wave_data: WaveItem) -> void:
	# คำนวณจำนวนศัตรูใหม่ (ถ้าเป็น Boss 2 ให้คูณ 2 เพราะเกิดทีละคู่)
	var actual_boss_count = wave_data.boss_count
	if wave_data.boss_type == WaveItem.BossType.BOSS_2:
		actual_boss_count *= 2
		
	enemies_left = wave_data.normal_count + wave_data.elite_count + actual_boss_count

	if enemies_left == 0:
		push_warning("[WaveManager] Wave นี้ไม่มีศัตรู — ข้ามไป Wave ถัดไป")
		await get_tree().process_frame
		start_next_wave()
		return

	for _i in range(wave_data.normal_count):
		var random_normal = normal_scenes.pick_random() if normal_scenes.size() > 0 else null
		await _spawn_one(random_normal, wave_data.spawn_interval, wave_data.normal_scale)

	for _i in range(wave_data.elite_count):
		await _spawn_one(elite_scene, wave_data.spawn_interval, wave_data.elite_scale)

	# เลือก Boss ให้ตรงตามประเภท
	var selected_boss_scene = boss_scene
	match wave_data.boss_type:
		WaveItem.BossType.BOSS_2:
			selected_boss_scene = boss_2_scene
		WaveItem.BossType.BOSS_3:
			selected_boss_scene = boss_3_scene
		WaveItem.BossType.FINAL_BOSS:
			selected_boss_scene = final_boss_scene

	if wave_data.boss_type == WaveItem.BossType.BOSS_2:
		for _i in range(wave_data.boss_count):
			await _spawn_boss_pair(selected_boss_scene, wave_data.spawn_interval, wave_data.boss_scale)
	else:
		for _i in range(wave_data.boss_count):
			await _spawn_one(selected_boss_scene, wave_data.spawn_interval, wave_data.boss_scale)


func _spawn_one(scene: PackedScene, delay: float, enemy_scale: Vector2 = Vector2.ONE) -> void:
	if not scene:
		_consume_enemy_slot()
		return

	await get_tree().create_timer(delay).timeout

	if not is_instance_valid(spawner):
		push_error("[WaveManager] ไม่พบโหนด Spawner!")
		_consume_enemy_slot()
		return

	var instance: Node2D = await spawner.spawn_enemy(scene)
	if instance:
		_apply_enemy_scale(instance, enemy_scale)
		instance.tree_exited.connect(_on_enemy_cleared)
	else:
		push_warning("[WaveManager] Spawn enemy ไม่สำเร็จ — ตัดจำนวนศัตรูที่ค้างออก 1 ตัว")
		_consume_enemy_slot()


func _spawn_boss_pair(scene: PackedScene, delay: float, enemy_scale: Vector2 = Vector2.ONE) -> void:
	if not scene:
		_consume_enemy_slot()
		_consume_enemy_slot()
		return

	await get_tree().create_timer(delay).timeout

	if not is_instance_valid(spawner):
		push_error("[WaveManager] ไม่พบโหนด Spawner!")
		_consume_enemy_slot()
		_consume_enemy_slot()
		return

	var spawned_count := 0
	for _i in range(2):
		var instance: Node2D = await spawner.spawn_enemy(scene, false)
		if instance:
			spawned_count += 1
			_apply_enemy_scale(instance, enemy_scale)
			instance.tree_exited.connect(_on_enemy_cleared)

	for _i in range(2 - spawned_count):
		_consume_enemy_slot()


func _on_enemy_cleared() -> void:
	if not is_inside_tree():
		return

	enemies_left -= 1
	if enemies_left <= 0:
		_finish_current_wave()
		# หมายเหตุ: ระบบจะรอการเรียก start_next_wave() จากที่อื่น (เช่น RewardUI) 
		# หรือคุณสามารถเปิด auto-start ได้ถ้าต้องการ


func _consume_enemy_slot() -> void:
	if enemies_left <= 0:
		return

	enemies_left -= 1
	if enemies_left <= 0:
		_finish_current_wave()


func _finish_current_wave() -> void:
	var is_final_wave := current_wave_index >= waves.size() - 1
	if is_final_wave and not reward_after_final_wave:
		print("✅ Wave %d เคลียร์! (จบด่าน)" % (current_wave_index + 1))
		call_deferred("start_next_wave")
		return

	print("✅ Wave %d เคลียร์! (รอตัวเลือกรางวัล...)" % (current_wave_index + 1))
	wave_cleared.emit(current_wave_index)


func _apply_enemy_scale(instance: Node2D, enemy_scale: Vector2) -> void:
	if enemy_scale == Vector2.ONE:
		return

	instance.scale *= enemy_scale
