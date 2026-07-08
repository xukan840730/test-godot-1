extends Node2D

const Levels = preload("res://levels.gd")
const SpringScene = preload("res://spring.gd")
const BombScene = preload("res://bomb.gd")
const PoisonScene = preload("res://poison_block.gd")
const ShooterScene = preload("res://bomb_shooter.gd")
const SpikeScene = preload("res://spike.gd")
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
@onready var hud: CanvasLayer = $HUD
@onready var menu_button: Button = $HUD/Toolbar/MenuButton
@onready var main_menu: CanvasLayer = $MainMenu
@onready var level_grid: GridContainer = $MainMenu/Root/VBox/Columns/LevelsPanel/LevelsMargin/LevelsVBox/LevelsScroll/LevelGrid
@onready var guide_text: RichTextLabel = $MainMenu/Root/VBox/Columns/GuidePanel/GuideMargin/GuideVBox/GuideScroll/GuideText
@onready var menu_reset_button: Button = $MainMenu/Root/VBox/Footer/ResetButton

var bombs_root: Node2D
var poisons_root: Node2D
var shooters_root: Node2D
var spikes_root: Node2D
var current_mode: int = Mode.EDIT
var current_level_index: int = 0
var highest_unlocked_index: int = 0

var _track_snapshot: PackedVector2Array = PackedVector2Array()
var _level_boulders: Array = []
var _level_springs: Array = []
var _level_bombs: Array = []
var _level_poisons: Array = []
var _level_shooters: Array = []
var _level_spikes: Array = []


func _ready() -> void:
	bombs_root = Node2D.new()
	bombs_root.name = "Bombs"
	add_child(bombs_root)
	poisons_root = Node2D.new()
	poisons_root.name = "Poisons"
	add_child(poisons_root)
	shooters_root = Node2D.new()
	shooters_root.name = "Shooters"
	add_child(shooters_root)
	spikes_root = Node2D.new()
	spikes_root.name = "Spikes"
	add_child(spikes_root)
	_load_progress()
	win_panel.hide()
	goal.body_entered.connect(_on_goal_body_entered)
	marble.contact_monitor = true
	marble.max_contacts_reported = 8
	marble.body_entered.connect(_on_marble_body_entered)
	edit_button.pressed.connect(func(): _set_mode(Mode.EDIT))
	play_button.pressed.connect(func(): _set_mode(Mode.PLAY))
	next_button.pressed.connect(_on_next_pressed)
	reset_progress_button.pressed.connect(func(): reset_confirm_dialog.popup_centered())
	reset_confirm_dialog.confirmed.connect(_on_reset_progress_confirmed)
	_populate_level_dropdown()
	level_dropdown.item_selected.connect(_on_level_selected)
	menu_button.pressed.connect(_show_main_menu)
	menu_reset_button.pressed.connect(func(): reset_confirm_dialog.popup_centered())
	_populate_guide_text()
	_load_level(0)
	_show_main_menu()


func _show_main_menu() -> void:
	_populate_level_grid()
	main_menu.visible = true
	hud.visible = false


func _hide_main_menu() -> void:
	main_menu.visible = false
	hud.visible = true


func _populate_level_grid() -> void:
	for child in level_grid.get_children():
		child.queue_free()
	for i in Levels.LEVELS.size():
		var level: Dictionary = Levels.LEVELS[i]
		var unlocked: bool = i <= highest_unlocked_index
		var btn: Button = Button.new()
		btn.custom_minimum_size = Vector2(180, 56)
		btn.text = level.name if unlocked else "🔒 " + level.name
		btn.disabled = not unlocked
		btn.pressed.connect(func(): _on_menu_level_chosen(i))
		level_grid.add_child(btn)


func _on_menu_level_chosen(idx: int) -> void:
	_hide_main_menu()
	_load_level(idx)


