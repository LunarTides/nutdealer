extends Control
class_name CreatorTiles

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func is_tile_on(coords: Vector2i) -> bool:
	for tile: CreatorTile in get_children():
		if tile.coords == coords:
			return true
	
	return false

func get_tile_on(coords: Vector2i) -> CreatorTile:
	for tile: CreatorTile in get_children():
		if tile.coords == coords:
			return tile
	
	return null
