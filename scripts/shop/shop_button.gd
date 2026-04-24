class_name ShopButton
extends Button
## ===================================================
## ShopButton — แปะสคริปต์นี้ที่ปุ่มในฉาก Shop โดยตรง
## ===================================================

signal item_selected(button: ShopButton)

enum EffectType {
	DAMAGE_MULTIPLIER,  ## เพิ่มดาเมจเป็น %
	PROJECTILE_COUNT,   ## เพิ่มจำนวนกระสุน
	FLAT_MAX_HP,        ## เพิ่ม HP สูงสุดแบบคงที่
	GOLD_MULTIPLIER,    ## เพิ่มเงินรางวัลจากศัตรู
	PIERCE_BONUS,       ## เพิ่มการทะลุของกระสุน
}

@export_group("ตั้งค่าสินค้า (แก้ไขใน Inspector ได้เลย)")
@export var item_label: String = "ชื่อสินค้า"
@export var item_description: String = "คำอธิบายความสามารถของไอเทมชิ้นนี้"
@export var item_icon: Texture2D
@export var cost: int = 50
@export var effect_type: EffectType = EffectType.DAMAGE_MULTIPLIER
@export var effect_value: float = 0.25
@export var max_purchases: int = 3

var purchase_count: int = 0
var tween_hover: Tween

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_refresh_state()

	if not pressed.is_connected(_on_pressed):
		pressed.connect(_on_pressed)

	if not RunManager.coin_changed.is_connected(_on_coin_changed):
		RunManager.coin_changed.connect(_on_coin_changed)
		
	# เพิ่ม Animation ตอนชี้เมาส์
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND

func _refresh_state() -> void:
	var is_maxed := max_purchases > 0 and purchase_count >= max_purchases
	var can_afford := RunManager.run_coin >= cost

	# ปุ่มทางซ้ายจะสามารถกดเพื่อ "ดูรายละเอียด" ได้เสมอ แม้เงินจะไม่พอก็ตาม
	# เราจะไปดักการกดซื้อ (Buy) ที่ฝั่งขวาแทน
	if is_maxed:
		text = "%s (MAX)" % item_label
	else:
		text = "%s" % item_label


func get_save_key() -> String:
	return name


func set_purchase_count(value: int) -> void:
	purchase_count = max(0, value)
	_refresh_state()

func _on_coin_changed(_new_amount: int) -> void:
	_refresh_state()

func _on_pressed() -> void:
	# กดปุ่มฝั่งซ้าย = เลือกไอเทม (แสดงข้อมูลฝั่งขวา)
	item_selected.emit(self)
	
	# แอนิเมชันตอนกด
	var click_tween = create_tween()
	click_tween.bind_node(self)
	click_tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	scale = Vector2(0.95, 0.95)
	click_tween.tween_property(self, "scale", Vector2.ONE, 0.15)

func _on_mouse_entered() -> void:
	if tween_hover: tween_hover.kill()
	tween_hover = create_tween()
	tween_hover.bind_node(self)
	tween_hover.set_trans(Tween.TRANS_SPRING).set_ease(Tween.EASE_OUT)
	tween_hover.tween_property(self, "position:x", 15.0, 0.3)
	tween_hover.tween_property(self, "modulate", Color(1.2, 1.2, 1.5), 0.2)

func _on_mouse_exited() -> void:
	if tween_hover: tween_hover.kill()
	tween_hover = create_tween()
	tween_hover.bind_node(self)
	tween_hover.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween_hover.tween_property(self, "position:x", 0.0, 0.2)
	tween_hover.tween_property(self, "modulate", Color.WHITE, 0.2)

# ฟังก์ชันนี้จะถูกเรียกจาก shop_ui.gd เมื่อกดยืนยันการซื้อจากฝั่งขวา
func execute_purchase() -> bool:
	var is_maxed := max_purchases > 0 and purchase_count >= max_purchases
	if is_maxed:
		return false
		
	if not RunManager.spend_coin(cost):
		_animate_error()
		return false

	purchase_count += 1
	var stat_key := _get_stat_key()
	RunManager.apply_shop_modifier(stat_key, effect_value)

	if effect_type == EffectType.FLAT_MAX_HP:
		_apply_immediate_hp(effect_value)

	print("[Shop] ซื้อ '%s' สำเร็จ! เงินเหลือ: %dG | %s += %.2f" % [item_label, RunManager.run_coin, stat_key, effect_value])
	_animate_success()
	_refresh_state()
	return true

func _get_stat_key() -> String:
	match effect_type:
		EffectType.DAMAGE_MULTIPLIER:  return "damage_multiplier"
		EffectType.PROJECTILE_COUNT:   return "projectile_count"
		EffectType.FLAT_MAX_HP:        return "flat_max_hp"
		EffectType.GOLD_MULTIPLIER:    return "gold_multiplier"
		EffectType.PIERCE_BONUS:       return "pierce_bonus"
	return ""

func _apply_immediate_hp(amount: float) -> void:
	var player := get_tree().get_first_node_in_group("player")
	if not player or not player.has_node("HurtboxComponent"): return
	var hb: HurtboxComponent = player.get_node("HurtboxComponent")
	hb.current_hp = min(hb.current_hp + amount, hb.max_hp)
	Autoload.player_current_hp = hb.current_hp
	hb.took_damage.emit(hb.current_hp, player.global_position)

func _animate_success() -> void:
	var tween := create_tween()
	tween.bind_node(self)
	modulate = Color(0.4, 1.0, 0.4) 
	tween.tween_property(self, "modulate", Color.WHITE, 0.4)

func _animate_error() -> void:
	var orig_pos := position
	var tween := create_tween()
	tween.bind_node(self)
	tween.tween_property(self, "position:x", orig_pos.x + 10, 0.05)
	tween.tween_property(self, "position:x", orig_pos.x - 10, 0.05)
	tween.tween_property(self, "position:x", orig_pos.x + 10, 0.05)
	tween.tween_property(self, "position",   orig_pos,        0.05)
	modulate = Color.RED
	tween.parallel().tween_property(self, "modulate", Color.WHITE, 0.3)
