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


func _on_exit_button_pressed() -> void:
	if not Creator.dirty:
		exit()
		return
	
	# Ask to save first.
	if CreatorSave.has_saved_once:
		CreatorSave.create_save_dialogue(func(confirmed: bool) -> void:
			exit()
		)
	else:
		CreatorSave.create_save_dialogue(func(confirmed: bool) -> void:
			if not confirmed:
				exit()
				return
			
			CreatorSave.create_first_save_dialogue(func(first_saved: bool) -> void:
				if first_saved:
					exit()
			)
		)

func exit() -> void:
	get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")
	Creator.stop()
