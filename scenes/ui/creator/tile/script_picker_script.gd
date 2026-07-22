extends VBoxContainer
class_name TileScriptPickerScript

signal clicked

@export var data: TileScriptData:
	set(value):
		data = value
		reload_ui()

@export_category("UI Nodes")
@export var name_label: Label
@export var instances_label: Label

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if is_instance_valid(data):
		data.changed.connect(reload_ui)

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.is_released():
			clicked.emit()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func reload_ui() -> void:
	name_label.text = data.name
	instances_label.text = "Instances: %d" % data.instances
