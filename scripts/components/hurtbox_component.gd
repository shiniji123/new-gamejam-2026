extends Node
class_name HurtboxComponent

# --- สัญญาณแจ้งเตือน (Signals) ---
signal took_damage(current_hp, attacker_pos) # ส่งเมื่อโดนดาเมจ (ส่งเลือดปัจจุบัน และตำแหน่งคนตีมาด้วย)
signal died                                   # ส่งเมื่อตาย (เลือดหมด)

# --- การตั้งค่าที่ปรับแต่งได้ (Inspector) ---
@export_group("Health")
@export var max_hp: float = 100.0             # เลือดสูงสุด

@export_group("Visual Effects")
@export var visual_blinking: bool = true      # เปิด/ปิด ระบบตัวกะพริบตอนโดนตี
@export var blink_interval: float = 0.1       # ความถี่ในการกะพริบ (วินาที)

@export_group("Invincibility (ป้องกันดาเมจ)")
@export var damage_protection: bool = true    # เปิด/ปิด ระบบอมตะชั่วคราวหลังโดนตี
@export var invincibility_duration: float = 0.5 # ระยะเวลาที่เป็นอมตะ (วินาที)
# ------------------------------

# --- ตัวแปรภายใน ---
var current_hp: float                         # เลือดปัจจุบัน
var is_invincible: bool = false               # สถานะอมตะขณะนี้
var forced_invincible: bool = false

@onready var parent_node = get_parent()
@onready var sprite: AnimatedSprite2D = parent_node.get_node("AnimatedSprite2D")

# ตัวจับเวลาต่างๆ
@onready var invincibility_timer: Timer = Timer.new()
@onready var blink_timer: Timer = Timer.new()

func _ready() -> void:
	if parent_node.is_in_group("player"):
		# ดึงค่า MAX HP เริ่มต้นผ่านเครื่องคำนวณ (รวม Perk + Shop)
		max_hp = StatCalculator.get_player_max_hp(StatCalculator.BASE_PLAYER_HP)
		
		# เชื่อมต่อสัญญาณเมื่อมีการเปลี่ยน Perk เพื่อปรับเลือดสูงสุดทันที
		if not StatCalculator.stats_recalculated.is_connected(_on_stats_recalculated):
			StatCalculator.stats_recalculated.connect(_on_stats_recalculated)
		
		if Autoload.player_current_hp != -1.0:
			current_hp = Autoload.player_current_hp
		else:
			current_hp = max_hp  
	else:
		current_hp = max_hp
	
	invincibility_timer.one_shot = true
	invincibility_timer.wait_time = invincibility_duration
	invincibility_timer.timeout.connect(_on_invincibility_timeout)
	add_child(invincibility_timer)
	
	blink_timer.wait_time = blink_interval
	blink_timer.timeout.connect(_on_blink_timeout)
	add_child(blink_timer)

func _on_stats_recalculated() -> void:
	if parent_node.is_in_group("player"):
		var old_max = max_hp
		max_hp = StatCalculator.get_player_max_hp(StatCalculator.BASE_PLAYER_HP)
		
		# ถ้าเลือดสูงสุดเพิ่มขึ้น ให้เติมเลือดปัจจุบันตามไปด้วย (เพื่อความรู้สึกที่ดีของผู้เล่น)
		if max_hp > old_max:
			var diff = max_hp - old_max
			current_hp += diff
			
		# แจ้งเตือน UI ให้รู้ว่าตัวเลขเปลี่ยนแล้ว
		emit_signal("took_damage", current_hp, parent_node.global_position)

func take_damage(amount: float, attacker_pos: Vector2 = Vector2.ZERO) -> void:
	if forced_invincible or (damage_protection and is_invincible) or current_hp <= 0:
		return
		
	current_hp -= amount
	
	if parent_node.is_in_group("player"):
		Autoload.player_current_hp = current_hp
		
	emit_signal("took_damage", current_hp, attacker_pos)
	
	if current_hp <= 0:
		emit_signal("died")
	else:
		start_visual_effects()

func start_visual_effects() -> void:
	if damage_protection:
		is_invincible = true
		invincibility_timer.start()
	
	if visual_blinking:
		await get_tree().create_timer(0.1).timeout
		if is_instance_valid(self) and is_instance_valid(blink_timer):
			blink_timer.start()

func _on_invincibility_timeout() -> void:
	is_invincible = false
	
	if damage_protection:
		blink_timer.stop()
		if is_instance_valid(sprite): 
			sprite.visible = true

func _on_blink_timeout() -> void:
	if is_instance_valid(sprite):
		sprite.visible = !sprite.visible
		
	if not damage_protection and blink_timer.time_left == 0:
		await get_tree().create_timer(0.5).timeout
		if is_instance_valid(self) and is_instance_valid(blink_timer):
			blink_timer.stop()
			if is_instance_valid(sprite): 
				sprite.visible = true

func set_forced_invincible(value: bool) -> void:
	forced_invincible = value
