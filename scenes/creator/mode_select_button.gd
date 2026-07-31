extends TextureButton

@export var mode: Creator.Mode
@export var sfx_player: AudioStreamPlayer

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	color(Creator.mode)
	
	pressed.connect(func() -> void:
		Creator.mode = mode
		sfx_player.play()
	)
	Game.mode_changed.connect(func(old: Game.Mode, new: Game.Mode) -> void:
		visible = new == Game.Mode.DarkWorld
	)
	Creator.mode_changed.connect(func(old: Creator.Mode, new: Creator.Mode) -> void:
		color(new)
	)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func color(m: Creator.Mode) -> void:
	if m == mode:
		modulate = Color.WHITE
	else:
		modulate = Color.WHITE.darkened(0.5)
