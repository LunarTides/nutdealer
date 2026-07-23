extends ItemList

const TILE: PackedScene = preload("uid://cfme7hrx25bgv")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:	
	# TODO: Collapse instead of hiding.
	#Game.play_start.connect(func():
		#hide()
	#)
	#Game.play_end.connect(func():
		#show()
	#)
	
	Game.mode_changed.connect(func(old: Game.Mode, new: Game.Mode) -> void:
		visible = new == Game.Mode.DarkWorld
	)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_item_clicked(index: int, at_position: Vector2, mouse_button_index: int) -> void:
	var texture: Texture2D = get_item_icon(index)
	var tile: Tile = TILE.instantiate()
	tile.texture = texture
	
	CreatorPlaceTiles.start(tile)
	
	# Eraser
	if index == item_count - 1:
		CreatorPlaceTiles.should_erase = true


func _on_empty_clicked(at_position: Vector2, mouse_button_index: int) -> void:
	if Creator.mode == Creator.Mode.PlacingTile:
		Creator.mode = Creator.Mode.None
