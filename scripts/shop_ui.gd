extends CanvasLayer
## ===================================================
## ShopUI — จัดการร้านค้ารูปแบบ AAA (Split Screen)
## ===================================================

signal shop_closed

@export_group("UI Layout")
@export var main_panel: Control
@export var close_btn: Button

@export_group("Details Panel (ฝั่งขวา)")
@export var detail_icon: TextureRect
@export var detail_title: Label
@export var detail_desc: RichTextLabel
@export var detail_price: Label
@export var buy_btn: Button

@export_group("Item List (ฝั่งซ้าย)")
@export var item_container: VBoxContainer

var selected_item: ShopButton = null

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	hide()

	if main_panel:
		main_panel.pivot_offset = main_panel.size / 2.0

	if close_btn and not close_btn.pressed.is_connected(close_shop):
		close_btn.pressed.connect(close_shop)
		
	if buy_btn and not buy_btn.pressed.is_connected(_on_buy_pressed):
		buy_btn.pressed.connect(_on_buy_pressed)
		
	# ตั้งค่าหน้าจอเริ่มต้น
	_clear_details()
	_connect_items()

func _connect_items() -> void:
	if not item_container: return
	for child in item_container.get_children():
		if child is ShopButton:
			if not child.item_selected.is_connected(_on_item_selected):
				child.item_selected.connect(_on_item_selected)

func open_shop() -> void:
	show()
	get_tree().paused = true
	_clear_details()

	if main_panel:
		main_panel.scale = Vector2.ZERO
		var tween := create_tween()
		tween.bind_node(self)
		tween.tween_property(main_panel, "scale", Vector2.ONE, 0.4).set_trans(Tween.TRANS_SPRING).set_ease(Tween.EASE_OUT)

func close_shop() -> void:
	if main_panel:
		var tween := create_tween()
		tween.bind_node(self)
		tween.tween_property(main_panel, "scale", Vector2.ZERO, 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
		await tween.finished

	hide()
	get_tree().paused = false
	shop_closed.emit()

func _on_item_selected(item: ShopButton) -> void:
	selected_item = item
	
	if detail_title: detail_title.text = item.item_label
	if detail_desc: detail_desc.text = item.item_description
	if detail_price: detail_price.text = "Price: %d Gold" % item.cost
	
	if detail_icon:
		if item.item_icon:
			detail_icon.texture = item.item_icon
			detail_icon.show()
		else:
			detail_icon.hide()
			
	if buy_btn:
		buy_btn.disabled = false
		buy_btn.text = "Buy"
		
		# แอนิเมชันเด้งปุ่ม
		buy_btn.scale = Vector2(0.8, 0.8)
		var tween = create_tween()
		tween.bind_node(self)
		tween.set_trans(Tween.TRANS_SPRING).set_ease(Tween.EASE_OUT)
		tween.tween_property(buy_btn, "scale", Vector2.ONE, 0.3)

func _on_buy_pressed() -> void:
	if not selected_item: return
	
	var success = selected_item.execute_purchase()
	
	if success:
		# อัปเดตราคาใหม่เผื่อมีการซื้อซ้ำได้ (ถ้ามีระบบราคาเพิ่มขึ้นทีหลัง)
		if detail_price: detail_price.text = "Price: %d Gold" % selected_item.cost
		
		# เช็คว่าเต็มแม็กซ์หรือยัง
		if selected_item.max_purchases > 0 and selected_item.purchase_count >= selected_item.max_purchases:
			buy_btn.disabled = true
			buy_btn.text = "MAXED OUT"

func _clear_details() -> void:
	selected_item = null
	if detail_title: detail_title.text = "Select an item"
	if detail_desc: detail_desc.text = ""
	if detail_price: detail_price.text = ""
	if detail_icon: detail_icon.hide()
	if buy_btn: 
		buy_btn.disabled = true
		buy_btn.text = "Buy"


func get_save_data() -> Dictionary:
	var purchase_counts := {}
	if item_container:
		for child in item_container.get_children():
			if child is ShopButton:
				purchase_counts[child.get_save_key()] = child.purchase_count

	return {
		"purchase_counts": purchase_counts,
	}


func restore_from_save(data: Dictionary) -> void:
	var purchase_counts = data.get("purchase_counts", {})
	if item_container:
		for child in item_container.get_children():
			if child is ShopButton:
				child.set_purchase_count(int(purchase_counts.get(child.get_save_key(), 0)))

	_clear_details()

func _unhandled_input(event: InputEvent) -> void:
	if not visible: return
	if event.is_action_pressed("close_shop") or event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		close_shop()
