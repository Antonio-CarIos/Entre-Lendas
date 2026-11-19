extends GutTest
## Estrutura, circulação e travessia real das duas cenas com fade e persistência.

const HOUSE: PackedScene = preload("res://stages/stage_01_saci/house_interior.tscn")
const BEDROOM: PackedScene = preload("res://stages/stage_01_saci/house_bedroom.tscn")
const STAIRS: PackedScene = preload("res://components/transitions/stair_transition.tscn")
const PLAYER: PackedScene = preload("res://entities/player/player.tscn")
const ACTIONS: Array[StringName] = [
	&"move_up", &"move_down", &"move_left", &"move_right", &"interact", &"open_inventory"
]

var _previous_scene: Node
var _fade_duration: float
var _arrival_alphas: Array[float] = []
var _arrival_locks: Array[bool] = []


func before_each() -> void:
	_release_actions()
	WorldState.reset()
	_previous_scene = get_tree().current_scene
	_fade_duration = WorldState.scene_transition.fade_duration
	WorldState.scene_transition.fade_duration = 0.12
	_arrival_alphas.clear()
	_arrival_locks.clear()


func after_each() -> void:
	_release_actions()
	if WorldState.scene_transition.is_transitioning:
		await wait_for_signal(WorldState.scene_transition.transition_finished, 2.0)
	if get_tree().scene_changed.is_connected(_record_arrival):
		get_tree().scene_changed.disconnect(_record_arrival)
	var current: Node = get_tree().current_scene
	if current != _previous_scene:
		get_tree().current_scene = _previous_scene
		if is_instance_valid(current):
			current.queue_free()
		await wait_process_frames(2)
	WorldState.scene_transition.fade_duration = _fade_duration
	WorldState.reset()


func test_bedroom_has_the_requested_layers_and_the_same_house_materials() -> void:
	var room: Node2D = BEDROOM.instantiate() as Node2D
	add_child_autofree(room)
	var house: Node2D = HOUSE.instantiate() as Node2D
	for layer_name: String in ["FloorLayer", "FloorDetailsLayer", "WallsAndStairsLayer"]:
		var layer: TileMapLayer = room.get_node(layer_name) as TileMapLayer
		assert_not_null(layer)
		for cell: Vector2i in layer.get_used_cells():
			var atlas: TileSetAtlasSource = layer.tile_set.get_source(layer.get_cell_source_id(cell)) as TileSetAtlasSource
			var coords: Vector2i = layer.get_cell_atlas_coords(cell)
			assert_true(atlas.has_tile(coords))
			assert_true(Rect2i(Vector2i.ZERO, Vector2i(atlas.texture.get_size())).encloses(atlas.get_tile_texture_region(coords)))
	var floor_layer: TileMapLayer = room.get_node("FloorLayer") as TileMapLayer
	var house_floor: TileMapLayer = house.get_node("FloorLayer") as TileMapLayer
	assert_eq(floor_layer.get_used_rect(), Rect2i(0,0,20,15))
	assert_eq((floor_layer.tile_set.get_source(0) as TileSetAtlasSource).texture,
		(house_floor.tile_set.get_source(0) as TileSetAtlasSource).texture)
	assert_eq(floor_layer.get_cell_atlas_coords(Vector2i(8,8)), house_floor.get_cell_atlas_coords(Vector2i(8,14)))
	assert_true((room.get_node("YSortRoot") as Node2D).y_sort_enabled)
	var player: Player = room.get_node("YSortRoot/Player") as Player
	assert_eq(player.animated_sprite.sprite_frames,
		(house.get_node("YSortRoot/Player/AnimatedSprite2D") as AnimatedSprite2D).sprite_frames)
	assert_eq(player.camera.limit_right, 640)
	assert_eq(player.camera.limit_bottom, 480)
	house.free()


