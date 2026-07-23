extends Control
class_name CreatorDarkWorldUI

@export var pan_speed: float = 300
@export var zoom_speed: float = 10

@export_category("UI Nodes")
@export var grid_hint: TextureRect
@export var camera_2d: Camera2D
@export var mouse_coords_label: Label
@export var room_coords_label: Label
@export var camera_zoom_label: Label
@export var feedback_label: Label
@export var bottom_center_container: VBoxContainer
@export var pause_menu: Control

var listen_for_keys: bool = true
var actual_pan_speed: float = 0
var old_camera_2d_position: Vector2
var last_mouse_position: Vector2


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Creator.start()
	
	actual_pan_speed = pan_speed
	
	camera_2d.global_position = Global.screen_size / 2
	init_grid_hint()
	
	feedback_label.queue_free()
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
		init_grid_hint()
	)
	
	# Move the grid when the window's size is changed.
	get_tree().root.size_changed.connect(init_grid_hint)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	var mouse_pos: Vector2 = get_global_mouse_position()
	var mouse_coords: Vector2i = Global.position_to_coords(mouse_pos)
	mouse_coords_label.text = "%d, %d (%d, %d)" % [mouse_coords.x, mouse_coords.y, mouse_pos.x, mouse_pos.y]
	
	# Round because of inaccuracies. It can show 189% instead of 190% for some reason.
	# Probably some floating-point accuracy issues, idk.
	camera_zoom_label.text = "Zoom: %d%%" % roundi(camera_2d.zoom.x * 100)
	
	handle_room_coords_label()
	
	if camera_2d.enabled:
		# Camera panning
		var true_pan_speed: float = actual_pan_speed
		if Input.is_action_pressed(&"editor_pan_speed_up"):
			true_pan_speed *= 5
		
		if listen_for_keys:
			var vector: Vector2 = Input.get_vector(&"editor_pan_left", &"editor_pan_right", &"editor_pan_up", &"editor_pan_down")
			var is_ctrl_pressed: bool = Input.is_key_pressed(KEY_CTRL)
			
			# Pan using arrow keys.
			if vector and not is_ctrl_pressed:
				camera_2d.position += vector * true_pan_speed * delta
				# Move the grid hint to give an illusion that it's an infinite plane.
				move_grid_hint()
		
		# Pan using right mouse button.
		var should_set_last_mouse_position: bool = true
		
		var is_rmb_pressed: bool = Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT)
		if is_rmb_pressed and last_mouse_position:
			var mouse_vector: Vector2 = last_mouse_position - Global.mouse_position
			if not mouse_vector.is_zero_approx():
				camera_2d.position += mouse_vector
				should_set_last_mouse_position = false
				# Move the grid hint to give an illusion that it's an infinite plane.
				move_grid_hint()
		
		if should_set_last_mouse_position:
			last_mouse_position = Global.mouse_position
			
		old_camera_2d_position = camera_2d.position
	
	# Scale pan speed based on camera zoom.
	actual_pan_speed = pan_speed * (1 / camera_2d.zoom.x)

func _unhandled_input(event: InputEvent) -> void:
	if camera_2d.enabled and listen_for_keys:
		# Zooming
		if Input.is_action_pressed(&"editor_zoom_reset"):
			camera_2d.zoom = Vector2.ONE
		elif Input.is_action_pressed(&"editor_zoom_in"):
			camera_2d.zoom += Vector2.ONE * zoom_speed * 0.1 * 0.1
			if camera_2d.zoom > Vector2(2.0, 2.0):
				camera_2d.zoom = Vector2(2.0, 2.0)
		elif Input.is_action_pressed(&"editor_zoom_out"):
			camera_2d.zoom -= Vector2.ONE * zoom_speed * 0.1 * 0.1
			if camera_2d.zoom < Vector2(0.1, 0.1):
				camera_2d.zoom = Vector2(0.1, 0.1)

func init_grid_hint() -> void:
	# Move the grid hint a little left and make it a little bigger.
	# This removes any gaps that would give away the illusion of an infinite plane.
	var position_subtraction: Vector2 = Vector2(64 * 128, 64 * 64)
	grid_hint.position -= position_subtraction
	grid_hint.size = Global.screen_size + position_subtraction * 2
	old_camera_2d_position = Vector2.ZERO

func move_grid_hint() -> void:
	# Move the grid hint to give an illusion that it's an infinite plane.
	if old_camera_2d_position:
		var new_coords: Vector2i = Global.position_to_coords(camera_2d.position)
		var old_coords: Vector2i = Global.position_to_coords(old_camera_2d_position)
		if new_coords != old_coords:
			var difference: Vector2i = new_coords - old_coords
			grid_hint.position += Global.coords_to_position(difference)

func handle_room_coords_label() -> void:
	var bounds: Rect2i
	
	# If we're creating a room.
	if CreatorRoomManipulation.new_room_created:
		bounds = Room.bounds[CreatorRoomManipulation.new_room_index]
	# If we're hovering over a room.
	elif CreatorRoomManipulation.hovering != -1:
		bounds = Room.bounds[CreatorRoomManipulation.hovering]
	
	if not bounds:
		room_coords_label.modulate.a = 0.0
		return
	
	room_coords_label.modulate.a = 1.0
	
	var ssc: Vector2i = Global.screen_size_coords
	var diff: Vector2i = bounds.size - ssc
	@warning_ignore("integer_division")
	var mult: Vector2i = bounds.size / ssc
	var add: Vector2i = bounds.size - ssc * mult
	
	# If the size is more than the size of the screen,
	# add a SCR to the label.
	var size_str_x: String = str(bounds.size.x)
	if diff.x >= 0:
		size_str_x = "SCR%s%s" % [
			("x%d" % mult.x) if mult.x > 1 else "",
			("+%d" % add.x) if add.x > 0 else "",
		]
	
	var size_str_y: String = str(bounds.size.y)
	if diff.y >= 0:
		size_str_y = "SCR%s%s" % [
			("x%s" % mult.y) if mult.y > 1 else "",
			("+%d" % add.y) if add.y > 0 else "",
		]
	
	room_coords_label.text = "Room: %d, %d (%s x %s)" % [bounds.position.x, bounds.position.y, size_str_x, size_str_y]
