extends Node2D
## ===================================================
## fight_scene.gd — ฉากต่อสู้หลัก
## ===================================================
## ใช้ MapBoundaryHelper (static class) แทนการ duplicate โค้ด

@export_group("Audio")
## ลากไฟล์เพลงต่อสู้มาใส่ที่นี่ (ไม่ต้อง preload ในโค้ด)
@export var battle_music: AudioStream
## ระยะเวลา Fade-in ของเพลง (วินาที)
@export var music_fade_duration: float = 1.5

@export_group("Player Settings")
## ขนาดของ Player ในฉากนี้
@export var player_scale: Vector2 = Vector2(1.5, 1.5)


func _ready() -> void:
	# ===== SAFETY RESET: ล้างสถานะค้างจากฉากก่อนหน้า =====
	# ป้องกัน get_tree().paused ค้างมาจาก Shop/Dialogue ในฉาก exploration
	get_tree().paused = false
	
	# เซ็ตสถานะเกมเป็นโหมดต่อสู้
	Autoload.current_state = Autoload.State.COMBAT

	# เปิดเพลงประกอบ
	if battle_music:
		AudioManager.play_bgm(battle_music, music_fade_duration)
	else:
		push_warning("[FightScene] ยังไม่ได้ใส่ battle_music ใน Inspector!")

	# ตั้งค่าขนาดตัวละคร (รองรับทั้งชื่อ Player และ Player_Transform)
	var p = get_node_or_null("Player")
	if not p: p = get_node_or_null("Player_Transform")
	
	if p:
		p.scale = player_scale
		# ปลดล็อคการเคลื่อนที่ผู้เล่น (ถ้าถูก lock ไว้จาก NPC dialogue)
		p.set_physics_process(true)

	# เลือก WaveManager ให้ตรงกับ Event ปัจจุบัน และผูก UI
	_setup_active_wave_manager()

	# ตั้งค่าขอบเขตกล้องและกำแพงแผนที่
	_setup_map_bounds()


func _setup_active_wave_manager() -> void:
	var active_wave_manager: Node = null
	
	# หาชื่อ Event ล่าสุด
	var current_event_id = ""
	if Autoload.has_node("/root/EventManager"):
		current_event_id = EventManager.get_current_event().get("id", "")
		
	# ลองหา WaveManager ที่ตั้งชื่อตรงกับ Event เช่น "WaveManager_fight_wave_1"
	if current_event_id != "":
		active_wave_manager = get_node_or_null("WaveManager_" + current_event_id)
		
	# ถ้าหาไม่เจอ ให้ใช้โหนดที่ชื่อ "WaveManager" ธรรมดาแทน
	if not active_wave_manager:
		active_wave_manager = get_node_or_null("WaveManager")
		
	if not active_wave_manager:
		push_warning("[FightScene] ไม่พบโหนด WaveManager ใดๆ ในฉากนี้เลย!")
		return
		
	# ผูกกับ UI
	var reward_ui := get_node_or_null("UI/RewardUI")
	if reward_ui and reward_ui.has_method("connect_to_wave_manager"):
		reward_ui.connect_to_wave_manager(active_wave_manager)
		
	# สั่งเริ่มทำงาน
	if active_wave_manager.has_method("start_manager"):
		active_wave_manager.start_manager()


func _setup_map_bounds() -> void:
	if not has_node("Background"):
		return

	var bg := $Background
	var background_rect := MapBoundaryHelper.get_background_rect(bg)

	if background_rect.size == Vector2.ZERO:
		push_warning("[FightScene] ไม่สามารถคำนวณขนาด Background ได้")
		return

	# ล็อกขอบเขตกล้อง
	var p = get_node_or_null("Player")
	if not p: p = get_node_or_null("Player_Transform")
	
	if p and p.has_method("set_camera_limits"):
		p.set_camera_limits(background_rect)

	# สร้างกำแพงล่องหน 4 ด้าน
	MapBoundaryHelper.create_map_boundaries(self , background_rect)
