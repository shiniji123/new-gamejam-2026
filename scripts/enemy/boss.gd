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
@export var boss_knockback_resistance: float = 1.0
@export var spawn_shake_intensity: float = 20.0
@export var spawn_shake_duration: float = 1.0


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

	await get_tree().create_timer(spawn_delay).timeout
	_shake_camera(spawn_shake_intensity, spawn_shake_duration)


func _shake_camera(intensity: float, duration: float) -> void:
	if not is_instance_valid(player):
		var players := get_tree().get_nodes_in_group("player")
		if players.size() > 0:
			player = players[0]

	if is_instance_valid(player) and player.has_method("shake_camera"):
		player.shake_camera(intensity, duration)
