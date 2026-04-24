extends CanvasLayer

const FullscreenStripPlayerScene := preload("res://scripts/ui/fullscreen_strip_player.gd")
@export_group("Audio")
## ลากไฟล์เพลงต่อสู้มาใส่ที่นี่ (ไม่ต้อง preload ในโค้ด)
@export var battle_music: AudioStream
## ระยะเวลา Fade-in ของเพลง (วินาที)
@export var music_fade_duration: float = 1.5
@export var start_scene:PackedScene

@export_group("Start Cinematic")
@export var open_eye_texture: Texture2D = preload("res://assets/portraits/player/open_eye.PNG")
@export var open_eye_frame_count: int = 3
@export var open_eye_fps: float = 4.5
@export var open_eye_hold_time: float = 0.25
@export var open_eye_fade_out: float = 0.15

var _is_starting: bool = false

func _ready():
	# Auto-connect buttons
	$CenterContainer/VBoxContainer/Start_button.pressed.connect(_on_start_game_pressed)
	$CenterContainer/VBoxContainer/Quit_button.pressed.connect(_on_quit_pressed)

	# [Fix] เล่นเพลงพื้นหลังเมื่อเข้าหน้าเมนู
	if battle_music and Autoload.has_node("/root/AudioManager"):
		AudioManager.play_bgm(battle_music, music_fade_duration)

@export_group("Audio")
@export var start_sfx: AudioStream

func _on_start_game_pressed():
	print("Start button pressed!")
	if _is_starting:
		return
		
	if start_scene:
		_is_starting = true
		print("Starting game with scene: ", start_scene.resource_path)

		if start_sfx and has_node("/root/AudioManager"):
			AudioManager.play_sfx(start_sfx)

		await _play_open_eye_intro()

		if has_node("/root/SaveManager"):
			SaveManager.begin_new_game()
			
		if has_node("/root/SceneManager"):
			print("Using SceneManager to transition")
			# เพิ่ม Delay ก่อนเริ่ม Fade เล็กน้อยเพื่อให้ SFX เล่นจบหรือสร้างความรู้สึกที่นุ่มนวลขึ้น
			# เพิ่ม duration เป็น 1.0 เพื่อให้ fade ช้าลง และ fade_in_delay 0.5 เพื่อให้จอมืดนานขึ้นเล็กน้อย
			SceneManager.change_scene(start_scene.resource_path, 1.0, 0.5)
		else:
			print("SceneManager not found, using default change_scene_to_packed")
			get_tree().change_scene_to_packed(start_scene)
	else:
		print("Error: No start_scene assigned in Inspector")

func _on_quit_pressed():
	get_tree().quit()


func _play_open_eye_intro() -> void:
	if not open_eye_texture or open_eye_frame_count <= 0:
		return

	var player := FullscreenStripPlayerScene.new()
	player.autoplay = false
	player.setup(
		open_eye_texture,
		open_eye_frame_count,
		open_eye_fps,
		open_eye_hold_time,
		0.0,
		open_eye_fade_out
	)
	add_child(player)
	player.play()
	await player.finished
