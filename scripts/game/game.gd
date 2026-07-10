extends Node

signal play_start
signal play_end
signal room_changed(old_room_index: int, new_room_index: int)

const TILES: PackedScene = preload("uid://c810cm35ke6y5")
const TILE: PackedScene = preload("uid://cfme7hrx25bgv")

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

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	setup_tiles()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func setup_tiles() -> void:
	tiles = TILES.instantiate()
	add_child(tiles)
	
	border_tiles = Node.new()
	add_child(border_tiles)

func switch_room(room_index: int, player_pos: Vector2) -> void:
	# Get starting room from camera position.
	if room_index == -1:
		push_error("Must be a valid room.")
		return
	
	# Disable tiles inside old room.
	Game.tiles.call_inside_room(Game.current_room, func(tile: Tile) -> void:
		tile.disable()
	)
	# Enable tiles inside new room.
	Game.tiles.call_inside_room(room_index, func(tile: Tile) -> void:
		tile.enable()
	)
	
	Game.current_room = room_index
	
	# Move player.
	Game.player.global_position = player_pos
	
	constrain_player_to_current_room()

func constrain_player_to_current_room() -> void:
	# TODO: Fix 1 length corridors.
	var bounds: Rect2i = Room.bounds[current_room]
	
	for i: int in range(bounds.size.x):
		for v: int in range(bounds.size.y):
			var coords: Vector2i = Vector2i(i + bounds.position.x, v + bounds.position.y)
			var max_i: int = bounds.size.x - 1
			var max_v: int = bounds.size.y - 1
			
			if i == 0:
				coords.x -= 1
			elif v == 0:
				coords.y -= 1
			elif i >= max_i:
				coords.x += 1
			elif v >= max_v:
				coords.y += 1
			else:
				continue
			
			create_border_tile(coords)
			
			# Add missing tiles in each corner.
			if i == 0 and v == 0:
				var new_coords: Vector2i = coords
				new_coords.x += 1
				new_coords.y -= 1
				create_border_tile(new_coords)
			elif i == 0 and v == max_v or i == max_i and v == 0:
				var new_coords: Vector2i = coords
				new_coords.x += 1
				new_coords.y += 1
				create_border_tile(new_coords)
			elif i == max_i and v == max_v:
				var new_coords: Vector2i = coords
				new_coords.x -= 1
				new_coords.y += 1
				create_border_tile(new_coords)

func create_border_tile(coords: Vector2i) -> Tile:
	var tile: Tile = TILE.instantiate()
	tile.is_solid = true
	
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
