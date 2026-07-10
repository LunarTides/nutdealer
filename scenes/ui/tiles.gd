extends Control
class_name Tiles

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

static func delete_all() -> void:
	Game.tiles.queue_free()
	Game.border_tiles.queue_free()
	Game.setup_tiles()

func is_tile_on(coords: Vector2i) -> bool:
	for tile: Tile in get_children():
		if tile.coords == coords:
			return true
	
	return false

func get_tile_on(coords: Vector2i) -> Tile:
	for tile: Tile in get_children():
		if tile.coords == coords:
			return tile
	
	return null

func call_inside_room(room_index: int, callback: Callable) -> void:
	for tile: Tile in get_children():
		if Room.coords_to_room_index(tile.coords) == room_index:
			callback.call(tile)

func call_outside_room(room_index: int, callback: Callable) -> void:
	for tile: Tile in get_children():
		if Room.coords_to_room_index(tile.coords) != room_index:
			callback.call(tile)
