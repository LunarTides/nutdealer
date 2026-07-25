extends Control

signal closed

@export var party_members_check_box: CheckBox

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	party_members_check_box.button_pressed = Settings.creator.party_members_enabled


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_party_members_check_box_toggled(toggled_on: bool) -> void:
	Settings.creator.party_members_enabled = toggled_on


func _on_close_button_pressed() -> void:
	closed.emit()
	queue_free()
