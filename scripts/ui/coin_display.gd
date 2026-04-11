extends Label

# สคริปต์นี้เอาไปแปะไว้ที่โหนด Label สำหรับแสดงจำนวนเงิน

var last_coin: int = -1

func _process(_delta):
	var current_coin = Autoload.coin
	
	# อัปเดตข้อความทันที และเช็คว่าเงินเปลี่ยนไหม
	if current_coin != last_coin:
		text = "Gold: " + str(current_coin)
		
		# --- แอนิเมชันความรวยเด้งดึ๋งเมื่อเงินเปลี่ยน ---
		if last_coin != -1: 
			var tween = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
			
			# ทำให้ตัวเลขขยายเป่งขึ้นมา
			scale = Vector2(1.5, 1.5)
			tween.tween_property(self, "scale", Vector2.ONE, 0.4).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
			
			# กะพริบเป็นสีทองอร่ามแปปนึง แล้วค่อยกลับเป็นสีขาว
			modulate = Color(1.0, 0.8, 0.2) # สีทอง Gold
			tween.parallel().tween_property(self, "modulate", Color.WHITE, 0.4)
			
		last_coin = current_coin
