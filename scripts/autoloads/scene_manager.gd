extends Node

var canvas_layer: CanvasLayer
var color_rect: ColorRect
var tween: Tween
var is_transitioning: bool = false

# ตัวแปรล่อเป้า ให้ Tween มองเห็นได้ง่ายๆ (แก้บั๊ก Godot หาตัวแปร Shader แบบ Real-time ไม่เจอ)
var shader_progress: float = 0.0:
	set(val):
		shader_progress = val
		if color_rect and color_rect.material:
			color_rect.material.set_shader_parameter("progress", val)


# ========================================================
# MATHEMATICAL SHADER: โค้ดคณิตศาสตร์บังคับการ์ดจอบีบวงกลม
# ========================================================
const SHADER_CODE = """
shader_type canvas_item;

// ควบคุมค่าจาก 0.0 (ชัดเจน) ไป 1.0 (จอมืดมิด)
uniform float progress : hint_range(0.0, 1.0) = 0.0;
uniform vec4 transition_color : source_color = vec4(0.0, 0.0, 0.0, 1.0);

void fragment() {
	// คำนวณระยะห่างของแต่ละพิกเซลบนหน้าจอจากจุดกึ่งกลาง (0.5, 0.5)
	float d = distance(UV, vec2(0.5, 0.5));
	
	// ถอยหลังสูตร: ถ้า progress มากขึ้น รัศมี (Radius) จะยิ่งเล็กลง
	// รัศมีเริ่มต้นต้องเกิน 1.0 (เผื่อขอบจอ 16:9) เลยใช้ 1.5 ป้องกันมุมขอบดำครับ
	float radius = (1.0 - progress) * 1.5;
	
	if (d > radius) {
		// นอกรัศมี: ให้เทสีดำทับ
		COLOR = transition_color;
	} else {
		// ในรัศมี: ให้โปร่งใส 100% (มองทะลุเห็นเกม)
		COLOR = vec4(0.0, 0.0, 0.0, 0.0);
	}
}
"""

func _ready() -> void:
	# 1. แอบสร้าง CanvasLayer เพื่อให้หน้าจอดำเกิด "ทับทุกอย่างบนโลก" (รวมถึง UI อื่นๆ)
	canvas_layer = CanvasLayer.new()
	canvas_layer.layer = 100 # เลขเยอะ = อยู่บนสุด
	add_child(canvas_layer)
	
	# 2. สร้างผ้าใบสีดำคลุมทั้งจอ
	color_rect = ColorRect.new()
	color_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT) # ดึงให้ตึงขอบจอแบบชัวร์ๆ
	color_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE    # ปกติไม่ขวางการกดเมาส์
	canvas_layer.add_child(color_rect)
	# บังคับขนาดอีกรอบกันเหนียว
	color_rect.size = get_viewport().get_visible_rect().size
	
	# 3. ร่ายเวทมนตร์ Shader ใส่ผ้าใบ
	var mat = ShaderMaterial.new()
	var shader = Shader.new()
	shader.code = SHADER_CODE
	mat.shader = shader
	color_rect.material = mat


# คำสั่งหลักที่คุณสามารถเรียกตอนไหนก็ได้: SceneManager.change_scene("พาธของด่าน")
func change_scene(scene_path: String, duration: float = 0.6) -> void:
	# พิมพ์กันคนกดปุ่มรัวๆ บั๊ก
	if is_transitioning:
		return
	is_transitioning = true
	
	# ปิดไม่ให้ผู้เล่นกดปุ่มอะไรได้เลยตอนกำลังมืด!
	color_rect.mouse_filter = Control.MOUSE_FILTER_STOP 
	
	# ปิดเพลงเดิมอัตโนมัติก่อนเปลี่ยนฉากนุ่มๆ (ถ้ามี AudioManager ของผมคุมอยู่)
	if get_tree().root.has_node("AudioManager"):
		var am = get_tree().root.get_node("AudioManager")
		if am.has_method("stop_bgm"):
			am.stop_bgm(duration)
	
	# จังหวะ 1: ยืดวงกลมบีบเข้าหากันจนมืด (Fade Out)
	if tween and tween.is_valid():
		tween.kill()
	tween = create_tween()
	# เปลี่ยนมาใช้ตัวแปรแบบ Proxy เพื่อความนิ่งของโค้ดแทนการอ้างอิง Property ตรงๆ ใน Godot 4
	tween.tween_property(self, "shader_progress", 1.0, duration)\
		.set_trans(Tween.TRANS_SINE)
		
	# รอจนกว่าจอมืดสนิท
	await tween.finished
	
	# จังหวะ 2: ฉากวับ! เปลี่ยนฉากเบื้องหลังตอนคนมองไม่เห็น
	get_tree().change_scene_to_file(scene_path)
	
	# ถ่วงเวลาให้ฉากใหม่โหลด 0.1 วินาทีกันกระตุก
	await get_tree().create_timer(0.1).timeout
	
	# จังหวะ 3: ขยายวงกลมเปิดออกให้เห็นฉากใหม่ (Fade In)
	tween = create_tween()
	tween.tween_property(self, "shader_progress", 0.0, duration)\
		.set_trans(Tween.TRANS_SINE)
		
	await tween.finished
	
	# จบกระบวนการ ปลดล็อกปุ่ม
	is_transitioning = false
	color_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
