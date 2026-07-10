extends Node

signal creator_enabled
signal creator_disabled
signal mode_changed(old: Mode, new: Mode)

const PLAYER: PackedScene = preload("uid://bvxdrb5d24bxx")
const CREATOR_FIRST_SAVE_DIALOGUE: PackedScene = preload("uid://24k3h1cax05e")
const CREATOR_OPEN_WORLD_DIALOGUE: PackedScene = preload("uid://1xt5rpnm2slf")
const CREATOR_ABANDON_SAVE_DIALOGUE: PackedScene = preload("uid://dkt1holgrwxif")

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
var world_name: String
var has_saved_once: bool:
	get:
		return not not world_name
# TODO: Show this dirty flag in-editor.
var dirty: bool = true

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

func start_tile_placing(tile: Tile) -> void:
	mode = Mode.PlacingTile
	CreatorPlaceTiles.start(tile)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if Input.is_action_just_pressed(&"editor_preview_next_room") and Game.playing:
		# Switch to next room.
		var new_room_index: int = Game.current_room + 1
		if new_room_index >= Room.amount:
			new_room_index = 0
		
		var bounds: Rect2i = Room.bounds[new_room_index]
		
		# Integer division is fine since we're working with multiples of 64.
		@warning_ignore("integer_division")
		Game.switch_room(new_room_index, Global.coords_to_position(bounds.position + bounds.size / 2))
	
	if Input.is_action_just_pressed(&"save"):
		if world_name:
			save_world()
		else:
			var dialogue: ConfirmationDialog = CREATOR_FIRST_SAVE_DIALOGUE.instantiate()
			dialogue.confirmed.connect(func() -> void:
				var new_world_name: String = dialogue.get_node(^"WorldName").text
				if not new_world_name:
					return
				
				world_name = new_world_name
				save_world()
				dialogue.queue_free()
			)
			dialogue.canceled.connect(func() -> void:
				dialogue.queue_free()
			)
			add_child(dialogue)
			dialogue.popup_centered_clamped()
	
	if Input.is_action_just_pressed(&"editor_open_world"):
		if has_saved_once and dirty:
			# TODO: Implement
			push_warning("Not implemented: Is dirty while opening world. Please save first.")
			return
		
		var dialogue: FileDialog = CREATOR_OPEN_WORLD_DIALOGUE.instantiate()
		dialogue.dir_selected.connect(func(dir: String) -> void:
			dialogue.queue_free()
			
			if not dir.contains("/worlds/") or not FileAccess.file_exists("%s/world.cfg" % dir):
				return
			
			new_world()
			
			var parts: PackedStringArray = dir.split("/")
			world_name = parts[parts.size() - 1]
			load_world()
		)
		dialogue.canceled.connect(func() -> void:
			dialogue.queue_free()
		)
		add_child(dialogue)
	
	if Input.is_action_just_pressed(&"editor_new_world"):
		if not dirty:
			new_world()
			return
		
		# Dirty. Ask for confirmation.
		if not has_saved_once:
			# Haven't saved once. Abandon save.
			var dialogue: ConfirmationDialog = CREATOR_ABANDON_SAVE_DIALOGUE.instantiate()
			dialogue.confirmed.connect(func() -> void:
				dialogue.queue_free()
				new_world()
			)
			dialogue.canceled.connect(func() -> void:
				dialogue.queue_free()
			)
			add_child(dialogue)
			dialogue.popup_centered_clamped()
			return
		
		# TODO: Handle.
		push_warning("Not implemented: Is dirty, but has already saved once.")

func make_dirty() -> void:
	dirty = true

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
	Game.constrain_player_to_current_room()

func stop_playing() -> void:
	# Re-enable disabled tiles outside room.
	Game.tiles.call_outside_room(Game.current_room, func(tile: Tile) -> void:
		tile.enable()
	)
	
	Game.playing = false
	Game.player.queue_free()

func save_world() -> void:
	if Game.playing:
		push_error("You cannot save the world while previewing the game.")
		return
	
	var path: String = "user://worlds/%s" % world_name
	DirAccess.make_dir_recursive_absolute(path)
	
	# Tiles
	var tiles: PackedScene = PackedScene.new()
	tiles.pack(Game.tiles)
	ResourceSaver.save(tiles, "%s/tiles.tscn" % path)
	
	# Config
	var config: ConfigFile = ConfigFile.new()
	for i: int in range(Room.bounds.size()):
		var bounds: Rect2i = Room.bounds[i]
		config.set_value("rooms", str(i), bounds)
	
	config.save("%s/world.cfg" % path)
	
	dirty = false
	has_saved_once = true

func load_world() -> void:
	var path: String = "user://worlds/%s" % world_name
	if not FileAccess.file_exists("%s/world.cfg" % path):
		push_error("That world ('%s') does not exist." % world_name)
		return
	
	# Tiles
	var packed_tiles: PackedScene = load("%s/tiles.tscn" % path)
	var tiles: Tiles = packed_tiles.instantiate()
	
	for tile: Tile in tiles.get_children():
		# Don't ask.
		tile.owner = null
		tile.reparent(Game.tiles)
	
	# Config
	var config: ConfigFile = ConfigFile.new()
	config.load("%s/world.cfg" % path)
	
	for key: String in config.get_section_keys("rooms"):
		var bounds: Rect2i = config.get_value("rooms", key)
		Room.add_room(bounds)
	
	await get_tree().process_frame
	dirty = false
	has_saved_once = true

func new_world() -> void:
	Tiles.delete_all()
	Room.clear_rooms()
	
	world_name = ""
	has_saved_once = false
	make_dirty()
