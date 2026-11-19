extends GutTest
## Cidade editável, caminhos físicos, confirmação automática e retorno sem perder progresso.

const HOUSE: PackedScene = preload("res://stages/stage_01_saci/house_interior.tscn")
const CITY: PackedScene = preload("res://stages/stage_01_saci/santa_teresa_map.tscn")
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
		await wait_for_signal(WorldState.scene_transition.transition_finished, 2.0)
	var current: Node = get_tree().current_scene
	if current != _previous_scene:
		get_tree().current_scene = _previous_scene
		if is_instance_valid(current):
			current.queue_free()
		await wait_process_frames(2)
	WorldState.scene_transition.fade_duration = _fade_duration
	WorldState.reset()


func test_city_matches_concept_layout_and_uses_editable_production_assets() -> void:
	var city: Node2D = CITY.instantiate() as Node2D
	add_child_autofree(city)
	var floor_layer: TileMapLayer = city.get_node("FloorLayer") as TileMapLayer
	assert_eq(floor_layer.get_used_rect(), Rect2i(0, 0, 32, 18))
	assert_eq(floor_layer.get_used_cells().size(), 576)
	for layer_name: String in ["FloorLayer", "FloorDetailsLayer", "SidewalkLayer", "StreetEdgesLayer", "GardenDetailsLayer", "GardenEdgesLayer", "TramTracksLayer"]:
		assert_is(city.get_node(layer_name), TileMapLayer)
	for node: Node in city.find_children("*", "TileMapLayer", true, false):
		var layer: TileMapLayer = node as TileMapLayer
		assert_true(layer.tile_set.tile_size in [Vector2i(16,16), Vector2i(32,32)])
		for cell: Vector2i in layer.get_used_cells():
			var source: TileSetAtlasSource = layer.tile_set.get_source(layer.get_cell_source_id(cell)) as TileSetAtlasSource
			assert_false(source.texture.resource_path.contains("_templates"))
			assert_true(Rect2i(Vector2i.ZERO,Vector2i(source.texture.get_size())).encloses(source.get_tile_texture_region(layer.get_cell_atlas_coords(cell))))
	for node: Node in city.find_children("*", "Sprite2D", true, false):
		var sprite: Sprite2D = node as Sprite2D
		assert_not_null(sprite.texture)
		if sprite.region_enabled:
			assert_true(Rect2(Vector2.ZERO,sprite.texture.get_size()).encloses(sprite.region_rect))
	var locations: Dictionary[String,Vector2] = {"HouseEntrance":Vector2(856,336), "PlazaBench":Vector2(512,384), "Mural":Vector2(800,160), "Tram":Vector2(176,304), "Quitanda":Vector2(144,536), "BambooGrove":Vector2(880,544)}
	for site: String in locations:
		assert_eq((city.get_node("PointsOfInterest/"+site) as Marker2D).position,locations[site])
	for building_name: String in ["HouseFacade", "NorthHouse", "NorthEastHouse", "WestNeighborHouse", "EastNeighborHouse"]:
		var building: StaticBody2D = city.get_node("YSortRoot/SharedProps/"+building_name) as StaticBody2D
		assert_not_null((building.get_node("CollisionShape2D") as CollisionShape2D).shape)
		assert_is(building.get_node("FacadeLayer"),TileMapLayer)
		assert_is(building.get_node("RoofLayer"),TileMapLayer)
	var camera: Camera2D = city.get_node("YSortRoot/Player/Camera2D") as Camera2D
	assert_eq(camera.limit_right,1024)
	assert_eq(camera.limit_bottom,576)
	assert_true(camera.is_current())
	assert_true((city.get_node("YSortRoot/SharedProps") as Node2D).y_sort_enabled)


func test_city_keeps_camera_and_door_overrides_when_the_scene_is_packed_again() -> void:
	var original: Node = CITY.instantiate()
	var packed: PackedScene = PackedScene.new()
	assert_eq(packed.pack(original), OK)
	original.free()
	var restored: Node = packed.instantiate()
	var camera: Camera2D = restored.get_node("YSortRoot/Player/Camera2D") as Camera2D
	assert_eq(camera.limit_right, 1024)
	assert_eq(camera.limit_bottom, 576)
	assert_eq(camera.get("floor_layer_path"), NodePath("../../../FloorLayer"))
	var entrance: CollisionShape2D = restored.get_node("Transitions/EnterHouse/CollisionShape2D") as CollisionShape2D
	assert_eq(entrance.shape.get_rect().size, Vector2(40,16))
	restored.free()


