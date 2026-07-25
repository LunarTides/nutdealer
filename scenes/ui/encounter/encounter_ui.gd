@tool
extends Control
class_name EncounterUI

@export var grid_move_speed: float = 300
@export var grid_move_repeat_frequency: int = 4

@export_category("UI Nodes")
@export var grid: TextureRect
@export var camera_2d: Camera2D
@export var soul_container: PanelContainer


var old_grid_position: Vector2

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	init_grid()
	
	if not Engine.is_editor_hint():
		soul_container.hide()
	
	Encounter.state_changed.connect(func(old: Encounter.State, new: Encounter.State) -> void:
		var enemy: bool = new == Encounter.State.Enemy
		soul_container.visible = enemy
		soul_container.process_mode = Node.PROCESS_MODE_INHERIT if enemy else Node.PROCESS_MODE_DISABLED
	)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	move_grid(delta)

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
