extends CanvasLayer
## ===================================================
## ShopUI — จัดการเปิด/ปิดเท่านั้น
## ===================================================
## ปุ่มแต่ละตัวในร้านค้าจะจัดการตัวเองผ่านสคริปต์ shop_button.gd
## shop_ui.gd รับผิดชอบแค่การเปิดปิดและ Animation เท่านั้น

@export_group("UI Layout")
## Panel หลักของร้าน (ใช้สำหรับ Animation เปิด/ปิด)
@export var main_panel: Control
## ปุ่มปิดร้าน (ลากปุ่มมาใส่ได้เลย)
@export var close_btn: Button


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	hide()

	if main_panel:
		main_panel.pivot_offset = main_panel.size / 2.0

	if close_btn and not close_btn.pressed.is_connected(close_shop):
		close_btn.pressed.connect(close_shop)


func open_shop() -> void:
	show()
	get_tree().paused = true

	if main_panel:
		main_panel.scale = Vector2.ZERO
		var tween := create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		tween.tween_property(main_panel, "scale", Vector2.ONE, 0.4)\
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func close_shop() -> void:
	if main_panel:
		var tween := create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		tween.tween_property(main_panel, "scale", Vector2.ZERO, 0.2)\
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
		await tween.finished

	hide()
	get_tree().paused = false


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("close_shop") or event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		close_shop()
