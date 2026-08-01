extends Resource
class_name AudioSettings

@export var master_volume: float = 1.0:
	set(value):
		if master_volume != value:
			master_volume = value
			emit_changed()
			
			var master_idx: int = AudioServer.get_bus_index(&"Master")
			AudioServer.set_bus_volume_linear(master_idx, master_volume)
@export var music_volume: float = 1.0:
	set(value):
		if music_volume != value:
			music_volume = value
			emit_changed()
			
			var music_idx: int = AudioServer.get_bus_index(&"Music")
			AudioServer.set_bus_volume_linear(music_idx, music_volume)
