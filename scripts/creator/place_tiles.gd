extends Node

const TILE: PackedScene = preload("uid://cfme7hrx25bgv")

var tile_texture: Texture2D
var tile_texture_button: TextureButton
var tile_last_placed_position: Vector2i

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Creator.mode_changed.connect(func(old: Creator.Mode, new: Creator.Mode) -> void:
		# Delete the pending tile when the creator mode is changed.
		if is_instance_valid(tile_texture_button):
			tile_texture_button.queue_free()
	)

func start(texture: Texture2D) -> void:
	if Creator.mode != Creator.Mode.PlacingTile:
		return
	
	if not is_instance_valid(texture):
		push_error("Placing tile without proper texture")
		return
	
	tile_texture = texture
	create_tile_to_place()

func create_tile_to_place() -> void:
	tile_texture_button = TextureButton.new()
	tile_texture_button.texture_normal = tile_texture
	
	tile_texture_button.button_down.connect(func() -> void:
		create_placed_tile()
		create_tile_to_place()
	, ConnectFlags.CONNECT_ONE_SHOT)
	
	tile_texture_button.gui_input.connect(func(event: InputEvent) -> void:
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			Creator.mode = Creator.Mode.None
			tile_texture_button.queue_free()
	)
	
	get_tree().root.add_child(tile_texture_button)

func create_placed_tile() -> void:
	# Create a Tile
	var tile: Tile = TILE.instantiate()
	tile.texture = tile_texture
	tile.global_position = tile_texture_button.global_position
	Game.tiles.add_child(tile)
	tile.owner = Game.tiles
	tile_last_placed_position = Global.position_to_coords(tile.global_position)
	
	# Prepare new tile.
	tile_texture_button.queue_free()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if Creator.mode != Creator.Mode.PlacingTile:
		return
	
	if not is_instance_valid(tile_texture_button):
		push_error("Placing tile without proper tile_texture_button")
		return
	
	var mouse: Vector2 = tile_texture_button.get_global_mouse_position()	
	tile_texture_button.global_position = Global.align_to_grid(mouse)

func _input(event: InputEvent) -> void:
	if Creator.mode != Creator.Mode.PlacingTile:
		return
	
	if event is InputEventMouseMotion and not event.relative.is_zero_approx():
		if event.button_mask & MOUSE_BUTTON_LEFT == MOUSE_BUTTON_LEFT:
			# When moving the mouse while the left mouse button is pressed down, place tiles.
			var mouse: Vector2 = tile_texture_button.get_global_mouse_position()
			var pos: Vector2i = Global.position_to_coords(mouse)
			
			if pos != tile_last_placed_position:
				tile_texture_button.global_position = Global.coords_to_position(pos)
				create_placed_tile()
				create_tile_to_place()
