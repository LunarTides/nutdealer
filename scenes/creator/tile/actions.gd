extends PanelContainer

#const BEHAVIOUR_UI: PackedScene = preload("uid://b7xjlu3flg8wu")

@export var tile: Tile
@export var static_body_2d: StaticBody2D
@export var id_label: Label

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	hide()
	id_label.text = tile.id
	
	if not Creator.enabled:
		queue_free()
	
	static_body_2d.input_event.connect(_on_static_body_2d_input_event)
	tile.id_changed.connect(func() -> void:
		id_label.text = tile.id
	)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if Creator.enabled and not get_global_rect().has_point(Global.mouse_position):
			# Clicked outside window.
			tile.self_modulate = Color.WHITE
			hide()

func _on_static_body_2d_input_event(viewport: Node, event: InputEvent, shape_idx: int) -> void:
	if Creator.enabled and not visible and event is InputEventMouseButton and event.pressed:
		global_position = Global.mouse_position
		tile.self_modulate *= 1.25
		show()

func _on_delete_button_pressed() -> void:
	tile.queue_free()


func _on_copy_button_pressed() -> void:
	var new_tile: Tile = tile.clone()
	CreatorPlaceTiles.start(new_tile)
	tile.self_modulate = Color.WHITE
	hide()


func _on_move_button_pressed() -> void:
	var new_tile: Tile = tile.clone()
	CreatorPlaceTiles.start(new_tile)
	tile.queue_free()
	
	# Automatically stop the tile placement after one tile.
	CreatorPlaceTiles.placed.connect(CreatorPlaceTiles.stop, ConnectFlags.CONNECT_ONE_SHOT)

func _on_behaviour_button_pressed() -> void:
	# Spawn behaviour ui to the right of the tile.
	# NOTE: For some reason, I just literally cannot preload this scene.
	# Why, Godot? Why? 0 node count? OK.
	var packed_ui: PackedScene = load("uid://b7xjlu3flg8wu")
	var ui: Control = packed_ui.instantiate()
	ui.tile = tile
	Creator.dark_world_ui.add_child(ui)
	ui.global_position = tile.position + Vector2(64, 0)
	hide()
