extends CanvasLayer
@export var start_scene:PackedScene

var _is_starting: bool = false

func _ready():
	# Auto-connect buttons
	$CenterContainer/VBoxContainer/Start_button.pressed.connect(_on_start_game_pressed)
	$CenterContainer/VBoxContainer/Quit_button.pressed.connect(_on_quit_pressed)

@export var start_sfx: AudioStream

func _on_start_game_pressed():
	if _is_starting:
		return
		
	if start_scene:
		_is_starting = true

		if start_sfx and Autoload.has_node("/root/AudioManager"):
			AudioManager.play_sfx(start_sfx)
			
		if Autoload.has_node("/root/SaveManager"):
			SaveManager.begin_new_game()
			
		if Autoload.has_node("/root/SceneManager"):
			# เพิ่ม Delay ก่อนเริ่ม Fade เล็กน้อยเพื่อให้ SFX เล่นจบหรือสร้างความรู้สึกที่นุ่มนวลขึ้น
			await get_tree().create_timer(0.5).timeout
			# เพิ่ม duration เป็น 1.0 เพื่อให้ fade ช้าลง และ fade_in_delay 0.5 เพื่อให้จอมืดนานขึ้นเล็กน้อย
			SceneManager.change_scene(start_scene.resource_path, 1.0, 0.5)
		else:
			await get_tree().create_timer(0.5).timeout
			get_tree().change_scene_to_packed(start_scene)
	else:
		print("Not have Scene in Inspector")

func _on_quit_pressed():
	get_tree().quit()
