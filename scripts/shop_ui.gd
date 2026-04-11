extends CanvasLayer

@export_group("UI Layout (ส่วนออโต้โฟกัสปุ่ม)")
@export var main_panel: Control      # ลากกล่อง Panel หลักมาใส่ที่นี่
@export var damage_btn: Button       # ปุ่ม ดาเมจ
@export var shotgun_btn: Button      # ปุ่ม ลูกซอง
@export var hp_btn: Button           # ปุ่ม เลือด
@export var close_btn: Button        # ปุ่ม ปิดร้าน

func _ready():
	# บังคับระบบให้อมตะข้ามกาลเวลาเวลาหยุดเกม
	process_mode = Node.PROCESS_MODE_ALWAYS
	hide() 
	
	if main_panel:
		# เซ็ตจุดหมุนไว้ที่ตรงกลางจอเพื่อให้แอนิเมชันกระโดดสวยงาม
		main_panel.pivot_offset = main_panel.size / 2.0
		
	# --- ระบบผูกปุ่มอัตโนมัติ (Anti-Error) ---
	# ไม่ต้องไปกดลากเส้นเชือกสีเขียวๆ ในหน้าต่าง Inspector แล้ว! โค้ดจะจัดการมัดสายให้เองเลย
	if damage_btn:
		if not damage_btn.pressed.is_connected(buy_damage_buff): damage_btn.pressed.connect(buy_damage_buff)
		damage_btn.text = "ATK Buff (50G)"
		
	if shotgun_btn:
		if not shotgun_btn.pressed.is_connected(buy_multishot_buff): shotgun_btn.pressed.connect(buy_multishot_buff)
		shotgun_btn.text = "Shotgun (150G)"
		
	if hp_btn:
		if not hp_btn.pressed.is_connected(buy_hp_buff): hp_btn.pressed.connect(buy_hp_buff)
		hp_btn.text = "HP Buff (100G)"
		
	if close_btn and not close_btn.pressed.is_connected(close_shop):
		close_btn.pressed.connect(close_shop)

# --------------------------------
# ระบบคุมหน้าต่าง + แอนิเมชันเปิด/ปิด ระดับเกม AAA
# --------------------------------
func open_shop():
	show()
	get_tree().paused = true 
	
	# แอนิเมชันหน้าต่างเด้งดึ๋งๆ เหมือนเยลลี่ (Tween Animation)
	if main_panel:
		main_panel.scale = Vector2.ZERO # ย่อเหลือ 0
		var tween = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		# ขยายกลับไปที่ 1 ภายในเวลา 0.4 วินาที ด้วยเส้นโค้ง BACK_OUT (ทะลักแล้วเด้งกลับ)
		tween.tween_property(main_panel, "scale", Vector2.ONE, 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func close_shop():
	# แอนิเมชันหดตัวอย่างรวดเร็ว
	if main_panel:
		var tween = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		tween.tween_property(main_panel, "scale", Vector2.ZERO, 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
		await tween.finished # รอให้หดเสร็จก่อนค่อยปิดจริงๆ
		
	hide()
	get_tree().paused = false

# --- ระบบคีย์ลัดปิดหน้าต่าง (Input Shortcut) ---
func _unhandled_input(event: InputEvent) -> void:
	# ถ้าหน้าร้านไม่ได้เปิดอยู่ ไม่ต้องเปลืองแรงเช็คอะไรทั้งนั้น
	if not visible:
		return
		
	# ดักฟังเสียงกดปุ่มคีย์บอร์ดชื่อ "close_shop" (ที่คุณกำลังจะสร้าง) 
	# หรืออนุโลมให้ใช้ปุ่ม "ui_cancel" (ค่าเริ่มต้นคือปุ่ม Esc) เพื่อปิดร้าน
	if event.is_action_pressed("close_shop") or event.is_action_pressed("ui_cancel"):
		
		# กระทืบเบรก! สกัดไม่ให้คำสั่งกดปุ่มนี้ทะลุผ่านไปรบกวนระบบอื่น
		get_viewport().set_input_as_handled()
		close_shop()

# --------------------------------
# ระบบตัดเงิน (คงลอจิกเทพไว้เหมือนเดิม)
# --------------------------------
func buy_damage_buff():
	if Autoload.coin >= 50:
		Autoload.coin -= 50
		Autoload.damage_bonus += 0.25 
		print("[ร้านค้า] ซื้อบัฟดาเมจสำเร็จ! ยอดคงเหลือ: ", Autoload.coin)
	else:
		_animate_error(damage_btn)

func buy_multishot_buff():
	if Autoload.coin >= 150:
		Autoload.coin -= 150
		Autoload.multishot_level += 1 
		print("[ร้านค้า] ซื้อลูกซองสำเร็จ! ยอดคงเหลือ: ", Autoload.coin)
	else:
		_animate_error(shotgun_btn)
		
func buy_hp_buff():
	if Autoload.coin >= 100:
		Autoload.coin -= 100
		Autoload.max_hp_bonus += 50
		
		var player = get_tree().get_first_node_in_group("player")
		if player and player.has_node("HurtboxComponent"):
			var hb = player.get_node("HurtboxComponent")
			hb.max_hp += 50
			hb.current_hp += 50
			
			# แบ็คอัปเก็บเข้าเซฟไว้ด้วย!
			Autoload.player_current_hp = hb.current_hp
			
			var bars = get_tree().get_nodes_in_group("player_health_bar")
			if bars.size() > 0: bars[0].update_health(hb.current_hp, hb.max_hp)
				
		print("[ร้านค้า] ซื้อบัฟเลือดสำเร็จ! ยอดคงเหลือ: ", Autoload.coin)
	else:
		_animate_error(hp_btn)

# เอฟเฟกต์เฉพาะกิจเวลาเงินไม่พอ
func _animate_error(btn: Button):
	print("[ร้านค้า] เงินไม่พอ!")
	if btn:
		var orig_pos = btn.position
		var tween = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		# แอนิเมชันส่ายปุ่มไปมา เหมือนสั่นหัวว่าไม่ได้!
		tween.tween_property(btn, "position:x", orig_pos.x + 10, 0.05)
		tween.tween_property(btn, "position:x", orig_pos.x - 10, 0.05)
		tween.tween_property(btn, "position:x", orig_pos.x + 10, 0.05)
		tween.tween_property(btn, "position", orig_pos, 0.05)
		# ตัวปุ่มกระพริบสีแดงตอกย้ำความช้ำใจ
		btn.modulate = Color.RED
		tween.parallel().tween_property(btn, "modulate", Color.WHITE, 0.3)


func _on_buy_damage_buff_pressed() -> void:
	pass # Replace with function body.


func _on_buy_hp_buff_pressed() -> void:
	pass # Replace with function body.
