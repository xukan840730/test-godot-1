extends StaticBody2D

const SIZE: float = 36.0
const FILL_COLOR: Color = Color(0.55, 0.55, 0.6, 1.0)
const TIP_COLOR: Color = Color(0.85, 0.85, 0.9, 1.0)
const OUTLINE_COLOR: Color = Color(0.1, 0.1, 0.15, 1.0)

signal marble_touched()

var editing: bool = true


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


func set_editing(enabled: bool) -> void:
	editing = enabled
	queue_redraw()


func _on_body_entered(body: Node) -> void:
	if editing:
		return
	if body is RigidBody2D:
		if body.name == "Marble":
			emit_signal("marble_touched")
			return
		if "variant" in body and body.has_method("explode_now"):
			body.explode_now()


func _draw() -> void:
	var hs: float = SIZE * 0.5
	var rect: Rect2 = Rect2(Vector2(-hs, -hs), Vector2(SIZE, SIZE))
	draw_rect(rect, FILL_COLOR, true)
	draw_rect(rect, OUTLINE_COLOR, false, 2.0)
	# single upward-pointing triangular tip centered on the top edge
	var base_left: Vector2 = Vector2(-hs * 0.7, -hs)
	var base_right: Vector2 = Vector2(hs * 0.7, -hs)
	var tip: Vector2 = Vector2(0, -hs - SIZE * 0.75)
	draw_polygon(PackedVector2Array([base_left, tip, base_right]),
		PackedColorArray([TIP_COLOR, TIP_COLOR, TIP_COLOR]))
	draw_line(base_left, tip, OUTLINE_COLOR, 1.5)
	draw_line(tip, base_right, OUTLINE_COLOR, 1.5)
