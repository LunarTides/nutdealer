extends Node

enum Action {
	None,
	New,
	Resize,
	Move,
}

var enabled: bool = true

var room_start_pos: Vector2
var room_previous_pos: Vector2

var new_room_created: bool = false
var new_room_index: int = -1

var current_action: Action = Action.None:
	set(value):
		if current_action != value:
			current_action = value
			sfx_pitch = 1.0
var hovering: int = -1:
	set(value):
		if (not handle_lock and not hover_lock) or hovering == -1:
			hovering = value
var hover_lock: bool = false:
	set(value):
		hover_lock = value
		
		if not hover_lock:
			hovering = -1
var hovering_handle: Vector2:
	set(value):
		if not handle_lock:
			hovering_handle = value
var handle_lock: bool = false:
	set(value):
		handle_lock = value
		
		if not handle_lock:
			hovering = -1
			hovering_handle = Vector2.ZERO

var sfx_player: AudioStreamPlayer
var sfx_pitch: float = 1.0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	sfx_player = AudioStreamPlayer.new()
	#sfx_player.stream = preload("res://assets/audio/sfx/scissorbell_lite.wav")
	sfx_player.stream = preload("res://assets/audio/misc/hit.wav")
	add_child(sfx_player)
	
	Creator.creator_enabled.connect(func() -> void:
		start()
	)
	Creator.creator_disabled.connect(func() -> void:
		stop()
	)
	WorldSave.new_world_begun.connect(func() -> void:
		handle_lock = false
	)
	
	# Start disabled. Only enable when going into create mode.
	stop()

func start() -> void:
	process_mode = Node.PROCESS_MODE_INHERIT
	enabled = true

func stop() -> void:
	process_mode = Node.PROCESS_MODE_DISABLED
	enabled = false

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	sfx_pitch -= 0.5 * delta
	if sfx_pitch < 1.0:
		sfx_pitch = 1.0

func _input(event: InputEvent) -> void:
	if not enabled or Creator.mode != Creator.Mode.Room or Game.playing:
		return
	
	# Handle room creation / editing.
	if event is InputEventMouseMotion:
		if event.button_mask & MOUSE_BUTTON_LEFT == MOUSE_BUTTON_LEFT:
			if not event.relative.is_zero_approx():
				var mouse_pos: Vector2 = Global.mouse_position
				var room_index: int = Room.position_to_room_index(mouse_pos)
				if (hovering == -1 and room_index == -1 or new_room_created) and (current_action == Action.None or current_action == Action.New):
					# If no room or creating new room.
					current_action = Action.New
					handle_new_room(event)
				else:
					# Existing room.
					
					# Resize
					if hovering_handle and (current_action == Action.None or current_action == Action.Resize):
						handle_lock = true
						current_action = Action.Resize
						handle_resize_room(event)
					# Move
					elif current_action == Action.None or current_action == Action.Move:
						# Set hover lock to stop switching between the selected room when crossing rooms while moving.
						hover_lock = true
						current_action = Action.Move
						handle_move_room(event)
	
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.is_released():
				cleanup()

func cleanup() -> void:
	# Clear variables.
	if hovering_handle:
		cleanup_broken_room(hovering)
	if handle_lock:
		handle_lock = false
	if hover_lock:
		hover_lock = false
	
	if new_room_created:
		cleanup_broken_room(new_room_index)
	
	current_action = Action.None
	room_start_pos = Vector2.ZERO
	room_previous_pos = Vector2.ZERO
	new_room_created = false
	new_room_index = -1

func cleanup_broken_room(room_index: int) -> void:
	# Delete room if it's invalid. (Too small.)
	var start_coords: Vector2i = Global.position_to_coords(room_start_pos)
	var end_coords: Vector2i = Global.position_to_coords(room_previous_pos)
	var bounds: Rect2i = Room.bounds[room_index]
	
	if (start_coords - end_coords).abs() <= Vector2i(1, 1) or bounds.size.x <= 0 or bounds.size.y <= 0:
		# Don't delete invalid room.
		if room_index != -1:
			Room.delete_room(room_index)


func handle_new_room(event: InputEventMouseMotion) -> void:
	var mouse_pos: Vector2 = Global.mouse_position
	if not room_start_pos:
		room_start_pos = mouse_pos
	
	var start_coords: Vector2i = Global.position_to_coords(room_start_pos)
	var previous_coords: Vector2i = Global.position_to_coords(room_previous_pos)
	var current_coords: Vector2i = Global.mouse_coords
	if start_coords == current_coords or current_coords == previous_coords:
		# The mouse hasn't moved a coord space. Don't create/update the room yet.
		return
	
	var rect: Rect2i = Rect2i(start_coords, current_coords - start_coords)
	if not new_room_created:
		# New room.
		new_room_created = true
		new_room_index = Room.add_room(rect)
	else:
		# Update room that we're creating.
		Room.update_room(new_room_index, rect)
	
	room_previous_pos = mouse_pos
	play_sfx()

func handle_resize_room(event: InputEventMouseMotion) -> void:
	var mouse_pos: Vector2 = Global.mouse_position
	var bounds: Rect2i = Room.bounds[hovering]
	
	if not room_start_pos:
		# Set the corner to resize from based on the handle position.
		var size: Vector2i = Vector2i(0, 0)
		if hovering_handle.x == -1:
			size.x = bounds.size.x
		if hovering_handle.y == -1:
			size.y = bounds.size.y
		
		room_start_pos = bounds.position + size
	
	var start_coords: Vector2i = room_start_pos
	var current_coords: Vector2i = Global.mouse_coords
	
	# Lock the resize axis if using the non-diagonal handles.
	if hovering_handle.x == 0:
		current_coords.x = start_coords.x + bounds.size.x
	if hovering_handle.y == 0:
		current_coords.y = start_coords.y + bounds.size.y
	
	var rect: Rect2i = Rect2i(start_coords, current_coords - start_coords)
	Room.update_room(hovering, rect)
	
	var previous_coords: Vector2i = Global.position_to_coords(room_previous_pos)
	if current_coords != previous_coords:
		# TODO: Doesn't work with side-handles.
		play_sfx()
	
	room_previous_pos = mouse_pos

func handle_move_room(event: InputEventMouseMotion) -> void:
	if hovering == -1:
		return
	
	var mouse_pos: Vector2 = Global.mouse_position
	var bounds: Rect2i = Room.bounds[hovering]
	
	if not room_start_pos:
		room_start_pos = bounds.position
	if not room_previous_pos:
		room_previous_pos = mouse_pos
	
	var start_coords: Vector2i = room_start_pos
	var current_coords: Vector2i = Global.mouse_coords
	var previous_coords: Vector2i = Global.position_to_coords(room_previous_pos)
	
	var a: Vector2i = current_coords - start_coords
	var b: Vector2i = previous_coords - start_coords
	
	bounds.position += a - b
	Room.update_room(hovering, bounds, true)
	
	if current_coords != previous_coords:
		play_sfx()
	
	room_previous_pos = mouse_pos

func play_sfx() -> void:
	sfx_player.pitch_scale = sfx_pitch
	sfx_player.play()
	sfx_pitch += 0.1
