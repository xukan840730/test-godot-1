extends Area2D

const WIDTH: float = 80.0
const HEIGHT: float = 24.0
const BODY_COLOR: Color = Color(1.0, 0.85, 0.1, 1.0)
const COIL_COLOR: Color = Color(0.7, 0.55, 0.0, 1.0)
const OUTLINE_COLOR: Color = Color(0.4, 0.3, 0.0, 1.0)

@export var bounce_strength: float = 1100.0

var editing: bool = true
var dragging: bool = false
var drag_offset: Vector2 = Vector2.ZERO
var bounce_anim: float = 0.0
var hovered: bool = false


func _ready() -> void:
	var shape: CollisionShape2D = CollisionShape2D.new()
	var rect: RectangleShape2D = RectangleShape2D.new()
	rect.size = Vector2(WIDTH, HEIGHT)
	shape.shape = rect
	add_child(shape)
	body_entered.connect(_on_body_entered)
	mouse_entered.connect(func(): hovered = true; queue_redraw())
	mouse_exited.connect(func(): hovered = false; queue_redraw())
	monitoring = false
	input_pickable = true


func set_editing(enabled: bool) -> void:
	editing = enabled
	monitoring = not enabled
	dragging = false
	queue_redraw()


func _on_body_entered(body: Node) -> void:
	if editing:
		return
	if body is RigidBody2D:
		var rb: RigidBody2D = body
		var bounce_dir: Vector2 = Vector2.UP.rotated(rotation)
		var tangent: Vector2 = bounce_dir.orthogonal()
		var tangent_speed: float = rb.linear_velocity.dot(tangent) * 0.6
		rb.linear_velocity = tangent * tangent_speed + bounce_dir * bounce_strength
		bounce_anim = 1.0
		queue_redraw()


func _process(delta: float) -> void:
	if bounce_anim > 0.0:
		bounce_anim = max(0.0, bounce_anim - delta * 4.0)
		queue_redraw()


func _draw() -> void:
	var hw: float = WIDTH * 0.5
	var hh: float = HEIGHT * 0.5
	var squish: float = 1.0 - bounce_anim * 0.5
	var top: float = -hh * squish
	var bottom: float = hh
	var rect: Rect2 = Rect2(Vector2(-hw, top), Vector2(WIDTH, bottom - top))
	draw_rect(rect, BODY_COLOR, true)
	var outline_color: Color = Color(1.0, 0.4, 0.0, 1.0) if (editing and hovered) else OUTLINE_COLOR
	var outline_width: float = 3.0 if (editing and hovered) else 2.0
	draw_rect(rect, outline_color, false, outline_width)
	var coil_count: int = 4
	for i in coil_count:
		var t: float = float(i + 1) / float(coil_count + 1)
		var y: float = top + (bottom - top) * t
		draw_line(Vector2(-hw + 6, y), Vector2(hw - 6, y), COIL_COLOR, 2.0)
	var arrow_y: float = top - 14.0
	draw_line(Vector2(0, arrow_y + 6), Vector2(0, arrow_y - 8), Color(0.2, 0.2, 0.2, 0.7), 2.0)
	draw_line(Vector2(0, arrow_y - 8), Vector2(-4, arrow_y - 4), Color(0.2, 0.2, 0.2, 0.7), 2.0)
	draw_line(Vector2(0, arrow_y - 8), Vector2(4, arrow_y - 4), Color(0.2, 0.2, 0.2, 0.7), 2.0)


func _input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if not editing:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		dragging = true
		drag_offset = global_position - get_global_mouse_position()
		get_viewport().set_input_as_handled()


func _unhandled_input(event: InputEvent) -> void:
	if not editing:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
		dragging = false
	elif event is InputEventMouseMotion and dragging:
		global_position = get_global_mouse_position() + drag_offset
	elif hovered and event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_Q:
			rotation_degrees -= 45.0
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_E:
			rotation_degrees += 45.0
			get_viewport().set_input_as_handled()
