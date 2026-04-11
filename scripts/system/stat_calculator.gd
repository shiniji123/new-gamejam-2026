extends Node
# เปิดใช้งานเพื่อให้ Autoload ตัวนี้เรียกใช้จากชื่อคลาสได้ง่ายหากจำเป็น (และมีอยู่แล้วใน project.godot)
# หน้าที่: เป็นตัวกลาง (Manager) ในการคำนวณสถานะรวมของทั้งเกม

# สัญญาณเมื่อสเตตัสบางอย่างถูกคำนวณใหม่
signal stats_recalculated

# ฟังก์ชันอรรถประโยชน์ (Utility) สำหรับดึงค่าต่างๆ 
# ผู้รับผิดชอบ: รวมค่าพื้นฐานบวกกับโบนัสจากการถือครอง Perks และ Relics ต่างๆ (ผ่าน RunManager)

func get_player_damage(base_damage: float) -> float:
	# รวมเครื่องมือคำนวณ: Base * (1 + Perk Bonus + Shop Bonus)
	var multiplier_bonus: float = 0.0
	
	if RunManager:
		multiplier_bonus += RunManager.get_total_modifier("damage_multiplier")
	
	# รวมโบนัสจากร้านค้า (ระบบเก่า)
	var global_autoload = get_node_or_null("/root/Autoload")
	if global_autoload:
		multiplier_bonus += global_autoload.damage_bonus
	
	var final_damage := base_damage * (1.0 + multiplier_bonus)
	
	# บวกค่าความเสียหายพื้นฐาน (Flat) จาก Perk
	if RunManager:
		final_damage += RunManager.get_total_modifier("flat_damage")
	
	return max(1.0, final_damage)

func get_player_max_hp(base_hp: float) -> float:
	var multiplier_bonus := 0.0
	var flat_bonus := 0.0
	
	if RunManager:
		multiplier_bonus = RunManager.get_total_modifier("max_hp_multiplier")
		flat_bonus = RunManager.get_total_modifier("flat_max_hp")
	
	# รวมโบนัสเลือดจากร้านค้า (ระบบเก่า)
	var global_autoload = get_node_or_null("/root/Autoload")
	if global_autoload:
		flat_bonus += global_autoload.max_hp_bonus
		
	var final_hp = (base_hp + flat_bonus) * (1.0 + multiplier_bonus)
	return max(1.0, final_hp)

func get_projectile_count(base_count: int) -> int:
	var perk_bonus := 0
	if RunManager:
		perk_bonus = int(RunManager.get_total_modifier("projectile_count"))
	
	# รวมโบนัสจำนวนกระสุนจากร้านค้า (ระบบเก่า)
	var shop_bonus := 0
	var global_autoload = get_node_or_null("/root/Autoload")
	if global_autoload:
		shop_bonus = global_autoload.multishot_level
	
	var total = base_count + perk_bonus + shop_bonus
	
	if total > 1:
		print("[StatCalculator] คำนวณจำนวนกระสุน: ", total, " (พื้นฐาน: ", base_count, ", Perk: ", perk_bonus, ", Shop: ", shop_bonus, ")")
		
	return total

func get_enemy_reward(base_reward: int) -> int:
	var gold_multiplier := 0.0
	if RunManager:
		gold_multiplier = RunManager.get_total_modifier("gold_multiplier")
	return int(base_reward * (1.0 + gold_multiplier))

func get_pierce_count(base_pierce: int) -> int:
	var extra_pierce := 0
	if RunManager:
		# ดึงค่า pierce_bonus จาก Perk ที่ผู้เล่นเลือกมา
		extra_pierce = int(RunManager.get_total_modifier("pierce_bonus"))
	
	# คืนค่าจำนวนครั้งที่ทะลุได้รวมทั้งหมด (เริ่มต้นคือ 0 = ชนแล้วหายทันที)
	return base_pierce + extra_pierce

