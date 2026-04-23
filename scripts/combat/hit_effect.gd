extends Node2D

@export var duration: float = 0.4          # ระยะเวลา (หน่วยเป็นวินาที แนะนำที่ 0.3 - 0.5 ครับ)
@export var extra_scale: float = 1.0       # ตัวคูณขนาดให้ระเบิดใหญ่และสะใจขึ้น
@export var random_rotation: bool = true   # หมุนเอฟเฟกต์แบบสุ่มซ้ายขวา

func _ready():
	if random_rotation:
		rotation_degrees = randf_range(0.0, 360.0)
	
	# ขยายความอลังการของระเบิด
	scale = Vector2(extra_scale, extra_scale)
	
	# --- กรณีที่คุณเปลี่ยนโหนดเป็น AnimatedSprite2D ---
	if is_class("AnimatedSprite2D"):
		var sprite_frames = get("sprite_frames")
		# ถ้ามันติดลูปอยู่ ฟังก์ชัน animation_finished จะไม่ทำงาน ดังนั้นใช้ Timer ชัวร์กว่า
		call("play")
		
		# คำนวณความยาวของอนิเมชันให้พอดี (จะได้ไม่หายไปก่อนเล่นจบ)
		var anim_duration = duration
		if sprite_frames:
			var current_anim = get("animation")
			if current_anim and sprite_frames.has_animation(current_anim):
				var fps = sprite_frames.get_animation_speed(current_anim)
				if fps > 0:
					anim_duration = sprite_frames.get_frame_count(current_anim) / float(fps)
				
		await get_tree().create_timer(anim_duration).timeout
		queue_free()
		return
		
	# --- กรณีที่คุณใช้โหนดเป็น Sprite2D ---
	elif "hframes" in self and "vframes" in self:
		var h = get("hframes")
		var v = get("vframes")
		var total_frames = h * v
		var tween = create_tween()
		
		if total_frames > 1:
			set("frame", 0)
			tween.tween_property(self, "frame", total_frames - 1, duration)
			tween.tween_callback(self.queue_free)
		else:
			tween.set_parallel(true)
			tween.tween_property(self, "scale", scale * 1.5, duration).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
			tween.tween_property(self, "modulate:a", 0.0, duration).set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_IN)
			tween.set_parallel(false)
			tween.tween_callback(self.queue_free)
		
		# บังคับลบเผื่อ Tween ล้มเหลวหรือเกิดบั๊กค้าง
		await get_tree().create_timer(duration + 0.1).timeout
		if is_inside_tree():
			queue_free()
