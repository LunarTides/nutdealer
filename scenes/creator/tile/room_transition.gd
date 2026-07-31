extends VBoxContainer

@export var behavior_ui: Control
@export var connect_button: Button
@export var option_button: OptionButton

var tile: Tile:
	set(value):
		tile = value
		
		if tile.room_transition_index != -1:
			connect_button.text = "Connected to Room %d (%d, %d)" % [tile.room_transition_index, tile.room_transition_coords.x, tile.room_transition_coords.y]
		
		for index: int in option_button.item_count:
			if option_button.get_item_text(index) == tile.room_transition_trigger:
				option_button.selected = index

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_connect_button_pressed() -> void:
	behavior_ui.force_open = true
	connect_button.text = "Click a room..."
	
	CreatorRoomManipulation.room_clicked.connect(func(room_index: int) -> void:
		behavior_ui.force_open = false
		tile.room_transition_index = room_index
		tile.room_transition_coords = Global.mouse_coords
		connect_button.text = "Connected to Room %d (%d, %d)" % [room_index, Global.mouse_coords.x, Global.mouse_coords.y]
	, ConnectFlags.CONNECT_ONE_SHOT)


func _on_option_button_item_selected(index: int) -> void:
	tile.room_transition_trigger = option_button.get_item_text(index)
