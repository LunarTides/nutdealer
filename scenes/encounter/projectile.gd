@tool
extends CharacterBody2D
class_name Projectile

enum ProjectileType {
	Damage,
	Heal,
}

@export var sprite: Texture2D:
	set(value):
		sprite = value
		
		if is_instance_valid(animated_sprite_2d):
			animated_sprite_2d.sprite_frames.set_frame(&"default", 0, sprite)
@export var speed: float = 150.0
@export var type: ProjectileType = ProjectileType.Damage
@export var damage: int = 10
@export var start_position: Vector2

@export_category("Nodes")
@export var animated_sprite_2d: AnimatedSprite2D

func _ready() -> void:
	reset_position()
	
	animated_sprite_2d.sprite_frames = animated_sprite_2d.sprite_frames.duplicate()
	animated_sprite_2d.sprite_frames.set_frame(&"default", 0, sprite)
	
	Encounter.turn_ended.connect(func(turn: int) -> void:
		queue_free()
	)

func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	
	var direction: Vector2 = Vector2.LEFT
	velocity = direction * speed
	
	move_and_slide()

func reset_position() -> void:
	position = start_position