func test_furniture_uses_named_nodes_sprites_and_colliders_inside_the_atlas() -> void:
	var room: Node2D = BEDROOM.instantiate() as Node2D
	add_child_autofree(room)
	for prop_name: String in ["Bed", "Nightstand", "Wardrobe", "StandingMirror", "WritingDesk", "DeskChair", "Bookshelf", "PlantPot", "PlantPot2"]:
		var prop: StaticBody2D = room.get_node("YSortRoot/State_Organized/" + prop_name) as StaticBody2D
		assert_not_null(prop)
		assert_eq(prop.collision_layer, 1)
		assert_eq(prop.collision_mask, 2)
		var sprite: Sprite2D = prop.get_node("Sprite2D") as Sprite2D
		var collider: CollisionShape2D = prop.get_node("CollisionShape2D") as CollisionShape2D
		assert_true(Rect2(Vector2.ZERO, sprite.texture.get_size()).encloses(sprite.region_rect))
		assert_eq(sprite.texture.resource_path, "res://assets/art/props/stage_01/house/house_furniture_atlas.png")
		assert_eq(sprite.position.y + sprite.get_rect().end.y, 0.0,
			"Pivô dos móveis alinhado à base para Y-Sort.")
		assert_not_null(collider.shape)
		assert_false(collider.disabled)


func test_arrival_points_are_clear_and_outside_the_stair_triggers() -> void:
	for scene: PackedScene in [HOUSE,BEDROOM]:
		var level: Node2D = scene.instantiate() as Node2D
		add_child_autofree(level)
		await wait_physics_frames(2)
		var name_in_scene: String = "FromBedroom" if scene == HOUSE else "FromHouseInterior"
		var marker: Marker2D = level.get_node("SpawnPoints/" + name_in_scene) as Marker2D
		var stairs: StairTransition = level.get_node("Transitions").get_child(0) as StairTransition
		assert_eq(stairs.collision_layer, 0)
		assert_eq(stairs.collision_mask, 2)
		assert_false(stairs.monitorable)
		var trigger_shape: RectangleShape2D = (stairs.get_node("CollisionShape2D") as CollisionShape2D).shape as RectangleShape2D
		var feet: Rect2 = Rect2(marker.global_position + Vector2(-12,-16), Vector2(24,16))
		assert_false(Rect2(stairs.global_position - trigger_shape.size * 0.5, trigger_shape.size).intersects(feet))
		var player: Player = level.get_node("YSortRoot/Player") as Player
		assert_true(_feet_are_clear(player, marker.global_position))
		level.queue_free()
		await wait_process_frames(2)


func test_bedroom_furniture_and_perimeter_block_the_player() -> void:
	var room: Node2D = BEDROOM.instantiate() as Node2D
	add_child_autofree(room)
	await wait_physics_frames(3)
	var player: Player = room.get_node("YSortRoot/Player") as Player
	var bed: StaticBody2D = room.get_node("YSortRoot/State_Organized/Bed") as StaticBody2D
	var result: KinematicCollision2D = KinematicCollision2D.new()
	assert_true(player.test_move(Transform2D(0.0,Vector2(128,288)), Vector2(0,-128),result))
	assert_eq(result.get_collider(), bed)
	for direction: Vector2 in [Vector2.LEFT,Vector2.RIGHT,Vector2.UP,Vector2.DOWN]:
		result = KinematicCollision2D.new()
		assert_true(player.test_move(Transform2D(0.0,Vector2(240,304)), direction * 800.0,result))
		assert_is(result.get_collider(), TileMapLayer)


func test_every_furniture_approach_and_stairs_are_reachable_with_player_footprint() -> void:
	var room: Node2D = BEDROOM.instantiate() as Node2D
	add_child_autofree(room)
	await wait_physics_frames(3)
	var player: Player = room.get_node("YSortRoot/Player") as Player
	var reachable: Dictionary[Vector2i,bool] = {}
	var queue: Array[Vector2i] = [Vector2i(31,21)]
	reachable[queue[0]] = true
	var head: int = 0
	while head < queue.size():
		var cell: Vector2i = queue[head]
		head += 1
		for direction: Vector2i in [Vector2i.UP,Vector2i.DOWN,Vector2i.LEFT,Vector2i.RIGHT]:
			var next: Vector2i = cell + direction
			if reachable.has(next) or not Rect2i(2,9,36,19).has_point(next):
				continue
			if _feet_are_clear(player, Vector2(next * 16)):
				reachable[next] = true
				queue.append(next)
	for approach: Vector2i in [Vector2i(128,288),Vector2i(192,240),Vector2i(336,288),Vector2i(416,240),Vector2i(528,256),Vector2i(160,384),Vector2i(272,304),Vector2i(496,400)]:
		assert_true(reachable.has(approach / 16), "Acesso livre até " + str(approach))


