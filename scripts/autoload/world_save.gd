extends Node

signal save_begun
signal save_ended

signal load_begun
signal load_ended

signal first_save_begun
signal first_save_ended

const FIRST_SAVE_DIALOGUE: PackedScene = preload("uid://24k3h1cax05e")
const OPEN_WORLD_DIALOGUE: PackedScene = preload("uid://1xt5rpnm2slf")
const ABANDON_SAVE_DIALOGUE: PackedScene = preload("uid://dkt1holgrwxif")
const SAVE_DIALOGUE: PackedScene = preload("uid://ddvp7p0x0n6ov")
const OVERWRITE_SAVE_DIALOGUE: PackedScene = preload("uid://dnkgm1j1jhd81")

var has_saved_once: bool:
	get:
		return not not Creator.world_name
var world_name: String:
	get:
		return Creator.world_name
	set(value):
		Creator.world_name = value
		
		# Delete the temp folder if we set the world_name.
		CreatorResourceSaver.delete_temp_folder()
var dirty: bool:
	get:
		return Creator.dirty
	set(value):
		Creator.dirty = value

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Creator.creator_enabled.connect(func() -> void:
		get_tree().auto_accept_quit = false
	)
	Creator.creator_disabled.connect(func() -> void:
		get_tree().auto_accept_quit = true
	)

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		if not dirty:
			get_tree().quit()
			return
		
		# Is dirty.
		create_save_dialogue(func(confirmed: bool) -> void:
			if has_saved_once:
				get_tree().quit()
				return
			
			# First save.
			if not confirmed:
				get_tree().quit()
				return
			
			create_first_save_dialogue(func(first_saved: bool) -> void:
				# Only actually quit if the user created the save.
				if first_saved:
					get_tree().quit()
			)
		)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _unhandled_input(event: InputEvent) -> void:
	if Game.playing or not Creator.enabled:
		return
	
	# Save
	if event.is_action_pressed(&"save"):
		save_world()
	
	# Open World
	if event.is_action_pressed(&"editor_open_world"):
		open_world_or_save()
	
	# New World
	if event.is_action_pressed(&"editor_new_world"):
		new_world_or_save()

func new_world_or_save() -> void:
	if not dirty:
			new_world()
			return
	
	# Dirty. Ask for confirmation.
	if not has_saved_once:
		# Haven't saved once. Ask to abandon save.
		var dialogue: ConfirmationDialog = ABANDON_SAVE_DIALOGUE.instantiate()
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
	create_save_dialogue(func(confirmed: bool) -> void:
		new_world()
	)

func create_save_dialogue(then: Callable = func(confirmed: bool) -> void: pass) -> void:
	var dialogue: ConfirmationDialog = SAVE_DIALOGUE.instantiate()
	dialogue.confirmed.connect(func() -> void:
		if world_name:
			save_world()
		dialogue.queue_free()
		then.call(true)
	)
	dialogue.canceled.connect(func() -> void:
		dialogue.queue_free()
		then.call(false)
	)
	add_child(dialogue)
	dialogue.popup_centered_clamped()

func create_first_save_dialogue(then: Callable = func(confirmed: bool) -> void: pass) -> void:
	var dialogue: ConfirmationDialog = FIRST_SAVE_DIALOGUE.instantiate()
	dialogue.confirmed.connect(func() -> void:
		var new_world_name: String = dialogue.get_node(^"WorldName").text
		if not new_world_name:
			return
		
		# Check conflict. Ask before for overriding.
		if DirAccess.dir_exists_absolute("user://worlds/%s" % new_world_name):
			var overwrite_dialogue: ConfirmationDialog = OVERWRITE_SAVE_DIALOGUE.instantiate()
			overwrite_dialogue.confirmed.connect(func() -> void:
				# User chose to overwrite.
				overwrite_dialogue.queue_free()
				world_name = new_world_name
				first_save_begun.emit()
				save_world()
				dialogue.queue_free()
				
				then.call(true)
				first_save_ended.emit()
			)
			overwrite_dialogue.canceled.connect(func() -> void:
				overwrite_dialogue.queue_free()
				then.call(false)
			)
			add_child(overwrite_dialogue)
			overwrite_dialogue.popup_centered_clamped()
		else:
			# No conflict. Save.
			world_name = new_world_name
			first_save_begun.emit()
			save_world()
			dialogue.queue_free()
			then.call(true)
			first_save_ended.emit()
	)
	dialogue.canceled.connect(func() -> void:
		dialogue.queue_free()
		then.call(false)
	)
	add_child(dialogue)
	dialogue.popup_centered_clamped()
	# Place focus on the world name input.
	dialogue.get_node(^"WorldName").grab_focus()

