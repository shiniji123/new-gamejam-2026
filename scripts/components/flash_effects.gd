extends Node
class_name FlashEffects

# --- การตั้งค่าที่ปรับแต่งได้ (Inspector) ---
@export var flash_duration: float = 0.1       # ระยะเวลาในการขาวแวบ (วินาที)
@export var flash_color: Color = Color.WHITE  # สีที่จะแฟลช (ปกติคือสีขาว)
# ------------------------------

# อ้างอิงไปยัง Sprite ของตัวละคร (ต้องเป็น AnimatedSprite2D)
@onready var parent_sprite: AnimatedSprite2D = get_parent().get_node("AnimatedSprite2D")

func flash(duration: float = 0.0):
	# ถ้าไม่ได้ระบุเวลามาตอนเรียกใช้ ให้ใช้ค่าเริ่มต้นจาก Inspector
	var active_duration = duration if duration > 0 else flash_duration
	
	# ตรวจสอบว่าโหนดมี Sprite และมี Shader ติดตั้งไว้จริงหรือไม่
	if parent_sprite and parent_sprite.material:
		var tween = create_tween()
		
		# ขั้นตอนที่ 1: ตั้งค่าความเข้ม (Intensity) ให้เป็นสูงสุด (1.0) ทันที
		# (ต้องมั่นใจว่าใน Shader มีพารามิเตอร์ชื่อ "flash_intensity")
		parent_sprite.material.set_shader_parameter("flash_intensity", 1.0)
		parent_sprite.material.set_shader_parameter("flash_color", flash_color)
		
		# ขั้นตอนที่ 2: ใช้ Tween เพื่อค่อยๆ ลดค่า "flash_intensity" กลับสู่ 0.0
		# ทำให้เกิดเอฟเฟกต์การ "ขาวแวบแล้วจางหายไป" ครับ
		tween.tween_property(
			parent_sprite.material, 
			"shader_parameter/flash_intensity", 
			0.0, 
			active_duration
		)
