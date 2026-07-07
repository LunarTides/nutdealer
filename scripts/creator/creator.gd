extends Node

const CREATOR_TILE = preload("uid://cfme7hrx25bgv")

enum Mode {
	None,
	PlacingTile,
}

var mode = Mode.None:
	set(value):
		mode = value
		
		start_mode_placing_tile()

var tiles: Control
var tile_texture: Texture2D
var tile_texture_button: TextureButton

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Start disabled. Only enable when going into create mode.
	process_mode = Node.PROCESS_MODE_DISABLED

func start() -> void:
	process_mode = Node.PROCESS_MODE_INHERIT

func start_mode_placing_tile() -> void:
	if mode != Mode.PlacingTile:
		return
	
	if not is_instance_valid(tile_texture):
		push_error("Placing tile without proper tile_texture")
		return
	
	create_tile_to_place()

func create_tile_to_place() -> void:
	tile_texture_button = TextureButton.new()
	tile_texture_button.texture_normal = tile_texture
	
	tile_texture_button.button_down.connect(func():
		# Create a CreatorTile
		var tile = CREATOR_TILE.instantiate()
		tile.texture = tile_texture
		tile.global_position = tile_texture_button.global_position
		tiles.add_child(tile)
		tile.owner = tiles
		
		# Prepare new tile.
		tile_texture_button.queue_free()
		create_tile_to_place()
	, ConnectFlags.CONNECT_ONE_SHOT)
	
	tile_texture_button.gui_input.connect(func(event):
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			mode = Mode.None
			tile_texture_button.queue_free()
	)
	
	get_tree().root.add_child(tile_texture_button)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	process_mode_placing_tile()

func process_mode_placing_tile() -> void:
	if mode != Mode.PlacingTile:
		return
	
	if not is_instance_valid(tile_texture_button):
		push_error("Placing tile without proper tile_texture_button")
		return
	
	var mouse = tile_texture_button.get_global_mouse_position()
	var pos = (mouse / 64).floor()
	
	tile_texture_button.global_position = pos * 64

func save_world():
	var packed_scene: PackedScene = PackedScene.new()
	packed_scene.pack(get_tree().root.get_node("CreatorDarkWorldUI/Tiles"))
	ResourceSaver.save(packed_scene, "user://test.tscn")

func load_world():
	var packed_scene: PackedScene = load("user://test.tscn")
	var scene = packed_scene.instantiate()
	get_tree().root.add_child(scene)
