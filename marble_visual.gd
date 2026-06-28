extends Node2D

@export var radius: float = 16.0
@export var body_color: Color = Color(0.85, 0.25, 0.25)
@export var highlight_color: Color = Color(1.0, 0.95, 0.85, 0.9)
@export var rim_color: Color = Color(0.2, 0.05, 0.05)


func _draw() -> void:
	draw_circle(Vector2.ZERO, radius, body_color)
	draw_arc(Vector2.ZERO, radius - 1.0, 0.0, TAU, 32, rim_color, 1.5, true)
	draw_circle(Vector2(-radius * 0.35, -radius * 0.35), radius * 0.28, highlight_color)
