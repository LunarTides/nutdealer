extends PanelContainer

@export var name_input: LineEdit
@export var health_input: LineEdit

var tile: Tile
var encounter_index: int = 0
var encounter_data: EncounterData:
	get:
		return tile.encounter_datas[encounter_index]

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	update_ui()
	#encounter_data.changed.connect(update_ui)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_name_input_text_changed(new_text: String) -> void:
	encounter_data.name = new_text


func _on_health_input_text_changed(new_text: String) -> void:
	if not new_text.is_valid_int():
		Game.feedback("Invalid health.", Game.FeedbackType.Error)
		return
	
	encounter_data.health = new_text.to_int()

func update_ui() -> void:
	name_input.text = encounter_data.name
	health_input.text = str(encounter_data.health)
