extends Node2D

@export var min_radius: float = 400.0
@export var max_radius: float = 650.0

# ฟังก์ชันสุ่มเสกศัตรูรอบตัวผู้เล่น
func spawn_enemy(enemy_scene: PackedScene, use_spawn_delay: bool = true) -> Node2D:
	if not enemy_scene: return null
	
	var player = get_tree().get_first_node_in_group("player")
	if not player: return null
	
	# คำนวณจุดเกิดแบบสุ่มในรัศมีวงกลม
	var angle = randf() * TAU
	var distance = randf_range(min_radius, max_radius)
	var spawn_pos = player.global_position + Vector2(cos(angle), sin(angle)) * distance
	
	# สอน: เราเพิ่มความลื่นไหลโดยการรอนิดนึงก่อนเสกครับ (เสกออกมาทีเดียวจะดูกระตุก)
	if use_spawn_delay:
		await get_tree().create_timer(randf_range(0.1, 0.5)).timeout
	
	var enemy = enemy_scene.instantiate()
	enemy.global_position = spawn_pos
	
	var current_scene = get_tree().current_scene
	if current_scene:
		current_scene.add_child(enemy)
	else:
		get_tree().root.add_child(enemy)
	
	return enemy
