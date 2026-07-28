extends VBoxContainer

const PARTY_MEMBER: PackedScene = preload("uid://bhgdjs3lbq3cl")

@export var encounter_ui: Control
@export var party_member_info: PanelContainer
@export var enemy_info: PanelContainer

var tile: Tile:
	set(value):
		tile = value

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	for child: Control in get_children():
		child.queue_free()
	
	encounter_ui.visibility_changed.connect(func() -> void:
		if not encounter_ui.visible:
			return
		
		# When the encounter ui becomes visible, refresh the party members.
		for i: int in range(tile.encounter_party_members.size()):
			var party_member: PartyMember = tile.encounter_party_members[i]
			
			var party_member_node: Button = PARTY_MEMBER.instantiate()
			party_member_node.party_member_index = i
			party_member_node.sprite_frames = party_member.sprite_frames
			setup_party_member_node(party_member_node)
			add_child(party_member_node)
	)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_add_button_pressed() -> void:
	var encounter_enemy: EncounterEnemy = EncounterEnemy.new()
	tile.encounter_enemies.append(encounter_enemy)
	
	var new_index: int = get_child_count()
	
	var party_member: Button = PARTY_MEMBER.instantiate()
	party_member.party_member_index = new_index
	setup_party_member_node(party_member)
	add_child(party_member)
	
	# Show party_member info
	enemy_info.hide()
	party_member_info.party_member_index = new_index
	party_member_info.show()


func setup_party_member_node(node: Button) -> void:
	node.pressed.connect(func() -> void:
		# FIXME: Can't click on Susie for some reason.
		enemy_info.hide()
		party_member_info.party_member_index = node.party_member_index
		party_member_info.show()
	)
	node.deleted.connect(func() -> void:
		tile.encounter_party_members.pop_at(node.party_member_index)
		for child: Button in get_children():
			child.party_member_index -= 1
	)
