extends RigidBody2D

const RADIUS: float = 18.0
const BLAST_RADIUS: float = 90.0
const FUSE_SECONDS: float = 3.0
const BLACK_BODY: Color = Color(0.15, 0.15, 0.18, 1.0)
const PURPLE_BODY: Color = Color(0.55, 0.2, 0.7, 1.0)
const BLUE_BODY: Color = Color(0.2, 0.5, 1.0, 1.0)
const FUSE_COLOR: Color = Color(0.85, 0.85, 0.85, 1.0)
const SPARK_COLOR: Color = Color(1.0, 0.7, 0.1, 1.0)
const TEXT_COLOR: Color = Color(1.0, 1.0, 1.0, 1.0)

signal exploded(center: Vector2, radius: float)

var variant: String = "black"
var locked: bool = false

var armed: bool = false
var fuse_remaining: float = FUSE_SECONDS
var dragging: bool = false
var drag_offset: Vector2 = Vector2.ZERO
var hovered: bool = false
var editing: bool = true
var exploded_already: bool = false


func _ready() -> void:
	var shape: CollisionShape2D = CollisionShape2D.new()
	var circle: CircleShape2D = CircleShape2D.new()
	circle.radius = RADIUS
	shape.shape = circle
	add_child(shape)
	freeze = true
	linear_damp = 0.4
	angular_damp = 0.5
	contact_monitor = true
	max_contacts_reported = 4
	body_entered.connect(_on_body_entered)
	set_process(true)


func _on_body_entered(_body: Node) -> void:
	if variant != "blue" or exploded_already or editing:
		return
	explode_now()


func explode_now() -> void:
	if exploded_already or editing:
		return
	exploded_already = true
	armed = false
	emit_signal("exploded", global_position, BLAST_RADIUS)
	queue_free()


func arm() -> void:
	armed = true
	fuse_remaining = FUSE_SECONDS
	exploded_already = false
	queue_redraw()


func disarm() -> void:
	armed = false
	fuse_remaining = FUSE_SECONDS
	exploded_already = false
	visible = true
	queue_redraw()


func set_editing(enabled: bool) -> void:
	editing = enabled
	dragging = false
	freeze = enabled
	if enabled:
		linear_velocity = Vector2.ZERO
		angular_velocity = 0.0
	queue_redraw()


func _process(delta: float) -> void:
	if variant == "blue":
		return
	if armed and not exploded_already:
		fuse_remaining = max(0.0, fuse_remaining - delta)
		queue_redraw()
		if fuse_remaining <= 0.0:
			exploded_already = true
			armed = false
			emit_signal("exploded", global_position, BLAST_RADIUS)
			queue_free()


func _draw() -> void:
	var body_color: Color = BLACK_BODY
	if variant == "purple":
		body_color = PURPLE_BODY
	elif variant == "blue":
		body_color = BLUE_BODY
	draw_circle(Vector2.ZERO, RADIUS, body_color)
	draw_arc(Vector2.ZERO, RADIUS, 0.0, TAU, 28, Color(0.0, 0.0, 0.0, 1.0), 1.5, true)
	var fuse_top: Vector2 = Vector2(0, -RADIUS)
	var fuse_tip: Vector2 = Vector2(6, -RADIUS - 10)
	draw_line(fuse_top, fuse_tip, FUSE_COLOR, 2.0)
	if variant == "blue":
		draw_circle(fuse_tip, 4.0, SPARK_COLOR)
		if editing and hovered and not locked:
			draw_arc(Vector2.ZERO, RADIUS + 3.0, 0.0, TAU, 28, Color(1.0, 0.4, 0.0, 1.0), 2.0, true)
		return
	if armed:
		draw_circle(fuse_tip, 4.0, SPARK_COLOR)
		var seconds_left: int = int(ceil(fuse_remaining))
		var font: Font = ThemeDB.fallback_font
		var text: String = str(seconds_left)
		var text_size: Vector2 = font.get_string_size(text, HORIZONTAL_ALIGNMENT_CENTER, -1, 16)
		draw_string(font, Vector2(-text_size.x * 0.5, 5), text, HORIZONTAL_ALIGNMENT_CENTER, -1, 16, TEXT_COLOR)
	if editing and hovered and not locked:
		draw_arc(Vector2.ZERO, RADIUS + 3.0, 0.0, TAU, 28, Color(1.0, 0.4, 0.0, 1.0), 2.0, true)


func _unhandled_input(event: InputEvent) -> void:
	if not editing or locked:
		return
	if event is InputEventMouseMotion:
		var mouse: Vector2 = get_global_mouse_position()
		var was_hovered: bool = hovered
		hovered = mouse.distance_to(global_position) <= RADIUS
		if hovered != was_hovered:
			queue_redraw()
		if dragging:
			global_position = get_global_mouse_position() + drag_offset
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed and hovered:
			dragging = true
			drag_offset = global_position - get_global_mouse_position()
			get_viewport().set_input_as_handled()
		elif not event.pressed:
			dragging = false
