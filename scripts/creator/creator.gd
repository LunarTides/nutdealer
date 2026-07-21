extends Node

signal creator_enabled
signal creator_disabled
signal mode_changed(old: Mode, new: Mode)
signal dirty_changed

const PLAYER: PackedScene = preload("uid://cbbmactdk1u14")
const CREATOR_FIRST_SAVE_DIALOGUE: PackedScene = preload("uid://24k3h1cax05e")
const CREATOR_OPEN_WORLD_DIALOGUE: PackedScene = preload("uid://1xt5rpnm2slf")
const CREATOR_ABANDON_SAVE_DIALOGUE: PackedScene = preload("uid://dkt1holgrwxif")
const FEEDBACK_LABEL: PackedScene = preload("uid://u158p04d7v48")

enum Mode {
	None,
	PlacingTile,
}

var mode: Mode = Mode.None:
	set(value):
		var old_mode: Mode = mode
		mode = value
		mode_changed.emit(old_mode, mode)
var enabled: bool = false:
	set(value):
		enabled = value
		
		if enabled:
			creator_enabled.emit()
		else:
			creator_disabled.emit()
var world_name: String
var dirty: bool = false:
	set(value):
		if dirty != value:
			dirty = value
			dirty_changed.emit()
var dark_world_ui: CreatorDarkWorldUI
var feedback_label: Label

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Start disabled. Only enable when going into create mode.
	process_mode = Node.PROCESS_MODE_DISABLED
	
	Game.play_start.connect(func() -> void:
		# Set to normal mode on play/preview.
		mode = Mode.None
	)

func start() -> void:
	process_mode = Node.PROCESS_MODE_INHERIT
	enabled = true

func stop() -> void:
	process_mode = Node.PROCESS_MODE_DISABLED
	enabled = false

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if Input.is_action_just_pressed(&"editor_preview_next_room") and Game.playing:
		# Switch to next room.
		var new_room_index: int = Game.current_room + 1
		if new_room_index >= Room.amount:
			new_room_index = 0
		
		# Integer division is fine since we're working with multiples of 64.
		@warning_ignore("integer_division")
		Game.switch_room(new_room_index)

func make_dirty() -> void:
	dirty = true

func _feedback(message: String, feedback_type: Game.FeedbackType) -> void:
	if is_instance_valid(feedback_label):
		feedback_label.queue_free()
	
	feedback_label = FEEDBACK_LABEL.instantiate()
	dark_world_ui.bottom_center_container.add_child(feedback_label)
	dark_world_ui.feedback_label = feedback_label
	
	# Change label properties depending on the type of feedback.
	var text_intro: String = ""
	var color: Color = Color.WHITE
	if feedback_type == Game.FeedbackType.Info:
		pass
	elif feedback_type == Game.FeedbackType.Success:
		color = Color.GREEN
	elif feedback_type == Game.FeedbackType.Warning:
		push_warning(message)
		text_intro = "WARNING: "
		color = Color.YELLOW
	elif feedback_type == Game.FeedbackType.Error:
		push_error(message)
		text_intro = "ERROR: "
		color = Color.RED
	
	feedback_label.text = "%s%s" % [text_intro, message]
	feedback_label.modulate.a = 1.0
	feedback_label.label_settings.font_color = color
	
	# Show on screen for 3 seconds, then fade out for 2 seconds.
	var tween: Tween = create_tween()
	tween.tween_interval(3.0)
	tween.tween_property(feedback_label, ^"modulate:a", 0.0, 2.0)
	tween.tween_callback(feedback_label.queue_free)

func start_preview() -> void:
	# Get starting room from camera position.
	var room_index: int = Room.position_to_room_index(dark_world_ui.camera_2d.global_position)
	if room_index == -1:
		Game.feedback("Must start in a room.", Game.FeedbackType.Error)
		return
	
	print_debug("Previewing from Room %d" % room_index)
	
	# Disable tiles outside room.
	Game.tiles.call_outside_room(room_index, func(tile: Tile) -> void:
		tile.disable()
	)
	
	Game.playing = true
	Game.current_room = room_index
	
	# Create player.
	if is_instance_valid(Game.player):
		Game.player.queue_free()
	var player: Player = PLAYER.instantiate()
	dark_world_ui.add_child(player)
	player.global_position = dark_world_ui.camera_2d.global_position
	Game.player = player
	
	Game.constrain_player_to_current_room()
	Game.constrain_camera_to_current_room()

func stop_preview() -> void:
	# Re-enable disabled tiles outside room.
	Game.tiles.call_outside_room(Game.current_room, func(tile: Tile) -> void:
		tile.enable()
	)
	
	Game.playing = false
	Game.player.queue_free()
