extends VBoxContainer

@export var enemy: EncounterEnemy

@export_category("UI Nodes")
@export var name_label: Label
@export var health_label: Label

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	update_ui()
	enemy.changed.connect(update_ui)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func update_ui() -> void:
	name_label.text = enemy.name
	health_label.text = "Health: %d" % enemy.health
