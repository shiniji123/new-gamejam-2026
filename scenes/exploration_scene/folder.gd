extends Node2D

@export_group("System Link (ระบบหลังบ้าน)")
@export var interaction_area: InteractionArea 
@export var shop_ui: CanvasLayer             

@export_group("Visuals (ภาพเคลือนไหวร้านค้า)")
@export var animated_sprite: AnimatedSprite2D # เอาไว้ใส่โหนดถ้าร้านเป็น Sprite Sheet ขยับได้

func _ready():
	# 1. เชื่อมต่อระบบแวะพูดคุย
	if interaction_area:
		# แอบเปลี่ยนชือข้อความให้หล่อๆ ขึ้น
		interaction_area.action_name = "Shopping" 
		interaction_area.interact = Callable(self, "_on_interact")
		
	# 2. ปลุกชีพ Sprite Sheet ให้ขยับตลอดเวลา!
	# ถ้าคุณลาก AnimatedSprite2D มาใส่ช่องนี้ มันจะเล่นอนิเมชันให้ดุ๊กดิ๊กอัตโนมัติ
	if animated_sprite:
		animated_sprite.play()

func _on_interact():
	if shop_ui:
		shop_ui.open_shop()
	else:
		print("[ระบบ] ลืมใส่ Shop UI ให้ลุงคนขายของตัวนี้ครับ!")