func create_open_world_dialogue() -> void:
	# Create worlds folder if it doesn't already exist.
	if not DirAccess.dir_exists_absolute("user://worlds"):
		DirAccess.make_dir_recursive_absolute("user://worlds")
	
	var dialogue: FileDialog = OPEN_WORLD_DIALOGUE.instantiate()
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

func open_world_or_save() -> void:
	if dirty:
		# Ask to save first.
		if has_saved_once:
			create_save_dialogue(func(confirmed: bool) -> void:
				create_open_world_dialogue()
			)
		else:
			create_save_dialogue(func(confirmed: bool) -> void:
				if not confirmed:
					create_open_world_dialogue()
					return
				
				create_first_save_dialogue(func(first_saved: bool) -> void:
					if first_saved:
						create_open_world_dialogue()
				)
			)
		return
	
	create_open_world_dialogue()

func make_dirty() -> void:
	Creator.make_dirty()

func save_world() -> void:
	if Game.playing:
		Game.feedback("You cannot save the world while previewing the game.", Game.FeedbackType.Error)
		return
	
	if not world_name:
		# New world.
		create_first_save_dialogue()
		return
	
	save_begun.emit()
	var path: String = "user://worlds/%s" % world_name
	DirAccess.make_dir_recursive_absolute(path)
	
	# Tiles
	var tiles: PackedScene = PackedScene.new()
	tiles.pack(Game.tiles)
	DirAccess.make_dir_recursive_absolute("%s/tiles" % path)
	ResourceSaver.save(tiles, "%s/tiles/tiles.tscn" % path)
	
	# Tile Scripts
	for tile: Tile in Game.tiles.get_all():
		if is_instance_valid(tile.logic_script):
			DirAccess.make_dir_recursive_absolute("%s/tiles/scripts" % path)
			
			var script_path_split: PackedStringArray = tile.logic_script_path.split("/")
			var script_name: String = script_path_split[script_path_split.size() - 1]
			
			var file: FileAccess = FileAccess.open("%s/tiles/scripts/%s" % [path, script_name], FileAccess.WRITE)
			file.store_string(tile.logic_script.source_code)
	
	# Config
	var config: ConfigFile = ConfigFile.new()
	for i: int in range(Room.bounds.size()):
		var bounds: Rect2i = Room.bounds[i]
		config.set_value("rooms", str(i), bounds)
	
	config.save("%s/world.cfg" % path)
	
	dirty = false
	has_saved_once = true
	
	save_ended.emit()
	Game.feedback("World saved.", Game.FeedbackType.Success)

func load_world() -> void:
	var path: String = "user://worlds/%s" % world_name
	if not FileAccess.file_exists("%s/world.cfg" % path):
		Game.feedback("That world ('%s') does not exist.", Game.FeedbackType.Error)
		return
	
	load_begun.emit()
	
	# Tiles
	var packed_tiles: PackedScene = load("%s/tiles/tiles.tscn" % path)
	var tiles: Tiles = packed_tiles.instantiate()
	
	for tile: Tile in tiles.get_children():
		# Don't ask.
		tile.owner = null
		tile.reparent(Game.tiles)
		tile.owner = Game.tiles
	
	# Config
	var config: ConfigFile = ConfigFile.new()
	config.load("%s/world.cfg" % path)
	
	if config.has_section("rooms"):
		for key: String in config.get_section_keys("rooms"):
			var bounds: Rect2i = config.get_value("rooms", key)
			Room.add_room(bounds)
	
	load_ended.emit()
	
	await get_tree().process_frame
	dirty = false
	has_saved_once = true

func new_world() -> void:
	Tiles.delete_all()
	Room.clear_rooms()
	
	world_name = ""
	
	await get_tree().process_frame
	has_saved_once = false
	dirty = false
