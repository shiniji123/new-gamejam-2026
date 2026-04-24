extends Node
## ===================================================
## StatCalculator — คำนวณสถิติรวมของผู้เล่น
## ===================================================
## แหล่งข้อมูลเดียว: RunManager.get_total_modifier()
## ซึ่งรวมค่าจาก Perk + Relic + Shop Modifiers ให้อัตโนมัติ

## Signal เพื่อแจ้งเตือนระบบอื่นเมื่อสถิติมีการเปลี่ยนแปลง
signal stats_recalculated

## HP พื้นฐานของผู้เล่น — แก้ตรงนี้ที่เดียวเพื่อเปลี่ยน HP เริ่มต้น!
const BASE_PLAYER_HP: float = 100.0


func get_player_damage(base_damage: float) -> float:
	## คำนวณดาเมจสุดท้าย: base * (1 + multiplier%) + flat_bonus
	var multiplier_bonus := RunManager.get_total_modifier("damage_multiplier")
	var flat_bonus := RunManager.get_total_modifier("flat_damage")
	var final_damage := base_damage * (1.0 + multiplier_bonus) + flat_bonus
	return max(1.0, final_damage)


func get_player_max_hp(base_hp: float) -> float:
	## คำนวณ HP สูงสุด: (base + flat_bonus) * (1 + multiplier%)
	var multiplier_bonus := RunManager.get_total_modifier("max_hp_multiplier")
	var flat_bonus := RunManager.get_total_modifier("flat_max_hp")
	var final_hp := (base_hp + flat_bonus) * (1.0 + multiplier_bonus)
	return max(1.0, final_hp)


func get_projectile_count(base_count: int) -> int:
	## คำนวณจำนวนกระสุนรวม
	var bonus := int(RunManager.get_total_modifier("projectile_count"))
	return max(1, base_count + bonus)


func get_player_fire_rate(base_fire_rate: float) -> float:
	## คำนวณอัตราการยิงรวมจาก perk + shop
	var multiplier_bonus := RunManager.get_total_modifier("fire_rate_multiplier")
	var flat_bonus := RunManager.get_total_modifier("flat_fire_rate")
	var final_fire_rate := (base_fire_rate + flat_bonus) * (1.0 + multiplier_bonus)
	return max(0.1, final_fire_rate)


func get_enemy_reward(base_reward: int) -> int:
	## คำนวณเงินรางวัลจากการสังหารศัตรู (รวม gold multiplier)
	var gold_multiplier := RunManager.get_total_modifier("gold_multiplier")
	return int(base_reward * (1.0 + gold_multiplier))


func get_pierce_count(base_pierce: int) -> int:
	## คำนวณจำนวนการทะลุของกระสุน
	var bonus := int(RunManager.get_total_modifier("pierce_bonus"))
	return base_pierce + bonus
