extends Node

var enabled: bool = true

var new_room_start_pos: Vector2
var new_room_previous_pos: Vector2
var new_room_created: bool = false
var new_room_index: int = -1

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Start disabled. Only enable when going into create mode.
	process_mode = Node.PROCESS_MODE_DISABLED
	enabled = false

func start() -> void:
	process_mode = Node.PROCESS_MODE_INHERIT
	enabled = true

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _input(event: InputEvent) -> void:
	if not enabled or Game.playing or Creator.mode != Creator.Mode.None:
		return
	
	# Handle room creation / editing.
	if event is InputEventMouseMotion:
		if event.button_mask & MOUSE_BUTTON_LEFT == MOUSE_BUTTON_LEFT:
			if not event.relative.is_zero_approx():
				var mouse_pos: Vector2 = Global.mouse_position
				var room_index: int = Room.position_to_room_index(mouse_pos)
				if room_index == -1 or new_room_created:
					# If no room or creating new room.
					handle_new_room(event)
				else:
					# Existing room.
					pass
	
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.is_released():
			cleanup_new_room()

func handle_new_room(event: InputEventMouseMotion) -> void:
	var mouse_pos: Vector2 = Global.mouse_position
	if not new_room_start_pos:
		new_room_start_pos = mouse_pos
	
	var start_coords: Vector2i = Global.position_to_coords(new_room_start_pos)
	var previous_coords: Vector2i = Global.position_to_coords(new_room_previous_pos)
	var current_coords: Vector2i = Global.position_to_coords(mouse_pos)
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
	
	new_room_previous_pos = mouse_pos

func cleanup_new_room() -> void:
	if not new_room_created:
		return
	
	# Delete room if it's invalid. (Too small.)
	var start_coords: Vector2i = Global.position_to_coords(new_room_start_pos)
	var end_coords: Vector2i = Global.position_to_coords(new_room_previous_pos)
	var bounds: Rect2i = Room.bounds[new_room_index]
	
	if (start_coords - end_coords).abs() <= Vector2i(1, 1) or bounds.size.x <= 0 or bounds.size.y <= 0:
		# Don't delete invalid room.
		if new_room_index != -1:
			Room.delete_room(new_room_index)
	
	# Clear variables.
	new_room_start_pos = Vector2.ZERO
	new_room_previous_pos = Vector2.ZERO
	new_room_created = false
	new_room_index = -1
