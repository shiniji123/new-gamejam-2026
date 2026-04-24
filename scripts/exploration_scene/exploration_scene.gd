extends Node2D

const MEMORY_CUTSCENE_SCENE := preload("res://scenes/cutscene/memory_cutscene_controller.tscn")
## ===================================================
## exploration_scene.gd — ฉากสำรวจ
## ===================================================
## ใช้ MapBoundaryHelper (static class) แทนการ duplicate โค้ด

@export_group("Audio")
## ลากไฟล์เพลงสำรวจมาใส่ที่นี่ (ไม่ต้อง preload ในโค้ด)
@export var explore_music: AudioStream
## ระยะเวลา Fade-in ของเพลง (วินาที)
@export var music_fade_duration: float = 2.0

@export_group("Player Settings")
## ขนาดของ Player ในฉากนี้
@export var player_scale: Vector2 = Vector2(3, 3)


func _ready() -> void:
	# เซ็ตสถานะเกมเป็นโหมดสำรวจ
	Autoload.current_state = Autoload.State.EXPLORE
	# เปิดเพลงประกอบ
	if explore_music:
		AudioManager.play_bgm(explore_music, music_fade_duration)
	else:
		push_warning("[ExplorationScene] ยังไม่ได้ใส่ explore_music ใน Inspector!")

	# ตั้งค่าขนาดตัวละคร
	if has_node("Player"):
		$Player.scale = player_scale

	if SaveManager.apply_pending_state_if_available(self):
		print("Pending save state applied")

	# ตั้งค่าขอบเขตกล้องและกำแพงแผนที่
	_setup_map_bounds()
	call_deferred("_ensure_event_cutscene")


func _setup_map_bounds() -> void:
	if not has_node("Background"):
		return

	var bg := $Background
	var map_rect := MapBoundaryHelper.get_background_rect(bg)

	if map_rect.size == Vector2.ZERO:
		push_warning("[ExplorationScene] ไม่สามารถคำนวณขนาด Background ได้")
		return

	# ล็อกขอบเขตกล้อง
	if has_node("Player") and $Player.has_method("set_camera_limits"):
		$Player.set_camera_limits(map_rect)

	# สร้างกำแพงล่องหน 4 ด้าน
	MapBoundaryHelper.create_map_boundaries(self, map_rect)


func _ensure_event_cutscene() -> void:
	if not get_tree().root.has_node("EventManager"):
		return
	if not EventManager.is_event_active("memory_cutscene_after_fight_3"):
		return
	if has_node("MemoryCutsceneController"):
		return

	var cutscene := MEMORY_CUTSCENE_SCENE.instantiate()
	add_child(cutscene)
