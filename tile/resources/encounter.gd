extends Resource
class_name TileEncounter

# TODO: Replace with a path for reusing encounters.
@export var enemies: Array[EncounterEnemy] = [EncounterEnemy.new()]:
	set(value):
		if enemies != value:
			enemies = value
			emit_changed()
@export var party_member_names: PackedStringArray = []:
	set(value):
		if party_member_names != value:
			party_member_names = value
			emit_changed()

var defeated: bool = false
