extends Node

signal added(party_member: PartyMember)
signal removed(party_member: PartyMember)

var party_members: Array[PartyMember]

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	initialize_with_kris_susie_ralsei()
	
	WorldSave.new_world_ended.connect(func() -> void:
		initialize_with_kris_susie_ralsei()
	)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func add(party_member: PartyMember) -> void:
	party_members.append(party_member)
	added.emit(party_member)

func remove(party_member: PartyMember) -> void:
	party_members.erase(party_member)
	removed.emit(party_member)

func remove_with_name(party_member_name: String) -> void:
	var index: int = party_members.find_custom(func(p: PartyMember) -> bool: return p.name == party_member_name)
	if index == -1:
		assert(false, "No party member with name '%s'." % party_member_name)
		return
	
	var party_member: PartyMember = party_members[index]
	party_members.remove_at(index)
	removed.emit(party_member)

func from_name(party_member_name: String) -> PartyMember:
	var index: int = party_members.find_custom(func(p: PartyMember) -> bool: return p.name == party_member_name)
	if index == -1:
		return null
	
	var party_member: PartyMember = party_members[index]
	return party_member

func initialize_with_kris_susie_ralsei() -> void:
	party_members = []
	
	var kris: PartyMember = PartyMember.new()
	kris.name = "Kris"
	kris.max_health = 100
	kris.sprite_frames = load("res://character/sprite_frames/kris.tres")
	add(kris)
	
	var susie: PartyMember = PartyMember.new()
	susie.name = "Susie"
	susie.max_health = 100
	susie.sprite_frames = load("res://character/sprite_frames/susie.tres")
	add(susie)
	
	var ralsei: PartyMember = PartyMember.new()
	ralsei.name = "Ralsei"
	ralsei.max_health = 100
	ralsei.sprite_frames = load("res://character/sprite_frames/ralsei.tres")
	add(ralsei)
