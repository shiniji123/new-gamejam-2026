extends Node2D

# ฟังก์ชันนี้จะทำงานทันทีที่เริ่มเกม (หรือเริ่ม Scene นี้)
func _ready() -> void:
	# 🛠️ ระบบจัดการกล้องอัตโนมัติ:
	# เราจะสั่งให้กล้องที่ติดอยู่กับตัวผู้เล่น ไม่สามารถเลื่อนออกไปนอกพื้นหลังได้ครับ
	
	# 1. ตรวจเช็คว่ามีโหนด Player และ Background อยู่ในฉากจริงหรือไม่
	if has_node("Player") and has_node("Background"):
		# 2. ดึงรูปภาพพื้นหลังมาดูขนาด
		var texture = $Background.texture
		if texture:
			# 3. คำนวณพื้นที่ (Rect2) ของพื้นหลัง
			var background_rect = Rect2(Vector2.ZERO, texture.get_size())
			
			# 4. ส่งค่าพื้นที่นี้ไปให้ตัว Player เพื่อกำหนดขอบเขตกล้อง (Camera Limits)
			# วิธีนี้จะทำให้เราไม่ต้องมานั่งแก้ตัวเลขขอบเขตกล้องเองเมื่อเราเปลี่ยนรูปพื้นหลังครับ
			$Player.set_camera_limits(background_rect)
