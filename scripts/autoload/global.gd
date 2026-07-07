extends Node


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	get_window().min_size = Vector2(1152, 640)
	
	# TODO: Remove. Enable creator.
	await get_tree().process_frame
	Creator.start()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
