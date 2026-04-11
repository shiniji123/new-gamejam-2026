extends Node
# Autoload ที่รับผิดชอบวงจรชีวิตของการเล่น 1 รอบ (1 Run)
# ใช้เก็บสถิติต่างๆ ในปัจจุบัน คลัง Perk และส่งสัญญาณให้สคริปต์ต่างๆ ทำงานสอดคล้องกัน

signal perk_applied(perk: PerkData)
signal relic_added(relic: RelicData)

# ตัวแปรประจำการ Run ตัวปัจจุบัน
var run_coin: int = 0
var current_wave: int = 0
var player_current_hp: float = -1.0 # -1 คือต้องรีเซ็ตตอนเริ่มตาใหม่ หรือตอนโหลดตัวละครครั้งแรก

# คลังข้อมูล (Inventory) ในตัวละครระหว่าง Run
var active_perks: Array[PerkData] = []
var active_relics: Array[RelicData] = []

func start_new_run() -> void:
	# รีเซ็ตค่าทั้งหมดสำหรับการเริ่มรอบใหม่ (เช่น เมื่อเริ่มโหมด Roguelike ใหม่)
	run_coin = 0
	current_wave = 0
	player_current_hp = -1.0
	active_perks.clear()
	active_relics.clear()
	StatCalculator.stats_recalculated.emit()

# --- ระบบคลังสำหรับ Perk ---

func apply_perk(perk: PerkData) -> void:
	if not perk:
		return
		
	# เช็คจำนวนซ้ำกันสูงสุด (Stack limitation)
	if get_perk_count(perk.id) >= perk.max_stack:
		print("ไม่สามารถรับ Perk ได้อีก เพราะถึงระดับสูงสุดแล้ว: ", perk.title)
		return
		
	# เช็คความเข้ากันไม่ได้ (Exclusivity Check)
	for ex in perk.exclusive_with:
		if has_perk(ex):
			print("ไม่สามารถรับ Perk ได้เพราะขัดแย้งกับสิ่งที่มีอยู่: ", ex)
			return

	active_perks.append(perk)
	print("[RunManager] รับ Perk ใหม่สำเร็จ: ", perk.title, " (ID: ", perk.id, ")")
	perk_applied.emit(perk)
	
	# ทริกเกอร์ให้ StatCalculator แจ้งเตือนเมื่อสถานะมีการเปลี่ยนแปลง
	StatCalculator.stats_recalculated.emit()

func has_perk(id: StringName) -> bool:
	return get_perk_count(id) > 0

func get_perk_count(id: StringName) -> int:
	var count = 0
	for p in active_perks:
		if p.id == id:
			count += 1
	return count

# --- ระบบคลังสำหรับ Relic อาติแฟกต์ ---

func add_relic(relic: RelicData) -> void:
	if not relic:
		return
		
	if not relic.stackable and has_relic(relic.id):
		print("ไม่สามารถสะสมอาติแฟกต์/คำสาป นี้ได้ซ้ำอีก: ", relic.title)
		return
		
	active_relics.append(relic)
	relic_added.emit(relic)
	StatCalculator.stats_recalculated.emit()

func has_relic(id: StringName) -> bool:
	for r in active_relics:
		if r.id == id:
			return true
	return false

# --- คำนวณ Modifiers (ค่ารวบรวมที่สะสม/ซ้อนทับกัน) สำหรับ StatCalculator เรียกใช้ ---

func get_total_modifier(stat_name: String) -> float:
	var total: float = 0.0
	
	# รวม Modifier จาก Perks
	for p in active_perks:
		if p.modifiers.has(stat_name):
			total += float(p.modifiers[stat_name])
			
	# รวม Modifier จาก Relics (มีทั้งข้อดีและข้อเสีย)
	for r in active_relics:
		if r.positive_modifiers.has(stat_name):
			total += float(r.positive_modifiers[stat_name])
		if r.negative_modifiers.has(stat_name):
			total += float(r.negative_modifiers[stat_name])
			
	return total

# --- ฟังก์ชั่นเสริม: ระบบสุ่มเลือกรางวัลเมื่อจบ Wave ---
# คืนค่าตัวเลือก Perks ตามจำนวน count ที่กำหนด โดยรับ Pool ทั้งหมด (เพื่อไม่ให้ hardcode กฎเข้าไปในฟังก์ชันนี้)
func get_reward_choices(count: int, all_available_perks: Array[PerkData]) -> Array[PerkData]:
	var choices: Array[PerkData] = []
	var pool_copy = all_available_perks.duplicate()
	# อาจจะต้องสับเปลี่ยน (Shuffle) เพื่อความเป็นแบบสุ่ม หรือใช้สูตรรูปแบบอื่นตามความหายาก (Rarity)
	pool_copy.shuffle()
	
	for i in range(min(count, pool_copy.size())):
		choices.append(pool_copy[i])
		
	return choices
