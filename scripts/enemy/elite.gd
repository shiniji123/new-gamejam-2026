extends BaseEnemy

# สอน: โค้ดนี้ "สืบทอด" (Inherits) มาจาก enemy.gd ครับ 
# อะไรก็ตามที่มีใน enemy.gd ตัวนี้จะมีเหมือนกันหมด แต่จะเก่งกว่าครับ

func _ready():
	# 1. เรียกใช้งานโค้ดพื้นฐานของตัวปกติก่อน (สำคัญมาก)
	super._ready()
	
	# 2. ปรับแต่งค่าพลังที่นี่ (จะเปลี่ยนใน Inspector ก็ได้ หรือใส่ในโค้ดนี้เลยก็ได้ครับ)
	# สมมติว่า Elite จะเก่งกว่าตัวปกติ 2 เท่า
	damage *= 1.5 
	speed *= 1.1
	
	# 3. ปรับเลือด (ถ้ามี Hurtbox)
	if has_node("HurtboxComponent"):
		var hurtbox = get_node("HurtboxComponent")
		hurtbox.max_hp = 200.0 # เลือดเยอะกว่าปกติ
		hurtbox.current_hp = 200.0
