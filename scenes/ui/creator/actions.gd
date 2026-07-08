extends HBoxContainer

@export var play_button: Button


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Game.play_start.connect(func() -> void:
		play_button.text = "Stop"
	)
	Game.play_end.connect(func() -> void:
		play_button.text = "Play"
	)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_play_button_pressed() -> void:
	if Game.playing:
		Creator.stop_playing()
	else:
		Creator.start_playing()
