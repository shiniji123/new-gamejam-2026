extends CanvasLayer
@export var start_scene:PackedScene
func _ready():
	# Auto-connect buttons
	$CenterContainer/VBoxContainer/Start_button.pressed.connect(_on_start_game_pressed)
	$CenterContainer/VBoxContainer/Quit_button.pressed.connect(_on_quit_pressed)

func _on_start_game_pressed():
	if start_scene:
		if Autoload.has_node("/root/SaveManager"):
			SaveManager.begin_new_game()
		get_tree().change_scene_to_packed(start_scene)
	else:
		print("Not have Scene in Inspector")

func _on_quit_pressed():
	get_tree().quit()
