extends BaseEnemy

# Boss: โหดและเลือดเยอะที่สุด
func _ready():
	super._ready()
	
	damage *= 3.0
	speed *= 0.7 # บอสตัวใหญ่อาจจะเดินอืดลงนิดนึงครับ
	knockback_resistance = 0.8 # ต้านทานแรงดีด 80% (ตัวหนักมาก)
	
	if has_node("HurtboxComponent"):
		var hurtbox = get_node("HurtboxComponent")
		hurtbox.max_hp = 1200.0
		hurtbox.current_hp = 1200.0
