extends Node2D

const ROOM_ACTIONS: PackedScene = preload("uid://cde6f8eqmtpcb")

var hovering: int = -1:
	set(value):
		hovering = value
		queue_redraw()
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

func _unhandled_input(event: InputEvent) -> void:
	if Creator.mode != Creator.Mode.None:
		# We're in some kind of mode. Remove hovering state.
		if hovering != -1:
			hovering = -1
		return
	
	if event is InputEventMouseButton:
		# If you click outside the action dropdown, remove it.
		if is_instance_valid(actions) and not actions.get_global_rect().has_point(Global.mouse_position):
			actions.queue_free()
		
		if hovering != -1:
			if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
				handle_click()

func _draw() -> void:
	for i: int in range(Room.bounds.size()):
		var bound: Rect2i = Room.bounds[i]
		
		var filled: bool = hovering == i
		var width: int = -1 if filled else 3
		
		draw_rect(Room.coords_to_position(bound), Color.SKY_BLUE, filled, width, true)

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
