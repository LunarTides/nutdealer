extends Node

signal creator_enabled
signal creator_disabled
signal mode_changed(old: Mode, new: Mode)

const PLAYER: PackedScene = preload("uid://bvxdrb5d24bxx")

enum Mode {
	None,
	PlacingTile,
}

var mode: Mode = Mode.None:
	set(value):
		var old_mode: Mode = mode
		mode = value
		mode_changed.emit(old_mode, mode)
var enabled: bool = false:
	set(value):
		enabled = value
		
		if enabled:
			creator_enabled.emit()
		else:
			creator_disabled.emit()

@onready var dark_world_ui: CreatorDarkWorldUI = $/root/CreatorDarkWorldUI

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Start disabled. Only enable when going into create mode.
	process_mode = Node.PROCESS_MODE_DISABLED
	
	Game.play_start.connect(func() -> void:
		# Set to normal mode on play.
		mode = Mode.None
	)

func start() -> void:
	process_mode = Node.PROCESS_MODE_INHERIT
	enabled = true
	CreatorRoomManipulation.start()

func start_tile_placing(texture: Texture2D) -> void:
	mode = Mode.PlacingTile
	CreatorPlaceTiles.start(texture)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func start_playing() -> void:
	# Get starting room from camera position.
	var room_index: int = Room.position_to_room_index(dark_world_ui.camera_2d.global_position)
	if room_index == -1:
		push_warning("Must start in a room.")
		return
	
	print_debug("Playing from Room %d" % room_index)
	
	# Disable tiles outside room.
	Game.tiles.call_outside_room(room_index, func(tile: Tile) -> void:
		tile.disable()
	)
	
	Game.playing = true
	Game.current_room = room_index
	
	# Create player.
	var player: Player = PLAYER.instantiate()
	dark_world_ui.add_child(player)
	player.global_position = dark_world_ui.camera_2d.global_position
	Game.player = player

func stop_playing() -> void:
	# Re-enable disabled tiles outside room.
	Game.tiles.call_outside_room(Game.current_room, func(tile: Tile) -> void:
		tile.enable()
	)
	
	Game.playing = false
	Game.player.queue_free()

func save_world() -> void:
	var packed_scene: PackedScene = PackedScene.new()
	packed_scene.pack(get_tree().root.get_node(^"Game/Tiles"))
	ResourceSaver.save(packed_scene, "user://test.tscn")

func load_world() -> void:
	var packed_scene: PackedScene = load("user://test.tscn")
	var scene: Node = packed_scene.instantiate()
	get_tree().root.add_child(scene)
