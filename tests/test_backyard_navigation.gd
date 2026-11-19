extends GutTest
## Interação real com portas, circulação do quintal e persistência entre mapas.

const HOUSE: PackedScene = preload("res://stages/stage_01_saci/house_interior.tscn")
const BACKYARD: PackedScene = preload("res://stages/stage_01_saci/house_backyard.tscn")
const KITCHEN_DOOR: NodePath = ^"YSortRoot/State_Organized/Door/BackyardDoor"
const RETURN_DOOR: NodePath = ^"YSortRoot/State_Organized/KitchenDoor/ReturnToHouse"
const ACTIONS: Array[StringName] = [
	&"move_up", &"move_down", &"move_left", &"move_right", &"interact", &"open_inventory"
]

var _previous_scene: Node
var _fade_duration: float


func before_each() -> void:
	WorldState.reset()
	_release_actions()
	_previous_scene = get_tree().current_scene
	_fade_duration = WorldState.scene_transition.fade_duration
	WorldState.scene_transition.fade_duration = 0.10


func after_each() -> void:
	_release_actions()
	if WorldState.scene_transition.is_transitioning:
		await wait_for_signal(WorldState.scene_transition.transition_finished,2.0)
	var current: Node = get_tree().current_scene
	if current != _previous_scene:
		get_tree().current_scene = _previous_scene
		if is_instance_valid(current):
			current.queue_free()
		await wait_process_frames(2)
	WorldState.scene_transition.fade_duration = _fade_duration
	WorldState.reset()


func test_backyard_is_editable_uses_production_atlases_and_has_safe_spawns() -> void:
	var yard: Node2D = BACKYARD.instantiate() as Node2D
	add_child_autofree(yard)
	var floor_layer: TileMapLayer = yard.get_node("FloorLayer") as TileMapLayer
	assert_true(floor_layer.get_used_rect().encloses(Rect2i(0,0,26,21)))
	for layer_name: String in ["FloorLayer","FloorDetailsLayer","GroundEdgesLayer","WallsAndFenceLayer","RoofLayer"]:
		var layer: TileMapLayer = yard.get_node(layer_name) as TileMapLayer
		assert_not_null(layer)
		for cell: Vector2i in layer.get_used_cells():
			var source: TileSetAtlasSource = layer.tile_set.get_source(layer.get_cell_source_id(cell)) as TileSetAtlasSource
			assert_false(source.texture.resource_path.contains("_templates"))
			assert_true(Rect2i(Vector2i.ZERO,Vector2i(source.texture.get_size())).encloses(source.get_tile_texture_region(layer.get_cell_atlas_coords(cell))))
	var player: Player = yard.get_node("YSortRoot/Player") as Player
	assert_eq(player.camera.limit_right,832)
	assert_eq(player.camera.limit_bottom,672)
	assert_true((yard.get_node("YSortRoot") as Node2D).y_sort_enabled)
	assert_true((yard.get_node("YSortRoot/State_Organized/Clothesline") as Node2D).y_sort_enabled)
	assert_not_null(yard.get_node("YSortRoot/State_Organized/Clothesline/Rope") as Line2D)
	for prop_name: String in ["KitchenDoor","HouseStructure","Tree","Gate","Clothesline/LeftPost","Clothesline/RightPost","WoodenBarrel","WoodenBarrelV2"]:
		var prop: StaticBody2D = yard.get_node("YSortRoot/State_Organized/"+prop_name) as StaticBody2D
		assert_not_null(prop)
		assert_eq(prop.collision_layer,1)
		assert_eq(prop.collision_mask,2)
		assert_not_null((prop.get_node("CollisionShape2D") as CollisionShape2D).shape)
	await wait_physics_frames(3)
	for marker_name: String in ["PlayerEntrySpawn","FromHouseInterior"]:
		var marker: Marker2D = yard.get_node("SpawnPoints/"+marker_name) as Marker2D
		assert_true(_feet_are_clear(player,marker.global_position))
	assert_eq((yard.get_node("YSortRoot/Horse") as Node2D).global_position,(yard.get_node("SpawnPoints/HorseSpawn") as Marker2D).global_position)
	var door: SceneDoor = yard.get_node(RETURN_DOOR) as SceneDoor
	assert_eq(door.collision_layer,4)
	assert_eq(door.collision_mask,0)
	assert_eq(door.target_scene,HOUSE.resource_path)
	assert_eq(door.target_spawn,&"FromBackyard")


