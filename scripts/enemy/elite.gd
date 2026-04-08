extends BaseEnemy

# Elite: แข็งแกร่งกว่าศัตรูปกติ
func _ready():
	super._ready() # เรียกใช้งานความสามารถพื้นฐาน
	
	# ปรับแต่งค่าพลัง (เดี๋ยวคุณไปปรับต่อใน Editor ได้ครับ)
	damage *= 1.5
	speed *= 1.2
	knockback_resistance = 0.3 # ต้านทานแรงดีด 30%
	
	# เพิ่มเลือดถ้ามี HurtboxComponent
	if has_node("HurtboxComponent"):
		var hurtbox = get_node("HurtboxComponent")
		hurtbox.max_hp = 300.0
		hurtbox.current_hp = 300.0
