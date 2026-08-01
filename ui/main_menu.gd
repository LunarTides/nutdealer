@tool
extends Control

const CREATOR_DARK_WORLD_UI: PackedScene = preload("uid://cidw2jv7myp3u")
const SETTINGS: PackedScene = preload("uid://haqo8dlnsblw")

const MOVE_SFX: AudioStream = preload("res://assets/audio/ui/menumove.wav")
const SELECT_SFX: AudioStream = preload("res://assets/audio/ui/select.wav")

@export var grid_move_speed: float = 300
@export var grid_move_repeat_frequency: int = 4
@export var spell_streams: Dictionary[String, AudioStream]

@export_category("UI Nodes")
@export var grid: TextureRect
@export var version_label: Label

@export var idle_container: CenterContainer
@export var title_label: Label
@export var title_label_animation_player: AnimationPlayer
@export var title_label_pulse: Label
@export var title_label_pulse_animation_player: AnimationPlayer

@export var intro_container: HBoxContainer
@export var sfx_player: AudioStreamPlayer
@export var intro_sfx_player: AudioStreamPlayer
@export var music_player: AudioStreamPlayer

var title_pulse_label: Label
var old_grid_position: Vector2

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	version_label.text = "v%s" % ProjectSettings.get_setting("application/config/version")
	
	init_grid()
	
	if not Engine.is_editor_hint():
		idle_container.hide()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	move_grid(delta)


func _on_play_button_pressed() -> void:
	sfx_player.stream = SELECT_SFX
	sfx_player.play()
	
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

func _on_settings_button_pressed() -> void:
	sfx_player.stream = SELECT_SFX
	sfx_player.play()
	
	var settings: Control = SETTINGS.instantiate()
	add_sibling(settings)
	
	hide()
	settings.closed.connect(show)

func _on_exit_button_pressed() -> void:
	Settings.save_settings()
	get_tree().quit()

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

func intro_step(step: int) -> void:
	# NUT
	if step == 0:
		intro_sfx_player.pitch_scale = 1.1
		intro_sfx_player.play()
	# DEA
	elif step == 1:
		intro_sfx_player.pitch_scale = 0.9
		intro_sfx_player.play()
	# LER
	elif step == 2:
		intro_sfx_player.pitch_scale = 1.33
		
		# Echo
		for i: int in 6:
			intro_sfx_player.volume_db = -3.0 * i
			intro_sfx_player.pitch_scale -= 0.01
			intro_sfx_player.play()
			await get_tree().create_timer(0.5).timeout
	# END
	elif step == 3:
		intro_sfx_player.volume_db = 0.0
		intro_sfx_player.pitch_scale = 1.0

func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	if Engine.is_editor_hint():
		return
	
	if anim_name == &"intro":
		title_label_animation_player.play(&"title")
		title_label_pulse_animation_player.play(&"title_pulse")
		
		idle_container.show()
		intro_container.queue_free()
	
	music_player.play()
	
	while true:
		await spell()
		await get_tree().create_timer(5.0).timeout


func _on_button_mouse_entered() -> void:
	sfx_player.stream = MOVE_SFX
	sfx_player.play()


func spell() -> void:
	# Kinda sucks and blows.
	return
	
	for chr: String in "nutdealer":
		intro_sfx_player.volume_db = -6.0
		intro_sfx_player.pitch_scale = 1.0
		intro_sfx_player.stream = spell_streams[chr]
		intro_sfx_player.play(0.01)
		
		# The a goes on for an additional 0.1 seconds, which is noticable,
		# so cut it off early.
		if chr == "a":
			await get_tree().create_timer(0.3).timeout
		else:
			await intro_sfx_player.finished
