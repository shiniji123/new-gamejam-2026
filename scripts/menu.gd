extends CanvasLayer
@export_group("Audio")
## ลากไฟล์เพลงต่อสู้มาใส่ที่นี่ (ไม่ต้อง preload ในโค้ด)
@export var battle_music: AudioStream
## ระยะเวลา Fade-in ของเพลง (วินาที)
@export var music_fade_duration: float = 1.5
@export var start_scene:PackedScene
func _ready():
	# Auto-connect buttons
	$CenterContainer/VBoxContainer/Start_button.pressed.connect(_on_start_game_pressed)
	$CenterContainer/VBoxContainer/Quit_button.pressed.connect(_on_quit_pressed)

	# [Fix] เล่นเพลงพื้นหลังเมื่อเข้าหน้าเมนู
	if battle_music and Autoload.has_node("/root/AudioManager"):
		AudioManager.play_bgm(battle_music, music_fade_duration)

@export var start_sfx: AudioStream

func _on_start_game_pressed():
	if start_scene:
		if start_sfx and Autoload.has_node("/root/AudioManager"):
			AudioManager.play_sfx(start_sfx)
			
		if Autoload.has_node("/root/SaveManager"):
			SaveManager.begin_new_game()
			
		if Autoload.has_node("/root/SceneManager"):
			SceneManager.change_scene(start_scene.resource_path)
		else:
			get_tree().change_scene_to_packed(start_scene)
	else:
		print("Not have Scene in Inspector")

func _on_quit_pressed():
	get_tree().quit()
