extends Node


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	delete_temp_folder()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func get_full_path(relative_path: String) -> String:
	if relative_path.begins_with("user://") or relative_path.begins_with("/home/") or relative_path.begins_with("C:/"):
		return relative_path
	
	var full_path: String = "user://worlds/%s%s" % [Creator.world_name, relative_path]
	if not Creator.world_name:
		create_temp_folder()
		full_path = "user://temp%s" % relative_path
	
	return full_path

func get_relative_path(full_path: String) -> String:
	var world_name: String = Creator.world_name if Creator.world_name else "temp"
	var split: PackedStringArray = full_path.split(world_name)
	if split.size() <= 1:
		return full_path
	
	return split[1]

func save(resource: Resource, path: String = "") -> void:
	var full_path: String = get_full_path(path)
	if path:
		resource.take_over_path(full_path)
	
	# Recursively make the folder.
	var folder: String = "/".join(full_path.split("/").slice(0, -1))
	DirAccess.make_dir_recursive_absolute(folder)
	
	ResourceSaver.save(resource)

func load_resource(path: String) -> Resource:
	var full_path: String = get_full_path(path)
	return load(full_path)

func exists(path: String) -> bool:
	var full_path: String = get_full_path(path)
	return DirAccess.dir_exists_absolute(full_path)

func copy(from: String, to: String) -> void:
	var full_from: String = get_full_path(from)
	if not FileAccess.file_exists(full_from):
		return
	
	var full_to: String = get_full_path(to)
	
	# Recursively make the folder.
	var folder: String = "/".join(full_to.split("/").slice(0, -1))
	DirAccess.make_dir_recursive_absolute(folder)
	
	DirAccess.copy_absolute(full_from, full_to)

func create_temp_folder() -> void:
	DirAccess.make_dir_absolute("user://temp")

func delete_temp_folder() -> void:
	remove_recursive("user://temp")

func remove_recursive(directory: String) -> bool:
	# If the directory doesn't exist, return.
	if not DirAccess.dir_exists_absolute(directory):
		return false
	
	for dir_name: String in DirAccess.get_directories_at(directory):
		remove_recursive(directory.path_join(dir_name))
	for file_name: String in DirAccess.get_files_at(directory):
		DirAccess.remove_absolute(directory.path_join(file_name))
	
	DirAccess.remove_absolute(directory)
	return true
