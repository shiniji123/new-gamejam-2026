extends BaseEnemy

# สอน: โค้ดนี้ "สืบทอด" มาจาก BaseEnemy เช่นกัน แต่จะโหดกว่าตัว Elite ครับ

func _ready():
	# 1. เรียกใช้งานโค้ดพื้นฐาน
	super._ready()
	
	# 2. ปรับตัวแปรพื้นฐาน
	damage *= 3.0    # ดาเมจแรงมาก
	speed *= 0.8     # บอสตัวใหญ่อาจจะเดินช้าลงนิดนึง
	
	# 3. ปรับเลือดมหาศาล
	if has_node("HurtboxComponent"):
		var hurtbox = get_node("HurtboxComponent")
		hurtbox.max_hp = 1000.0
		hurtbox.current_hp = 1000.0
