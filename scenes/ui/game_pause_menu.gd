extends Control

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	hide()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	#global_position = Global.screen_size / 3
	pass

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"pause_menu"):
		visible = not visible
		get_tree().paused = visible

func _on_close_button_pressed() -> void:
	hide()
	get_tree().paused = false


func _on_exit_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")
	Game.stop_playing()
	get_tree().paused = false
