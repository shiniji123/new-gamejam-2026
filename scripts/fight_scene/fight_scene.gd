extends Node2D

const FullscreenStripPlayerScene := preload("res://scripts/ui/fullscreen_strip_player.gd")
## ===================================================
## fight_scene.gd — ฉากต่อสู้หลัก
## ===================================================
## ใช้ MapBoundaryHelper (static class) แทนการ duplicate โค้ด

@export_group("Audio")
## ลากไฟล์เพลงต่อสู้มาใส่ที่นี่ (ไม่ต้อง preload ในโค้ด)
@export var battle_music: AudioStream
@export var final_boss_music: AudioStream
## ระยะเวลา Fade-in ของเพลง (วินาที)
@export var music_fade_duration: float = 1.5

@export_group("Player Settings")
## ขนาดของ Player ในฉากนี้
@export var player_scale: Vector2 = Vector2(1.5, 1.5)

@export_group("Transform Intro")
@export var play_transform_intro: bool = true
@export var transform_intro_texture: Texture2D = preload("res://assets/portraits/player/transfrom_scene.PNG")
@export var transform_intro_frame_count: int = 13
@export var transform_intro_fps: float = 9.0
@export var transform_intro_hold_time: float = 0.2
@export var transform_intro_fade_out: float = 0.15

@export_group("Game Over")
@export var game_over_scene: PackedScene = preload("res://scenes/ui/game_over_ui.tscn")

var _game_over_ui: CanvasLayer = null


func _ready() -> void:
	# ===== SAFETY RESET: ล้างสถานะค้างจากฉากก่อนหน้า =====
	# ป้องกัน get_tree().paused ค้างมาจาก Shop/Dialogue ในฉาก exploration
	get_tree().paused = false
	
	# เซ็ตสถานะเกมเป็นโหมดต่อสู้
	Autoload.current_state = Autoload.State.COMBAT

	# เปิดเพลงประกอบ
	var music_to_play := _get_music_for_current_event()
	if music_to_play:
		AudioManager.play_bgm(music_to_play, music_fade_duration)
	else:
		push_warning("[FightScene] ยังไม่ได้ใส่ battle_music ใน Inspector!")

	# ตั้งค่าขนาดตัวละคร (รองรับทั้งชื่อ Player และ Player_Transform)
	var p = get_node_or_null("Player")
	if not p: p = get_node_or_null("Player_Transform")
	
	if p:
		p.scale = player_scale
		# ปลดล็อคการเคลื่อนที่ผู้เล่น (ถ้าถูก lock ไว้จาก NPC dialogue)
		p.set_physics_process(false)
		_setup_game_over_listener(p)

	# เลือก WaveManager ให้ตรงกับ Event ปัจจุบัน และผูก UI

	# ตั้งค่าขอบเขตกล้องและกำแพงแผนที่
	_setup_map_bounds()

	await _play_transform_intro()

	if p:
		p.set_physics_process(true)

	_setup_active_wave_manager()


func _play_transform_intro() -> void:
	if not play_transform_intro or not transform_intro_texture or transform_intro_frame_count <= 0:
		return

	var player := FullscreenStripPlayerScene.new()
	player.autoplay = false
	player.setup(
		transform_intro_texture,
		transform_intro_frame_count,
		transform_intro_fps,
		transform_intro_hold_time,
		0.0,
		transform_intro_fade_out
	)
	add_child(player)
	player.play()
	await player.finished


func _get_music_for_current_event() -> AudioStream:
	if Autoload.has_node("/root/EventManager"):
		var current_event_id := String(EventManager.get_current_event().get("id", ""))
		if current_event_id == "fight_wave_5" and final_boss_music:
			return final_boss_music

	return battle_music


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
		active_wave_manager = get_node_or_null("WaveManager_fight_wave_1")
		
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


func _setup_game_over_listener(player_node: Node) -> void:
	var hurtbox := player_node.get_node_or_null("HurtboxComponent")
	if hurtbox and hurtbox.has_signal("died") and not hurtbox.died.is_connected(_on_player_died):
		hurtbox.died.connect(_on_player_died)


func _on_player_died() -> void:
	if _game_over_ui:
		return

	await get_tree().create_timer(0.7).timeout
	if not is_inside_tree() or _game_over_ui:
		return

	if game_over_scene:
		_game_over_ui = game_over_scene.instantiate() as CanvasLayer
		add_child(_game_over_ui)
		get_tree().paused = true
