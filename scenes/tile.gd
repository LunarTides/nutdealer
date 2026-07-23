extends Node2D
class_name Tile

const CREATOR_TILE_BEHAVIOUR_UI: PackedScene = preload("uid://b7xjlu3flg8wu")

signal id_changed

@export var texture: Texture2D:
	set(value):
		texture = value
		
		if is_inside_tree():
			sprite_2d.texture = texture
			regenerate_id()
@export var is_solid: bool = false:
	set(value):
		is_solid = value
		
		if is_inside_tree():
			if is_solid:
				static_body_2d.collision_layer |= 1
			elif static_body_2d.collision_layer & 1 == 1:
				static_body_2d.collision_layer ^= 1
			
			regenerate_id()
@export var should_hide_during_play: bool = false:
	set(value):
		should_hide_during_play = value
		
		if is_inside_tree():
			regenerate_id()
@export var is_room_start_position: bool = false:
	set(value):
		is_room_start_position = value
		
		if is_inside_tree():
			regenerate_id()
# TODO: Remove this and replace it with more generic `encounter` property with different options.
@export var encounter_on_interact: bool = false:
	set(value):
		encounter_on_interact = value
		
		if is_inside_tree():
			regenerate_id()
@export_storage var logic_script_path: String

var id: String = "null":
	set(value):
		id = value
		
		if is_inside_tree() and is_instance_valid(id_label):
			id_label.text = id
		
		id_changed.emit()
var coords: Vector2i:
	get:
		return Global.position_to_coords(global_position)
	set(value):
		global_position = Global.coords_to_position(value)
var room_index: int:
	get:
		return Room.position_to_room_index(global_position)
var logic_script: GDScript:
	set(value):
		logic_script = value
		
		if is_inside_tree():
			if is_instance_valid(logic_script):
				logic.set_script(logic_script)
			
			regenerate_id()
var logic_script_name: String:
	get:
		return logic_script_path.split("/")[-1].replace(".gd", "")
var logic_script_dirty: bool = false
var is_encounter: bool:
	get:
		return encounter_on_interact

@onready var static_body_2d: StaticBody2D = $StaticBody2D
@onready var sprite_2d: Sprite2D = $StaticBody2D/Sprite2D
@onready var collision_shape_2d: CollisionShape2D = $StaticBody2D/CollisionShape2D
@onready var actions: PanelContainer = $Actions
@onready var id_label: Label = $Actions/VBoxContainer/IDLabel
# TODO: Call _room_enter and _room_exit when entering / exiting room.
@onready var logic: TileLogic = $Logic

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	sprite_2d.texture = texture
	if is_solid:
		static_body_2d.collision_layer |= 1
	elif static_body_2d.collision_layer & 1 == 1:
		static_body_2d.collision_layer ^= 1
	
	static_body_2d.mouse_entered.connect(_on_mouse_entered)
	static_body_2d.mouse_exited.connect(_on_mouse_exited)
	
	if id == "null":
		regenerate_id()
	id_label.text = id
	
	actions.hide()
	if not Creator.enabled:
		actions.queue_free()
	
	logic.process_mode = Node.PROCESS_MODE_DISABLED
	Game.play_start.connect(func() -> void:
		if should_hide_during_play:
			hide()
		
		logic.process_mode = Node.PROCESS_MODE_PAUSABLE
	)
	Game.play_end.connect(func() -> void:
		if should_hide_during_play and not visible:
			show()
		
		logic.process_mode = Node.PROCESS_MODE_DISABLED
	)
	
	# Load script.
	if logic_script_path:
		var script: GDScript = load(logic_script_path)
		set_logic_script_to(script)
	
	# Change script path to reflect new world folder location.
	WorldSave.first_save_begun.connect(func() -> void:
		if not logic_script_path:
			return
		
		var relative_path: String = logic_script_path.split("/temp")[1]
		logic_script_path = CreatorResourceSaver.get_full_path(relative_path)
		logic_script.resource_path = logic_script_path
		logic.script.resource_path = logic_script_path
	)
	
	# Keep invisible if it should hide during play.
	visibility_changed.connect(func() -> void:
		if Game.playing and should_hide_during_play:
			hide()
	)
	
	# Call the `_ready` function on the tile if we're actually playing. (Not creating.)
	if not Creator.enabled:
		logic._ready()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if Creator.enabled and not actions.get_global_rect().has_point(Global.mouse_position):
			# Clicked outside window.
			self_modulate = Color.WHITE
			actions.hide()


func _on_delete_button_pressed() -> void:
	queue_free()


func _on_copy_button_pressed() -> void:
	var new_tile: Tile = clone()
	CreatorPlaceTiles.start(new_tile)
	self_modulate = Color.WHITE
	actions.hide()


func _on_move_button_pressed() -> void:
	var new_tile: Tile = clone()
	CreatorPlaceTiles.start(new_tile)
	queue_free()

func _on_behaviour_button_pressed() -> void:
	# Spawn behaviour ui to the right of the tile.
	var ui: Control = CREATOR_TILE_BEHAVIOUR_UI.instantiate()
	ui.tile = self
	Creator.dark_world_ui.add_child(ui)
	ui.global_position = position + Vector2(64, 0)
	actions.hide()

func interact() -> void:
	logic._interact()
	
	if encounter_on_interact:
		Encounter.start(self)

func disable() -> void:
	hide()
	process_mode = Node.PROCESS_MODE_DISABLED

func enable() -> void:
	show()
	process_mode = Node.PROCESS_MODE_ALWAYS

func clone(new_id: bool = false) -> Tile:
	var new_tile: Tile = duplicate(DUPLICATE_DEFAULT | DUPLICATE_INTERNAL_STATE)
	if new_id:
		new_tile.regenerate_id()
	return new_tile

func create_logic_script(text: String, path: String) -> void:
	# New script.
	var script: GDScript = GDScript.new()
	script.source_code = text
	
	CreatorResourceSaver.save(script, path)
	# For some reason, we have to reload the script in order for it to work.
	script.reload()
	logic_script = script
	if not logic_script_path:
		logic_script_path = script.resource_path

func update_logic_script(text: String) -> void:
	# Update script.
	if not is_instance_valid(logic_script):
		Game.feedback("No logic script to update. Please call create_logic_script first.", Game.FeedbackType.Error)
		return
	
	logic_script.source_code = text
	CreatorResourceSaver.save(logic_script)
	logic_script.reload(true)
	logic.script = logic_script

func set_logic_script_to(script: GDScript) -> void:
	script.reload()
	logic_script = script
	if not logic_script_path and script.resource_path:
		logic_script_path = script.resource_path

func _on_mouse_entered() -> void:
	if Creator.enabled:
		sprite_2d.self_modulate *= 1.25


func _on_mouse_exited() -> void:
	if Creator.enabled:
		sprite_2d.self_modulate = Color.WHITE


func _on_static_body_2d_input_event(viewport: Node, event: InputEvent, shape_idx: int) -> void:
	if Creator.enabled and not actions.visible and event is InputEventMouseButton and event.pressed:
		actions.global_position = Global.mouse_position
		self_modulate *= 1.25
		actions.show()

func regenerate_id() -> void:
	var chars: String = "abcdefghijklmnopqrstuvwxyz"
	
	var new_id: String = ""
	for _i: int in range(8):
		new_id += chars[randi_range(0, chars.length() - 1)]
	id = new_id
	
	# Anything that causes the id to be regenerated is a dirty operation.
	Creator.make_dirty()
