extends HBoxContainer

@export var play_button: Button


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_play_button_pressed() -> void:
	if Game.playing:
		Creator.stop_playing()
		play_button.text = "Play"
	else:
		Creator.start_playing()
		play_button.text = "Stop"
