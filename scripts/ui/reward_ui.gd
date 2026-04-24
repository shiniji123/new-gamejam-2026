extends Control
# นำสคริปต์นี้ไปติดกับ CanvasLayer ใน 2D Editor แล้วตั้งชื่อว่า RewardUI
# จุดประสงค์คือเปิดหน้าต่างนี้ขึ้นมาตอน Wave เคลียร์ เพื่อให้ผู้เล่นเลือก Perk 1 ชิ้น

@export_category("ตั้งค่าการสุ่มรางวัล")
# ลากไฟล์ PerkData (.tres) หลายๆ ไฟล์ในหน้า Inspector มาใส่เป็น Pool การสุ่มได้เลย
@export var perk_pool: Array[PerkData] = []
## จำนวนการ์ดที่แสดงให้เลือกหลังจบ Wave
@export var choices_count: int = 3

@export_category("การเชื่อมต่อ UI")
# ลาก HBoxContainer หรือโหนดแม่ที่เก็บแพทเทิร์นการ์ดต่างๆ เอาไว้มาใส่ตรงนี้
@export var cards_container: Container

# ตัวแปรจำ WaveManager เอาไว้สั่งให้ปล่อยศัตรูตาต่อไป
var _wave_manager: Node = null
var _is_closing: bool = false

func _ready() -> void:
	# ตั้งค่าให้สคริปต์นี้ทำงานได้แม้ว่าจะหยุดเวลาของเกมอยู่ (สำคัญมากสำหรับการทำหน้า Pause)
	process_mode = Node.PROCESS_MODE_ALWAYS
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	# ซ่อนตัวเองตั้งแต่เริ่ม
	hide()

# ฟังก์ชันนี้จะถูกเรียกจากฉากหลัก (fight_scene) เพื่อจับคู่ตัวจัดการ Wave
func connect_to_wave_manager(wave_manager_node: Node) -> void:
	if _wave_manager and _wave_manager.has_signal("wave_cleared") and _wave_manager.wave_cleared.is_connected(_on_wave_cleared):
		_wave_manager.wave_cleared.disconnect(_on_wave_cleared)

	_wave_manager = wave_manager_node
	if _wave_manager and _wave_manager.has_signal("wave_cleared") and not _wave_manager.wave_cleared.is_connected(_on_wave_cleared):
		_wave_manager.wave_cleared.connect(_on_wave_cleared)

func _on_wave_cleared(_wave_index: int) -> void:
	# พอศัตรูชุดนี้หมด ให้โชว์หน้าจอรางวัล และหยุดเกมทันที
	_is_closing = false
	get_tree().paused = true
	show_rewards()

func show_rewards() -> void:
	# โปร่งใสและค่อยๆ เฟดอิน
	modulate.a = 0.0
	mouse_filter = Control.MOUSE_FILTER_STOP
	show()
	
	# แอนิเมชันตอนเปิดหน้าต่าง
	var tween = create_tween()
	tween.bind_node(self)
	tween.set_parallel(true) \
		.set_trans(Tween.TRANS_CUBIC) \
		.set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "modulate:a", 1.0, 0.5)
	
	if cards_container:
		var choices = RunManager.get_reward_choices(choices_count, perk_pool)
		var i = 0
		var delay: float = 0.0 # สำหรับทำ Stagger animation (แจกไพ่ทีละใบ)
		
		for child_node in cards_container.get_children():
			var child := child_node as Control
			if not child:
				continue

			if i < choices.size():
				if child.has_method("setup_card"):
					child.call("setup_card", choices[i])
					
					if child.has_signal("card_selected"):
						if child.is_connected("card_selected", Callable(self, "_on_card_selected")):
							child.disconnect("card_selected", Callable(self, "_on_card_selected"))
						child.connect("card_selected", Callable(self, "_on_card_selected"))
				
				# ซ่อนการ์ดไว้ข้างล่างก่อน แล้วค่อยๆ เด้งขึ้นมา
				child.show()
				child.modulate.a = 0.0
				var base_y: float = child.position.y
				child.position.y = base_y + 100.0
				
				# แอนิเมชันแจกไพ่ (Staggered Entry)
				var card_tween = create_tween()
				card_tween.bind_node(self)
				card_tween.set_parallel(true) \
					.set_trans(Tween.TRANS_BACK) \
					.set_ease(Tween.EASE_OUT)
				card_tween.tween_property(child, "position:y", base_y, 0.6).set_delay(delay)
				card_tween.tween_property(child, "modulate:a", 1.0, 0.4).set_delay(delay)
				
				delay += 0.15 # หน่วงเวลาใบถัดไป
				i += 1
			else:
				child.hide()

func _on_card_selected(perk: PerkData) -> void:
	if _is_closing:
		return
	_is_closing = true

	RunManager.apply_perk(perk)
	print("[RewardUI] ผู้เล่นตัดสินใจเลือก: ", perk.title)
	
	# ปิดปุ่มกดทั้งหมดชั่วคราวกันกดเบิ้ล
	for child_node in cards_container.get_children():
		var child := child_node as Control
		if not child:
			continue
		child.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	# แอนิเมชันตอนปิดหน้าต่าง (เฟดออก)
	var tween = create_tween()
	tween.bind_node(self)
	tween.set_trans(Tween.TRANS_CUBIC) \
		.set_ease(Tween.EASE_IN)
	tween.tween_property(self, "modulate:a", 0.0, 0.3)
	
	await tween.finished
	hide()
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	# เปิดให้กดได้ใหม่เผื่อครั้งหน้า
	for child_node in cards_container.get_children():
		var child := child_node as Control
		if not child:
			continue
		child.mouse_filter = Control.MOUSE_FILTER_STOP
	
	get_tree().paused = false
	_restore_player_state()
	
	if _wave_manager and _wave_manager.has_method("start_next_wave"):
		_wave_manager.start_next_wave()


func _restore_player_state() -> void:
	var player := get_tree().get_first_node_in_group("player")
	if not player:
		return

	player.set_physics_process(true)

	if _has_property(player, "velocity"):
		player.set("velocity", Vector2.ZERO)
	if _has_property(player, "knockback_velocity"):
		player.set("knockback_velocity", Vector2.ZERO)
	if _has_property(player, "is_dashing"):
		player.set("is_dashing", false)
	if _has_property(player, "can_dash"):
		player.set("can_dash", true)


func _has_property(node: Object, property_name: String) -> bool:
	for property_data in node.get_property_list():
		if property_data.get("name", "") == property_name:
			return true
	return false
