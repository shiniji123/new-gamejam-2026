extends Control

@export_file("*.tscn") var menu_scene_path: String = "res://scenes/menu.tscn"

@onready var menu_button: Button = $CenterContainer/VBoxContainer/MenuButton


func _ready() -> void:
	get_tree().paused = false
	Autoload.current_state = Autoload.State.EXPLORE

	if menu_button and not menu_button.pressed.is_connected(_on_menu_button_pressed):
		menu_button.pressed.connect(_on_menu_button_pressed)
		menu_button.grab_focus()


func _on_menu_button_pressed() -> void:
	get_tree().paused = false
	if get_tree().root.has_node("SceneManager"):
		SceneManager.change_scene(menu_scene_path)
	else:
		get_tree().change_scene_to_file(menu_scene_path)
