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
	
	Game.play_started.connect(func() -> void:
		hide()
	)
	Game.play_ended.connect(func() -> void:
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
		
		var tile_center_position: Vector2 = tile.position + Vector2(32, 32)
		draw_circle(tile_center_position, 8, color, false, 3)
		
		# Draw room transition stuff.
		if is_instance_valid(tile.room_transition):
			var target_position: Vector2 = Global.coords_to_position(tile.room_transition.coords)
			var target_center_position: Vector2 = target_position + Vector2(32, 32)
			
			draw_dashed_line(
				tile_center_position,
				target_center_position,
				color.darkened(0.2),
				2.0,
				4.0,
			)
			
			var arc_center: Vector2 = Vector2(
				(target_center_position.x + tile_center_position.x) / 2,
				(target_center_position.y + tile_center_position.y) / 2,
			)
			var radius: float = tile_center_position.distance_to(target_center_position) / 2
			var start_angle: float = (target_center_position - tile_center_position).angle()
			var end_angle: float = (tile_center_position - target_center_position).angle()
			if end_angle < 0:
				end_angle += TAU
			draw_arc(
				arc_center,
				radius,
				start_angle,
				end_angle,
				16,
				color.darkened(0.2),
				2,
			)
			
			draw_multiline([
				target_position + Vector2(16, 16),
				target_position + Vector2(48, 48),
				target_position + Vector2(48, 16),
				target_position + Vector2(16, 48),
			], color, 3)
			
			var font: Font = preload("res://assets/fonts/main.ttf")
			draw_string(
				font,
				target_position,
				"Target",
				HORIZONTAL_ALIGNMENT_CENTER,
				-1,
				18
			)
