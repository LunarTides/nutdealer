extends CharacterBody2D
class_name ControllingCharacter

@export var speed = 300.0

@export_category("Nodes")
@export var animated_sprite_2d: AnimatedSprite2D


func _physics_process(delta: float) -> void:
	# Get the input vector and handle the movement.
	var vector := Input.get_vector(&"walk_left", &"walk_right", &"walk_up", &"walk_down")
	if vector:
		velocity = vector * speed
	else:
		velocity = Vector2.ZERO

	set_correct_sprite()
	move_and_slide()

func set_correct_sprite() -> void:
	animated_sprite_2d.play()
	
	if velocity.x > 0:
		animated_sprite_2d.animation = &"move_right"
	elif velocity.x < 0:
		animated_sprite_2d.animation = &"move_left"
	elif velocity.y > 0:
		animated_sprite_2d.animation = &"move_down"
	elif velocity.y < 0:
		animated_sprite_2d.animation = &"move_up"
	else:
		if animated_sprite_2d.sprite_frames.has_animation(&"idle"):
			animated_sprite_2d.animation = &"idle"
		else:
			animated_sprite_2d.stop()
