extends Resource
class_name PartyMemberData

@export var name: String:
	set(value):
		if name != value:
			name = value
			emit_changed()
@export var health: int:
	set(value):
		if health != value:
			health = value
			emit_changed()

var encounter_intention: Encounter.Intention:
	set(value):
		if encounter_intention != value:
			encounter_intention = value
			emit_changed()
