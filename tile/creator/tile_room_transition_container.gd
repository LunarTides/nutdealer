extends VBoxContainer

@export var behavior_ui: Control
@export var connect_button: Button
@export var option_button: OptionButton

var tile: Tile:
	set(value):
		tile = value
		
		if is_instance_valid(tile.room_transition) and tile.room_transition.index != -1:
			connect_button.text = "Connected to Room %d (%d, %d)" % [tile.room_transition_index, tile.room_transition_coords.x, tile.room_transition_coords.y]
			option_button.selected = tile.room_transition.trigger

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_connect_button_pressed() -> void:
	behavior_ui.waiting_for_outside_action = true
	connect_button.text = "Click somewhere inside a room..."
	
	CreatorRoomManipulation.room_clicked.connect(func(room_index: int) -> void:
		behavior_ui.waiting_for_outside_action = false
		
		if not is_instance_valid(tile.room_transition):
			tile.room_transition = TileRoomTransition.new()
		
		tile.room_transition.index = room_index
		tile.room_transition.coords = Global.mouse_coords
		connect_button.text = "Connected to Room %d (%d, %d)" % [room_index, Global.mouse_coords.x, Global.mouse_coords.y]
	, ConnectFlags.CONNECT_ONE_SHOT)


func _on_option_button_item_selected(index: int) -> void:
	if not is_instance_valid(tile.room_transition):
		# Nope.
		option_button.selected = 0
		return
	
	# Trust.
	tile.room_transition.trigger = index as TileRoomTransition.Trigger
