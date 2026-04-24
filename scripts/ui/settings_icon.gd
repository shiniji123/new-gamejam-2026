extends Control

@export var line_color: Color = Color(0.92, 0.95, 1.0, 0.95)
@export var knob_color: Color = Color(1.0, 0.78, 0.3, 1.0)
@export var line_width: float = 3.0
@export var knob_radius: float = 3.6


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	queue_redraw()


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		queue_redraw()


func _draw() -> void:
	var width := size.x
	var height := size.y
	if width <= 0.0 or height <= 0.0:
		return

	var top_y := height * 0.28
	var mid_y := height * 0.50
	var bot_y := height * 0.72

	draw_line(Vector2(width * 0.18, top_y), Vector2(width * 0.82, top_y), line_color, line_width)
	draw_line(Vector2(width * 0.18, mid_y), Vector2(width * 0.82, mid_y), line_color, line_width)
	draw_line(Vector2(width * 0.18, bot_y), Vector2(width * 0.82, bot_y), line_color, line_width)

	draw_circle(Vector2(width * 0.34, top_y), knob_radius, knob_color)
	draw_circle(Vector2(width * 0.67, mid_y), knob_radius, knob_color)
	draw_circle(Vector2(width * 0.47, bot_y), knob_radius, knob_color)