func test_city_supports_concept_daylight_and_both_narrative_lighting_states() -> void:
	var city: Node2D = CITY.instantiate() as Node2D
	add_child_autofree(city)
	var light: CanvasModulate = city.get_node("CityModulate") as CanvasModulate
	assert_eq(light.color,Color.WHITE)
	city.call(&"apply_city_state", &"scene_7_street_hub")
	assert_eq(light.color,Color("9eaab8"))
	city.call(&"apply_city_state", &"scene_2_sunset")
	assert_eq(light.color,Color("ffdfb3"))
	city.call(&"apply_city_state", &"invalid_phase")
	assert_eq(light.color,Color("ffdfb3"))
	city.call(&"apply_city_state", &"concept_daylight")
	assert_eq(light.color,Color.WHITE)


func test_concept_paths_connect_house_plaza_tram_market_and_bamboo() -> void:
	var city: Node2D = CITY.instantiate() as Node2D
	add_child_autofree(city)
	await wait_physics_frames(3)
	var player: Player = city.get_node("YSortRoot/Player") as Player
	player.set_movement_enabled(false)
	var reachable: Dictionary[Vector2i,bool] = {}
	var queue: Array[Vector2i] = [Vector2i(64,56)]
	reachable[queue[0]] = true
	var head: int = 0
	while head < queue.size():
		var cell: Vector2i = queue[head]
		head += 1
		for direction: Vector2i in [Vector2i.UP,Vector2i.DOWN,Vector2i.LEFT,Vector2i.RIGHT]:
			var next: Vector2i = cell+direction
			if reachable.has(next) or not Rect2i(2,4,124,68).has_point(next):
				continue
			if _feet_are_clear(player,Vector2(next*8)) and not player.test_move(Transform2D(0.0,Vector2(cell*8)),Vector2(direction*8)):
				reachable[next] = true
				queue.append(next)
	for point: Vector2i in [Vector2i(856,368), Vector2i(512,416), Vector2i(800,192), Vector2i(176,336), Vector2i(144,560), Vector2i(880,544), Vector2i(512,64), Vector2i(320,160)]:
		assert_true(reachable.has(point/8), "Caminho até "+str(point))
	for direction: Vector2 in [Vector2.LEFT,Vector2.RIGHT,Vector2.UP,Vector2.DOWN]:
		assert_true(player.test_move(Transform2D(0.0,Vector2(512,448)),direction*1500.0))
	var spawn: Marker2D = city.get_node("SpawnPoints/FromHouseInterior") as Marker2D
	assert_true(_feet_are_clear(player,spawn.global_position))
	var entrance: ThresholdDoor = city.get_node("Transitions/EnterHouse") as ThresholdDoor
	assert_eq((entrance.get_node("CollisionShape2D") as CollisionShape2D).shape.get_rect().size,Vector2(40,16))


func test_house_forecourt_is_open_without_invisible_gate_or_wall_collisions() -> void:
	var city: Node2D = CITY.instantiate() as Node2D
	add_child_autofree(city)
	await wait_physics_frames(3)
	var player: Player = city.get_node("YSortRoot/Player") as Player
	player.set_movement_enabled(false)
	# Estes pontos eram bloqueados pelas folhas do portão e pela mureta.
	for point: Vector2 in [Vector2(744,384),Vector2(824,376),Vector2(884,376),Vector2(968,384)]:
		assert_true(_feet_are_clear(player,point), "Calçada livre em "+str(point))
	assert_false(player.test_move(Transform2D(0.0,Vector2(720,384)),Vector2(272,0)))
	assert_false(player.test_move(Transform2D(0.0,Vector2(744,360)),Vector2(0,48)))
	assert_false(_feet_are_clear(player,Vector2(856,320)), "A fachada continua sólida")


func test_quitandeira_stays_idle_behind_counter_and_e_opens_and_closes_dialogue() -> void:
	var city: Node2D = _live(CITY)
	var vendor: StaticBody2D = city.get_node("YSortRoot/SharedProps/Quitanda/Quitandeira") as StaticBody2D
	var sprite: AnimatedSprite2D = vendor.get_node("AnimatedSprite2D") as AnimatedSprite2D
	var start: Vector2 = vendor.global_position
	assert_eq(sprite.animation,&"idle_down")
	assert_eq(sprite.sprite_frames.get_frame_count(&"idle_down"),1)
	assert_true(sprite.is_playing())
	var counter: StaticBody2D = city.get_node("YSortRoot/SharedProps/Quitanda/Counter") as StaticBody2D
	assert_lte(vendor.global_position.y,counter.global_position.y)
	var player: Player = city.get_node("YSortRoot/Player") as Player
	player.global_position = Vector2(144,560)
	Input.action_press(&"move_up")
	await wait_physics_frames(1)
	Input.action_release(&"move_up")
	await wait_physics_frames(3)
	assert_true(_feet_are_clear(player,player.global_position))
	await _tap_key(KEY_E)
	var hud: GameplayHUD = city.get_node("GameplayHUD") as GameplayHUD
	assert_eq(hud.mode,GameplayHUD.ModalMode.NOTICE)
	assert_true((hud.get_node("Screen/Dialogue/Text") as Label).text.begins_with("Quitandeira:"))
	assert_false(player.movement_enabled)
	await _tap_key(KEY_E)
	assert_eq(hud.mode,GameplayHUD.ModalMode.NONE)
	assert_true(player.movement_enabled)
	assert_eq(vendor.global_position,start)
	assert_eq(sprite.animation,&"idle_down")


