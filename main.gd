extends Node2D

const Levels = preload("res://levels.gd")
const SpringScene = preload("res://spring.gd")
const SAVE_PATH: String = "user://progress.save"

enum Mode { EDIT, PLAY }

@onready var marble: RigidBody2D = $Marble
@onready var goal: Area2D = $Goal
@onready var boulders_root: Node2D = $Boulders
@onready var springs_root: Node2D = $Springs
@onready var win_panel: VBoxContainer = $HUD/WinPanel
@onready var win_label: Label = $HUD/WinPanel/WinLabel
@onready var next_button: Button = $HUD/WinPanel/NextButton
@onready var track_editor: Node = $TrackEditor
@onready var edit_button: Button = $HUD/Toolbar/EditButton
@onready var play_button: Button = $HUD/Toolbar/PlayButton
@onready var level_dropdown: OptionButton = $HUD/Toolbar/LevelDropdown
@onready var reset_progress_button: Button = $HUD/Toolbar/ResetProgressButton
@onready var reset_confirm_dialog: ConfirmationDialog = $HUD/ResetConfirmDialog

var current_mode: int = Mode.EDIT
var current_level_index: int = 0
var highest_unlocked_index: int = 0


func _ready() -> void:
	_load_progress()
	win_panel.hide()
	goal.body_entered.connect(_on_goal_body_entered)
	edit_button.pressed.connect(func(): _set_mode(Mode.EDIT))
	play_button.pressed.connect(func(): _set_mode(Mode.PLAY))
	next_button.pressed.connect(_on_next_pressed)
	reset_progress_button.pressed.connect(func(): reset_confirm_dialog.popup_centered())
	reset_confirm_dialog.confirmed.connect(_on_reset_progress_confirmed)
	_populate_level_dropdown()
	level_dropdown.item_selected.connect(_on_level_selected)
	_load_level(0)


func _populate_level_dropdown() -> void:
	level_dropdown.clear()
	for i in Levels.LEVELS.size():
		var level: Dictionary = Levels.LEVELS[i]
		var label: String = level.name if i <= highest_unlocked_index else "🔒 " + level.name
		level_dropdown.add_item(label, i)
		level_dropdown.set_item_disabled(i, i > highest_unlocked_index)


func _on_level_selected(idx: int) -> void:
	if idx > highest_unlocked_index:
		level_dropdown.selected = current_level_index
		return
	_load_level(idx)


func _load_level(idx: int) -> void:
	current_level_index = idx
	var level: Dictionary = Levels.LEVELS[idx]
	track_editor.load_level(level)
	goal.position = level.goal
	_spawn_boulders(level.get("boulders", []))
	_spawn_springs(level.get("springs", []))
	level_dropdown.selected = idx
	_set_mode(Mode.EDIT)


func _spawn_springs(positions: Array) -> void:
	for child in springs_root.get_children():
		child.queue_free()
	for pos in positions:
		var spring: Area2D = Area2D.new()
		spring.set_script(SpringScene)
		spring.position = pos
		springs_root.add_child(spring)


func _spawn_boulders(rects: Array) -> void:
	for child in boulders_root.get_children():
		child.queue_free()
	for rect in rects:
		var body: StaticBody2D = StaticBody2D.new()
		body.position = rect.position + rect.size * 0.5
		var shape: CollisionShape2D = CollisionShape2D.new()
		var rect_shape: RectangleShape2D = RectangleShape2D.new()
		rect_shape.size = rect.size
		shape.shape = rect_shape
		body.add_child(shape)
		var visual: Polygon2D = Polygon2D.new()
		var hw: float = rect.size.x * 0.5
		var hh: float = rect.size.y * 0.5
		visual.polygon = PackedVector2Array([
			Vector2(-hw, -hh), Vector2(hw, -hh), Vector2(hw, hh), Vector2(-hw, hh)
		])
		visual.color = Color(1.0, 0.55, 0.1, 1.0)
		body.add_child(visual)
		boulders_root.add_child(body)


func _set_mode(m: int) -> void:
	current_mode = m
	win_panel.hide()
	for spring in springs_root.get_children():
		if spring.has_method("set_editing"):
			spring.set_editing(m == Mode.EDIT)
	if m == Mode.EDIT:
		marble.freeze = true
		marble.linear_velocity = Vector2.ZERO
		marble.angular_velocity = 0.0
		marble.hide()
		track_editor.set_editing(true)
		edit_button.disabled = true
		play_button.disabled = false
	else:
		track_editor.set_editing(false)
		_teleport_marble(track_editor.get_start_position())
		marble.show()
		marble.freeze = false
		edit_button.disabled = false
		play_button.disabled = false


func _teleport_marble(target_pos: Vector2) -> void:
	marble.linear_velocity = Vector2.ZERO
	marble.angular_velocity = 0.0
	var xform: Transform2D = Transform2D(0.0, target_pos)
	PhysicsServer2D.body_set_state(marble.get_rid(), PhysicsServer2D.BODY_STATE_TRANSFORM, xform)
	PhysicsServer2D.body_set_state(marble.get_rid(), PhysicsServer2D.BODY_STATE_LINEAR_VELOCITY, Vector2.ZERO)
	PhysicsServer2D.body_set_state(marble.get_rid(), PhysicsServer2D.BODY_STATE_ANGULAR_VELOCITY, 0.0)
	marble.global_position = target_pos
	marble.rotation = 0.0


func _on_goal_body_entered(body: Node) -> void:
	if current_mode == Mode.PLAY and body == marble:
		marble.freeze = true
		_on_level_won()


func _on_level_won() -> void:
	var was_locked: bool = current_level_index >= highest_unlocked_index
	if was_locked and current_level_index + 1 < Levels.LEVELS.size():
		highest_unlocked_index = current_level_index + 1
		_save_progress()
		_populate_level_dropdown()
		level_dropdown.selected = current_level_index
	var has_next: bool = current_level_index + 1 < Levels.LEVELS.size()
	win_label.text = "You won!" if has_next else "All levels complete!"
	next_button.visible = has_next
	win_panel.show()


func _on_next_pressed() -> void:
	var next_idx: int = current_level_index + 1
	if next_idx < Levels.LEVELS.size():
		_load_level(next_idx)


func _on_reset_progress_confirmed() -> void:
	highest_unlocked_index = 0
	_save_progress()
	_populate_level_dropdown()
	_load_level(0)


func _unhandled_input(event: InputEvent) -> void:
	if current_mode != Mode.PLAY:
		return
	if event.is_action_pressed("ui_accept") or (event is InputEventKey and event.pressed and event.keycode == KEY_R):
		_reset_marble()


func _reset_marble() -> void:
	_teleport_marble(track_editor.get_start_position())
	marble.freeze = false
	win_panel.hide()


func _load_progress() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		highest_unlocked_index = 0
		return
	var f: FileAccess = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if f == null:
		return
	highest_unlocked_index = f.get_32()
	f.close()
	highest_unlocked_index = clamp(highest_unlocked_index, 0, Levels.LEVELS.size() - 1)


func _save_progress() -> void:
	var f: FileAccess = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f == null:
		return
	f.store_32(highest_unlocked_index)
	f.close()