func _populate_guide_text() -> void:
	guide_text.text = "[b]Goal[/b]: roll the marble into the green square.\n\n" \
		+ "[b]Edit / Play[/b]: top toolbar. Edit lets you reshape the track and place objects; Play runs the level. R or Enter restarts.\n\n" \
		+ "[b]Track[/b]: drag points in Edit mode to reshape the path. Pinned points (locked levels) can't be moved.\n\n" \
		+ "[b]Marble[/b]: red ball, affected by gravity. Don't let it leave the screen.\n\n" \
		+ "[b]Bombs[/b]\n" \
		+ "• [color=#999]Black[/color]: 3-second fuse, blasts terrain and most objects. Strength 1.\n" \
		+ "• [color=#b070d0]Purple[/color]: locked bombs with 3-second fuse. Strength 1.\n" \
		+ "• [color=#5090ff]Blue[/color]: shooter ammo. Explodes on contact with anything. Strength 1.\n" \
		+ "• [color=#f2d926]Yellow[/color]: 4-second fuse. Strength 2 — powerful enough to break poison blocks.\n" \
		+ "• [color=#ff8c00]Orange[/color]: 5-second fuse. Strength 3 — powerful enough to destroy orange springs.\n\n" \
		+ "[b]Bomb Shooters[/b]: dark grey square fires blue bombs every 1.5s. Drag to move; Q/E rotate ±45°, J/L rotate ±22.5°. [color=#b04dd0]Purple[/color] shooters are locked.\n\n" \
		+ "[b]Springs[/b]\n" \
		+ "• [color=#e0c020]Yellow[/color]: standard bounce.\n" \
		+ "• [color=#5090ff]Blue[/color]: small bounce.\n" \
		+ "• [color=#3fce5a]Green[/color]: standard bounce, resists strength-1 blasts. Strength-2 (yellow) bombs destroy it.\n" \
		+ "• [color=#e04040]Red[/color]: strong bounce.\n" \
		+ "• [color=#ff8c00]Orange[/color]: has a small bounce and resists strength-1 and 2 blasts. Strength-3 (orange) bombs destroy it.\n" \
		+ "Q/E rotate the spring 45 degrees.\n\n" \
		+ "[b]Boulders[/b]: orange blocks. Solid; can be destroyed by bomb blasts.\n\n" \
		+ "[b]Poison[/b]: purple block with a cyan face. Touching it resets the level. Only strength-2 (yellow) bombs can destroy it.\n\n" \
		+ "[b]Spikes[/b]\n" \
		+ "• [color=#d0d0d8]Light grey[/color]: resets the level on marble contact and instantly detonates any bomb that hits it. Bomb blasts destroy them.\n" \
		+ "• [color=#3a3a44]Dark grey[/color]: same as light grey, but indestructible — no bomb of any strength can remove them.\n\n" \
		+ "[b]Menu[/b]: the Menu toolbar button returns here."


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
	_level_boulders = level.get("boulders", []).duplicate()
	_level_springs = level.get("springs", []).duplicate()
	_level_bombs = level.get("bombs", []).duplicate()
	_level_poisons = level.get("poisons", []).duplicate()
	_level_shooters = level.get("shooters", []).duplicate()
	_level_spikes = level.get("spikes", []).duplicate()
	_track_snapshot = PackedVector2Array()
	_spawn_world()
	level_dropdown.selected = idx
	_set_mode(Mode.EDIT)


func _spawn_world() -> void:
	_spawn_boulders(_level_boulders)
	_spawn_springs(_level_springs, _level_boulders)
	_spawn_bombs(_level_bombs)
	_spawn_poisons(_level_poisons)
	_spawn_shooters(_level_shooters)
	_spawn_spikes(_level_spikes)


func _spawn_springs(positions: Array, boulder_rects: Array) -> void:
	for child in springs_root.get_children():
		child.queue_free()
	for entry in positions:
		var spring: Area2D = Area2D.new()
		spring.set_script(SpringScene)
		spring.boulders = boulder_rects
		if entry is Dictionary:
			spring.position = entry.get("pos", Vector2.ZERO)
			var v: String = entry.get("variant", "yellow")
			spring.variant = v
			spring.locked = entry.get("locked", false)
			if v == "blue":
				spring.bounce_strength = 700.0
			elif v == "red":
				spring.bounce_strength = 1700.0
			elif v == "orange":
				spring.bounce_strength = 700.0
			elif v == "green":
				spring.bounce_strength = 1100.0
			if entry.has("rotation"):
				spring.rotation = entry.rotation
		else:
			spring.position = entry
		springs_root.add_child(spring)


func _spawn_bombs(positions: Array) -> void:
	for child in bombs_root.get_children():
		child.queue_free()
	for entry in positions:
		var bomb: RigidBody2D = RigidBody2D.new()
		bomb.set_script(BombScene)
		var pos: Vector2 = entry if entry is Vector2 else entry.get("pos", Vector2.ZERO)
		bomb.position = pos
		if entry is Dictionary:
			bomb.variant = entry.get("variant", "black")
			bomb.locked = entry.get("locked", false)
		bomb.exploded.connect(_on_bomb_exploded)
		bombs_root.add_child(bomb)


