extends HBoxContainer

@export var preview_button: Button


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Game.play_start.connect(func() -> void:
		preview_button.text = "Stop"
	)
	Game.play_end.connect(func() -> void:
		preview_button.text = "Preview"
	)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_preview_button_pressed() -> void:
	if Game.playing:
		Creator.stop_preview()
	else:
		Creator.start_preview()
