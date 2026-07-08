extends Node2D

const HANDLE_RADIUS: float = 8.0
const HIT_RADIUS: float = 14.0
const FLOOR_Y: float = 700.0
const ZONE_FILL: Color = Color(0.9, 0.2, 0.2, 0.35)
const ZONE_OUTLINE: Color = Color(0.7, 0.05, 0.05, 0.9)
const BOULDER_FILL: Color = Color(1.0, 0.55, 0.1, 0.85)
const BOULDER_OUTLINE: Color = Color(0.55, 0.25, 0.0, 1.0)
const START_MARKER_COLOR: Color = Color(0.3, 0.85, 1.0, 0.55)

@export var collision_polygon_path: NodePath
@export var fill_polygon_path: NodePath

var top_points: PackedVector2Array = PackedVector2Array()
var no_draw_zones: Array = []
var boulders: Array = []
var locked_indices: Array = []
var start_marker: Vector2 = Vector2.ZERO
var dragged_index: int = -1
var editing: bool = true
var _locked_indices_snapshot: Array = []

@onready var collision_polygon: CollisionPolygon2D = get_node(collision_polygon_path)
@onready var fill_polygon: Polygon2D = get_node(fill_polygon_path)


func _ready() -> void:
	if top_points.is_empty():
		var poly: PackedVector2Array = collision_polygon.polygon
		if poly.size() >= 4:
			top_points = poly.slice(0, poly.size() - 2)
		else:
			top_points = PackedVector2Array([Vector2(100, 300), Vector2(1150, 560)])
		_rebuild_polygon()


func load_level(level: Dictionary) -> void:
	top_points = (level.default_track as PackedVector2Array).duplicate()
	no_draw_zones = level.no_draw_zones.duplicate()
	boulders = level.get("boulders", []).duplicate()
	locked_indices = level.get("locked_indices", []).duplicate()
	start_marker = level.start
	dragged_index = -1
	for i in top_points.size():
		if i in locked_indices:
			continue
		top_points[i] = _push_out_of_blockers(top_points[i])
	_rebuild_polygon()
	queue_redraw()


func snapshot_track() -> PackedVector2Array:
	_locked_indices_snapshot = locked_indices.duplicate()
	return top_points.duplicate()


func restore_track(snapshot: PackedVector2Array) -> void:
	top_points = snapshot.duplicate()
	locked_indices = _locked_indices_snapshot.duplicate()
	_rebuild_polygon()
	queue_redraw()


func destroy_in_radius(center: Vector2, radius: float) -> void:
	var kept: PackedVector2Array = PackedVector2Array()
	var kept_locks: Array = []
	for i in top_points.size():
		if top_points[i].distance_to(center) > radius:
			if i in locked_indices:
				kept_locks.append(kept.size())
			kept.append(top_points[i])
	top_points = kept
	locked_indices = kept_locks
	dragged_index = -1
	_rebuild_polygon()
	queue_redraw()


func set_editing(enabled: bool) -> void:
	editing = enabled
	dragged_index = -1
	queue_redraw()


func _draw() -> void:
	if not editing:
		return
	for zone in no_draw_zones:
		draw_rect(zone, ZONE_FILL, true)
		draw_rect(zone, ZONE_OUTLINE, false, 2.0)
	for boulder in boulders:
		draw_rect(boulder, BOULDER_FILL, true)
		draw_rect(boulder, BOULDER_OUTLINE, false, 2.0)
	if start_marker != Vector2.ZERO:
		draw_circle(start_marker, 16.0, START_MARKER_COLOR)
		draw_arc(start_marker, 16.0, 0.0, TAU, 32, Color(0.1, 0.4, 0.6, 0.9), 1.5, true)
	for i in top_points.size():
		var color: Color
		if i in locked_indices:
			color = Color(0.45, 0.45, 0.5)
		elif i == dragged_index:
			color = Color(1.0, 0.85, 0.2)
		else:
			color = Color(0.95, 0.95, 0.95)
		draw_circle(top_points[i], HANDLE_RADIUS, color)
		draw_arc(top_points[i], HANDLE_RADIUS, 0.0, TAU, 24, Color(0.1, 0.1, 0.1), 1.5, true)


func _unhandled_input(event: InputEvent) -> void:
	if not editing:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			var idx: int = _hit_test(get_global_mouse_position())
			if idx != -1:
				dragged_index = idx
				get_viewport().set_input_as_handled()
				queue_redraw()
		else:
			if dragged_index != -1:
				dragged_index = -1
				queue_redraw()
	elif event is InputEventMouseMotion and dragged_index != -1:
		var pos: Vector2 = get_global_mouse_position()
		pos.y = min(pos.y, FLOOR_Y - 20.0)
		pos = _push_out_of_blockers(pos)
		top_points[dragged_index] = pos
		_rebuild_polygon()
		queue_redraw()


func _hit_test(world_pos: Vector2) -> int:
	
	for i in top_points.size():
		if i in locked_indices:
			continue
		if world_pos.distance_to(top_points[i]) <= HIT_RADIUS:
			return i
	return -1


func _push_out_of_blockers(pos: Vector2) -> Vector2:
	pos = _push_out_of_rects(pos, no_draw_zones)
	pos = _push_out_of_rects(pos, boulders)
	return pos


func _push_out_of_zones(pos: Vector2) -> Vector2:
	return _push_out_of_rects(pos, no_draw_zones)


func _push_out_of_rects(pos: Vector2, rects: Array) -> Vector2:
	for rect in rects:
		if rect.has_point(pos):
			var dist_left: float = pos.x - rect.position.x
			var dist_right: float = (rect.position.x + rect.size.x) - pos.x
			var dist_top: float = pos.y - rect.position.y
			var dist_bottom: float = (rect.position.y + rect.size.y) - pos.y
			var min_dist: float = min(dist_left, min(dist_right, min(dist_top, dist_bottom)))
			if min_dist == dist_left:
				pos.x = rect.position.x - 1.0
			elif min_dist == dist_right:
				pos.x = rect.position.x + rect.size.x + 1.0
			elif min_dist == dist_top:
				pos.y = rect.position.y - 1.0
			else:
				pos.y = rect.position.y + rect.size.y + 1.0
	return pos


func _rebuild_polygon() -> void:
	if top_points.size() < 2:
		collision_polygon.polygon = PackedVector2Array()
		fill_polygon.polygon = PackedVector2Array()
		return
	var min_x: float = top_points[0].x
	var max_x: float = top_points[0].x
	for p in top_points:
		min_x = min(min_x, p.x)
		max_x = max(max_x, p.x)
	var full: PackedVector2Array = PackedVector2Array()
	full.append_array(top_points)
	full.append(Vector2(max_x, FLOOR_Y))
	full.append(Vector2(min_x, FLOOR_Y))
	collision_polygon.polygon = full
	fill_polygon.polygon = full


func get_start_position() -> Vector2:
	if start_marker != Vector2.ZERO:
		return start_marker
	if top_points.is_empty():
		return Vector2(130, 100)
	return Vector2(top_points[0].x + 30.0, top_points[0].y - 60.0)
