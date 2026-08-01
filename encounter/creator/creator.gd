extends Control

const ENEMY_INFO: PackedScene = preload("uid://cxr3ttkfmv0mw")

@export_category("UI Nodes")
@export var enemy_infos: TabContainer
@export var end_encounter_button: Button
@export var end_encounter_without_animation_button: Button

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	visible = Creator.enabled
	
	for child: Control in enemy_infos.get_children():
		# Rename so it doesn't conflict with the new encounter infos later.
		child.name = "0"
		child.queue_free()
	
	for i: int in range(Encounter.enemies.size()):
		var enemy: EncounterEnemy = Encounter.enemies[i]
		var enemy_info: Control = ENEMY_INFO.instantiate()
		enemy_info.enemy = enemy
		enemy_infos.add_child(enemy_info)
		enemy_info.name = str(i + 1)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _on_end_encounter_button_pressed() -> void:
	end_encounter_button.hide()
	end_encounter_without_animation_button.hide()
	Encounter.end(true)


func _on_end_encounter_without_animation_button_pressed() -> void:
	end_encounter_button.hide()
	end_encounter_without_animation_button.hide()
	Encounter.end(true, true)
