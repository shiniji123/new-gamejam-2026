class_name MapBoundaryHelper
## ===================================================
## MapBoundaryHelper — Static Helper สำหรับกำแพงล่องหน
## ===================================================
## ใช้สำหรับสร้างกำแพงฟิสิกส์รอบขอบแผนที่อัตโนมัติ
## เรียกใช้ได้จากทั้ง fight_scene.gd และ exploration_scene.gd
## โดยไม่ต้อง duplicate โค้ดซ้ำกัน

## คำนวณ Rect2 ที่ครอบคลุมพื้นที่ Background โหนด
## รองรับทั้ง Control (TextureRect), Sprite2D, และ TextureBackground
static func get_background_rect(bg: Node) -> Rect2:
	if not bg:
		return Rect2()

	# กรณี Control node (TextureRect, ColorRect, etc.)
	if bg is Control:
		return (bg as Control).get_global_rect()

	# กรณี Sprite2D หรือโหนดที่มีฟังก์ชัน get_rect()
	if bg.has_method("get_rect"):
		var local_rect: Rect2 = bg.call("get_rect")
		var g_scale: Vector2 = bg.global_scale
		return Rect2(
			bg.global_position + (local_rect.position * g_scale),
			local_rect.size * g_scale
		)

	# กรณีมี texture property (เช่น TextureBackground plugin)
	if "texture" in bg and bg.get("texture") != null:
		return Rect2(
			bg.global_position,
			bg.get("texture").get_size() * bg.global_scale
		)

	push_warning("[MapBoundaryHelper] ไม่สามารถคำนวณขนาด Background ได้!")
	return Rect2()


## สร้างกำแพง StaticBody2D ล่องหน 4 ด้านรอบพื้นที่ rect
## parent_scene คือโหนดที่จะเพิ่มกำแพงเข้าไปเป็นลูก
static func create_map_boundaries(parent_scene: Node, rect: Rect2) -> void:
	if rect.size == Vector2.ZERO:
		push_warning("[MapBoundaryHelper] Rect มีขนาดเป็น 0 — ไม่สร้างกำแพง")
		return

	var bounds_body := StaticBody2D.new()
	bounds_body.name = "MapBoundaries"

	_add_wall(bounds_body, Vector2(0,  1),  Vector2(0, rect.position.y))   # บน (ดันลง)
	_add_wall(bounds_body, Vector2(0, -1),  Vector2(0, rect.end.y))        # ล่าง (ดันขึ้น)
	_add_wall(bounds_body, Vector2(1,  0),  Vector2(rect.position.x, 0))   # ซ้าย (ดันขวา)
	_add_wall(bounds_body, Vector2(-1, 0),  Vector2(rect.end.x, 0))        # ขวา (ดันซ้าย)

	parent_scene.add_child(bounds_body)


## สร้างกำแพง 1 ด้านโดยใช้ WorldBoundaryShape2D (ระนาบอนันต์)
static func _add_wall(parent: Node2D, normal: Vector2, pos: Vector2) -> void:
	var shape_node := CollisionShape2D.new()
	var boundary := WorldBoundaryShape2D.new()
	boundary.normal = normal
	shape_node.shape = boundary
	shape_node.position = pos
	parent.add_child(shape_node)