func test_every_sprite_region_stays_inside_its_atlas() -> void:
	var yard: Node2D = BACKYARD.instantiate() as Node2D
	add_child_autofree(yard)
	for node: Node in yard.find_children("*","Sprite2D",true,false):
		var sprite: Sprite2D = node as Sprite2D
		assert_not_null(sprite.texture)
		assert_true(sprite.texture.resource_path.begins_with("res://assets/art/"))
		assert_false(sprite.texture.resource_path.contains("_templates"))
		if sprite.region_enabled:
			assert_gt(sprite.region_rect.size.x,0.0)
			assert_gt(sprite.region_rect.size.y,0.0)
			assert_true(Rect2(Vector2.ZERO,sprite.texture.get_size()).encloses(sprite.region_rect))


func test_paths_to_the_door_barrels_tree_clothesline_animals_and_gate_are_reachable() -> void:
	var yard: Node2D = BACKYARD.instantiate() as Node2D
	add_child_autofree(yard)
	await wait_physics_frames(3)
	var player: Player = yard.get_node("YSortRoot/Player") as Player
	var reachable: Dictionary[Vector2i,bool] = {}
	var spawn: Marker2D = yard.get_node("SpawnPoints/PlayerEntrySpawn") as Marker2D
	var queue: Array[Vector2i] = [Vector2i((spawn.global_position/16.0).round())]
	reachable[queue[0]] = true
	var head: int = 0
	while head < queue.size():
		var cell: Vector2i = queue[head]
		head += 1
		for direction: Vector2i in [Vector2i.UP,Vector2i.DOWN,Vector2i.LEFT,Vector2i.RIGHT]:
			var next: Vector2i = cell+direction
			if reachable.has(next) or not Rect2i(3,3,46,37).has_point(next):
				continue
			if _feet_are_clear(player,Vector2(next*16)):
				reachable[next] = true
				queue.append(next)
	for point: Vector2i in [Vector2i(144,320),Vector2i(320,336),Vector2i(560,304),Vector2i(208,576),Vector2i(208,544),Vector2i(704,240),Vector2i(400,464),Vector2i(480,592),Vector2i(416,608),Vector2i(688,592),Vector2i(464,144),Vector2i(560,96)]:
		assert_true(reachable.has(point/16),"Acesso livre a "+str(point))
	for direction: Vector2 in [Vector2.LEFT,Vector2.RIGHT,Vector2.UP,Vector2.DOWN]:
		assert_true(player.test_move(Transform2D(0.0,Vector2(560,336)),direction*900.0))


func test_direct_backyard_start_spawns_at_door_and_e_asks_to_enter_house() -> void:
	var yard: Node2D = BACKYARD.instantiate() as Node2D
	get_tree().root.add_child(yard)
	get_tree().current_scene = yard
	var player: Player = yard.get_node("YSortRoot/Player") as Player
	var hud: GameplayHUD = yard.get_node("GameplayHUD") as GameplayHUD
	assert_eq(player.global_position,Vector2(140,320))
	assert_eq(player.facing_direction,Vector2.UP)
	await wait_physics_frames(3)
	assert_true(_feet_are_clear(player,player.global_position))
	assert_false(player.test_move(player.global_transform,Vector2(0,32)))
	assert_true(player.test_move(player.global_transform,Vector2(0,-64)))
	await _tap_key(KEY_E)
	assert_eq(hud.mode,GameplayHUD.ModalMode.DOOR_CONFIRM)
	assert_eq((hud.get_node("Screen/Dialogue/Text") as Label).text,"Deseja entrar na casa?")
	assert_false(player.movement_enabled)
	await _tap_key(KEY_ESCAPE)
	assert_true(player.movement_enabled)
	assert_eq(get_tree().current_scene,yard)
	Input.action_press(&"move_up")
	await wait_physics_frames(24)
	Input.action_release(&"move_up")
	await wait_physics_frames(3)
	assert_gte(player.global_position.y,303.9,"A fachada impede atravessar a porta")
	assert_lt(player.global_position.y,320.0,"O Player pode se aproximar da porta")
	await _tap_key(KEY_E)
	assert_eq(hud.mode,GameplayHUD.ModalMode.DOOR_CONFIRM)
	await _tap_key(KEY_ESCAPE)


