extends Control

@export_category("UI Nodes")
@export var party_member_label: Label

var tile: Tile
var party_member_index: int = 0:
	set(value):
		party_member_index = value
		update_ui()
var party_member: PartyMember:
	get:
		if not is_instance_valid(tile) or not is_instance_valid(tile.encounter):
			return
		
		if tile.encounter.party_member_names.size() <= party_member_index:
			return
		
		return PartyMembers.from_name(tile.encounter.party_member_names[party_member_index])

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	update_ui()
	hide()
	#party_member.changed.connect(update_ui)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func update_ui() -> void:
	if not party_member or Engine.is_editor_hint():
		return
	
	party_member_label.text = "%s [Health: %d]" % [party_member.name, party_member.health]
