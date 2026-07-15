extends Resource
class_name TileScriptData

@export var name: String:
	set(value):
		if name != value:
			name = value
			emit_changed()
@export var path: String:
	set(value):
		if path != value:
			path = value
			emit_changed()
@export var instances: int = 0:
	set(value):
		if instances != value:
			instances = value
			emit_changed()
@export var tile_script: GDScript:
	set(value):
		if tile_script != value:
			tile_script = value
			emit_changed()
