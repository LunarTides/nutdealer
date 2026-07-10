extends Control

const CREATOR_DARK_WORLD_UI: PackedScene = preload("uid://cidw2jv7myp3u")

@export var grid_move_speed: float = 300
@export var grid_move_repeat_frequency: int = 4

@export_category("UI Nodes")
@export var grid: TextureRect
@export var title_label: Label

var title_pulse_label: Label
var old_grid_position: Vector2

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	title_label.get_node(^"AnimationPlayer").play(&"title")
	init_grid()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	title_label.offset_transform_rotation += 1 * delta
	move_grid(delta)


func _on_play_button_pressed() -> void:
	CreatorSave.loaded.connect(func() -> void:
		if Room.amount < 1:
			push_error("This world has no rooms.")
			CreatorSave.new_world()
			return
		
		queue_free()
		Game.play_from(0)
	)
	
	CreatorSave.create_open_world_dialogue()


func _on_create_button_pressed() -> void:
	get_tree().change_scene_to_packed(CREATOR_DARK_WORLD_UI)

func title_pulse() -> void:
	if is_instance_valid(title_pulse_label):
		title_pulse_label.queue_free()
	
	title_pulse_label = title_label.duplicate()
	title_pulse_label.top_level = true
	title_label.get_parent().add_child.call_deferred(title_pulse_label)
	title_pulse_label.global_position = title_label.global_position
	
	# Waiting a single frame for some reason makes the animation smoother.
	await get_tree().process_frame
	
	var animation_player: AnimationPlayer = title_pulse_label.get_node(^"AnimationPlayer")
	animation_player.play(&"title_pulse")
	animation_player.seek(title_label.get_node(^"AnimationPlayer").current_animation_position, true, true)

func title_pulse_delete() -> void:
	title_pulse_label.queue_free()

func init_grid() -> void:
	# Move the grid a little left and make it a little bigger.
	# This removes any gaps that would give away the illusion of an infinite plane.
	grid.position += Vector2(-64 * grid_move_repeat_frequency, 0)
	grid.size = Global.screen_size + Vector2(64 * 4, 64 * 4)
	old_grid_position = Vector2.ZERO

func move_grid(delta: float) -> void:
	var vector: Vector2 = Vector2.UP + Vector2.RIGHT
	grid.position += vector * grid_move_speed * delta
	
	# Move the grid to give an illusion that it's an infinite plane.
	if grid.position.x >= 0:
		grid.position = Vector2(-64 * grid_move_repeat_frequency, 0)
