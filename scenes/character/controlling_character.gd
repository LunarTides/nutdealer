extends CharacterBody2D
class_name ControllingCharacter

@export var speed: float = 300.0

@export_category("Nodes")
@export var animated_sprite_2d: AnimatedSprite2D

var direction: Vector2 = Vector2.ZERO

func _process(delta: float) -> void:
	# Handle interacting with tiles.
	if Input.is_action_just_pressed(&"interact"):
		var pos: Vector2 = global_position + (direction * 16)
		if direction == Vector2(0, 1):
			pos += direction * 32
		elif direction != Vector2(0, -1):
			pos += direction * 8
		
		var coords: Vector2i = Global.position_to_coords(pos)
		var tile: CreatorTile = Creator.tiles.get_tile_on(coords)
		
		if is_instance_valid(tile):
			tile.interact()

func _physics_process(delta: float) -> void:
	# Get the input vector and handle the movement.
	var vector: Vector2 = Input.get_vector(&"walk_left", &"walk_right", &"walk_up", &"walk_down")
	if vector:
		velocity = vector * speed
	else:
		velocity = Vector2.ZERO
	
	set_correct_direction()
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

func set_correct_direction() -> void:
	if velocity.x > 0:
		direction = Vector2(1, 0)
	elif velocity.x < 0:
		direction = Vector2(-1, 0)
	elif velocity.y > 0:
		direction = Vector2(0, 1)
	elif velocity.y < 0:
		direction = Vector2(0, -1)
