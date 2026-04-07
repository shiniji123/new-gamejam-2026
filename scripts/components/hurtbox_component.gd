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
@export var invincibility_duration: float = 1.0 # ระยะเวลาที่เป็นอมตะ (วินาที)
# ------------------------------

# --- ตัวแปรภายใน ---
var current_hp: float                         # เลือดปัจจุบัน
var is_invincible: bool = false               # สถานะอมตะขณะนี้

@onready var parent_node = get_parent()
@onready var sprite: AnimatedSprite2D = parent_node.get_node("AnimatedSprite2D")

# ตัวจับเวลาต่างๆ
@onready var invincibility_timer: Timer = Timer.new()
@onready var blink_timer: Timer = Timer.new()

func _ready():
	current_hp = max_hp
	
	# ตั้งค่าตัวจับเวลาอมตะ
	invincibility_timer.one_shot = true
	invincibility_timer.wait_time = invincibility_duration
	invincibility_timer.timeout.connect(_on_invincibility_timeout)
	add_child(invincibility_timer)
	
	# ตั้งค่าตัวจับเวลากะพริบ
	blink_timer.wait_time = blink_interval
	blink_timer.timeout.connect(_on_blink_timeout)
	add_child(blink_timer)

# --- ฟังก์ชันสาธารณะสำหรับเรียกใช้ดาเมจ ---
func take_damage(amount: float, attacker_pos: Vector2 = Vector2.ZERO):
	# 1. เช็คว่าอยู่ในช่วงอมตะ หรือตายไปแล้วหรือไม่
	if (damage_protection and is_invincible) or current_hp <= 0:
		return
		
	# 2. ลดเลือดและแจ้งเตือนผ่าน Signal
	current_hp -= amount
	emit_signal("took_damage", current_hp, attacker_pos)
	
	# 3. เช็คว่าตายหรือยัง
	if current_hp <= 0:
		emit_signal("died")
	else:
		# ถ้ายังไม่ตาย ให้แสดงเอฟเฟกต์ (และอมตะถ้าเปิดไว้)
		start_visual_effects()

func start_visual_effects():
	# เริ่มเปิดระบบอมตะ (ถ้าเลือกใช้)
	if damage_protection:
		is_invincible = true
		invincibility_timer.start()
	
	# เริ่มเปิดระบบกะพริบตัว (ถ้าเลือกใช้)
	if visual_blinking:
		# สอน: เราจะรอ 0.1 วินาทีเพื่อให้เอฟเฟกต์ "แฟลชขาว" ทำงานไปก่อนครับ
		await get_tree().create_timer(0.1).timeout
		blink_timer.start()

# --- ฟังก์ชันจัดการตัวจับเวลา (Timer Handlers) ---

func _on_invincibility_timeout():
	is_invincible = false
	
	# หยุดกะพริบทันทีเมื่อหมดช่วงอมตะ (สำหรับ Player)
	if damage_protection:
		blink_timer.stop()
		if sprite: sprite.visible = true

func _on_blink_timeout():
	# ลอจิกการกะพริบ: สลับสถานะ Visible (จริง <-> เท็จ)
	if sprite:
		sprite.visible = !sprite.visible
		
	# กรณีพิเศษ: ถ้าเป็นศัตรูที่ไม่มีระบบอมตะ (damage_protection = false) 
	# เราจะสั่งให้มันหยุดกะพริบเองหลังจากผ่านไปซักครู่
	if not damage_protection and blink_timer.time_left == 0:
		await get_tree().create_timer(0.5).timeout
		blink_timer.stop()
		if sprite: sprite.visible = true
