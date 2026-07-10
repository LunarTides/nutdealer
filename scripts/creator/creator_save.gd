extends Node

const CREATOR_FIRST_SAVE_DIALOGUE: PackedScene = preload("uid://24k3h1cax05e")
const CREATOR_OPEN_WORLD_DIALOGUE: PackedScene = preload("uid://1xt5rpnm2slf")
const CREATOR_ABANDON_SAVE_DIALOGUE: PackedScene = preload("uid://dkt1holgrwxif")
const CREATOR_SAVE_DIALOGUE: PackedScene = preload("uid://ddvp7p0x0n6ov")
const CREATOR_OVERWRITE_SAVE_DIALOGUE: PackedScene = preload("uid://dnkgm1j1jhd81")

var has_saved_once: bool:
	get:
		return not not Creator.world_name
var world_name: String:
	get:
		return Creator.world_name
	set(value):
		Creator.world_name = value
var dirty: bool:
	get:
		return Creator.dirty
	set(value):
		Creator.dirty = value

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass

func start() -> void:
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if Game.playing:
		return
	
	# Save
	if Input.is_action_just_pressed(&"save"):
		# Old world.
		if world_name:
			save_world()
			return
		
		# New world.
		create_first_save_dialogue()
	
	# Open World
	if Input.is_action_just_pressed(&"editor_open_world"):
		if has_saved_once and dirty:
			# Ask to save first.
			create_save_dialogue(create_open_world_dialogue)
			return
		
		create_open_world_dialogue()
	
	# New World
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
		
		# Ask to save first.
		create_save_dialogue(new_world)

func create_save_dialogue(then: Callable) -> void:
	var dialogue: ConfirmationDialog = CREATOR_SAVE_DIALOGUE.instantiate()
	dialogue.confirmed.connect(func() -> void:
		save_world()
		dialogue.queue_free()
		then.call()
	)
	dialogue.canceled.connect(func() -> void:
		dialogue.queue_free()
		then.call()
	)
	add_child(dialogue)
	dialogue.popup_centered_clamped()

func create_first_save_dialogue() -> void:
	var dialogue: ConfirmationDialog = CREATOR_FIRST_SAVE_DIALOGUE.instantiate()
	dialogue.confirmed.connect(func() -> void:
		var new_world_name: String = dialogue.get_node(^"WorldName").text
		if not new_world_name:
			return
		
		# Check conflict. Ask before for overriding.
		if DirAccess.dir_exists_absolute("user://worlds/%s" % new_world_name):
			var overwrite_dialogue: ConfirmationDialog = CREATOR_OVERWRITE_SAVE_DIALOGUE.instantiate()
			overwrite_dialogue.confirmed.connect(func() -> void:
				# User chose to overwrite.
				overwrite_dialogue.queue_free()
				world_name = new_world_name
				save_world()
				dialogue.queue_free()
			)
			overwrite_dialogue.canceled.connect(func() -> void:
				overwrite_dialogue.queue_free()
			)
			add_child(overwrite_dialogue)
			overwrite_dialogue.popup_centered_clamped()
		else:
			# No conflict. Save.
			world_name = new_world_name
			save_world()
			dialogue.queue_free()
	)
	dialogue.canceled.connect(func() -> void:
		dialogue.queue_free()
	)
	add_child(dialogue)
	dialogue.popup_centered_clamped()
	# Place focus on the world name input.
	dialogue.get_node(^"WorldName").grab_focus()

func create_open_world_dialogue() -> void:
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

func make_dirty() -> void:
	Creator.make_dirty()

func save_world() -> void:
	if Game.playing:
		# TODO: Show to the player.
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
		tile.owner = Game.tiles
	
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
	dirty = false
