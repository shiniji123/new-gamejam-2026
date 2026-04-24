extends "res://scripts/player/player.gd"
## ===================================================
## PlayerTransform — ร่างต่อสู้ (Fight Scene)
## ===================================================

@export_group("Dash Settings")
@export var dash_speed: float = 800.0 # ปรับให้เร็วขึ้นอีกนิด
@export var dash_duration: float = 0.2
@export var dash_cooldown: float = 0.4

var is_dashing: bool = false
var can_dash: bool = true

func _ready() -> void:
	super._ready()
	print("--- [DEBUG] Player Transform พร้อมใช้งานแล้ว! ---")

func _physics_process(_delta: float) -> void:
	if is_dead: return
	
	# ตรวจสอบการกดปุ่ม "dash" (Spacebar)
	if Input.is_action_just_pressed("dash"):
		print("--- [DEBUG] ตรวจพบการกดปุ่ม DASH! (can_dash: ", can_dash, ", is_dashing: ", is_dashing, ") ---")
		if can_dash and not is_dashing:
			_start_dash()
	
	if is_dashing:
		var dash_dir = Input.get_vector("left", "right", "up", "down")
		if dash_dir == Vector2.ZERO:
			# ถ้าไม่ได้กดทิศทาง ให้พุ่งไปทางที่หันหน้าอยู่
			# (อ้างอิงจากโค้ดเดิม: flip_h = true คือหันขวา, false คือหันซ้าย)
			dash_dir = Vector2.RIGHT if animated_sprite.flip_h else Vector2.LEFT
			
		velocity = dash_dir * dash_speed
		move_and_slide()
		return
		
	super._physics_process(_delta)

func _start_dash() -> void:
	print("--- [DEBUG] กำลังเริ่ม DASH! ---")
	is_dashing = true
	can_dash = false
	
	if animated_sprite.sprite_frames.has_animation("dash"):
		animated_sprite.play("dash")
	
	await get_tree().create_timer(dash_duration).timeout
	is_dashing = false
	print("--- [DEBUG] สิ้นสุดการพุ่ง (เริ่ม Cooldown) ---")
	
	await get_tree().create_timer(dash_cooldown).timeout
	can_dash = true
	print("--- [DEBUG] Dash พร้อมใช้อีกครั้ง! ---")

func update_animation(direction: Vector2):
	if is_dashing: return
	super.update_animation(direction)
