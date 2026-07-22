extends VBoxContainer

@export var speed_button: TextureButton
@export var noclip_button: TextureButton

var noclip: bool = false:
	set(value):
		noclip = value
		
		if is_instance_valid(Game.player):
			Game.player.noclip = noclip
		
		# Change sprite colors.
		if noclip:
			noclip_button.self_modulate = Color.hex(0xffffff99)
			if is_instance_valid(Game.player):
				Game.player.animated_sprite_2d.self_modulate = Color.hex(0xffffff99)
		else:
			noclip_button.self_modulate = Color.WHITE
			if is_instance_valid(Game.player):
				Game.player.animated_sprite_2d.self_modulate = Color.WHITE
var speed_multiplier: float = 1:
	set(value):
		speed_multiplier = value
		
		speed_button.self_modulate = Color.BLUE.lerp(Color.YELLOW, speed_multiplier / 8)
		speed_button.tooltip_text = "Speed Multiplier: %dx" % speed_multiplier
		
		if is_instance_valid(Game.player):
			Game.player.speed = Game.player.default_speed * speed_multiplier
			Game.player.animated_sprite_2d.speed_scale = speed_multiplier

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	hide()
	
	noclip_button.self_modulate = Color.WHITE
	
	Game.play_start.connect(func() -> void:
		show()
		
		speed_multiplier = 1
		noclip = false
	)
	Game.play_end.connect(func() -> void:
		hide()
	)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _on_speed_button_pressed() -> void:
	speed_multiplier *= 2
	if speed_multiplier > 16:
		speed_multiplier = 1

func _on_noclip_button_pressed() -> void:
	noclip = not noclip
