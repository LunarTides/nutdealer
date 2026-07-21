@tool
extends Control

const CREATOR_DARK_WORLD_UI: PackedScene = preload("uid://cidw2jv7myp3u")

@export var grid_move_speed: float = 300
@export var grid_move_repeat_frequency: int = 4

@export_category("UI Nodes")
@export var grid: TextureRect

@export var idle_container: CenterContainer
@export var title_label: Label
@export var title_label_animation_player: AnimationPlayer
@export var title_label_pulse: Label
@export var title_label_pulse_animation_player: AnimationPlayer

@export var intro_container: HBoxContainer


var title_pulse_label: Label
var old_grid_position: Vector2

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	init_grid()
	
	if not Engine.is_editor_hint():
		idle_container.hide()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	move_grid(delta)


func _on_play_button_pressed() -> void:
	WorldSave.load_ended.connect(func() -> void:
		if Room.amount < 1:
			Game.feedback("This world has no rooms.", Game.FeedbackType.Error)
			WorldSave.new_world()
			return
		
		queue_free()
		Game.play_from(0)
	)
	
	WorldSave.create_open_world_dialogue()


func _on_create_button_pressed() -> void:
	get_tree().change_scene_to_packed(CREATOR_DARK_WORLD_UI)

func init_grid() -> void:
	# Move the grid a little left and make it a little bigger.
	# This removes any gaps that would give away the illusion of an infinite plane.
	var screen_size: Vector2 = Vector2(1152, 640)
	if not Engine.is_editor_hint():
		screen_size = Global.screen_size
	
	grid.size = screen_size + Vector2(64 * 4, 64 * 4)
	old_grid_position = Vector2.ZERO

func move_grid(delta: float) -> void:
	var vector: Vector2 = Vector2.UP + Vector2.RIGHT
	grid.position += vector * grid_move_speed * delta
	
	# Move the grid to give an illusion that it's an infinite plane.
	if grid.position.x >= 0:
		grid.position = Vector2(-64 * grid_move_repeat_frequency, 0)


func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	if Engine.is_editor_hint():
		return
	
	if anim_name == &"intro":
		title_label_animation_player.play(&"title")
		title_label_pulse_animation_player.play(&"title_pulse")
		
		idle_container.show()
		intro_container.queue_free()
