extends Node

var screen_size: Vector2:
	get:
		return get_viewport().get_visible_rect().size

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	get_window().min_size = Vector2(1152, 640)
	
	# TODO: Remove. Enable creator.
	await get_tree().process_frame
	Creator.start()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func position_to_coords(pos: Vector2) -> Vector2i:
	return (pos / 64).floor()

func coords_to_position(coords: Vector2i) -> Vector2:
	return Vector2(coords * 64)

func align_to_grid(pos: Vector2) -> Vector2:
	return coords_to_position(position_to_coords(pos))
