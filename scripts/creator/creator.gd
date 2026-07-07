extends Node

signal mode_changed(old: Mode, new: Mode)

const CONTROLLING_CHARACTER = preload("uid://bvxdrb5d24bxx")

enum Mode {
	None,
	PlacingTile,
}

var mode: Mode = Mode.None:
	set(value):
		var old_mode = mode
		mode = value
		mode_changed.emit(old_mode, mode)
var tiles: CreatorTiles
var enabled: bool = false

@onready var dark_world_ui = $/root/CreatorDarkWorldUI

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Start disabled. Only enable when going into create mode.
	process_mode = Node.PROCESS_MODE_DISABLED
	
	Game.play_start.connect(func():
		# Set to normal mode on play.
		mode = Mode.None
	)

func start() -> void:
	process_mode = Node.PROCESS_MODE_INHERIT
	enabled = true

func start_tile_placing(texture: Texture2D):
	mode = Mode.PlacingTile
	CreatorPlaceTiles.start(texture)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func start_playing() -> void:
	Game.playing = true
	
	var controlling_character: ControllingCharacter = CONTROLLING_CHARACTER.instantiate()
	dark_world_ui.add_child(controlling_character)
	controlling_character.global_position = dark_world_ui.camera_2d.global_position
	Game.controlling_character = controlling_character

func stop_playing() -> void:
	Game.playing = false
	Game.controlling_character.queue_free()

func save_world():
	var packed_scene: PackedScene = PackedScene.new()
	packed_scene.pack(get_tree().root.get_node("CreatorDarkWorldUI/Tiles"))
	ResourceSaver.save(packed_scene, "user://test.tscn")

func load_world():
	var packed_scene: PackedScene = load("user://test.tscn")
	var scene = packed_scene.instantiate()
	get_tree().root.add_child(scene)
