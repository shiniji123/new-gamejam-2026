extends Node
## ===================================================
## RunManager — ศูนย์กลางข้อมูลใน 1 รอบการเล่น (Run)
## ===================================================
## รับผิดชอบทั้งหมดที่เกิดขึ้นภายใน 1 Run:
##   - เงิน (coin) พร้อม Signal อัตโนมัติ
##   - คลัง Perk และ Relic
##   - Modifier จากร้านค้า (shop_modifiers)
##   - หมายเลข Wave ปัจจุบัน
##   - ค่ารวมของ Modifier ทุกแหล่ง (ผ่าน get_total_modifier)

signal perk_applied(perk: PerkData)
signal relic_added(relic: RelicData)
## เมื่อเงินเปลี่ยนแปลง ส่งค่าใหม่ออกมาให้ UI อัปเดตได้ทันทีโดยไม่ต้อง poll
signal coin_changed(new_amount: int)

# --- เงินสะสมในรอบ (Coin) ---
# ใช้ setter เพื่อ emit signal อัตโนมัติทุกครั้งที่เงินเปลี่ยน
var _run_coin: int = 0
var run_coin: int:
	get:
		return _run_coin
	set(val):
		_run_coin = max(0, val)
		coin_changed.emit(_run_coin)

# --- ข้อมูล Run ---
var current_wave: int = 0

# --- คลังข้อมูล (Inventory) ---
var active_perks: Array[PerkData] = []
var active_relics: Array[RelicData] = []

# --- Modifier สะสมจากร้านค้า (แยกออกจาก Perk เพื่อความชัดเจน) ---
# รูปแบบ: { "damage_multiplier": 0.5, "flat_max_hp": 100.0, ... }
var shop_modifiers: Dictionary = {}


# ====================================================
# ระบบจัดการวงจรชีวิต (Run Lifecycle)
# ====================================================

func start_new_run() -> void:
	## รีเซ็ตค่าทั้งหมดเมื่อเริ่มรอบใหม่
	run_coin = 0
	current_wave = 0
	active_perks.clear()
	active_relics.clear()
	shop_modifiers.clear()
	Autoload.player_current_hp = -1.0
	StatCalculator.stats_recalculated.emit()


# ====================================================
# ระบบจัดการเงิน (Economy)
# ====================================================

func add_coin(amount: int) -> void:
	## เพิ่มเงิน (เรียกจาก Enemy เมื่อตาย)
	run_coin += amount

func spend_coin(amount: int) -> bool:
	## ลองหักเงิน — คืน true ถ้าสำเร็จ, false ถ้าไม่พอ
	if _run_coin < amount:
		return false
	run_coin -= amount
	return true


# ====================================================
# ระบบร้านค้า (Shop Modifiers)
# ====================================================

func apply_shop_modifier(stat_name: String, value: float) -> void:
	## เพิ่ม/สะสม Modifier จากการซื้อสินค้าในร้าน
	shop_modifiers[stat_name] = shop_modifiers.get(stat_name, 0.0) + value
	StatCalculator.stats_recalculated.emit()

func get_shop_modifier(stat_name: String) -> float:
	## ดึงค่า Modifier ร้านค้าสำหรับ stat ที่กำหนด
	return float(shop_modifiers.get(stat_name, 0.0))


# ====================================================
# ระบบ Perk
# ====================================================

func apply_perk(perk: PerkData) -> void:
	if not perk:
		return

	# เช็คจำนวนซ้ำกันสูงสุด (Stack Limit)
	if get_perk_count(perk.id) >= perk.max_stack:
		print("[RunManager] ถึงระดับสูงสุดแล้ว: ", perk.title)
		return

	# เช็คความเข้ากันไม่ได้ (Exclusivity)
	for ex in perk.exclusive_with:
		if has_perk(ex):
			print("[RunManager] ขัดแย้งกับ Perk ที่มีอยู่: ", ex)
			return

	active_perks.append(perk)
	print("[RunManager] รับ Perk: ", perk.title, " (ID: ", perk.id, ")")
	perk_applied.emit(perk)
	StatCalculator.stats_recalculated.emit()

func has_perk(id: StringName) -> bool:
	return get_perk_count(id) > 0

func get_perk_count(id: StringName) -> int:
	var count := 0
	for p in active_perks:
		if p.id == id:
			count += 1
	return count


# ====================================================
# ระบบ Relic
# ====================================================

func add_relic(relic: RelicData) -> void:
	if not relic:
		return

	if not relic.stackable and has_relic(relic.id):
		print("[RunManager] ไม่สามารถสะสมซ้ำ: ", relic.title)
		return

	active_relics.append(relic)
	relic_added.emit(relic)
	StatCalculator.stats_recalculated.emit()

func has_relic(id: StringName) -> bool:
	for r in active_relics:
		if r.id == id:
			return true
	return false


# ====================================================
# รวม Modifier ทุกแหล่ง (Perk + Relic + Shop)
# ====================================================

func get_total_modifier(stat_name: String) -> float:
	## รวมค่า Modifier จากทุกแหล่งสำหรับ stat ที่ต้องการ
	## เรียกใช้โดย StatCalculator
	var total: float = 0.0

	# 1. Perk Modifiers
	for p in active_perks:
		if p.modifiers.has(stat_name):
			total += float(p.modifiers[stat_name])

	# 2. Relic Modifiers (ทั้งบวกและลบ)
	for r in active_relics:
		if r.positive_modifiers.has(stat_name):
			total += float(r.positive_modifiers[stat_name])
		if r.negative_modifiers.has(stat_name):
			total += float(r.negative_modifiers[stat_name])

	# 3. Shop Modifiers
	total += get_shop_modifier(stat_name)

	return total


# ====================================================
# ระบบสุ่มรางวัล Wave
# ====================================================

func get_reward_choices(count: int, all_available_perks: Array[PerkData]) -> Array[PerkData]:
	## สุ่มเลือก Perk จาก pool ตามจำนวน count ที่กำหนด
	var pool_copy := all_available_perks.duplicate()
	pool_copy.shuffle()

	var choices: Array[PerkData] = []
	for i in range(min(count, pool_copy.size())):
		choices.append(pool_copy[i])

	return choices
