class_name WaveItem
extends Node
## ===================================================
## WaveItem — ตัวกำหนดค่าของแต่ละ Wave
## ===================================================
## วิธีใช้งาน:
##   1. สร้างโหนดลูกภายใต้ WaveManager
##   2. เอาสคริปต์นี้ไปแปะ (หรือเลือก Class "WaveItem" ตอนสร้างโหนด)
##   3. แก้ไขจำนวนศัตรูใน Inspector ได้เลย!

@export_category("จำนวนศัตรูใน Wave นี้")
@export var normal_count: int = 5
@export var elite_count: int = 0
@export var boss_count: int = 0

@export_category("ตั้งค่าเวลา")
## หน่วงเวลาก่อนเริ่ม Wave นี้ (วินาที)
@export var start_delay: float = 2.0
## หน่วงเวลาระหว่างการเสกศัตรูแต่ละตัว (วินาที)
@export var spawn_interval: float = 0.3

## ฟังก์ชันช่วย: คืนจำนวนศัตรูทั้งหมด
func get_total_enemies() -> int:
	return normal_count + elite_count + boss_count