func test_stair_trigger_ignores_stationary_locked_and_opposite_direction_players() -> void:
	var stairs: StairTransition = STAIRS.instantiate() as StairTransition
	add_child_autofree(stairs)
	var player: Player = PLAYER.instantiate() as Player
	player.position = Vector2(0,8)
	add_child_autofree(player)
	watch_signals(stairs)
	player.set_movement_enabled(false)
	await wait_physics_frames(3)
	stairs._physics_process(0.0)
	assert_signal_not_emitted(stairs, &"transition_requested")
	player.set_movement_enabled(true)
	player.velocity = Vector2.ZERO
	stairs._physics_process(0.0)
	player.velocity = Vector2.DOWN * 120.0
	stairs._physics_process(0.0)
	assert_signal_not_emitted(stairs, &"transition_requested")
	player.velocity = Vector2.UP * 120.0
	stairs._physics_process(0.0)
	stairs._physics_process(0.0)
	assert_signal_emit_count(stairs, &"transition_requested",1)


func test_invalid_destination_is_rejected_without_locking_or_fading() -> void:
	var level: Node2D = _live_house()
	var player: Player = level.get_node("YSortRoot/Player") as Player
	assert_false(WorldState.scene_transition.travel_to(level,player,"res://does_not_exist.tscn",&"FromHouseInterior"))
	assert_false(WorldState.scene_transition.travel_to(level,player,BEDROOM.resource_path,&"MissingMarker"))
	assert_false(WorldState.scene_transition.travel_to(self,player,BEDROOM.resource_path,&"FromHouseInterior"))
	assert_false(WorldState.scene_transition.is_transitioning)
	assert_true(player.movement_enabled)
	assert_false((WorldState.scene_transition.get_node("Fade") as ColorRect).visible)


