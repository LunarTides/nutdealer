extends Node

const TILE: PackedScene = preload("uid://cfme7hrx25bgv")

var tile: Tile
var tile_texture_button: TextureButton
var tile_last_placed_position: Vector2i

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Creator.mode_changed.connect(func(old: Creator.Mode, new: Creator.Mode) -> void:
		# Delete the pending tile when the creator mode is changed.
		if is_instance_valid(tile_texture_button):
			tile_texture_button.queue_free()
	)

func start(tile_to_place: Tile) -> void:
	if not is_instance_valid(tile_to_place):
		push_error("Placing tile without proper tile")
		return
	
	Creator.mode = Creator.Mode.PlacingTile
	tile = tile_to_place
	create_hovering_tile()

func create_hovering_tile() -> void:
	tile_texture_button = TextureButton.new()
	tile_texture_button.texture_normal = tile.texture
	
	tile_texture_button.button_down.connect(func() -> void:
		place_current_tile()
		create_hovering_tile()
	, ConnectFlags.CONNECT_ONE_SHOT)
	
	tile_texture_button.gui_input.connect(func(event: InputEvent) -> void:
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			Creator.mode = Creator.Mode.None
			tile_texture_button.queue_free()
	)
	
	get_tree().root.add_child(tile_texture_button)

func place_current_tile() -> void:
	var coords: Vector2i = Global.position_to_coords(tile_texture_button.global_position)
	var existing_tile: Tile = Game.tiles.get_tile_on(coords)
	if existing_tile and existing_tile.id == tile.id:
		# We're about to place a duplicate tile on this coord.
		# Don't do this.
		tile_texture_button.queue_free()
		return
	
	# Create a Tile
	tile.global_position = tile_texture_button.global_position
	Game.tiles.add_child(tile)
	tile_last_placed_position = coords
	
	var new_tile: Tile = tile.clone()
	
	# Have to set owner after duplicating otherwise error.
	tile.owner = Game.tiles
	tile = new_tile
	
	# Prepare new tile.
	tile_texture_button.queue_free()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if Creator.mode != Creator.Mode.PlacingTile:
		return
	
	if not is_instance_valid(tile_texture_button):
		push_error("Placing tile without proper tile_texture_button")
		Creator.mode = Creator.Mode.None
		return
	
	var mouse: Vector2 = tile_texture_button.get_global_mouse_position()	
	tile_texture_button.global_position = Global.align_to_grid(mouse)

func _input(event: InputEvent) -> void:
	if Creator.mode != Creator.Mode.PlacingTile or not is_instance_valid(tile_texture_button):
		return
	
	if event is InputEventMouseMotion and not event.relative.is_zero_approx():
		if event.button_mask & MOUSE_BUTTON_LEFT == MOUSE_BUTTON_LEFT:
			# When moving the mouse while the left mouse button is pressed down, place tiles.
			var mouse: Vector2 = Global.mouse_position
			var pos: Vector2i = Global.position_to_coords(mouse)
			
			if pos != tile_last_placed_position:
				tile_texture_button.global_position = Global.coords_to_position(pos)
				place_current_tile()
				create_hovering_tile()
