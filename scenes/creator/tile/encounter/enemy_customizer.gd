extends Control

@export_category("UI Nodes")
@export var name_input: LineEdit
@export var health_input: LineEdit

var tile: Tile
var enemy_index: int = 0:
	set(value):
		enemy_index = value
		update_ui()
var enemy: EncounterEnemy:
	get:
		if not is_instance_valid(tile) or not is_instance_valid(tile.encounter):
			return
		
		return tile.encounter.enemies[enemy_index]

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	update_ui()
	hide()
	#enemy.changed.connect(update_ui)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_name_input_text_changed(new_text: String) -> void:
	enemy.name = new_text


func _on_health_input_text_changed(new_text: String) -> void:
	if not new_text.is_valid_int():
		Game.feedback("Invalid health.", Game.FeedbackType.Error)
		return
	
	enemy.health = new_text.to_int()

func update_ui() -> void:
	if not enemy or Engine.is_editor_hint():
		return
	
	name_input.text = enemy.name
	health_input.text = str(enemy.health)
