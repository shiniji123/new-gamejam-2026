class_name ShopButton
extends Button
## ===================================================
## ShopButton — แปะสคริปต์นี้ที่ปุ่มในฉาก Shop โดยตรง
## ===================================================
## วิธีใช้:
##   1. วางปุ่ม Button ในฉากตามที่ต้องการ (ออกแบบใน Scene Editor ได้เลย)
##   2. ลาก shop_button.gd มาแปะที่โหนดปุ่มนั้น
##   3. กรอก item_label, cost, effect_type, effect_value ใน Inspector
##   แค่นั้นเลย! ปุ่มจะจัดการซื้อ/หักเงิน/เพิ่ม Stat ให้เองทั้งหมด

## ประเภทของ Effect ที่ปุ่มนี้จะเพิ่มเมื่อซื้อ
## (จะมี Dropdown ให้เลือกใน Inspector)
enum EffectType {
	DAMAGE_MULTIPLIER,  ## เพิ่มดาเมจเป็น %
	PROJECTILE_COUNT,   ## เพิ่มจำนวนกระสุน
	FLAT_MAX_HP,        ## เพิ่ม HP สูงสุดแบบคงที่
	GOLD_MULTIPLIER,    ## เพิ่มเงินรางวัลจากศัตรู
	PIERCE_BONUS,       ## เพิ่มการทะลุของกระสุน
}

@export_group("ตั้งค่าสินค้า (แก้ไขใน Inspector ได้เลย)")
## ชื่อสินค้าที่จะแสดงบนปุ่ม (ราคาจะเพิ่มให้อัตโนมัติ)
@export var item_label: String = "ชื่อสินค้า"
## ราคา (หน่วยเป็น Gold)
@export var cost: int = 50
## ประเภท Effect ที่จะเพิ่มเมื่อซื้อ
@export var effect_type: EffectType = EffectType.DAMAGE_MULTIPLIER
## ค่าที่เพิ่ม เช่น 0.25 = +25% ดาเมจ, 1.0 = +1 กระสุน, 50.0 = +50 HP
@export var effect_value: float = 0.25
## จำนวนครั้งสูงสุดที่ซื้อได้ (0 = ไม่จำกัด)
@export var max_purchases: int = 3

# ติดตามจำนวนครั้งที่ซื้อในรอบนี้
var _purchase_count: int = 0


func _ready() -> void:
	# ทำงานตลอดแม้หยุดเกม (สำคัญมาก!)
	process_mode = Node.PROCESS_MODE_ALWAYS

	# แสดงราคาบนปุ่มทันที
	_refresh_state()

	# เชื่อม Signal กดปุ่มกับฟังก์ชันซื้อของหน้านี้เอง
	if not pressed.is_connected(_on_pressed):
		pressed.connect(_on_pressed)

	# อัปเดตสถานะ disabled เมื่อเงินเปลี่ยน
	if not RunManager.coin_changed.is_connected(_on_coin_changed):
		RunManager.coin_changed.connect(_on_coin_changed)


func _refresh_state() -> void:
	## อัปเดตข้อความและ disabled ของปุ่มนี้
	var is_maxed := max_purchases > 0 and _purchase_count >= max_purchases
	var can_afford := RunManager.run_coin >= cost

	disabled = is_maxed or not can_afford

	if is_maxed:
		text = "%s (MAX)" % item_label
	else:
		text = "%s (%dG)" % [item_label, cost]


func _on_coin_changed(_new_amount: int) -> void:
	## เมื่อเงินเปลี่ยน อัปเดตปุ่มนี้ด้วย (กลาย disabled ถ้าเงินไม่พอ)
	_refresh_state()


func _on_pressed() -> void:
	## ลองหักเงิน — ถ้าไม่พอจะส่าย
	if not RunManager.spend_coin(cost):
		_animate_error()
		return

	_purchase_count += 1

	# ใช้ Effect ตามที่เลือกไว้
	var stat_key := _get_stat_key()
	RunManager.apply_shop_modifier(stat_key, effect_value)

	# กรณีพิเศษ: HP Buff ต้องเพิ่มเลือดปัจจุบันทันทีด้วย
	if effect_type == EffectType.FLAT_MAX_HP:
		_apply_immediate_hp(effect_value)

	print("[Shop] ซื้อ '%s' สำเร็จ! เงินเหลือ: %dG | %s += %.2f" % [item_label, RunManager.run_coin, stat_key, effect_value])
	_animate_success()
	_refresh_state()


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
	if not player or not player.has_node("HurtboxComponent"):
		return
	var hb: HurtboxComponent = player.get_node("HurtboxComponent")
	hb.current_hp = min(hb.current_hp + amount, hb.max_hp)
	Autoload.player_current_hp = hb.current_hp
	# ให้ HurtboxComponent emit signal เพื่อ UI หลอดเลือดอัปเดตทันที
	hb.took_damage.emit(hb.current_hp, player.global_position)


func _animate_success() -> void:
	## เพิ่มเอฟเฟกต์ Flash สีเขียวเมื่อซื้อสำเร็จ
	var tween := create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	modulate = Color(0.4, 1.0, 0.4)  # เขียวสด
	tween.tween_property(self, "modulate", Color.WHITE, 0.4)


func _animate_error() -> void:
	var orig_pos := position
	var tween := create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(self, "position:x", orig_pos.x + 10, 0.05)
	tween.tween_property(self, "position:x", orig_pos.x - 10, 0.05)
	tween.tween_property(self, "position:x", orig_pos.x + 10, 0.05)
	tween.tween_property(self, "position",   orig_pos,        0.05)
	modulate = Color.RED
	tween.parallel().tween_property(self, "modulate", Color.WHITE, 0.3)
