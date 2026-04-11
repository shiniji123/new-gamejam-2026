extends HSlider

# ตั้งชื่อ Bus ที่ต้องการให้สไลเดอร์นี้คุม (ค่าเริ่มต้นของ Godot คือ "Master")
@export var bus_name: String = "Master"
var bus_index: int

func _ready() -> void:
	# ค้นหาหมายเลขช่องสัญญาณ (Bus Index) จากชื่อ
	bus_index = AudioServer.get_bus_index(bus_name)
	
	# ป้องกันคนพิมพ์ชื่อ Bus ผิด
	if bus_index == -1:
		print("ไม่พบ Bus เสียงที่ชื่อ: ", bus_name)
		return
		
	# ดึงค่าเสียงปัจจุบันมาแสดงบน Slider ให้ถูกต้อง
	# (เสียงใน Godot เป็นระดับเดซิเบล -dB เราต้องแปลงเป็นเปอเซ็นต์เส้นตรงก่อนด้วยฟังก์ชัน db_to_linear)
	value = db_to_linear(AudioServer.get_bus_volume_db(bus_index))
	
	# ผูกสายสัญญาณ ถ้ารูดสไลเดอร์เมื่อไหร่ ให้เรียกฟังก์ชัน _on_value_changed อัตโนมัติ
	value_changed.connect(_on_value_changed)


func _on_value_changed(new_value: float) -> void:
	# ถ้าลากจนหลอดสุด 0 ให้สั่ง Mute (ปิดเสียงสนิท) ไปเลย
	if new_value <= 0.001:
		AudioServer.set_bus_mute(bus_index, true)
	else:
		AudioServer.set_bus_mute(bus_index, false)
		# แปลงตัวเลขจากหลอดกลับเป็นเดซิเบล แล้วยัดลงไปปรับที่ตัวรับเสียงของเกม
		AudioServer.set_bus_volume_db(bus_index, linear_to_db(new_value))
