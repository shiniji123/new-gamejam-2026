extends BaseEnemy
## ===================================================
## boss.gd — ศัตรูบอส (ดัดแปลงมาจาก BaseEnemy)
## ===================================================
## ปรับค่าต่างๆ ได้โดยตรงใน Inspector โดยไม่ต้องแก้โค้ด

@export_group("Boss Configuration")
## HP เริ่มต้นของบอส
@export var base_hp: float = 1200.0
## ตัวคูณดาเมจ (3.0 = สามเท่า)
@export var damage_multiplier: float = 3.0
## ตัวคูณความเร็ว (บอสมักเดินช้า)
@export var speed_multiplier: float = 0.7
## เงินรางวัลเมื่อตาย (สูงมาก เพราะยากมาก)
@export var boss_reward_money: int = 200
## ความต้านทานแรงดีด (0.8 = ตัวหนักแทบไม่ขยับ)
@export var boss_knockback_resistance: float = 0.8


func _ready() -> void:
	super._ready()

	# ปรับสถิติตาม multiplier
	damage *= damage_multiplier
	speed *= speed_multiplier
	knockback_resistance = boss_knockback_resistance
	reward_money = boss_reward_money

	# ตั้งค่า HP จาก export var (ปรับได้ใน Inspector)
	if has_node("HurtboxComponent"):
		var hurtbox := get_node("HurtboxComponent") as HurtboxComponent
		hurtbox.max_hp = base_hp
		hurtbox.current_hp = base_hp
