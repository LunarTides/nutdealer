extends Node


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func all_tile_scripts() -> Array[TileScriptData]:
	var path: String = CreatorResourceSaver.get_full_path("/tiles/scripts")
	if not DirAccess.dir_exists_absolute(path):
		return []
	
	var scripts: Array[TileScriptData] = []
	
	var script_names: PackedStringArray = DirAccess.get_files_at(path)
	for script_name: String in script_names:
		var data: TileScriptData = TileScriptData.new()
		data.name = script_name
		
		var file_path: String = "%s/%s" % [path, script_name]
		data.path = file_path
		#data.source_code = FileAccess.get_file_as_string(file_path)
		
		# Set instances
		var instances: int = 0
		var tile_script: GDScript
		
		for tile: Tile in Game.tiles.get_children():
			if tile.logic_script_path == file_path:
				instances += 1
				tile_script = tile.logic_script
		data.instances = instances
		data.tile_script = tile_script
		
		scripts.append(data)
	
	return scripts
