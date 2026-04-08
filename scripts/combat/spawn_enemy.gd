extends Node2D

# --- การตั้งค่ารัศมีการเกิด ---
@export var min_radius: float = 450.0  # ระยะที่ใกล้ที่สุด (ไม่ให้เกิดทับตัวคนเล่น)
@export var max_radius: float = 700.0  # ระยะที่ไกลที่สุด

# ฟังก์ชันหลักในการเสกศัตรู
func spawn_enemy(enemy_scene: PackedScene) -> Node2D:
	if not enemy_scene: return null
	
	# 1. ค้นหาตำแหน่งผู้เล่น
	var player = get_tree().get_first_node_in_group("player")
	if not player: return null
	
	# 2. คำนวณตำแหน่งแบบสุ่มเป็นวงกลมรอบตัวผู้เล่น
	# - สุ่มมุม (0 ถึง 360 องศา)
	var random_angle = randf() * TAU
	# - สุ่มระยะห่างจากตัวผู้เล่น (อยู่ในช่วง min ถึง max)
	var random_dist = randf_range(min_radius, max_radius)
	
	# - แปลงค่าขั้ว (Polar) เป็นพิกัด Vector2 (Cartesian)
	var spawn_pos = player.global_position + Vector2(
		cos(random_angle) * random_dist,
		sin(random_angle) * random_dist
	)
	
	# 3. สร้าง Instance จาก Scene และกำหนดตำแหน่ง
	var enemy_instance = enemy_scene.instantiate()
	enemy_instance.global_position = spawn_pos
	
	# 4. นำไปแปะไว้ในฉาก (ควรแปะไว้ที่ระดับโลกเพื่อให้มันเดินได้อิสระ)
	get_tree().root.add_child(enemy_instance)
	
	return enemy_instance # ส่งค่ากลับเพื่อให้ระบบ Wave เอาไปนับจำนวนได้ครับ
