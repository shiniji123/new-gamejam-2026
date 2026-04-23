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

func _ready() -> void:
	# ตั้งค่าให้สคริปต์นี้ทำงานได้แม้ว่าจะหยุดเวลาของเกมอยู่ (สำคัญมากสำหรับการทำหน้า Pause)
	process_mode = Node.PROCESS_MODE_ALWAYS
	# ซ่อนตัวเองตั้งแต่เริ่ม
	hide()

# ฟังก์ชันนี้จะถูกเรียกจากฉากหลัก (fight_scene) เพื่อจับคู่ตัวจัดการ Wave
func connect_to_wave_manager(wave_manager_node: Node) -> void:
	_wave_manager = wave_manager_node
	if _wave_manager.has_signal("wave_cleared"):
		_wave_manager.wave_cleared.connect(_on_wave_cleared)

func _on_wave_cleared(_wave_index: int) -> void:
	# พอศัตรูชุดนี้หมด ให้โชว์หน้าจอรางวัล และหยุดเกมทันที
	Engine.time_scale = 0.0
	show_rewards()

func show_rewards() -> void:
	show()
	
	if cards_container:
		# บอกให้ RunManager ช่วยสุ่ม Perks ออกมา 3 ชิ้น (สามารถแก้เลข 3 เป็นอย่างอื่นได้)
		var choices = RunManager.get_reward_choices(choices_count, perk_pool)
		
		var i = 0
		# ไล่ส่งข้อมูลให้ลูกๆ ที่อยู่ข้างใน Container (ซึ่งเป็นตัว RewardChoiceCard)
		for child in cards_container.get_children():
			if i < choices.size():
				if child.has_method("setup_card"):
					child.setup_card(choices[i])
					
					# เคลียร์ Signal ที่อาจเคยต่อขยะไว้ แล้วต่อใหม่
					if child.card_selected.is_connected(_on_card_selected):
						child.card_selected.disconnect(_on_card_selected)
					child.card_selected.connect(_on_card_selected)
				child.show()
				i += 1
			else:
				# ถ้าการ์ดมีเยอะกว่า Perks ที่สุ่มได้ ก็ซ่อนอันที่เหลือไป
				child.hide()

func _on_card_selected(perk: PerkData) -> void:
	# 1. แปะผลความสามารถ Perk ไปที่ตัวผู้เล่น (จัดการโดย RunManager)
	RunManager.apply_perk(perk)
	print("[RewardUI] ผู้เล่นตัดสินใจเลือก: ", perk.title)
	
	# 2. ปิดหน้าต่างนี้
	hide()
	
	# 3. ให้เวลาของเกมเดินต่อเป็นปกติ
	Engine.time_scale = 1.0
	
	# 4. เรียก Wave ต่อไป (สามารถใส่หน่วงเวลานิดนึงเพื่อให้ UI เล่น Effect ก็ได้)
	if _wave_manager and _wave_manager.has_method("start_next_wave"):
		_wave_manager.start_next_wave()
