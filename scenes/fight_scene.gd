extends Node2D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# ตั้งค่าขอบเขตกล้องตามขนาดของ TextureRect (ภาพพื้นหลัง)
	if has_node("Player") and has_node("TextureRect"):
		$Player.set_camera_limits($TextureRect.get_rect())
