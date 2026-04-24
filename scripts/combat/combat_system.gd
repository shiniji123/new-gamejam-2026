extends Node2D
class_name CombatSystem

# --- การตั้งค่าที่ปรับแต่งได้ (Inspector) ---
@export_group("Projectile Settings")
@export var projectile_scene: PackedScene      # ลากไฟล์ .tscn ของกระสุนมาใส่ที่นี่
@export var projectile_speed: float = 500.0    # ความเร็วลูกไฟ

@export_group("Stats")
@export var damage: float = 50.0               # ดาเมจต่อหนึ่งนัด แนะนำไปปรับแก้ใน Inspector ได้เลยครับ
@export var fire_rate: float = 1.0             # อัตราการยิง (นัดต่อวินาที)

@export_group("Audio")
@export var shoot_sound: AudioStream           # ลากไฟล์เสียงยิงมาใส่ได้เลย

@export_group("Spread")
@export var spread_angle: float = 15.0        # มุมกระจายเมื่อยิงหลายนัด (ออกแต่ละด้าน หน่วยเป็นองศา)
# ------------------------------

# ตัวจับเวลาการยิงออโต้
@onready var fire_timer: Timer = Timer.new()

func _ready() -> void:
	if projectile_scene == null:
		push_warning("คำเตือน: ยังไม่ได้ลากไฟล์กระสุนมาใส่ใน CombatSystem นะครับ!")
		return
		
	_update_fire_rate_timer()
	fire_timer.autostart = true
	fire_timer.timeout.connect(_on_fire_timer_timeout)
	add_child(fire_timer)

	if not StatCalculator.stats_recalculated.is_connected(_on_stats_recalculated):
		StatCalculator.stats_recalculated.connect(_on_stats_recalculated)

func _on_fire_timer_timeout() -> void:
	if Autoload.current_state != Autoload.State.COMBAT:
		return
		
	var target: Node2D = get_closest_enemy()
	if target:
		fire_at_target(target)

func get_closest_enemy() -> Node2D:
	var enemies: Array = get_tree().get_nodes_in_group("enemy")
	var closest_enemy: Node2D = null
	var min_distance: float = INF
	
	for enemy in enemies:
		if "is_dead" in enemy and enemy.is_dead: 
			continue
		
		var dist: float = global_position.distance_to(enemy.global_position)
		if dist < min_distance:
			min_distance = dist
			closest_enemy = enemy
			
	return closest_enemy

func fire_at_target(target: Node2D) -> void:
	if shoot_sound:
		AudioManager.play_sfx(shoot_sound, true)
		
	# เรียกใช้ StatCalculator เพื่อคำนวณดาเมจ จำนวนกระสุน และการโจมตีทะลุรวม (Perks + Shop + Base)
	var final_damage: float = StatCalculator.get_player_damage(damage)
	var total_shots: int = StatCalculator.get_projectile_count(1)
	var final_pierce: int = StatCalculator.get_pierce_count(0) # เริ่มต้นทะลุไม่ได้ (0)
	
	var base_dir: Vector2 = target.global_position - global_position
	var spread_rad: float = deg_to_rad(spread_angle)
	
	for i in range(total_shots):
		var proj = projectile_scene.instantiate()
		
		# สร้างในฉากปัจจุบัน กระสุนจะได้ลบหายไปตอนเปลี่ยนด่าน
		var current_scene: Node = get_tree().current_scene
		if current_scene:
			current_scene.add_child(proj)
		else:
			get_tree().root.add_child(proj)
			
		proj.global_position = global_position
		
		var angle_offset: float = 0.0
		if total_shots > 1:
			angle_offset = spread_rad * (i - (total_shots - 1) / 2.0)
		var final_dir: Vector2 = base_dir.rotated(angle_offset)
		
		if proj.has_method("setup"):
			proj.setup(final_dir, projectile_speed, final_damage, final_pierce)


func _on_stats_recalculated() -> void:
	_update_fire_rate_timer()


func _update_fire_rate_timer() -> void:
	var final_fire_rate := StatCalculator.get_player_fire_rate(fire_rate)
	fire_timer.wait_time = 1.0 / final_fire_rate
