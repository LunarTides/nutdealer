extends Node2D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	CreatorSelect.selection_changed.connect(func(old: Rect2i, new: Rect2i) -> void:
		queue_redraw()
	)
	CreatorSelect.selected_changed.connect(func(old: Array[Tile], new: Array[Tile]) -> void:
		queue_redraw()
	)
	CreatorSelect.selected_moved.connect(func(vector: Vector2i) -> void:
		queue_redraw()
	)
	
	Game.play_start.connect(func() -> void:
		hide()
	)
	Game.play_end.connect(func() -> void:
		show()
	)
	Game.tiles.child_exiting_tree.connect(func(node: Node) -> void:
		# Selected node is being deleted.
		if CreatorSelect.selected.has(node):
			queue_redraw()
	)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _draw() -> void:
	var color: Color = Color.LIGHT_YELLOW
	
	var filled: bool = false
	var width: int = -1 if filled else 3
	
	var rect: Rect2i = Room.coords_to_position(CreatorSelect.selection)
	if rect.size > Vector2i(0, 0):
		draw_rect(rect, color, filled, width, true)
	
	for tile: Tile in CreatorSelect.selected:
		if not tile.enabled:
			continue
		
		draw_circle(tile.position + Vector2(32, 32), 8, color, false, 3)
