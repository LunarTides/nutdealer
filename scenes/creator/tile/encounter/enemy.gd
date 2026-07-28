@tool
extends Button

signal deleted

@export var sprite_frames: SpriteFrames:
	set(value):
		sprite_frames = value
		
		if is_instance_valid(animated_sprite_2d):
			animated_sprite_2d.sprite_frames = sprite_frames
			animated_sprite_2d.play(&"battle_idle")
@export var enemy_index: int

@export_category("Nodes")
@export var animated_sprite_2d: AnimatedSprite2D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	animated_sprite_2d.play(&"battle_idle")


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_delete_button_pressed() -> void:
	deleted.emit()
	queue_free()
