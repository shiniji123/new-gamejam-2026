class_name WaveData
extends Resource
## ===================================================
## WaveData — ข้อมูลของ Wave แต่ละคลื่น
## ===================================================
## วิธีใช้: สร้างไฟล์ .tres ใหม่ใน Godot แล้วลากเรียงใส่ Array waves ของ WaveManager
## เพิ่ม/ลด/แก้ไข Wave ได้ทันทีโดยไม่ต้องแก้โค้ด

## ชื่อ Wave สำหรับแสดงใน UI (เช่น "Wave 1", "Wave Boss")
@export var wave_label: String = ""

## จำนวนศัตรูทั่วไป (Normal)
@export var normal_count: int = 5

## จำนวนศัตรู Elite
@export var elite_count: int = 0

## จำนวนบอส (Boss)
@export var boss_count: int = 0

## หน่วงเวลาระหว่างการเสกศัตรูแต่ละตัว (วินาที)
@export var spawn_delay: float = 0.3

## หน่วงเวลาก่อนเริ่ม Wave นี้ (วินาที) — Wave แรกมักใส่ไว้ 3.0 เผื่อโหลดฉาก
@export var pre_wave_delay: float = 2.0

## ฟังก์ชันช่วย: คืนจำนวนศัตรูทั้งหมดใน Wave นี้
func get_total_enemies() -> int:
	return normal_count + elite_count + boss_count
