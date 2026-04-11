extends Node2D

# ฟังก์ชันนี้จะทำงานทันทีที่เริ่มเกม (หรือเริ่ม Scene นี้)
func _ready() -> void:
	# เซ็นชื่อว่าเรากำลังเข้าสู่สงครามแล้ว (พร้อมยิง!)
	Autoload.current_state = Autoload.State.COMBAT
	
	# ------------------
	# เล่นโค้ดเพลง
	# ------------------
	# ตรง preload("...") ให้คุณแก้พาธชื่ไฟล์เป็นเพลงแบทเทิลของคุณ 
	# ส่วนเลข 1.5 คือระยะเวลา (Fade-in) ที่จะค่อยๆ เร่งเสียงดังขึ้น 1.5 วินาที
	var my_battle_music = preload("res://assets/sounds/fight_scene_bg.wav")
	AudioManager.play_bgm(my_battle_music, 1.5)
	# 🛠️ ระบบจัดการกล้องอัตโนมัติ:
	# เราจะสั่งให้กล้องที่ติดอยู่กับตัวผู้เล่น ไม่สามารถเลื่อนออกไปนอกพื้นหลังได้ครับ
	
	# 1. ตรวจเช็คว่ามีโหนด Player และ Background อยู่ในฉากจริงหรือไม่
	if has_node("Player") and has_node("Background"):
		var bg = $Background
		if bg:
			# คำนวณพื้นที่ (Rect2) โดยหาว่าผู้สร้างย่อ/ขยายรูปไปกี่เท่า (Scale) และดึงมาคำนวณด้วยเป๊ะๆ
			var background_rect: Rect2
			if "size" in bg: 
				background_rect = bg.get_global_rect()
			elif bg.has_method("get_rect"): 
				var local_rect = bg.get_rect()
				var g_pos = bg.global_position
				var g_scale = bg.global_scale
				background_rect = Rect2(g_pos + (local_rect.position * g_scale), local_rect.size * g_scale)
			else:
				background_rect = Rect2(bg.global_position, bg.texture.get_size() * bg.global_scale)
			
			# 4. ส่งค่าพื้นที่นี้ไปให้ตัว Player เพื่อกำหนดขอบเขตกล้อง (Camera Limits)
			# วิธีนี้จะทำให้เราไม่ต้องมานั่งแก้ตัวเลขขอบเขตกล้องเองเมื่อเราเปลี่ยนรูปพื้นหลังครับ
			if $Player.has_method("set_camera_limits"):
				$Player.set_camera_limits(background_rect)
				
			# 5. เสกกำแพงอิฐล่องหนด้วยคณิตศาสตร์ฟิสิกส์
			_create_map_boundaries(background_rect)


# เสกก้อนอิฐล่องหน 4 ด้านมารายล้อมฉากอัตโนมัติ (Physics Boundaries)
func _create_map_boundaries(rect: Rect2):
	var bounds_body = StaticBody2D.new()
	
	# สร้างกำแพง 4 ทิศ (บน, ล่าง, ซ้าย, ขวา)
	_add_wall(bounds_body, Vector2(0, 1), Vector2(0, rect.position.y))   # บน (ดันลง)
	_add_wall(bounds_body, Vector2(0, -1), Vector2(0, rect.end.y))       # ล่าง (ดันขึ้น)
	_add_wall(bounds_body, Vector2(1, 0), Vector2(rect.position.x, 0))   # ซ้าย (ดันขวา)
	_add_wall(bounds_body, Vector2(-1, 0), Vector2(rect.end.x, 0))       # ขวา (ดันซ้าย)
	
	add_child(bounds_body)

# ฟังก์ชันย่อยสำหรับปั้นกำแพงแต่ละทิศให้เป็นรูปเป็นร่าง
func _add_wall(parent: Node2D, normal: Vector2, pos: Vector2):
	var shape_node = CollisionShape2D.new()
	var boundary = WorldBoundaryShape2D.new()
	
	boundary.normal = normal
	shape_node.shape = boundary
	shape_node.position = pos
	
	parent.add_child(shape_node)