func test_prop_collisions_match_visible_bases_and_do_not_block_empty_lawn() -> void:
	var yard: Node2D = BACKYARD.instantiate() as Node2D
	add_child_autofree(yard)
	await wait_physics_frames(3)
	var player: Player = yard.get_node("YSortRoot/Player") as Player
	for point: Vector2 in [Vector2(140,288),Vector2(240,96),Vector2(240,224),Vector2(745,196),Vector2(448,112),Vector2(478,112),Vector2(84,542),Vector2(340,542)]:
		assert_false(_feet_are_clear(player,point),"Obstáculo sólido em "+str(point))
	for point: Vector2 in [Vector2(140,320),Vector2(528,388),Vector2(772,388),Vector2(505,208),Vector2(212,542),Vector2(448,144),Vector2(704,208)]:
		assert_true(_feet_are_clear(player,point),"Passagem livre em "+str(point))
	for post_name: String in ["LeftPost","RightPost"]:
		var post: StaticBody2D = yard.get_node("YSortRoot/State_Organized/Clothesline/"+post_name) as StaticBody2D
		var sprite: Sprite2D = post.get_node("Sprite2D") as Sprite2D
		var feet: CollisionShape2D = post.get_node("CollisionShape2D") as CollisionShape2D
		assert_eq(sprite.global_position.x,feet.global_position.x)
		assert_almost_eq(sprite.global_position.y+32.0,post.global_position.y,0.01)


func test_player_walks_under_roof_edges_while_house_structure_stays_solid() -> void:
	var yard: Node2D = BACKYARD.instantiate() as Node2D
	add_child_autofree(yard)
	var player: Player = yard.get_node("YSortRoot/Player") as Player
	var roof: TileMapLayer = yard.get_node("RoofLayer") as TileMapLayer
	assert_gt(roof.z_index,(yard.get_node("YSortRoot") as Node2D).z_index,"As telhas cobrem os personagens")
	assert_eq(roof.tile_set.get_physics_layers_count(),1,"A camada de física continua disponível no editor")
	await wait_physics_frames(3)
	for point: Vector2 in [Vector2(50,72),Vector2(432,72),Vector2(432,160)]:
		assert_true(_feet_are_clear(player,point),"Passagem sob o beiral em "+str(point))
	assert_false(player.test_move(Transform2D(0.0,Vector2(560,72)),Vector2(-128,0)),"É possível entrar sob o beiral direito")
	for point: Vector2 in [Vector2(240,96),Vector2(240,224)]:
		assert_false(_feet_are_clear(player,point),"A construção permanece sólida")
	player.global_position = Vector2(50,144)
	Input.action_press(&"move_up")
	await wait_physics_frames(36)
	Input.action_release(&"move_up")
	await wait_physics_frames(3)
	assert_lt(player.global_position.y,90.0,"O Player atravessa a faixa onde havia colisão nas telhas")
	assert_almost_eq(player.global_position.x,50.0,0.1)


