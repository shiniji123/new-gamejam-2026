extends Label
## ===================================================
## coin_display.gd — แสดงยอดเงินปัจจุบัน
## ===================================================
## ใช้ Signal แทน _process เพื่อไม่เปลืองเวลา CPU ทุก frame

func _ready() -> void:
	# ตั้งค่าให้ทำงานตลอดเวลาแม้จะหยุดเกม (เพื่อให้เงินเด้งตอนเปิดร้านค้าได้)
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	# แสดงค่าเงินปัจจุบันทันทีตอนโหลด
	_update_display(RunManager.run_coin)

	# Subscribe signal — อัปเดตอัตโนมัติเมื่อเงินเปลี่ยน โดยไม่ต้อง poll
	if not RunManager.coin_changed.is_connected(_update_display):
		RunManager.coin_changed.connect(_update_display)


func _update_display(new_amount: int) -> void:
	text = "💰 %d G" % new_amount

	# Animation เด้งดึ๋งเมื่อเงินเปลี่ยน
	var tween := create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	scale = Vector2(1.4, 1.4)
	tween.tween_property(self, "scale", Vector2.ONE, 0.4)\
		.set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)

	modulate = Color(1.0, 0.85, 0.2)   # สีทอง
	tween.parallel().tween_property(self, "modulate", Color.WHITE, 0.4)