func _spawn_poisons(positions: Array) -> void:
	for child in poisons_root.get_children():
		child.queue_free()
	for entry in positions:
		var poison: RigidBody2D = RigidBody2D.new()
		poison.set_script(PoisonScene)
		var pos: Vector2 = entry if entry is Vector2 else entry.get("pos", Vector2.ZERO)
		poison.position = pos
		if entry is Dictionary:
			poison.locked = entry.get("locked", false)
		poison.marble_touched.connect(_on_poison_touched)
		poisons_root.add_child(poison)


func _on_poison_touched() -> void:
	if current_mode == Mode.PLAY:
		_reset_marble()


func _spawn_spikes(positions: Array) -> void:
	for child in spikes_root.get_children():
		child.queue_free()
	for entry in positions:
		var spike: StaticBody2D = StaticBody2D.new()
		spike.set_script(SpikeScene)
		var pos: Vector2 = entry if entry is Vector2 else entry.get("pos", Vector2.ZERO)
		spike.position = pos
		if entry is Dictionary:
			spike.variant = entry.get("variant", "light")
			if entry.has("rotation"):
				spike.rotation = entry.rotation
			elif entry.has("rotation_degrees"):
				spike.rotation_degrees = entry.rotation_degrees
		spike.marble_touched.connect(_on_poison_touched)
		spikes_root.add_child(spike)


func _spawn_shooters(positions: Array) -> void:
	for child in shooters_root.get_children():
		child.queue_free()
	for entry in positions:
		var shooter: Node2D = Node2D.new()
		shooter.set_script(ShooterScene)
		var pos: Vector2 = entry if entry is Vector2 else entry.get("pos", Vector2.ZERO)
		shooter.position = pos
		if entry is Dictionary:
			shooter.locked = entry.get("locked", false)
			if entry.has("rotation"):
				shooter.rotation = entry.rotation
			elif entry.has("rotation_degrees"):
				shooter.rotation_degrees = entry.rotation_degrees
		shooter.fire_bomb.connect(_on_shooter_fire)
		shooters_root.add_child(shooter)


func _on_shooter_fire(spawn_pos: Vector2, velocity: Vector2) -> void:
	if current_mode != Mode.PLAY:
		return
	var bomb: RigidBody2D = RigidBody2D.new()
	bomb.set_script(BombScene)
	bomb.position = spawn_pos
	bomb.variant = "blue"
	bomb.exploded.connect(_on_bomb_exploded)
	bombs_root.add_child(bomb)
	bomb.set_editing(false)
	bomb.linear_velocity = velocity
	bomb.gravity_scale = 0.0
	bomb.linear_damp = 0.0
	bomb.angular_damp = 0.0


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
	if m == Mode.EDIT:
		if _track_snapshot.size() > 0:
			_restore_world_to_level()
		for spring in springs_root.get_children():
			if spring.has_method("set_editing"):
				spring.set_editing(true)
		for bomb in bombs_root.get_children():
			if bomb.has_method("disarm"):
				bomb.disarm()
			if bomb.has_method("set_editing"):
				bomb.set_editing(true)
		for poison in poisons_root.get_children():
			if poison.has_method("set_editing"):
				poison.set_editing(true)
		for shooter in shooters_root.get_children():
			if shooter.has_method("set_editing"):
				shooter.set_editing(true)
		for spike in spikes_root.get_children():
			if spike.has_method("set_editing"):
				spike.set_editing(true)
		marble.freeze = true
		marble.linear_velocity = Vector2.ZERO
		marble.angular_velocity = 0.0
		marble.hide()
		track_editor.set_editing(true)
		edit_button.disabled = true
		play_button.disabled = false
	else:
		_track_snapshot = track_editor.snapshot_track()
		for spring in springs_root.get_children():
			if spring.has_method("set_editing"):
				spring.set_editing(false)
		for bomb in bombs_root.get_children():
			if bomb.has_method("set_editing"):
				bomb.set_editing(false)
			if bomb.has_method("arm"):
				bomb.arm()
		for poison in poisons_root.get_children():
			if poison.has_method("set_editing"):
				poison.set_editing(false)
		for shooter in shooters_root.get_children():
			if shooter.has_method("set_editing"):
				shooter.set_editing(false)
		for spike in spikes_root.get_children():
			if spike.has_method("set_editing"):
				spike.set_editing(false)
		track_editor.set_editing(false)
		_teleport_marble(track_editor.get_start_position())
		marble.show()
		marble.freeze = false
		edit_button.disabled = false
		play_button.disabled = false


