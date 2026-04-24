extends Node2D

@export_group("System Link (ระบบหลังบ้าน)")
@export var interaction_area: InteractionArea 
@export var shop_ui: CanvasLayer             

@export_group("Visuals (ภาพเคลือนไหวร้านค้า)")
@export var animated_sprite: AnimatedSprite2D # เอาไว้ใส่โหนดถ้าร้านเป็น Sprite Sheet ขยับได้

var _zoom_tween: Tween
var _base_scale: Vector2 = Vector2.ZERO

func _ready():
	# 1. เชื่อมต่อระบบแวะพูดคุย
	if interaction_area:
		# แอบเปลี่ยนชือข้อความให้หล่อๆ ขึ้น
		interaction_area.action_name = "Shop" 
		interaction_area.interact = Callable(self, "_on_interact")
		
	# 2. ปลุกชีพ Sprite Sheet ให้ขยับตลอดเวลา!
	# ถ้าคุณลาก AnimatedSprite2D มาใส่ช่องนี้ มันจะเล่นอนิเมชันให้ดุ๊กดิ๊กอัตโนมัติ
	if animated_sprite:
		animated_sprite.play()
		_start_zoom_animation()
		
	# เชื่อมสัญญาณเมื่อปิดร้านค้าให้กลับมาซูมใหม่
	if shop_ui:
		if not shop_ui.shop_closed.is_connected(_start_zoom_animation):
			shop_ui.shop_closed.connect(_start_zoom_animation)

func _on_interact():
	if shop_ui:
		_stop_zoom_animation()
		shop_ui.open_shop()
	else:
		print("[ระบบ] ลืมใส่ Shop UI ให้ลุงคนขายของตัวนี้ครับ!")

# --- Helper functions สำหรับแอนิเมชันซูม ---
func _start_zoom_animation() -> void:
	if not animated_sprite: return
	
	if _base_scale == Vector2.ZERO:
		_base_scale = animated_sprite.scale
		
	if _zoom_tween and _zoom_tween.is_valid():
		_zoom_tween.kill()
		
	_zoom_tween = create_tween().set_loops()
	_zoom_tween.tween_property(animated_sprite, "scale", _base_scale * 1.05, 1.8).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_zoom_tween.tween_property(animated_sprite, "scale", _base_scale, 1.8).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func _stop_zoom_animation() -> void:
	if _zoom_tween and _zoom_tween.is_valid():
		_zoom_tween.kill()
	
	if animated_sprite and _base_scale != Vector2.ZERO:
		animated_sprite.scale = _base_scale