func test_e_at_kitchen_door_asks_and_no_keeps_player_inside() -> void:
	var house: Node2D = _live_house()
	var player: Player = house.get_node("YSortRoot/Player") as Player
	var hud: GameplayHUD = house.get_node("GameplayHUD") as GameplayHUD
	var door: SceneDoor = house.get_node(KITCHEN_DOOR) as SceneDoor
	assert_eq(door.target_scene,BACKYARD.resource_path)
	await wait_physics_frames(3)
	assert_false(player.test_move(player.global_transform,Vector2(-284,0)))
	assert_false(player.test_move(Transform2D(0.0,Vector2(36,440)),Vector2(0,-56)))
	await _approach_kitchen(player)
	await _tap_key(KEY_E)
	assert_eq(hud.mode,GameplayHUD.ModalMode.DOOR_CONFIRM)
	assert_eq((hud.get_node("Screen/Dialogue/Text") as Label).text,"Deseja sair e ir para o quintal?")
	assert_false(player.movement_enabled)
	assert_false(WorldState.scene_transition.is_transitioning)
	await _tap_key(KEY_RIGHT)
	assert_true((hud.get_node("Screen/Dialogue/No") as Button).has_focus())
	await _tap_key(KEY_E)
	assert_eq(hud.mode,GameplayHUD.ModalMode.NONE)
	assert_true(player.movement_enabled)
	assert_eq(get_tree().current_scene,house)
	assert_true(WorldState.inventory.get_items().is_empty())


func test_escape_and_tab_cancel_the_pending_door_without_traveling() -> void:
	var house: Node2D = _live_house()
	var player: Player = house.get_node("YSortRoot/Player") as Player
	var hud: GameplayHUD = house.get_node("GameplayHUD") as GameplayHUD
	await _approach_kitchen(player)
	await _tap_key(KEY_E)
	await _tap_key(KEY_ESCAPE)
	assert_eq(hud.mode,GameplayHUD.ModalMode.NONE)
	assert_true(player.movement_enabled)
	await _tap_key(KEY_E)
	await _tap_key(KEY_TAB)
	assert_eq(hud.mode,GameplayHUD.ModalMode.INVENTORY)
	await _tap_key(KEY_TAB)
	assert_eq(hud.mode,GameplayHUD.ModalMode.NONE)
	assert_false(WorldState.scene_transition.is_transitioning)
	assert_eq(get_tree().current_scene,house)


func test_yes_goes_to_backyard_and_return_door_restores_house_and_inventory() -> void:
	var house: Node2D = _live_house()
	var inventory: InventorySystem = WorldState.inventory
	var bottle: CollectibleItem = preload("res://components/interactables/collectible_item.tscn").instantiate() as CollectibleItem
	bottle.item_data = preload("res://core/inventory/items/stage_01/garrafa_vazia.tres")
	bottle.persistent_id = &"backyard_test_bottle"
	house.add_child(bottle)
	assert_true(bottle.collect(inventory))
	WorldState.register_entity_outcome(&"saci",WorldStateLogic.Outcome.FRIENDSHIP)
	var player: Player = house.get_node("YSortRoot/Player") as Player
	var hud: GameplayHUD = house.get_node("GameplayHUD") as GameplayHUD
	await _approach_kitchen(player)
	await _tap_key(KEY_E)
	await _tap_key(KEY_E)
	assert_true(WorldState.scene_transition.is_transitioning)
	assert_false(player.movement_enabled)
	await wait_for_signal(WorldState.scene_transition.transition_finished,2.0)
	var yard: Node2D = get_tree().current_scene as Node2D
	assert_eq(yard.scene_file_path,BACKYARD.resource_path)
	player = yard.get_node("YSortRoot/Player") as Player
	hud = yard.get_node("GameplayHUD") as GameplayHUD
	assert_eq(player.global_position,Vector2(140,320))
	assert_eq(player.facing_direction,Vector2.UP)
	assert_true(player.movement_enabled)
	assert_true(player.camera.is_current())
	assert_eq(WorldState.inventory,inventory)
	assert_eq(inventory.get_quantity(&"garrafa_vazia"),1)
	assert_eq(WorldState.nature_balance,1)
	await wait_physics_frames(6)
	assert_eq(hud.mode,GameplayHUD.ModalMode.NONE)
	assert_false(WorldState.scene_transition.is_transitioning)
	await _tap_key(KEY_E)
	assert_eq(hud.mode,GameplayHUD.ModalMode.DOOR_CONFIRM)
	assert_eq((hud.get_node("Screen/Dialogue/Text") as Label).text,"Deseja entrar na casa?")
	await _tap_key(KEY_E)
	assert_true(WorldState.scene_transition.is_transitioning)
	await wait_for_signal(WorldState.scene_transition.transition_finished,2.0)
	house = get_tree().current_scene as Node2D
	assert_eq(house.scene_file_path,HOUSE.resource_path)
	player = house.get_node("YSortRoot/Player") as Player
	assert_eq(player.global_position,Vector2(36,392))
	assert_eq(player.facing_direction,Vector2.DOWN)
	assert_true(player.movement_enabled)
	assert_false(house.has_node("YSortRoot/BottleCollectible"))
	assert_eq(inventory.get_quantity(&"garrafa_vazia"),1)
	await wait_physics_frames(6)
	assert_false(WorldState.scene_transition.is_transitioning)
	assert_eq((house.get_node("GameplayHUD") as GameplayHUD).mode,GameplayHUD.ModalMode.NONE)