func _restore_world_to_level() -> void:
	if _track_snapshot.size() > 0:
		track_editor.restore_track(_track_snapshot)
		_track_snapshot = PackedVector2Array()
	_spawn_world()


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


func _on_marble_body_entered(body: Node) -> void:
	if current_mode != Mode.PLAY:
		return
	if body is StaticBody2D and body.get_script() == SpikeScene:
		_reset_marble()


func _on_bomb_exploded(center: Vector2, radius: float, strength: int) -> void:
	track_editor.destroy_in_radius(center, radius)
	for spring in springs_root.get_children():
		if spring.variant == "orange" and strength < 3:
			continue
		if spring.variant == "green" and strength < 2:
			continue
		if spring.global_position.distance_to(center) <= radius:
			spring.queue_free()
	var surviving_boulders: Array = []
	for child in boulders_root.get_children():
		if _boulder_in_blast(child, center, radius):
			child.queue_free()
		else:
			surviving_boulders.append(child)
	for spike in spikes_root.get_children():
		if spike.variant == "dark":
			continue
		if spike.global_position.distance_to(center) <= radius:
			spike.queue_free()
	if strength >= 2:
		for poison in poisons_root.get_children():
			if poison.global_position.distance_to(center) <= radius:
				poison.queue_free()
	if current_mode == Mode.PLAY and not marble.freeze:
		marble.sleeping = false
	for spring in springs_root.get_children():
		if "boulders" in spring:
			var rects: Array = []
			for b in surviving_boulders:
				var shape_node: CollisionShape2D = b.get_node_or_null("CollisionShape2D")
				if shape_node == null:
					for c in b.get_children():
						if c is CollisionShape2D:
							shape_node = c
							break
				if shape_node and shape_node.shape is RectangleShape2D:
					var size: Vector2 = (shape_node.shape as RectangleShape2D).size
					rects.append(Rect2(b.global_position - size * 0.5, size))
			spring.boulders = rects


func _boulder_in_blast(body: Node, center: Vector2, radius: float) -> bool:
	var shape_node: CollisionShape2D = body.get_node_or_null("CollisionShape2D")
	if shape_node == null:
		for c in body.get_children():
			if c is CollisionShape2D:
				shape_node = c
				break
	if shape_node == null or not shape_node.shape is RectangleShape2D:
		return body.global_position.distance_to(center) <= radius
	var size: Vector2 = (shape_node.shape as RectangleShape2D).size
	var rect: Rect2 = Rect2(body.global_position - size * 0.5, size)
	var closest: Vector2 = Vector2(
		clamp(center.x, rect.position.x, rect.position.x + rect.size.x),
		clamp(center.y, rect.position.y, rect.position.y + rect.size.y)
	)
	return closest.distance_to(center) <= radius


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
	if main_menu.visible:
		_populate_level_grid()
	_load_level(0)


func _unhandled_input(event: InputEvent) -> void:
	if current_mode != Mode.PLAY:
		return
	if event.is_action_pressed("ui_accept") or (event is InputEventKey and event.pressed and event.keycode == KEY_R):
		_reset_marble()


func _reset_marble() -> void:
	if _track_snapshot.size() > 0:
		_restore_world_to_level()
		for spring in springs_root.get_children():
			if spring.has_method("set_editing"):
				spring.set_editing(false)
		for bomb in bombs_root.get_children():
			if bomb.has_method("set_editing"):
				bomb.set_editing(false)
		for poison in poisons_root.get_children():
			if poison.has_method("set_editing"):
				poison.set_editing(false)
		for shooter in shooters_root.get_children():
			if shooter.has_method("set_editing"):
				shooter.set_editing(false)
	else:
		_spawn_poisons(_level_poisons)
		_spawn_shooters(_level_shooters)
		_spawn_spikes(_level_spikes)
		for poison in poisons_root.get_children():
			if poison.has_method("set_editing"):
				poison.set_editing(false)
		for shooter in shooters_root.get_children():
			if shooter.has_method("set_editing"):
				shooter.set_editing(false)
		for spike in spikes_root.get_children():
			if spike.has_method("set_editing"):
				spike.set_editing(false)
		# also clear in-flight blue bombs
		for bomb in bombs_root.get_children():
			if bomb.variant == "blue":
				bomb.queue_free()
	for bomb in bombs_root.get_children():
		if bomb.has_method("arm"):
			bomb.arm()
	_track_snapshot = track_editor.snapshot_track()
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
