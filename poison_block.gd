extends RigidBody2D

const SIZE: float = 36.0
const FILL_COLOR: Color = Color(0.65, 0.15, 0.85, 1.0)
const HAZARD_COLOR: Color = Color(0.2, 1.0, 0.4, 1.0)
const OUTLINE_COLOR: Color = Color(0.2, 0.0, 0.3, 1.0)

signal marble_touched()

var editing: bool = true
var locked: bool = true


func _ready() -> void:
	var shape: CollisionShape2D = CollisionShape2D.new()
	var rect: RectangleShape2D = RectangleShape2D.new()
	rect.size = Vector2(SIZE, SIZE)
	shape.shape = rect
	add_child(shape)
	var area: Area2D = Area2D.new()
	area.name = "TouchArea"
	var area_shape: CollisionShape2D = CollisionShape2D.new()
	var area_rect: RectangleShape2D = RectangleShape2D.new()
	area_rect.size = Vector2(SIZE, SIZE)
	area_shape.shape = area_rect
	area.add_child(area_shape)
	area.body_entered.connect(_on_body_entered)
	add_child(area)
	freeze = true
	linear_damp = 0.2
	angular_damp = 0.5


func set_editing(enabled: bool) -> void:
	editing = enabled
	freeze = enabled
	if enabled:
		linear_velocity = Vector2.ZERO
		angular_velocity = 0.0
	queue_redraw()


func _on_body_entered(body: Node) -> void:
	if editing:
		return
	if body is RigidBody2D and body.name == "Marble":
		emit_signal("marble_touched")


func _draw() -> void:
	var hs: float = SIZE * 0.5
	var rect: Rect2 = Rect2(Vector2(-hs, -hs), Vector2(SIZE, SIZE))
	draw_rect(rect, FILL_COLOR, true)
	draw_rect(rect, OUTLINE_COLOR, false, 2.0)
	draw_circle(Vector2(-6, -4), 3.0, HAZARD_COLOR)
	draw_circle(Vector2(6, -4), 3.0, HAZARD_COLOR)
	draw_line(Vector2(-5, 6), Vector2(5, 6), HAZARD_COLOR, 2.0)
