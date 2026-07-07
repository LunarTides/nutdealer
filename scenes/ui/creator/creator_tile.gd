extends TextureButton
class_name CreatorTile

@export var actions: PanelContainer

var texture: Texture2D
var coords: Vector2i:
	get:
		return Global.position_to_coords(global_position)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	texture_normal = texture
	pressed.connect(_on_pressed)
	
	actions.hide()
	if not Creator.enabled:
		actions.queue_free()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		if not actions.get_global_rect().has_point(get_global_mouse_position()):
			self_modulate = Color.WHITE
			actions.hide()


func _on_pressed() -> void:
	actions.global_position = get_global_mouse_position()
	self_modulate *= 1.25
	actions.show()


func _on_delete_button_pressed() -> void:
	queue_free()


func _on_copy_button_pressed() -> void:
	# TODO: Actually copy the entire tile instead of the texture.
	Creator.start_tile_placing(texture)
	self_modulate = Color.WHITE
	actions.hide()


func _on_move_button_pressed() -> void:
	# TODO: Actually copy the entire tile instead of the texture.
	Creator.start_tile_placing(texture)
	queue_free()
