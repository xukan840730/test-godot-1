extends Area2D

const WIDTH: float = 80.0
const HEIGHT: float = 24.0
const YELLOW_BODY: Color = Color(1.0, 0.85, 0.1, 1.0)
const YELLOW_COIL: Color = Color(0.7, 0.55, 0.0, 1.0)
const YELLOW_OUTLINE: Color = Color(0.4, 0.3, 0.0, 1.0)
const BLUE_BODY: Color = Color(0.45, 0.7, 1.0, 1.0)
const BLUE_COIL: Color = Color(0.1, 0.35, 0.8, 1.0)
const BLUE_OUTLINE: Color = Color(0.0, 0.15, 0.45, 1.0)
const RED_BODY: Color = Color(1.0, 0.25, 0.25, 1.0)
const RED_COIL: Color = Color(0.7, 0.1, 0.1, 1.0)
const RED_OUTLINE: Color = Color(0.4, 0.0, 0.0, 1.0)
const ORANGE_BODY: Color = Color(1.0, 0.55, 0.0, 1.0)
const ORANGE_COIL: Color = Color(0.7, 0.35, 0.0, 1.0)
const ORANGE_OUTLINE: Color = Color(0.4, 0.2, 0.0, 1.0)

@export var bounce_strength: float = 1100.0
var variant: String = "yellow"
var boulders: Array = []
var locked: bool = false

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
	var body_color: Color = YELLOW_BODY
	var coil_color: Color = YELLOW_COIL
	var base_outline: Color = YELLOW_OUTLINE
	if variant == "blue":
		body_color = BLUE_BODY
		coil_color = BLUE_COIL
		base_outline = BLUE_OUTLINE
	elif variant == "red":
		body_color = RED_BODY
		coil_color = RED_COIL
		base_outline = RED_OUTLINE
	elif variant == "orange":
		body_color = ORANGE_BODY
		coil_color = ORANGE_COIL
		base_outline = ORANGE_OUTLINE
	draw_rect(rect, body_color, true)
	var outline_color: Color = Color(1.0, 0.4, 0.0, 1.0) if (editing and hovered) else base_outline
	var outline_width: float = 3.0 if (editing and hovered) else 2.0
	draw_rect(rect, outline_color, false, outline_width)
	var coil_count: int = 4
	for i in coil_count:
		var t: float = float(i + 1) / float(coil_count + 1)
		var y: float = top + (bottom - top) * t
		draw_line(Vector2(-hw + 6, y), Vector2(hw - 6, y), coil_color, 2.0)
	var arrow_y: float = top - 14.0
	draw_line(Vector2(0, arrow_y + 6), Vector2(0, arrow_y - 8), Color(0.2, 0.2, 0.2, 0.7), 2.0)
	draw_line(Vector2(0, arrow_y - 8), Vector2(-4, arrow_y - 4), Color(0.2, 0.2, 0.2, 0.7), 2.0)
	draw_line(Vector2(0, arrow_y - 8), Vector2(4, arrow_y - 4), Color(0.2, 0.2, 0.2, 0.7), 2.0)


func _input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if not editing or locked:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		dragging = true
		drag_offset = global_position - get_global_mouse_position()
		get_viewport().set_input_as_handled()


func _unhandled_input(event: InputEvent) -> void:
	if not editing or locked:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
		dragging = false
	elif event is InputEventMouseMotion and dragging:
		global_position = _push_out_of_boulders(get_global_mouse_position() + drag_offset)
	elif hovered and event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_Q:
			rotation_degrees -= 45.0
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_E:
			rotation_degrees += 45.0
			get_viewport().set_input_as_handled()


func _push_out_of_boulders(pos: Vector2) -> Vector2:
	var hw: float = WIDTH * 0.5
	var hh: float = HEIGHT * 0.5
	for rect in boulders:
		var expanded: Rect2 = Rect2(rect.position - Vector2(hw, hh), rect.size + Vector2(WIDTH, HEIGHT))
		if expanded.has_point(pos):
			var dist_left: float = pos.x - expanded.position.x
			var dist_right: float = (expanded.position.x + expanded.size.x) - pos.x
			var dist_top: float = pos.y - expanded.position.y
			var dist_bottom: float = (expanded.position.y + expanded.size.y) - pos.y
			var min_dist: float = min(dist_left, min(dist_right, min(dist_top, dist_bottom)))
			if min_dist == dist_left:
				pos.x = expanded.position.x - 1.0
			elif min_dist == dist_right:
				pos.x = expanded.position.x + expanded.size.x + 1.0
			elif min_dist == dist_top:
				pos.y = expanded.position.y - 1.0
			else:
				pos.y = expanded.position.y + expanded.size.y + 1.0
	return pos
