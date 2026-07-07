extends ItemList

@export var tiles: Control

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Creator.tiles = tiles


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_item_clicked(index: int, at_position: Vector2, mouse_button_index: int) -> void:
	var texture = get_item_icon(index)
	Creator.start_tile_placing(texture)


func _on_empty_clicked(at_position: Vector2, mouse_button_index: int) -> void:
	if Creator.mode == Creator.Mode.PlacingTile:
		Creator.mode = Creator.Mode.None
