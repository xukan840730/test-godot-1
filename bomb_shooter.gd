extends Node2D

const SIZE: float = 38.0
const FIRE_INTERVAL: float = 1.5
const PROJECTILE_SPEED: float = 380.0
const BODY_COLOR: Color = Color(0.25, 0.25, 0.3, 1.0)
const BARREL_COLOR: Color = Color(0.4, 0.4, 0.45, 1.0)
const OUTLINE_COLOR: Color = Color(0.05, 0.05, 0.1, 1.0)
const ACCENT_COLOR: Color = Color(0.2, 0.5, 1.0, 1.0)
const LOCKED_BODY_COLOR: Color = Color(0.4, 0.15, 0.55, 1.0)
const LOCKED_BARREL_COLOR: Color = Color(0.6, 0.3, 0.75, 1.0)

signal fire_bomb(spawn_pos: Vector2, velocity: Vector2)

var editing: bool = true
var dragging: bool = false
var drag_offset: Vector2 = Vector2.ZERO
var hovered: bool = false
var fire_timer: float = 0.0
var locked: bool = false


func _ready() -> void:
	set_process(true)


func set_editing(enabled: bool) -> void:
	editing = enabled
	dragging = false
	fire_timer = FIRE_INTERVAL * 0.5
	queue_redraw()


func _process(delta: float) -> void:
	if editing:
		return
	fire_timer -= delta
	if fire_timer <= 0.0:
		fire_timer = FIRE_INTERVAL
		var dir: Vector2 = Vector2.RIGHT.rotated(rotation)
		var spawn_pos: Vector2 = global_position + dir * (SIZE * 0.6)
		emit_signal("fire_bomb", spawn_pos, dir * PROJECTILE_SPEED)


func _draw() -> void:
	var hs: float = SIZE * 0.5
	var body_color: Color = LOCKED_BODY_COLOR if locked else BODY_COLOR
	var barrel_color: Color = LOCKED_BARREL_COLOR if locked else BARREL_COLOR
	# body box
	var rect: Rect2 = Rect2(Vector2(-hs, -hs), Vector2(SIZE, SIZE))
	draw_rect(rect, body_color, true)
	draw_rect(rect, OUTLINE_COLOR, false, 2.0)
	# barrel pointing along +X (rotation rotates the whole node)
	var barrel: Rect2 = Rect2(Vector2(0, -6), Vector2(hs + 8, 12))
	draw_rect(barrel, barrel_color, true)
	draw_rect(barrel, OUTLINE_COLOR, false, 2.0)
	# blue accent dot showing it shoots blue bombs
	draw_circle(Vector2(hs + 2, 0), 3.5, ACCENT_COLOR)
	if editing and hovered and not locked:
		draw_rect(rect.grow(3.0), Color(1.0, 0.4, 0.0, 1.0), false, 2.0)


func _unhandled_input(event: InputEvent) -> void:
	if not editing or locked:
		return
	if event is InputEventMouseMotion:
		var mouse: Vector2 = get_global_mouse_position()
		var was_hovered: bool = hovered
		var hs: float = SIZE * 0.5
		# hit-test in unrotated local space
		var local_mouse: Vector2 = (mouse - global_position).rotated(-rotation)
		hovered = abs(local_mouse.x) <= hs + 8.0 and abs(local_mouse.y) <= hs
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
	elif hovered and event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_Q:
			rotation_degrees -= 45.0
			queue_redraw()
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_E:
			rotation_degrees += 45.0
			queue_redraw()
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_J:
			rotation_degrees -= 22.5
			queue_redraw()
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_L:
			rotation_degrees += 22.5
			queue_redraw()
			get_viewport().set_input_as_handled()
