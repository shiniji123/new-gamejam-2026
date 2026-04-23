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
	# เซ็ตสถานะเกมเป็นโหมดต่อสู้
	Autoload.current_state = Autoload.State.COMBAT

	# เปิดเพลงประกอบ
	if battle_music:
		AudioManager.play_bgm(battle_music, music_fade_duration)
	else:
		push_warning("[FightScene] ยังไม่ได้ใส่ battle_music ใน Inspector!")

	# ตั้งค่าขนาดตัวละคร
	if has_node("Player"):
		$Player.scale = player_scale

	# ผูก RewardUI เข้ากับ WaveManager
	_connect_reward_ui()

	# ตั้งค่าขอบเขตกล้องและกำแพงแผนที่
	_setup_map_bounds()


func _connect_reward_ui() -> void:
	var wave_manager := get_node_or_null("WaveManager")
	var reward_ui := get_node_or_null("UI/RewardUI")

	if wave_manager and reward_ui and reward_ui.has_method("connect_to_wave_manager"):
		reward_ui.connect_to_wave_manager(wave_manager)


func _setup_map_bounds() -> void:
	if not has_node("Background"):
		return

	var bg := $Background
	var background_rect := MapBoundaryHelper.get_background_rect(bg)

	if background_rect.size == Vector2.ZERO:
		push_warning("[FightScene] ไม่สามารถคำนวณขนาด Background ได้")
		return

	# ล็อกขอบเขตกล้อง
	if has_node("Player") and $Player.has_method("set_camera_limits"):
		$Player.set_camera_limits(background_rect)

	# สร้างกำแพงล่องหน 4 ด้าน
	MapBoundaryHelper.create_map_boundaries(self, background_rect)
