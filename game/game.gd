extends Node

signal play_started
signal play_ended
signal room_changed(old_room_index: int, new_room_index: int)
signal mode_changed(old: Mode, new: Mode)

const TILES: PackedScene = preload("uid://c810cm35ke6y5")
const TILE: PackedScene = preload("uid://cfme7hrx25bgv")
const GAME_PAUSE_MENU: PackedScene = preload("uid://dic6f6j0grcf0")

enum Mode {
	DarkWorld,
	Encounter,
}

enum FeedbackType {
	Info,
	Success,
	Warning,
	Error,
}

var playing: bool = false:
	set(value):
		if playing != value:
			playing = value
			
			if playing:
				play_started.emit()
			else:
				play_ended.emit()
var mode: Mode = Mode.DarkWorld:
	set(value):
		if mode != value:
			var old: Mode = mode
			mode = value
			mode_changed.emit(old, mode)
		
var player: Player
var party_members: Array[WorldPartyMember]
var party_members_with_player: Array[WorldPartyMember]:
	get:
		var value: Array[WorldPartyMember] = [player]
		value.append_array(party_members)
		return value
var tiles: Tiles
var border_tiles: Node
var current_room: int = 0:
	set(value):
		var old: int = current_room
		current_room = value
		room_changed.emit(old, current_room)
var canvas_layer: CanvasLayer
var pause_menu: Control
var music_player: AudioStreamPlayer

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	setup_tiles()
	
	music_player = AudioStreamPlayer.new()
	music_player.bus = &"Music"
	music_player.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(music_player)
	
	canvas_layer = CanvasLayer.new()
	add_child(canvas_layer)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func setup_tiles() -> void:
	tiles = TILES.instantiate()
	tiles.child_entered_tree.connect(func(node: Node) -> void:
		Creator.make_dirty()
	)
	tiles.child_exiting_tree.connect(func(node: Node) -> void:
		Creator.make_dirty()
	)
	add_child(tiles)
	
	border_tiles = Node.new()
	Encounter.started.connect(func(tile: Tile) -> void:
		border_tiles.process_mode = Node.PROCESS_MODE_DISABLED
	)
	Encounter.ended.connect(func(tile: Tile, won: bool) -> void:
		border_tiles.process_mode = Node.PROCESS_MODE_INHERIT
	)
	add_child(border_tiles)

func feedback(message: String, feedback_type: FeedbackType) -> void:
	if Creator.enabled:
		Creator._feedback(message, feedback_type)
		return
	
	# TODO: Handle error messages without creator.

func play_from(room_index: int, position: Vector2 = Vector2.ZERO) -> void:
	if room_index == -1:
		feedback("Must start in a room.", FeedbackType.Error)
		return
	
	if Room.amount < 1:
		feedback("This world has no rooms.", FeedbackType.Error)
		return
	
	playing = true
	current_room = room_index
	
	# This has side-effects that changes which tiles are considered inside the room.
	constrain_player_to_current_room()
	
	# Disable tiles outside room.
	tiles.call_outside_room(room_index, func(tile: Tile) -> void:
		tile.disable()
	)
	# Enable tiles inside room.
	tiles.call_inside_room(room_index, func(tile: Tile) -> void:
		tile.enable()
	)
	
	# Create player.
	if not is_instance_valid(player):
		# NOTE: For some reason, we can't preload the player scene. ???
		var player_scene: PackedScene = load("uid://cbbmactdk1u14")
		player = player_scene.instantiate()
		player.party_member = PartyMembers.lead
		add_child(player)
		
		for party_member: PartyMember in PartyMembers.party_members:
			if party_member == player.party_member:
				continue
			
			var party_member_scene: PackedScene = preload("uid://cvqr7nikcw4k6")
			var follow_player: FollowPlayer = party_member_scene.instantiate()
			follow_player.party_member = party_member
			party_members.append(follow_player)
			add_child(follow_player)
	
	if position == Vector2.ZERO:
		# Teleport player to room start position.
		var success: bool = teleport_player_to_room_start_position()
		if not success:
			# No room start position. Position the player in the center of the room.
			var room_bounds: Rect2i = Room.bounds[current_room]
			
			@warning_ignore("integer_division")
			player.global_position = Global.coords_to_position(room_bounds.position + room_bounds.size / 2)
	else:
		player.global_position = position
	
	# Create pause menu.
	if not Creator.enabled and not is_instance_valid(pause_menu):
		pause_menu = GAME_PAUSE_MENU.instantiate()
		canvas_layer.add_child(pause_menu)
	
	play_music()
	constrain_camera_to_current_room()

