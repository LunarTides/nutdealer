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
