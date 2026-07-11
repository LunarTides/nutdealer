extends Control

@export var tab_container: TabContainer
@export var check_box_container: VBoxContainer

var tile: Tile

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	for check_box: TileBehaviourCheckBox in check_box_container.get_children():
		if check_box is not TileBehaviourCheckBox:
			return
		
		check_box.tile = tile

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		if not tab_container.get_global_rect().has_point(get_global_mouse_position()):
			# Clicked outside window.
			queue_free()
