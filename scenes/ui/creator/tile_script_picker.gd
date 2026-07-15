extends Control
class_name TileScriptPicker

signal chosen(script_data: TileScriptData)

const TILE_SCRIPT_PICKER_SCRIPT: PackedScene = preload("uid://cwxrfwnkpdf8x")

@export var panel_container: PanelContainer
@export var script_container: VBoxContainer

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	for child: TileScriptPickerScript in script_container.get_children():
		child.queue_free()
	
	for data: TileScriptData in GameData.all_tile_scripts():
		var script_ui: TileScriptPickerScript = TILE_SCRIPT_PICKER_SCRIPT.instantiate()
		script_ui.data = data
		script_ui.clicked.connect(func() -> void:
			chosen.emit(data)
			queue_free()
		)
		script_container.add_child(script_ui)

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		if not panel_container.get_global_rect().has_point(get_global_mouse_position()):
			# Clicked outside window.
			queue_free()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
