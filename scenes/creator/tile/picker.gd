extends ItemList

const TILE: PackedScene = preload("uid://cfme7hrx25bgv")
const IMPORT_TEXTURE_DIALOGUE: PackedScene = preload("uid://m13iyxlbc6ii")

const TILE_SFX: AudioStream = preload("res://assets/audio/sfx/bell_bounce_short.wav")
const IMPORT_SFX: AudioStream = preload("res://assets/audio/sfx/coaster_kiss.wav")

var special_tile_amount: int = 2

@export var sfx_player: AudioStreamPlayer

# Called when the node enters the scene tree for the first time.
func _ready() -> void:	
	# TODO: Collapse instead of hiding.
	#Game.play_start.connect(func():
		#hide()
	#)
	#Game.play_end.connect(func():
		#show()
	#)
	
	Game.mode_changed.connect(func(old: Game.Mode, new: Game.Mode) -> void:
		visible = new == Game.Mode.DarkWorld
	)
	Creator.mode_changed.connect(func(old: Creator.Mode, new: Creator.Mode) -> void:
		if new == Creator.Mode.Brush:
			var items: PackedInt32Array = get_selected_items()
			var index: int = 0
			if items.size() > 0:
				index = items[0]
			
			item_clicked.emit(index, Global.mouse_position, MOUSE_BUTTON_LEFT)
	)
	
	WorldSave.load_ended.connect(func() -> void:
		for texture: ImageTexture in GameData.custom_tile_textures:
			var idx: int = add_icon_item(texture)
			move_item(idx, idx - special_tile_amount)
	)
	WorldSave.new_world_begun.connect(func() -> void:
		for texture: ImageTexture in GameData.custom_tile_textures:
			remove_item(item_count - special_tile_amount - 1)
	)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_item_clicked(index: int, at_position: Vector2, mouse_button_index: int) -> void:
	# Import
	if index == item_count - 1:
		deselect_all()
		
		sfx_player.stream = IMPORT_SFX
		sfx_player.play()
		
		var import_dialogue: FileDialog = IMPORT_TEXTURE_DIALOGUE.instantiate()
		import_dialogue.files_selected.connect(func(paths: PackedStringArray) -> void:
			for path: String in paths:
				var new_path: String = CreatorResourceSaver.get_full_path("/tiles/textures/%s" % path.split("/")[-1])
				CreatorResourceSaver.copy(path, new_path)
				
				var image: Image = Image.load_from_file(new_path)
				var image_texture: ImageTexture = ImageTexture.create_from_image(image)
				image_texture.resource_path = new_path
				GameData.custom_tile_textures.append(image_texture)
				
				var idx: int = add_icon_item(image_texture)
				move_item(idx, idx - special_tile_amount)
			
			import_dialogue.queue_free()
		)
		import_dialogue.canceled.connect(import_dialogue.queue_free)
		add_child(import_dialogue)
		import_dialogue.popup_file_dialog()
		return
	
	var texture: Texture2D = get_item_icon(index)
	var tile: Tile = TILE.instantiate()
	tile.texture = texture
	
	CreatorPlaceTiles.start(tile)
	
	sfx_player.stream = TILE_SFX
	sfx_player.play()
	
	# Eraser
	if index == item_count - 2:
		CreatorPlaceTiles.should_erase = true


func _on_empty_clicked(at_position: Vector2, mouse_button_index: int) -> void:
	if Creator.mode == Creator.Mode.Brush:
		Creator.mode = Creator.Mode.Select