func test_mural_uses_real_wall_bamboo_uses_real_assets_and_market_has_fruit_crates() -> void:
	var city: Node2D = CITY.instantiate() as Node2D
	add_child_autofree(city)
	var wall: StaticBody2D = city.get_node("YSortRoot/SharedProps/MuralWall") as StaticBody2D
	assert_eq(wall.find_children("*","Sprite2D",true,false).size(),4)
	for index: int in range(1,7):
		assert_is(wall.get_node("Panel%02d" % index),Marker2D)
	var bamboo: Node2D = city.get_node("YSortRoot/SharedProps/BambooGrove") as Node2D
	assert_eq(bamboo.find_children("*","Sprite2D",true,false).size(),5)
	for prop: String in ["FruitCrateLeft","FruitCrateRight","Counter"]:
		assert_is(city.get_node("YSortRoot/SharedProps/Quitanda/"+prop),StaticBody2D)


func test_bottom_exit_prompts_without_e_and_cancel_does_not_repeat_or_let_player_leave_map() -> void:
	var house: Node2D = _live(HOUSE)
	var player: Player = house.get_node("YSortRoot/Player") as Player
	var hud: GameplayHUD = house.get_node("GameplayHUD") as GameplayHUD
	await _approach_house_exit(player)
	_assert_question(hud, "Deseja sair e ir para a cidade?")
	assert_false(player.movement_enabled)
	await _tap_key(KEY_RIGHT)
	assert_true((hud.get_node("Screen/Dialogue/No") as Button).has_focus())
	await _tap_key(KEY_E)
	assert_eq(hud.mode, GameplayHUD.ModalMode.NONE)
	assert_true(player.movement_enabled)
	Input.action_press(&"move_down")
	await wait_physics_frames(35)
	Input.action_release(&"move_down")
	assert_lte(player.position.y, 672.0)
	assert_eq(hud.mode, GameplayHUD.ModalMode.NONE)
	assert_eq(get_tree().current_scene, house)
	Input.action_press(&"move_up")
	await wait_physics_frames(30)
	Input.action_release(&"move_up")
	await _approach_house_exit(player)
	_assert_question(hud, "Deseja sair e ir para a cidade?")
	await _tap_key(KEY_ESCAPE)
	assert_eq(hud.mode, GameplayHUD.ModalMode.NONE)
	assert_true(player.movement_enabled)


func test_house_city_round_trip_keeps_inventory_pickups_and_safe_arrivals() -> void:
	var house: Node2D = _live(HOUSE)
	var inventory: InventorySystem = WorldState.inventory
	# Coleta mecânica de teste: não distribuir a garrafa na casa do roteiro.
	var pickup: CollectibleItem = preload("res://components/interactables/collectible_item.tscn").instantiate() as CollectibleItem
	pickup.item_data = preload("res://core/inventory/items/stage_01/garrafa_vazia.tres")
	pickup.persistent_id = &"navigation_test_bottle"
	house.add_child(pickup)
	assert_true(pickup.collect(inventory))
	WorldState.register_entity_outcome(&"saci", WorldStateLogic.Outcome.FRIENDSHIP)
	var player: Player = house.get_node("YSortRoot/Player") as Player
	await _approach_house_exit(player)
	await _tap_key(KEY_E)
	assert_true(WorldState.scene_transition.is_transitioning)
	assert_false(player.movement_enabled)
	await wait_for_signal(WorldState.scene_transition.transition_finished, 2.0)
	var city: Node2D = get_tree().current_scene as Node2D
	assert_eq(city.scene_file_path, CITY.resource_path)
	player = city.get_node("YSortRoot/Player") as Player
	var hud: GameplayHUD = city.get_node("GameplayHUD") as GameplayHUD
	assert_eq(player.global_position, Vector2(856,368))
	assert_eq(player.facing_direction, Vector2.DOWN)
	assert_true(player.movement_enabled)
	assert_true(player.camera.is_current())
	assert_eq(WorldState.inventory, inventory)
	assert_eq(inventory.get_quantity(&"garrafa_vazia"), 1)
	assert_eq(WorldState.nature_balance, 1)
	await wait_physics_frames(8)
	assert_eq(hud.mode, GameplayHUD.ModalMode.NONE)
	Input.action_press(&"move_up")
	await wait_until(_door_question_visible, 1.0)
	Input.action_release(&"move_up")
	_assert_question(hud, "Deseja entrar na casa?")
	await _tap_key(KEY_ESCAPE)
	assert_true(player.movement_enabled)
	assert_false(WorldState.scene_transition.is_transitioning)
	# Recuar e voltar rearma a área; permanecer parado após cancelar não rearma.
	await wait_physics_frames(5)
	assert_eq(hud.mode, GameplayHUD.ModalMode.NONE)
	Input.action_press(&"move_down")
	await wait_physics_frames(16)
	Input.action_release(&"move_down")
	Input.action_press(&"move_up")
	await wait_until(_door_question_visible, 1.0)
	Input.action_release(&"move_up")
	_assert_question(hud, "Deseja entrar na casa?")
	await _tap_key(KEY_E)
	await wait_for_signal(WorldState.scene_transition.transition_finished, 2.0)
	house = get_tree().current_scene as Node2D
	assert_eq(house.scene_file_path, HOUSE.resource_path)
	player = house.get_node("YSortRoot/Player") as Player
	assert_eq(player.global_position, Vector2(320,624))
	assert_eq(player.facing_direction, Vector2.UP)
	assert_true(player.movement_enabled)
	assert_true(_feet_are_clear(player, player.global_position))
	assert_false(house.has_node("YSortRoot/BottleCollectible"))
	assert_eq(inventory.get_quantity(&"garrafa_vazia"), 1)
	await wait_physics_frames(8)
	assert_eq((house.get_node("GameplayHUD") as GameplayHUD).mode, GameplayHUD.ModalMode.NONE)
	assert_false(WorldState.scene_transition.is_transitioning)


