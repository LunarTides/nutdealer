extends Control

@export var pan_speed: float = 300

@export_category("UI Nodes")
@export var grid_hint: TextureRect
@export var camera_2d: Camera2D

var old_camera_2d_position: Vector2


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	camera_2d.global_position = Global.screen_size / 2
	
	# Move the grid hint a little left and make it a little bigger.
	# This removes any gaps that would give away the illusion of an infinite plane.
	grid_hint.position -= Vector2(64, 64)
	grid_hint.size = Global.screen_size + Vector2(64 * 4, 64 * 4)
	
	Game.play_start.connect(func():
		grid_hint.hide()
		camera_2d.enabled = false
	)
	Game.play_end.connect(func():
		# Move the camera to the player's position.
		camera_2d.global_position = Game.controlling_character.global_position
		camera_2d.enabled = true
		
		# Move the grid hint to the camera's position.
		grid_hint.show()
		grid_hint.global_position = Global.align_to_grid(camera_2d.global_position) - Global.screen_size / 2
		# Reset the old camera position since, otherwise,
		# the difference calculation would kick in and move the
		# grid hint too far away from the camera.
		old_camera_2d_position = Vector2.ZERO
	)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if camera_2d.enabled:
		# Camera panning
		var true_pan_speed: float = pan_speed
		if Input.is_action_pressed(&"editor_pan_speed_up"):
			true_pan_speed *= 5
		
		var vector = Input.get_vector(&"editor_pan_left", &"editor_pan_right", &"editor_pan_up", &"editor_pan_down")
		if vector:
			camera_2d.position += vector * true_pan_speed * delta
			
			# Move the grid hint to give an illusion that it's an infinite plane.
			if old_camera_2d_position:
				var new_coords: Vector2i = Global.position_to_coords(camera_2d.position)
				var old_coords: Vector2i = Global.position_to_coords(old_camera_2d_position)
				if new_coords != old_coords:
					var difference: Vector2i = (new_coords - old_coords)
					grid_hint.position += Global.coords_to_position(difference)
			old_camera_2d_position = camera_2d.position
			
