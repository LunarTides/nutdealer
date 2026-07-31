extends Node

const SELECT_SFX: AudioStream = preload("res://assets/audio/sfx/hurtsmall.wav")

signal selection_changed(old: Rect2i, new: Rect2i)
signal selected_changed(old: Array[Tile], new: Array[Tile])
signal selected_moved(vector: Vector2i)

var enabled: bool = false
var selected: Array[Tile] = []:
	set(value):
		if selected != value:
			var old: Array[Tile] = selected
			selected = value
			selected_changed.emit(old, selected)
var selection: Rect2i:
	set(value):
		if selection != value:
			var old: Rect2i = selection
			selection = value
			selection_changed.emit(old, selection)
var selection_creating: bool = false
var moving: bool = false
var add_to_selection_has_chosen: bool = false
var add_to_selection_should_remove: bool = false
var has_connected_signal_to_tiles: bool = false
var sfx_player: AudioStreamPlayer

var start_pos: Vector2
var previous_pos: Vector2

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	sfx_player = AudioStreamPlayer.new()
	add_child(sfx_player)
	
	Creator.creator_enabled.connect(func() -> void:
		start()
	)
	Creator.creator_disabled.connect(func() -> void:
		stop()
	)
	
	# Start disabled. Only enable when going into create mode.
	stop()

func start() -> void:
	process_mode = Node.PROCESS_MODE_INHERIT
	enabled = true
	
	if not has_connected_signal_to_tiles:
		Game.tiles.child_entered_tree.connect(func(node: Node) -> void:
			if node is not Tile:
				return
			
			# Add a node to selected when clicking on it.
			node.clicked.connect(func(button_index: MouseButton) -> void:
				if Creator.mode != Creator.Mode.Select:
					return
				
				if button_index == MOUSE_BUTTON_LEFT:
					if Input.is_key_pressed(KEY_SHIFT) or Input.is_key_pressed(KEY_CTRL):
						play_select_sfx()
						var tile_selected: bool = selected.has(node)
						if tile_selected:
							selected.erase(node)
							selected_changed.emit(selected, selected)
							return
						
						selected.append(node)
						selected_changed.emit(selected, selected)
					else:
						if selected.size() > 1 && selected.has(node):
							return
						
						selected = [node]
						play_select_sfx()
			)
		)
		Game.tiles.child_exiting_tree.connect(func(node: Node) -> void:
			if selected.has(node):
				selected.erase(node)
		)
		has_connected_signal_to_tiles = true

func stop() -> void:
	process_mode = Node.PROCESS_MODE_DISABLED
	enabled = false

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _input(event: InputEvent) -> void:
	if not enabled or Creator.mode != Creator.Mode.Select or Game.playing:
		return
	
	if event is InputEventMouseMotion:
		if event.button_mask & MOUSE_BUTTON_LEFT == MOUSE_BUTTON_LEFT:
			if not event.relative.is_zero_approx():
				if (selected.size() <= 0 or selection_creating) and not moving:
					# Create new selection.
					handle_new_selection(event)
				else:
					# Existing selection.
					if Input.is_key_pressed(KEY_SHIFT) or Input.is_key_pressed(KEY_CTRL):
						handle_add_to_selected(event)
					else:
						# Move
						handle_move_selected(event)
						moving = true
	
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.is_released():
				cleanup()
			else:
				# Delete selected when clicking on an empty tile.
				var tile: Tile = Game.tiles.get_tile_on_mouse()
				if not is_instance_valid(tile):
					selected = []
				elif not add_to_selection_has_chosen:
					add_to_selection_should_remove = selected.has(tile)
					add_to_selection_has_chosen = true
	
	if event.is_action_pressed(&"creator_delete"):
		# Delete all selected tiles.
		for tile: Tile in selected:
			tile.delete_with_explosion()
		selected = []

func cleanup() -> void:
	# Clear variables.
	start_pos = Vector2.ZERO
	previous_pos = Vector2.ZERO
	selection_creating = false
	moving = false
	add_to_selection_has_chosen = false
	add_to_selection_should_remove = false
	selection = Rect2i(0, 0, 0, 0)

func handle_new_selection(event: InputEventMouseMotion) -> void:
	if not selection_creating:
		selected = []
	
	var mouse_pos: Vector2 = Global.mouse_position
	if not start_pos:
		start_pos = mouse_pos
	
	var start_coords: Vector2i = Global.position_to_coords(start_pos)
	var previous_coords: Vector2i = Global.position_to_coords(previous_pos)
	var current_coords: Vector2i = Global.mouse_coords
	if start_coords == current_coords or current_coords == previous_coords:
		# The mouse hasn't moved a coord space. Don't create/update the selection yet.
		return
	
	var rect: Rect2i = Rect2i(start_coords, current_coords - start_coords)
	if rect.size.x < 0:
		# Negative size. This is unsupported in certain operations.
		# Move the position instead of resizing it.
		rect.position.x = rect.position.x + rect.size.x
		rect.size.x = abs(rect.size.x)
	if rect.size.y < 0:
		# Negative size. This is unsupported in certain operations.
		# Move the position instead of resizing it.
		rect.position.y = rect.position.y + rect.size.y
		rect.size.y = abs(rect.size.y)
	
	selection = rect
	selection_creating = true
	
	previous_pos = mouse_pos
	
	# Add tiles to selected.
	for tile: Tile in Game.tiles.get_all():
		if selected.has(tile):
			# The selection no longer includes this tile. Remove it from the selected list.
			if not selection.has_point(tile.coords):
				selected.erase(tile)
			
			continue
		
		if selection.has_point(tile.coords):
			selected.append(tile)
			play_select_sfx()

func handle_move_selected(event: InputEventMouseMotion) -> void:
	var mouse_pos: Vector2 = Global.mouse_position
	
	if not start_pos:
		start_pos = mouse_pos
	if not previous_pos:
		previous_pos = mouse_pos
	
	var start_coords: Vector2i = Global.position_to_coords(start_pos)
	var current_coords: Vector2i = Global.position_to_coords(mouse_pos)
	var previous_coords: Vector2i = Global.position_to_coords(previous_pos)
	if current_coords == previous_coords:
		# The mouse hasn't moved a coord space. Don't create/update the selection yet.
		return
	
	var a: Vector2i = current_coords - start_coords
	var b: Vector2i = previous_coords - start_coords
	
	if selection.size != Vector2i(0, 0):
		selection.position += a - b
	
	for tile: Tile in selected:
		tile.coords += a - b
	
	selected_moved.emit(a - b)
	previous_pos = mouse_pos

func handle_add_to_selected(event: InputEvent) -> void:
	var tile: Tile = Game.tiles.get_tile_on_mouse()
	if not is_instance_valid(tile):
		return
	
	var tile_selected: bool = selected.has(tile)
	
	if add_to_selection_should_remove:
		if tile_selected:
			play_select_sfx()
		
		selected.erase(tile)
	elif not tile_selected:
		selected.append(tile)
		play_select_sfx()
	
	selected_changed.emit(selected, selected)

func play_select_sfx() -> void:
	sfx_player.stream = SELECT_SFX
	sfx_player.volume_linear = 0.75
	sfx_player.pitch_scale = randf_range(0.75, 1.25)
	sfx_player.play()
	
	await sfx_player.finished
	sfx_player.volume_linear = 1.0
	sfx_player.pitch_scale = 1.0
