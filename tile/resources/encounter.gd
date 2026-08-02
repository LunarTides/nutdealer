extends Resource
class_name TileEncounter

# TODO: Replace with a path for reusing encounters.
@export var enemies: Array[EncounterEnemy] = [EncounterEnemy.new()]:
	set(value):
		if enemies != value:
			enemies = value
			emit_changed()
@export var party_members: Array[PartyMember]:
	set(value):
		if party_members != value:
			party_members = value
			emit_changed()

var defeated: bool = false
