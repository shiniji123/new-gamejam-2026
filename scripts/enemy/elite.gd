extends BaseEnemy
## ===================================================
## elite.gd — ศัตรู Elite (ดัดแปลงมาจาก BaseEnemy)
## ===================================================
## ปรับค่าต่างๆ ได้โดยตรงใน Inspector โดยไม่ต้องแก้โค้ด

@export_group("Elite Configuration")
## HP เริ่มต้นของ Elite (สูงกว่า Normal มาก)
@export var base_hp: float = 300.0
## ตัวคูณดาเมจ (1.5 = +50% จากค่าพื้นฐาน)
@export var damage_multiplier: float = 1.5
## ตัวคูณความเร็ว (1.2 = +20%)
@export var speed_multiplier: float = 1.2
## เงินรางวัลเมื่อตาย
@export var elite_reward_money: int = 30
## ความต้านทานแรงดีด (0.0 = ปกติ, 1.0 = ไม่ขยับ)
@export var elite_knockback_resistance: float = 0.3


func _ready() -> void:
	super._ready()

	# ปรับสถิติตาม multiplier
	damage *= damage_multiplier
	speed *= speed_multiplier
	knockback_resistance = elite_knockback_resistance
	reward_money = elite_reward_money

	# ตั้งค่า HP จาก export var (ปรับได้ใน Inspector)
	if has_node("HurtboxComponent"):
		var hurtbox := get_node("HurtboxComponent") as HurtboxComponent
		hurtbox.max_hp = base_hp
		hurtbox.current_hp = base_hp