func test_tab_cancels_the_exit_question_and_missing_destination_returns_control() -> void:
	var house: Node2D = _live(HOUSE)
	var player: Player = house.get_node("YSortRoot/Player") as Player
	var hud: GameplayHUD = house.get_node("GameplayHUD") as GameplayHUD
	await _approach_house_exit(player)
	await _tap_key(KEY_TAB)
	assert_eq(hud.mode, GameplayHUD.ModalMode.INVENTORY)
	await _tap_key(KEY_TAB)
	assert_eq(hud.mode, GameplayHUD.ModalMode.NONE)
	assert_true(player.movement_enabled)
	var door: ThresholdDoor = house.get_node("Transitions/FrontDoorToCity") as ThresholdDoor
	door.target_scene = "res://missing_city.tscn"
	await _tap_key(KEY_E)
	_assert_question(hud, "Deseja sair e ir para a cidade?")
	await _tap_key(KEY_E)
	assert_eq(hud.mode, GameplayHUD.ModalMode.NOTICE)
	assert_false(WorldState.scene_transition.is_transitioning)
	await _tap_key(KEY_E)
	assert_true(player.movement_enabled)
	assert_eq(get_tree().current_scene, house)


func _live(scene: PackedScene) -> Node2D:
	var level: Node2D = scene.instantiate() as Node2D
	get_tree().root.add_child(level)
	get_tree().current_scene = level
	return level


func _approach_house_exit(player: Player) -> void:
	player.position = Vector2(320,608)
	await wait_physics_frames(3)
	Input.action_press(&"move_down")
	await wait_until(_door_question_visible, 1.0)
	Input.action_release(&"move_down")
	await wait_process_frames(2)


func _door_question_visible() -> bool:
	var scene: Node = get_tree().current_scene
	var hud: GameplayHUD = scene.get_node("GameplayHUD") as GameplayHUD
	return hud.mode == GameplayHUD.ModalMode.DOOR_CONFIRM


func _assert_question(hud: GameplayHUD, text: String) -> void:
	assert_eq(hud.mode, GameplayHUD.ModalMode.DOOR_CONFIRM)
	assert_eq((hud.get_node("Screen/Dialogue/Text") as Label).text, text)


func _feet_are_clear(player: Player, at: Vector2) -> bool:
	var shape: RectangleShape2D = RectangleShape2D.new()
	shape.size = Vector2(24,16)
	var query: PhysicsShapeQueryParameters2D = PhysicsShapeQueryParameters2D.new()
	query.shape = shape
	query.transform = Transform2D(0.0, at + Vector2(0,-8))
	query.collision_mask = 1
	return player.get_world_2d().direct_space_state.intersect_shape(query).is_empty()


func _tap_key(key: Key) -> void:
	var event: InputEventKey = InputEventKey.new()
	event.keycode = key
	event.physical_keycode = key
	event.pressed = true
	Input.parse_input_event(event)
	await wait_process_frames(1)
	var release: InputEventKey = InputEventKey.new()
	release.keycode = key
	release.physical_keycode = key
	Input.parse_input_event(release)
	await wait_process_frames(1)


func _release_actions() -> void:
	for action: StringName in ACTIONS:
		Input.action_release(action)
