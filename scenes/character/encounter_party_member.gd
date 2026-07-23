extends Node2D
class_name EncounterPartyMember

signal intro_animation_ended

var index: int = 0
var data: PartyMemberData

@export var animated_sprite_2d: AnimatedSprite2D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Temp before I get the sprites sorted.
	if index == 1:
		# Susie
		modulate = Color.hex(0xdc00b4ff)
	elif index == 2:
		# Ralsei
		modulate = Color.hex(0x36d439ff)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func play_intro_animation() -> void:
	var tween: Tween = create_tween()
	tween.tween_interval(0.5)
	tween.tween_property(self, ^"position", Vector2(150, 150), 0.5)
	tween.tween_callback(intro_animation_ended.emit)

func reposition() -> void:
	position = Vector2(150, 150 * (index + 1))
