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
