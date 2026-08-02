extends Resource
class_name PartyMember

@export var name: String:
	set(value):
		if name != value:
			name = value
			emit_changed()
@export var max_health: int:
	set(value):
		if max_health != value:
			max_health = value
			emit_changed()
@export var health: int = max_health:
	set(value):
		if health != value:
			health = value
			emit_changed()
@export var sprite_frames: SpriteFrames:
	set(value):
		if sprite_frames != value:
			sprite_frames = value
			emit_changed()

var encounter_intention: Encounter.Intention:
	set(value):
		if encounter_intention != value:
			encounter_intention = value
			emit_changed()


func reset() -> void:
	health = max_health
