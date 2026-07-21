extends HBoxContainer

@export var file_menu_button: MenuButton
@export var edit_menu_button: MenuButton
@export var help_menu_button: MenuButton
@export var preview_options_menu_button: MenuButton
@export var preview_button: Button


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Game.play_start.connect(func() -> void:
		preview_button.text = "Stop"
	)
	Game.play_end.connect(func() -> void:
		preview_button.text = "Preview"
	)
	
	setup_menu_buttons()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_preview_button_pressed() -> void:
	if Game.playing:
		Creator.stop_preview()
	else:
		use_preview_options()
		Creator.start_preview()


func setup_menu_buttons() -> void:
	# File
	file_menu_button.get_popup().id_pressed.connect(func(id: int) -> void:
		# New
		if id == 0:
			WorldSave.new_world_or_save()
		# Open
		elif id == 1:
			WorldSave.open_world_or_save()
		# Save
		elif id == 2:
			WorldSave.save_world()
	)
	
	# Edit
	edit_menu_button.get_popup().id_pressed.connect(func(id: int) -> void:
		# All: _ready
		if id == 0:
			for tile: Tile in Game.tiles.get_all():
				if is_instance_valid(tile.logic):
					tile.logic._ready()
	)
	
	# Help
	help_menu_button.get_popup().id_pressed.connect(func(id: int) -> void:
		var dialogue: AcceptDialog = AcceptDialog.new()
		add_child(dialogue)
		
		# Licenses
		if id == 0:
			dialogue.title = "Licenses"
			dialogue.size = Global.screen_size - Vector2(420, 0) # nice
			# Popup immediately to reduce latency.
			dialogue.popup_centered_clamped()
			
			var scroll_container: ScrollContainer = ScrollContainer.new()
			dialogue.add_child(scroll_container)
			var label: Label = Label.new()
			scroll_container.add_child(label)
			
			var font: SystemFont = SystemFont.new()
			font.font_names = ["sans-serif", "monospace"]
			label.add_theme_font_override(&"font", font)
			
			# Add license info to label
			label.text += "NUTDEALER is licensed under the GPL-3.0 license.\n\n"
			label.text += FileAccess.get_file_as_string("res://LICENSE")
			label.text += "\n\n\n\n\n\n\n\n" # Just add a bunch of newlines to seperate the two licenses.
			label.text += "NUTDEALER uses the Godot game engine, which is licensed under the MIT license:\n"
			label.text += Engine.get_license_text()
		# About
		elif id == 1:
			dialogue.title = "About"
			dialogue.size = Vector2(512, 128)
			dialogue.popup_centered_clamped()
			
			var label: RichTextLabel = RichTextLabel.new()
			label.text += "NUTDEALER v%s\n" % ProjectSettings.get_setting("application/config/version")
			label.text += "Made with [color=ff6666]<3[/color] by [url=https://lunartides.dev][color=999]Lunar[/color][color=fff]Tides[/color][/url]"
			label.meta_clicked.connect(func(meta: Variant) -> void:
				OS.shell_open(str(meta))
			)
			label.bbcode_enabled = true
			dialogue.add_child(label)
	)
	
	# Preview Options
	var preview_options_popup: PopupMenu = preview_options_menu_button.get_popup()
	preview_options_popup.hide_on_checkable_item_selection = false
	preview_options_popup.id_pressed.connect(func(id: int) -> void:
		if preview_options_popup.is_item_checkable(id):
			preview_options_popup.toggle_item_checked(id)
	)

func use_preview_options() -> void:
	var preview_options_popup: PopupMenu = preview_options_menu_button.get_popup()
	
	for index: int in preview_options_popup.item_count:
		var id: int = preview_options_popup.get_item_id(index)
		if not preview_options_popup.is_item_checked(id):
			continue
		
		# All: _ready
		if id == 0:
			for tile: Tile in Game.tiles.get_all():
				if is_instance_valid(tile.logic):
					tile.logic._ready()
