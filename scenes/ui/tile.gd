extends Node2D
class_name Tile

const CREATOR_TILE_BEHAVIOUR_UI: PackedScene = preload("uid://b7xjlu3flg8wu")

@export var static_body_2d: StaticBody2D
@export var sprite_2d: Sprite2D
@export var collision_shape_2d: CollisionShape2D
@export var actions: PanelContainer
@export var id_label: Label

var texture: Texture2D:
	set(value):
		texture = value
		sprite_2d.texture = texture
		
		regenerate_id()
var coords: Vector2i:
	get:
		return Global.position_to_coords(global_position)
var id: String = "null":
	set(value):
		id = value
		id_label.text = id
var is_solid: bool = false:
	set(value):
		is_solid = value
		
		if is_solid:
			static_body_2d.collision_layer |= 1
		elif static_body_2d.collision_layer & 1 == 1:
			static_body_2d.collision_layer ^= 1
		
		regenerate_id()

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
	
	actions.hide()
	if not Creator.enabled:
		actions.queue_free()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		if not actions.get_global_rect().has_point(Global.mouse_position):
			# Clicked outside window.
			self_modulate = Color.WHITE
			actions.hide()


func _on_delete_button_pressed() -> void:
	queue_free()


func _on_copy_button_pressed() -> void:
	var new_tile: Tile = clone()
	Creator.start_tile_placing(new_tile)
	self_modulate = Color.WHITE
	actions.hide()


func _on_move_button_pressed() -> void:
	var new_tile: Tile = clone()
	Creator.start_tile_placing(new_tile)
	queue_free()

func _on_behaviour_button_pressed() -> void:
	# Spawn behaviour ui to the right of the tile.
	var ui: Control = CREATOR_TILE_BEHAVIOUR_UI.instantiate()
	ui.tile = self
	Creator.dark_world_ui.add_child(ui)
	ui.global_position = position + Vector2(64, 0)
	actions.hide()

func interact() -> void:
	# TODO: Temp. Remove this.
	sprite_2d.self_modulate /= 1.25

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

func _on_mouse_entered() -> void:
	if Creator.enabled:
		sprite_2d.self_modulate *= 1.25


func _on_mouse_exited() -> void:
	if Creator.enabled:
		sprite_2d.self_modulate = Color.WHITE


func _on_static_body_2d_input_event(viewport: Node, event: InputEvent, shape_idx: int) -> void:
	if not actions.visible and event is InputEventMouseButton and event.pressed:
		actions.global_position = Global.mouse_position
		self_modulate *= 1.25
		actions.show()

func regenerate_id() -> void:
	var chars: String = "abcdefghijklmnopqrstuvwxyz"
	
	var new_id: String = ""
	for _i: int in range(8):
		new_id += chars[randi_range(0, chars.length() - 1)]
	id = new_id
