extends Control

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	hide()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"pause_menu"):
		visible = not visible

func _on_close_button_pressed() -> void:
	hide()


func _on_exit_to_menu_button_pressed() -> void:
	exit_to_menu()

func _on_exit_to_desktop_button_pressed() -> void:
	exit_to_desktop()

func exit_to_menu() -> void:
	if not Creator.dirty:
		force_exit_to_menu()
		return
	
	# Ask to save first.
	WorldSave.save_then(force_exit_to_menu)

func force_exit_to_menu() -> void:
	get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")
	Creator.stop()
	queue_free()

func exit_to_desktop() -> void:
	if not Creator.dirty:
		force_exit_to_desktop()
		return
	
	# Ask to save first.
	WorldSave.save_then(force_exit_to_desktop)

func force_exit_to_desktop() -> void:
	get_tree().quit()
