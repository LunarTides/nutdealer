extends Node

signal room_added(index: int)
signal room_updated(index: int, old: Rect2i, new: Rect2i)
signal room_deleted(index: int)

var bounds: Array[Rect2i]

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func add_room(rect: Rect2i) -> int:
	var index: int = bounds.size()
	bounds.append(rect)
	room_added.emit(index)
	return index

func update_room(index: int, rect: Rect2i) -> void:
	var old: Rect2i = bounds.get(index)
	if not old:
		return
	
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
	
	bounds[index] = rect
	room_updated.emit(index, old, rect)

func delete_room(index: int) -> int:
	bounds.remove_at(index)
	room_deleted.emit(bounds.size())
	return bounds.size()

func position_to_room_index(pos: Vector2) -> int:
	for i: int in range(bounds.size()):
		var bound: Rect2i = coords_to_position(bounds[i])
		if bound.has_point(pos):
			return i
	
	return -1

func coords_to_room_index(coords: Vector2i) -> int:
	return position_to_room_index(Global.coords_to_position(coords))

func coords_to_position(rect: Rect2i) -> Rect2i:
	rect.position *= 64
	rect.size *= 64
	return rect
