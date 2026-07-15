extends Control

const SCRIPT_FIRST_SAVE_DIALOGUE: PackedScene = preload("uid://c243swkrxn171")
const TILE_SCRIPT_PICKER: PackedScene = preload("uid://kkq2d5rx0xkf")

@export var tab_container: TabContainer
@export var check_box_container: VBoxContainer
@export var code_edit: CodeEdit

var tile: Tile
var code_intro: String = "extends Node2D

var tile:
	get:
		return get_parent()

"

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	for check_box: TileBehaviourCheckBox in check_box_container.get_children():
		if check_box is not TileBehaviourCheckBox:
			return
		
		check_box.tile = tile
	
	reload_ui()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		if not tab_container.get_global_rect().has_point(get_global_mouse_position()):
			# Clicked outside window.
			queue_free()

func reload_ui() -> void:
	if is_instance_valid(tile.logic_script):
		code_edit.text = tile.logic_script.source_code.replace(code_intro, "")

# TODO: Add proper feedback.
func _on_save_button_pressed() -> void:
	var code: String = "%s%s" % [code_intro, code_edit.text]
	
	if not tile.logic_script_path:
		var dialogue: ConfirmationDialog = SCRIPT_FIRST_SAVE_DIALOGUE.instantiate()
		dialogue.confirmed.connect(func() -> void:
			var script_name: String = dialogue.get_node(^"ScriptName").text
			if not script_name:
				return
			
			var path: String = "/tiles/scripts/%s.gd" % script_name
			
			# Check conflict. Ask before for overriding.
			if CreatorResourceSaver.exists(path):
				# TODO: Show to user.
				push_error("Conflict.")
				return
			
			# No conflict. Save.
			tile.set_logic_script(code, path)
			dialogue.queue_free()
		)
		dialogue.canceled.connect(func() -> void:
			dialogue.queue_free()
		)
		add_child(dialogue)
		dialogue.popup_centered_clamped()
		# Place focus on the world name input.
		dialogue.get_node(^"ScriptName").grab_focus()
		return
	
	tile.set_logic_script(code)


func _on_load_button_pressed() -> void:
	# FIXME: If we load a script, save then leave the world, then open the world again,
	# the tiles have different scripts again.
	var script_picker: TileScriptPicker = TILE_SCRIPT_PICKER.instantiate()
	script_picker.chosen.connect(func(data: TileScriptData) -> void:
		tile.logic_script = data.tile_script
		tile.logic_script_path = data.path
		reload_ui()
	)
	Game.canvas_layer.add_child(script_picker)