func test_climbing_and_descending_change_scenes_under_black_and_preserve_progress() -> void:
	var house: Node2D = _live_house()
	var shared_inventory: InventorySystem = WorldState.inventory
	# Preparação mecânica explícita; não espalhar recompensas futuras pelo roteiro.
	assert_true(shared_inventory.add_item(preload("res://core/inventory/items/stage_01/fita_vermelha.tres")))
	assert_true(shared_inventory.add_item(preload("res://core/inventory/items/stage_01/peneira.tres")))
	assert_true(shared_inventory.combine_items(&"fita_vermelha",&"peneira"))
	WorldState.register_entity_outcome(&"saci",WorldStateLogic.Outcome.FRIENDSHIP)
	get_tree().scene_changed.connect(_record_arrival)
	watch_signals(WorldState.scene_transition)
	var player: Player = house.get_node("YSortRoot/Player") as Player
	await wait_physics_frames(3)
	assert_false(player.test_move(player.global_transform,Vector2(0,168)))
	assert_false(player.test_move(Transform2D(0.0,Vector2(320,608)),Vector2(176,0)))
	player.position = Vector2(496,608)
	await wait_physics_frames(2)
	Input.action_press(&"move_up")
	await wait_until(_is_transitioning,2.0)
	Input.action_release(&"move_up")
	assert_true(WorldState.scene_transition.is_transitioning)
	assert_false(player.movement_enabled)
	assert_lt(player.position.y,576.0)
	assert_gt(player.position.y,500.0)
	var curtain: ColorRect = WorldState.scene_transition.get_node("Fade") as ColorRect
	assert_true(curtain.visible)
	assert_eq(curtain.size,get_viewport().get_visible_rect().size)
	var hud: GameplayHUD = house.get_node("GameplayHUD") as GameplayHUD
	var event: InputEventAction = InputEventAction.new()
	event.action = &"open_inventory"
	event.pressed = true
	hud._input(event)
	assert_eq(hud.mode,GameplayHUD.ModalMode.NONE)
	assert_false(WorldState.scene_transition.travel_to(house,player,BEDROOM.resource_path,&"FromHouseInterior"))
	await wait_for_signal(WorldState.scene_transition.transition_finished,2.0)
	var bedroom: Node2D = get_tree().current_scene as Node2D
	assert_eq(bedroom.scene_file_path,BEDROOM.resource_path)
	player = bedroom.get_node("YSortRoot/Player") as Player
	assert_eq(player.global_position,(bedroom.get_node("SpawnPoints/FromHouseInterior") as Marker2D).global_position)
	assert_eq(player.facing_direction,Vector2.UP)
	assert_true(player.movement_enabled)
	assert_true(player.camera.is_current())
	assert_false(curtain.visible)
	assert_eq(curtain.color.a,0.0)
	assert_eq(WorldState.inventory,shared_inventory)
	assert_eq(shared_inventory.get_quantity(&"peneira_cruz"),1)
	assert_eq(WorldState.nature_balance,1)
	await wait_physics_frames(5)
	assert_signal_emit_count(WorldState.scene_transition,&"transition_started",1)
	Input.action_press(&"move_down")
	await wait_until(_is_transitioning,2.0)
	Input.action_release(&"move_down")
	assert_true(WorldState.scene_transition.is_transitioning)
	await wait_for_signal(WorldState.scene_transition.transition_finished,2.0)
	house = get_tree().current_scene as Node2D
	assert_eq(house.scene_file_path,HOUSE.resource_path)
	player = house.get_node("YSortRoot/Player") as Player
	assert_eq(player.global_position,Vector2(496,608))
	assert_eq(player.facing_direction,Vector2.DOWN)
	assert_true(player.movement_enabled)
	assert_false(house.has_node("YSortRoot/RibbonCollectible"))
	assert_false(house.has_node("YSortRoot/SieveCollectible"))
	assert_false(house.has_node("YSortRoot/BottleCollectible"))
	assert_true(house.has_node("YSortRoot/State_Organized/Pipe"))
	assert_false(shared_inventory.has_item(&"fita_vermelha"))
	assert_false(shared_inventory.has_item(&"peneira"))
	assert_eq(shared_inventory.get_quantity(&"peneira_cruz"),1)
	assert_eq(_arrival_alphas,[1.0,1.0])
	assert_eq(_arrival_locks,[false,false])
	await wait_physics_frames(5)
	assert_signal_emit_count(WorldState.scene_transition,&"transition_started",2)


func test_new_game_reset_allows_collectibles_to_appear_again() -> void:
	WorldState.mark_pickup_collected(&"stage01_house_ribbon")
	WorldState.reset()
	var house: Node2D = preload("res://tests/fixtures/inventory_mechanics_lab.tscn").instantiate() as Node2D
	add_child_autofree(house)
	await wait_process_frames(2)
	assert_true(house.has_node("YSortRoot/RibbonCollectible"))
	assert_true(WorldState.inventory.get_items().is_empty())


func _live_house() -> Node2D:
	var house: Node2D = HOUSE.instantiate() as Node2D
	get_tree().root.add_child(house)
	get_tree().current_scene = house
	return house


func _is_transitioning() -> bool:
	return WorldState.scene_transition.is_transitioning


func _record_arrival() -> void:
	var curtain: ColorRect = WorldState.scene_transition.get_node("Fade") as ColorRect
	var player: Player = get_tree().current_scene.get_node("YSortRoot/Player") as Player
	_arrival_alphas.append(curtain.color.a)
	_arrival_locks.append(player.movement_enabled)


func _feet_are_clear(player: Player, at: Vector2) -> bool:
	var shape: RectangleShape2D = RectangleShape2D.new()
	shape.size = Vector2(24,16)
	var query: PhysicsShapeQueryParameters2D = PhysicsShapeQueryParameters2D.new()
	query.shape = shape
	query.transform = Transform2D(0.0,at + Vector2(0,-8))
	query.collision_mask = 1
	return player.get_world_2d().direct_space_state.intersect_shape(query).is_empty()


func _release_actions() -> void:
	for action: StringName in ACTIONS:
		Input.action_release(action)