func stop_playing(clear_world: bool = true) -> void:
	mode = Mode.DarkWorld
	playing = false
	
	# Re-enable disabled tiles outside room.
	tiles.call_outside_room(current_room, func(tile: Tile) -> void:
		tile.enable()
	)
	# Show border tiles.
	tiles.call_inside_room(current_room, func(tile: Tile) -> void:
		if tile.border_tile_for_room_index != -1:
			tile.show()
	)
	
	player.queue_free()
	for party_member: WorldPartyMember in party_members:
		party_member.queue_free()
	party_members.clear()
	
	if is_instance_valid(pause_menu):
		pause_menu.queue_free()
	
	pause_music()
	
	if clear_world:
		# Clear everything.
		WorldSave.new_world()

func switch_room(room_index: int) -> void:
	play_from(room_index)

func teleport_player_to_room_start_position() -> bool:
	var old_position: Vector2 = player.global_position
	
	tiles.call_inside_room(current_room, func(tile: Tile) -> void:
		if tile.is_room_start_position:
			player.global_position = tile.global_position + Vector2(32, 32)
	)
	return player.global_position != old_position

func constrain_player_to_current_room() -> void:
	var bounds: Rect2i = Room.bounds[current_room]
	
	for col: int in range(bounds.size.x):
		for row: int in range(bounds.size.y):
			var coords: Vector2i = Vector2i(bounds.position.x + col, bounds.position.y + row)
			
			# Left-most column.
			if col == 0:
				var new_coords: Vector2i = coords
				new_coords.x -= 1
				create_border_tile(new_coords)
			# Right-most column.
			if col >= bounds.size.x - 1:
				var new_coords: Vector2i = coords
				new_coords.x += 1
				create_border_tile(new_coords)
			
			# First row.
			if row == 0:
				var new_coords: Vector2i = coords
				new_coords.y -= 1
				create_border_tile(new_coords)
			# Last row.
			if row >= bounds.size.y - 1:
				var new_coords: Vector2i = coords
				new_coords.y += 1
				create_border_tile(new_coords)

func constrain_camera_to_current_room() -> void:
	var room_bounds: Rect2i = Room.bounds[current_room]
	var room_position_px: Vector2 = Global.coords_to_position(room_bounds.position)
	var room_size_px: Vector2 = Global.coords_to_position(room_bounds.size)
	
	player.camera.limit_left = int(room_position_px.x)
	player.camera.limit_right = int(room_position_px.x + room_size_px.x)
	player.camera.limit_top = int(room_position_px.y)
	player.camera.limit_bottom = int(room_position_px.y + room_size_px.y)

func create_border_tile(coords: Vector2i) -> Tile:
	var existing_tile: Tile = tiles.get_tile_on(coords)
	if existing_tile:
		# For bordering room transitions and stuff.
		if existing_tile.should_override_border_tile:
			existing_tile.border_tile_for_room_index = current_room
			return
	
	var tile: Tile = TILE.instantiate()
	tile.is_solid = true
	tile.border_tile_for_room_index = current_room
	#tile.texture = preload("res://icon.svg")
	
	# Delete tile when room changed, or play ended.
	room_changed.connect(func(old: int, new: int) -> void:
		if is_instance_valid(tile):
			tile.queue_free()
	, ConnectFlags.CONNECT_ONE_SHOT)
	play_ended.connect(func() -> void:
		if is_instance_valid(tile):
			tile.queue_free()
	, ConnectFlags.CONNECT_ONE_SHOT)
	
	border_tiles.add_child.call_deferred(tile)
	tile.global_position = Global.coords_to_position(coords)
	tile.id = "border"
	
	return tile

func play_music() -> void:
	if not Game.playing:
		return
	
	if not music_player.stream:
		music_player.stream = preload("res://assets/audio/music/tv_world.ogg")
	
	if music_player.stream_paused:
		music_player.stream_paused = false
	elif not music_player.playing:
		music_player.play()

func pause_music() -> void:
	music_player.stream_paused = true

func stop_music() -> void:
	music_player.stop()
