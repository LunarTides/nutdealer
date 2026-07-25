extends Resource
class_name CreatorSettings

@export var party_members_enabled: bool = true:
	set(value):
		if party_members_enabled != value:
			party_members_enabled = value
			emit_changed()
