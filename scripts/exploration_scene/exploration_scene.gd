extends Node2D

func _ready() -> void:
	# เซ็นชื่อว่าเรากำลังอยู่ในโหมดเดินเล่นนะ (ห้ามยิงกัน)
	Autoload.current_state = Autoload.State.EXPLORE
	
	# ------------------
	# เริ่มเปิดระบบเพลงสำหรับฉากสำรวจ
	# ------------------
	
	# กำหนดตำแหน่งไฟล์เพลง (อย่าลืมแก้ พาธตรงนี้ ให้ตรงกับไฟล์เพลงของคุณนะครับ!)
	# วิธีก็อป: ไปคลิกขวาที่ไฟล์เพลงในหน้าต่าง FileSystem ของ Godot แล้วกด Copy Path 
	# จากนั้นเอามา Paste ทับในเครื่องหมายคำพูดข้างล่างนี้ครับ
	var explore_music = preload("res://assets/sounds/exploration_bg.wav") 
	
	# สั่งให้ AudioManager เปิดเพลงนี้ และเฟดเสียงให้ค่อยๆ ดังขึ้นใน 2 วินาที
	AudioManager.play_bgm(explore_music, 2.0)
	
	# ------------------
	# ระบบล็อกกล้องและสร้างกำแพงป้องกันเดินทะลุขอบแผนที่
	# ------------------
	if has_node("Background"):
		var bg = $Background
		if bg:
			# คำนวณขอบเขตแผนที่จากขนาดและสเกลจริงที่แสดงอยู่บนจอ!
			var map_rect: Rect2
			if "size" in bg: # สำหรับโหนดกลุ่ม Control (เช่น TextureRect หรือ ColorRect)
				map_rect = bg.get_global_rect()
			elif bg.has_method("get_rect"):  # สำหรับโหนดกลุ่ม Sprite2D
				var local_rect = bg.get_rect()
				var g_pos = bg.global_position
				var g_scale = bg.global_scale
				map_rect = Rect2(g_pos + (local_rect.position * g_scale), local_rect.size * g_scale)
			else:
				# เผื่อฉุกเฉิน
				map_rect = Rect2(bg.global_position, bg.texture.get_size() * bg.global_scale)
			
			# 1. สั่งให้กล้องไม่วิ่งออกนอกแผนที่
			if has_node("Player") and $Player.has_method("set_camera_limits"):
				$Player.set_camera_limits(map_rect)
			
			# 2. สร้างกำแพงฟิสิกส์อัตโนมัติ เพื่อป้องกันผู้เล่นเดินละลุออกนอกขอบ
			_create_map_boundaries(map_rect)


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
