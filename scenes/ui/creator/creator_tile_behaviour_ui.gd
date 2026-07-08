extends Control

@export var tab_container: TabContainer
@export var solid_check_box: CheckBox

var tile: Tile

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	solid_check_box.button_pressed = tile.is_solid


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		if not tab_container.get_global_rect().has_point(get_global_mouse_position()):
			# Clicked outside window.
			queue_free()

func _on_solid_check_box_toggled(toggled_on: bool) -> void:
	if not is_instance_valid(tile):
		push_error("Invalid tile")
		return
	
	tile.is_solid = toggled_on
