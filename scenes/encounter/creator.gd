extends Control

const ENCOUNTER_INFO: PackedScene = preload("uid://cxr3ttkfmv0mw")

@export_category("UI Nodes")
@export var encounter_infos: TabContainer
@export var end_encounter_button: Button

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	visible = Creator.enabled
	
	for child: Control in encounter_infos.get_children():
		# Rename so it doesn't conflict with the new encounter infos later.
		child.name = "0"
		child.queue_free()
	
	for i: int in range(Encounter.encounter_datas.size()):
		var encounter_data: EncounterData = Encounter.encounter_datas[i]
		var encounter_info: Control = ENCOUNTER_INFO.instantiate()
		encounter_info.encounter_data = encounter_data
		encounter_infos.add_child(encounter_info)
		encounter_info.name = str(i + 1)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _on_end_encounter_button_pressed() -> void:
	Encounter.end()
