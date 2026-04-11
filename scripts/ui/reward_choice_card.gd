extends Control
# แนะนำให้กางเป็น Button หรือ PanelContainer ในหน้าต่าง 2D Editor
# สคริปต์นี้เอาไว้ใส่บนการ์ดแต่ละใบ เพื่อให้สามารถกดเลือกและแสดงไอคอนได้เอง

signal card_selected(perk: PerkData)

# ตัวแปรเหล่านี้ ลาก Node จากหน้าต่าง Scene มาหยอดใส่ทาง Inspector ได้เลย
@export var title_label: Label
@export var description_label: Label
@export var icon_rect: TextureRect
@export var trigger_button: Button

var _current_perk: PerkData

func _ready() -> void:
	if trigger_button:
		trigger_button.pressed.connect(_on_pressed)

# รับข้อมูลจากหน้า RewardUI เข้ามาถมใส่การ์ดใบนี้
func setup_card(perk: PerkData) -> void:
	_current_perk = perk
	if title_label:
		title_label.text = perk.title
	if description_label:
		description_label.text = perk.description
	if icon_rect and perk.icon:
		icon_rect.texture = perk.icon

func _on_pressed() -> void:
	if _current_perk:
		card_selected.emit(_current_perk)
