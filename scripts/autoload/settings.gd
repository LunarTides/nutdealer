extends Node

signal changed

var path: String = "user://settings.cfg"
var creator: CreatorSettings = CreatorSettings.new()

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	load_settings()
	
	creator.changed.connect(changed.emit)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		save_settings()

func save_settings() -> void:
	var settings: ConfigFile = ConfigFile.new()
	
	settings.set_value("creator", "party_members_enabled", creator.party_members_enabled)
	
	settings.save(path)

func load_settings() -> void:
	if not FileAccess.file_exists(path):
		return
	
	var settings: ConfigFile = ConfigFile.new()
	settings.load(path)
	
	for key: String in settings.get_section_keys("creator"):
		var value: Variant = settings.get_value("creator", key)
		creator.set(key, value)
