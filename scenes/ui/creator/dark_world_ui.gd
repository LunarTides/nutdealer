extends Control
class_name CreatorDarkWorldUI

@export var pan_speed: float = 300

@export_category("UI Nodes")
@export var grid_hint: TextureRect
@export var camera_2d: Camera2D
@export var mouse_coords_label: Label
@export var room_coords_label: Label

var can_pan_camera: bool = true
var old_camera_2d_position: Vector2


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Creator.start()
	
	camera_2d.global_position = Global.screen_size / 2
	init_grid_hint()
	
	Creator.dark_world_ui = self
	
	Game.play_start.connect(func() -> void:
		grid_hint.hide()
		camera_2d.enabled = false
	)
	Game.play_end.connect(func() -> void:
		# Move the camera to the player's position.
		camera_2d.global_position = Game.player.global_position
		camera_2d.enabled = true
		
		# Move the grid hint to the camera's position.
		grid_hint.show()
		grid_hint.global_position = Global.align_to_grid(camera_2d.global_position) - Global.screen_size / 2
		# Reset the old camera position since, otherwise,
		# the difference calculation would kick in and move the
		# grid hint too far away from the camera.
		old_camera_2d_position = Vector2.ZERO
	)
	
	# Move the grid when the window's size is changed.
	get_tree().root.size_changed.connect(init_grid_hint)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	var mouse_pos: Vector2 = get_global_mouse_position()
	var mouse_coords: Vector2i = Global.position_to_coords(mouse_pos)
	mouse_coords_label.text = "%d, %d (%d, %d)" % [mouse_coords.x, mouse_coords.y, mouse_pos.x, mouse_pos.y]
	
	handle_room_coords_label()
	
	if camera_2d.enabled and can_pan_camera:
		# Camera panning
		var true_pan_speed: float = pan_speed
		if Input.is_action_pressed(&"editor_pan_speed_up"):
			true_pan_speed *= 5
		
		var vector: Vector2 = Input.get_vector(&"editor_pan_left", &"editor_pan_right", &"editor_pan_up", &"editor_pan_down")
		var is_ctrl_pressed: bool = Input.is_key_pressed(KEY_CTRL)
		
		if vector and not is_ctrl_pressed:
			camera_2d.position += vector * true_pan_speed * delta
			
			# Move the grid hint to give an illusion that it's an infinite plane.
			if old_camera_2d_position:
				var new_coords: Vector2i = Global.position_to_coords(camera_2d.position)
				var old_coords: Vector2i = Global.position_to_coords(old_camera_2d_position)
				if new_coords != old_coords:
					var difference: Vector2i = new_coords - old_coords
					grid_hint.position += Global.coords_to_position(difference)
			old_camera_2d_position = camera_2d.position

func init_grid_hint() -> void:
	# Move the grid hint a little left and make it a little bigger.
	# This removes any gaps that would give away the illusion of an infinite plane.
	grid_hint.position -= Vector2(64, 64)
	grid_hint.size = Global.screen_size + Vector2(64 * 4, 64 * 4)
	old_camera_2d_position = Vector2.ZERO

func handle_room_coords_label() -> void:
	var bounds: Rect2i
	var mouse_room_index: int = Room.position_to_room_index(Global.mouse_position)
	
	# If we're creating a room.
	if CreatorRoomManipulation.new_room_created:
		bounds = Room.bounds[CreatorRoomManipulation.new_room_index]
	# If we're hovering over a room.
	elif mouse_room_index != -1:
		bounds = Room.bounds[mouse_room_index]
	
	if not bounds:
		room_coords_label.modulate.a = 0.0
		return
	
	room_coords_label.modulate.a = 1.0
	
	var ssc: Vector2i = Global.screen_size_coords
	var diff: Vector2i = bounds.size - ssc
	@warning_ignore("integer_division")
	var mult: Vector2i = bounds.size / ssc
	
	# If the size is more than the size of the screen,
	# add a SCR to the label.
	var size_str_x: String = str(bounds.size.x)
	if diff.x > 0:
		size_str_x = "SCR%s+%d" % [
			("x%s" % mult.x) if mult.x > 0 else "",
			bounds.size.x - ssc.x * mult.x
		]
	
	var size_str_y: String = str(bounds.size.y)
	if diff.y > 0:
		size_str_y = "SCR%s+%d" % [
			("x%s" % mult.y) if mult.y > 0 else "",
			bounds.size.y - ssc.y * mult.y
		]
	
	room_coords_label.text = "Room: %d, %d (%s x %s)" % [bounds.position.x, bounds.position.y, size_str_x, size_str_y]
