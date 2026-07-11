extends Node

signal play_start
signal play_end
signal room_changed(old_room_index: int, new_room_index: int)

const TILES: PackedScene = preload("uid://c810cm35ke6y5")
const TILE: PackedScene = preload("uid://cfme7hrx25bgv")
const PLAYER: PackedScene = preload("uid://bvxdrb5d24bxx")
const GAME_PAUSE_MENU: PackedScene = preload("uid://dic6f6j0grcf0")

var playing: bool = false:
	set(value):
		playing = value
		
		if playing:
			play_start.emit()
		else:
			play_end.emit()
var player: Player
var tiles: Tiles
var border_tiles: Node
var current_room: int = 0:
	set(value):
		var old: int = current_room
		current_room = value
		room_changed.emit(old, current_room)
var canvas_layer: CanvasLayer
var pause_menu: Control

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	setup_tiles()
	
	canvas_layer = CanvasLayer.new()
	add_child(canvas_layer)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func setup_tiles() -> void:
	tiles = TILES.instantiate()
	tiles.child_entered_tree.connect(func(node: Node) -> void:
		Creator.make_dirty()
	)
	tiles.child_exiting_tree.connect(func(node: Node) -> void:
		Creator.make_dirty()
	)
	add_child(tiles)
	
	border_tiles = Node.new()
	add_child(border_tiles)

func play_from(room_index: int) -> void:
	if room_index == -1:
		push_error("Must start in a room.")
		return
	
	if Room.amount < 1:
		push_error("This world has no rooms.")
		return
	
	# Disable tiles outside room.
	tiles.call_outside_room(room_index, func(tile: Tile) -> void:
		tile.disable()
	)
	
	playing = true
	current_room = room_index
	
	# Create pause menu.
	if is_instance_valid(pause_menu):
		pause_menu.queue_free()
	pause_menu = GAME_PAUSE_MENU.instantiate()
	canvas_layer.add_child(pause_menu)
	
	# Create player.
	if is_instance_valid(player):
		player.queue_free()
	player = PLAYER.instantiate()
	add_child(player)
	
	var room_bounds: Rect2i = Room.bounds[current_room]
	
	var success: bool = teleport_player_to_room_start_position()
	if not success:
		# No room start position. Position the player in the center of the room.
		@warning_ignore("integer_division")
		player.global_position = Global.coords_to_position(room_bounds.position + room_bounds.size / 2)
	
	constrain_player_to_current_room()

func stop_playing() -> void:
	playing = false
	player.queue_free()
	
	if is_instance_valid(pause_menu):
		pause_menu.queue_free()
	
	# Clear everything.
	CreatorSave.new_world()

func switch_room(room_index: int) -> void:
	# Get starting room from camera position.
	if room_index == -1:
		push_error("Must be a valid room.")
		return
	
	# Disable tiles inside old room.
	tiles.call_inside_room(current_room, func(tile: Tile) -> void:
		tile.disable()
	)
	# Enable tiles inside new room.
	tiles.call_inside_room(room_index, func(tile: Tile) -> void:
		tile.enable()
	)
	
	current_room = room_index
	
	# Move player.
	var success: bool = teleport_player_to_room_start_position()
	if not success:
		# No room start position. Position the player in the center of the room.
		var room_bounds: Rect2i = Room.bounds[current_room]
		
		@warning_ignore("integer_division")
		player.global_position = Global.coords_to_position(room_bounds.position + room_bounds.size / 2)
	
	constrain_player_to_current_room()

func teleport_player_to_room_start_position() -> bool:
	var old_position: Vector2 = player.global_position
	
	tiles.call_inside_room(current_room, func(tile: Tile) -> void:
		if tile.is_room_start_position:
			player.global_position = tile.global_position + Vector2(32, 32)
	)
	return player.global_position != old_position

func constrain_player_to_current_room() -> void:
	var bounds: Rect2i = Room.bounds[current_room]
	
	for col: int in range(bounds.size.x):
		for row: int in range(bounds.size.y):
			var coords: Vector2i = Vector2i(bounds.position.x + col, bounds.position.y + row)
			
			# Left-most column.
			if col == 0:
				var new_coords: Vector2i = coords
				new_coords.x -= 1
				create_border_tile(new_coords)
			# Right-most column.
			if col >= bounds.size.x - 1:
				var new_coords: Vector2i = coords
				new_coords.x += 1
				create_border_tile(new_coords)
			
			# First row.
			if row == 0:
				var new_coords: Vector2i = coords
				new_coords.y -= 1
				create_border_tile(new_coords)
			# Last row.
			if row >= bounds.size.y - 1:
				var new_coords: Vector2i = coords
				new_coords.y += 1
				create_border_tile(new_coords)

func create_border_tile(coords: Vector2i) -> Tile:
	var tile: Tile = TILE.instantiate()
	tile.is_solid = true
	#tile.texture = preload("res://icon.svg")
	
	# Delete tile when room changed, or play ended.
	room_changed.connect(func(old: int, new: int) -> void:
		if is_instance_valid(tile):
			tile.queue_free()
	, ConnectFlags.CONNECT_ONE_SHOT)
	play_end.connect(func() -> void:
		if is_instance_valid(tile):
			tile.queue_free()
	, ConnectFlags.CONNECT_ONE_SHOT)
	
	border_tiles.add_child(tile)
	tile.global_position = Global.coords_to_position(coords)
	tile.id = "border"
	
	return tile
