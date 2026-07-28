extends VBoxContainer

const ENEMY: PackedScene = preload("uid://du043hf2x26vo")

@export var party_member_info: PanelContainer
@export var enemy_info: PanelContainer

var tile: Tile:
	set(value):
		tile = value
		
		for i: int in range(tile.encounter_enemies.size()):
			var enemy: Button = ENEMY.instantiate()
			enemy.enemy_index = i
			setup_enemy_node(enemy)
			add_child(enemy)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	for child: Control in get_children():
		child.queue_free()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_add_button_pressed() -> void:
	var enemy: EncounterEnemy = EncounterEnemy.new()
	tile.encounter_enemies.append(enemy)
	
	var new_index: int = get_child_count()
	
	var enemy_node: Button = ENEMY.instantiate()
	enemy_node.enemy_index = new_index
	setup_enemy_node(enemy_node)
	add_child(enemy_node)
	
	# Show enemy info
	party_member_info.hide()
	enemy_info.enemy_index = new_index
	enemy_info.show()

func setup_enemy_node(node: Button) -> void:
	node.pressed.connect(func() -> void:
		party_member_info.hide()
		enemy_info.enemy_index = node.enemy_index
		enemy_info.show()
	)
	node.deleted.connect(func() -> void:
		tile.encounter_enemies.pop_at(node.enemy_index)
		for child: Button in get_children():
			child.enemy_index -= 1
	)
