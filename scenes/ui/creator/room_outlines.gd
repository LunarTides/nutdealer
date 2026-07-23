extends Node2D

const ROOM_ACTIONS: PackedScene = preload("uid://cde6f8eqmtpcb")

@export var handle_size: int = 4:
	set(value):
		handle_size = value
		queue_redraw()

var hovering: int = -1:
	set(value):
		hovering = value
		CreatorRoomManipulation.hovering = hovering
		
		if hovering == -1:
			# Not hovering. Show on top of tiles.
			z_index = 0
		else:
			# Hovering. Show behind tiles.
			z_index = -3
		
		queue_redraw()
var hovering_handle: Vector2 = Vector2.ZERO:
	set(value):
		hovering_handle = value
		queue_redraw()
		set_hovering_handle_cursor_shape()
		
		CreatorRoomManipulation.hovering_handle = hovering_handle
var actions: PanelContainer

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Room.room_added.connect(func(index: int) -> void:
		queue_redraw()
	)
	Room.room_updated.connect(func(index: int, old: Rect2i, new: Rect2i) -> void:
		queue_redraw()
	)
	Room.room_deleted.connect(func(index: int) -> void:
		queue_redraw()
	)
	Room.rooms_cleared.connect(func() -> void:
		queue_redraw()
	)
	
	Game.play_start.connect(func() -> void:
		hide()
	)
	Game.play_end.connect(func() -> void:
		show()
	)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	# Handle hovering.
	if Creator.mode != Creator.Mode.None:
		# We're in some kind of mode. Remove hovering state.
		if hovering != -1:
			hovering = -1
		return
	
	var mouse_pos: Vector2 = Global.mouse_position
	
	# Don't hover if the mouse is on a tile.
	var mouse_coords: Vector2i = Global.position_to_coords(mouse_pos)
	var is_on_tile: bool = Game.tiles.is_tile_on(mouse_coords)
	if is_on_tile:
		if hovering != -1:
			hovering = -1
		return
	
	var room_index: int = Room.position_to_room_index(mouse_pos)
	if hovering != room_index:
		hovering = room_index
	
	check_hovering_handle()

func _unhandled_input(event: InputEvent) -> void:
	if Creator.mode != Creator.Mode.None:
		# We're in some kind of mode. Remove hovering state.
		if hovering != -1:
			hovering = -1
		return
	
	if event is InputEventMouseButton:
		# If you click outside the action dropdown, remove it.
		if event.button_index == MOUSE_BUTTON_LEFT and is_instance_valid(actions) and not actions.get_global_rect().has_point(Global.mouse_position):
			actions.queue_free()
		
		if hovering != -1 and not hovering_handle:
			if event.button_index == MOUSE_BUTTON_LEFT and event.is_released():
				handle_click()

func _draw() -> void:
	for i: int in range(Room.bounds.size()):
		var bound: Rect2i = Room.bounds[i]
		
		var color: Color = Color.SKY_BLUE
		if bound.size.x >= Global.screen_size_coords.x and bound.size.y >= Global.screen_size_coords.y:
			color = Color.YELLOW
		
		#var filled: bool = hovering == i and not hovering_handle
		var filled: bool = false
		var width: int = -1 if filled else 3
		
		var rect: Rect2 = Room.coords_to_position(bound)
		draw_rect(rect, color, filled, width, true)
		
		# Draw corner handles
		var handle_color: Color = Color.ORANGE_RED
		
		draw_circle(rect.position, handle_size, handle_color)
		draw_circle(rect.position + Vector2(rect.size.x, 0), handle_size, handle_color)
		draw_circle(rect.position + Vector2(0, rect.size.y), handle_size, handle_color)
		draw_circle(rect.position + rect.size, handle_size, handle_color)
		
		# Draw side handles
		draw_circle(rect.position + Vector2(0, rect.size.y / 2), handle_size, handle_color)
		draw_circle(rect.position + Vector2(rect.size.x / 2, 0), handle_size, handle_color)
		draw_circle(rect.position + Vector2(rect.size.x, rect.size.y / 2), handle_size, handle_color)
		draw_circle(rect.position + Vector2(rect.size.x / 2, rect.size.y), handle_size, handle_color)

func handle_click() -> void:
	if is_instance_valid(actions):
		actions.queue_free()
	
	actions = ROOM_ACTIONS.instantiate()
	actions.global_position = Global.mouse_position
	actions.get_node(^"%DeleteButton").pressed.connect(func() -> void:
		Room.delete_room(hovering)
		hovering = -1
		actions.queue_free()
	)
	add_child(actions)

func check_hovering_handle() -> void:
	# Check if the user is hovering over any of the handles.
	# Sets the `hovering` and `hovering_handle` variables if so.
	hovering_handle = Vector2.ZERO
	
	var mouse_pos: Vector2 = Global.mouse_position
	
	var top_left: Vector2 =     Vector2(-1, -1)
	var top: Vector2 =          Vector2(0, -1)
	var top_right: Vector2 =    Vector2(1, -1)
	var right: Vector2 =        Vector2(1, 0)
	var bottom_right: Vector2 = Vector2(1, 1)
	var bottom: Vector2 =       Vector2(0, 1)
	var bottom_left: Vector2 =  Vector2(-1, 1)
	var left: Vector2 =         Vector2(-1, 0)
	
	for i: Vector2 in [top_left, top, top_right, right, bottom_right, bottom, bottom_left, left]:
		var pos: Vector2 = mouse_pos - i * handle_size
		var room: int = Room.position_to_room_index(pos)
		if room == -1:
			continue
		
		var bounds: Rect2i = Room.bounds[room]
		var rect: Rect2i = Room.coords_to_position(bounds)
		
		# 1 -> rect.size
		# 0 -> rect.size / 2
		# -1 -> 0
		var size: Vector2i = Vector2i(0, 0)
		
		if i.x == 1:
			size.x = rect.size.x
		elif i.x == 0:
			@warning_ignore("integer_division")
			size.x = rect.size.x / 2
		
		if i.y == 1:
			size.y = rect.size.y
		elif i.y == 0:
			@warning_ignore("integer_division")
			size.y = rect.size.y / 2
		
		var distance: float = pos.distance_to(rect.position + size)
		if distance <= handle_size * 2:
			hovering = room
			hovering_handle = i
			break

func set_hovering_handle_cursor_shape() -> void:
	if not hovering_handle:
		Input.set_default_cursor_shape(Input.CURSOR_ARROW)
		return
	
	# Horizontal
	if hovering_handle == Vector2(1, 0) or hovering_handle == Vector2(-1, 0):
		Input.set_default_cursor_shape(Input.CURSOR_HSIZE)
	# Vertical
	elif hovering_handle == Vector2(0, 1) or hovering_handle == Vector2(0, -1):
		Input.set_default_cursor_shape(Input.CURSOR_VSIZE)
	# Top-right and bottom-left
	elif hovering_handle == Vector2(-1, -1) or hovering_handle == Vector2(1, 1):
		Input.set_default_cursor_shape(Input.CURSOR_FDIAGSIZE)
	# Top-left and bottom-right
	elif hovering_handle == Vector2(1, -1) or hovering_handle == Vector2(-1, 1):
		Input.set_default_cursor_shape(Input.CURSOR_BDIAGSIZE)
		
