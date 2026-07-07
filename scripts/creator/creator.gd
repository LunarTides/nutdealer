extends Node

enum Mode {
	None,
	PlacingTile,
}

var mode = Mode.None
var tiles: CreatorTiles

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Start disabled. Only enable when going into create mode.
	process_mode = Node.PROCESS_MODE_DISABLED

func start() -> void:
	process_mode = Node.PROCESS_MODE_INHERIT

func start_tile_placing(texture: Texture2D):
	mode = Mode.PlacingTile
	CreatorPlaceTiles.start(texture)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func save_world():
	var packed_scene: PackedScene = PackedScene.new()
	packed_scene.pack(get_tree().root.get_node("CreatorDarkWorldUI/Tiles"))
	ResourceSaver.save(packed_scene, "user://test.tscn")

func load_world():
	var packed_scene: PackedScene = load("user://test.tscn")
	var scene = packed_scene.instantiate()
	get_tree().root.add_child(scene)