func test_missing_door_during_confirmation_does_not_travel_or_leave_player_locked() -> void:
	var house: Node2D = _live_house()
	var player: Player = house.get_node("YSortRoot/Player") as Player
	var hud: GameplayHUD = house.get_node("GameplayHUD") as GameplayHUD
	await _approach_kitchen(player)
	await _tap_key(KEY_E)
	house.get_node(KITCHEN_DOOR).queue_free()
	await wait_process_frames(2)
	await _tap_key(KEY_E)
	assert_eq(hud.mode,GameplayHUD.ModalMode.NONE)
	assert_true(player.movement_enabled)
	assert_false(WorldState.scene_transition.is_transitioning)


func test_invalid_door_destination_returns_a_notice_without_changing_scene() -> void:
	var house: Node2D = _live_house()
	var player: Player = house.get_node("YSortRoot/Player") as Player
	var hud: GameplayHUD = house.get_node("GameplayHUD") as GameplayHUD
	(house.get_node(KITCHEN_DOOR) as SceneDoor).target_scene = "res://missing_backyard.tscn"
	await _approach_kitchen(player)
	await _tap_key(KEY_E)
	await _tap_key(KEY_E)
	assert_eq(hud.mode,GameplayHUD.ModalMode.NOTICE)
	assert_false(WorldState.scene_transition.is_transitioning)
	assert_eq(get_tree().current_scene,house)
	await _tap_key(KEY_E)
	assert_true(player.movement_enabled)


func _live_house() -> Node2D:
	var house: Node2D = HOUSE.instantiate() as Node2D
	get_tree().root.add_child(house)
	get_tree().current_scene = house
	return house


func _approach_kitchen(player: Player) -> void:
	player.position = Vector2(36,384)
	Input.action_press(&"move_up")
	await wait_physics_frames(1)
	Input.action_release(&"move_up")
	await wait_physics_frames(3)


func _feet_are_clear(player: Player, at: Vector2) -> bool:
	var shape: RectangleShape2D = RectangleShape2D.new()
	shape.size = Vector2(24,16)
	var query: PhysicsShapeQueryParameters2D = PhysicsShapeQueryParameters2D.new()
	query.shape = shape
	query.transform = Transform2D(0.0,at+Vector2(0,-8))
	query.collision_mask = 1
	return player.get_world_2d().direct_space_state.intersect_shape(query).is_empty()


func _tap_key(key: Key) -> void:
	var pressed: InputEventKey = InputEventKey.new()
	pressed.keycode = key
	pressed.physical_keycode = key
	pressed.pressed = true
	Input.parse_input_event(pressed)
	await wait_process_frames(1)
	var released: InputEventKey = InputEventKey.new()
	released.keycode = key
	released.physical_keycode = key
	Input.parse_input_event(released)
	await wait_process_frames(1)


func _release_actions() -> void:
	for action: StringName in ACTIONS:
		Input.action_release(action)
