extends GutTest
## Verifica inputs reais, animações, colisão e integração na casa existente.

const PLAYER_SCENE: PackedScene = preload("res://entities/player/player.tscn")
const HOUSE_SCENE: PackedScene = preload("res://stages/stage_01_saci/house_interior.tscn")
const MOVE_ACTIONS: Array[StringName] = [
	&"move_up", &"move_down", &"move_left", &"move_right"
]

var _player: Player


func before_each() -> void:
	_release_movement()
	_player = PLAYER_SCENE.instantiate() as Player
	add_child_autofree(_player)
	watch_signals(_player)


func after_each() -> void:
	_release_movement()


func test_initial_state_and_foot_collision() -> void:
	assert_eq(_player.motion_mode, CharacterBody2D.MOTION_MODE_FLOATING)
	assert_eq(_player.collision_layer, 2)
	assert_eq(_player.collision_mask, 1)
	assert_true(_player.y_sort_enabled)
	assert_eq(_player.animated_sprite.animation, &"idle_down")
	assert_eq(_player.animated_sprite.offset, Vector2(0.0, -32.0))
	var collider: CollisionShape2D = _player.get_node("CollisionShape2D")
	var shape: RectangleShape2D = collider.shape as RectangleShape2D
	assert_eq(shape.size, Vector2(24.0, 16.0))
	assert_eq(collider.position, Vector2(0.0, -8.0))
	assert_true(_player.camera.is_current())
	assert_eq(_player.interaction_area.collision_layer, 0)
	assert_eq(_player.interaction_area.collision_mask, 4)


func test_animation_resources_match_real_pngs_in_all_directions() -> void:
	var frames: SpriteFrames = _player.animated_sprite.sprite_frames
	assert_eq(frames.get_animation_names().size(), 8)
	for direction: String in ["down", "up", "left", "right"]:
		for state: String in ["idle", "walk"]:
			var animation: StringName = StringName(state + "_" + direction)
			var count: int = 1 if state == "idle" else 8
			assert_eq(frames.get_frame_count(animation), count)
			assert_eq(frames.get_animation_speed(animation), 8.0)
			assert_true(frames.get_animation_loop(animation))
			for index: int in range(count):
				var texture: AtlasTexture = frames.get_frame_texture(animation, index) as AtlasTexture
				var relative_path: String = "idle/%s.png" % direction
				if state == "walk":
					relative_path = "walk_%s/frame_%03d.png" % [direction, index]
				assert_eq(texture.atlas.resource_path,
					"res://assets/art/characters/player/" + relative_path)
				assert_eq(texture.get_size(), Vector2(32.0, 64.0))
				var source_image: Image = texture.atlas.get_image()
				assert_true(Rect2i(texture.region).encloses(source_image.get_used_rect()),
					"O recorte deve preservar todos os pixels visíveis: " + relative_path)


func test_moving_down_updates_position_animation_and_interaction_area() -> void:
	await _assert_movement(&"move_down", Vector2.DOWN, &"walk_down", Vector2(0.0, 16.0))


func test_moving_up_updates_position_animation_and_interaction_area() -> void:
	await _assert_movement(&"move_up", Vector2.UP, &"walk_up", Vector2(0.0, -32.0))


func test_moving_left_updates_position_animation_and_interaction_area() -> void:
	await _assert_movement(&"move_left", Vector2.LEFT, &"walk_left", Vector2(-24.0, -8.0))


func test_moving_right_updates_position_animation_and_interaction_area() -> void:
	await _assert_movement(&"move_right", Vector2.RIGHT, &"walk_right", Vector2(24.0, -8.0))


func test_releasing_input_stops_and_keeps_last_facing_direction() -> void:
	Input.action_press(&"move_left")
	await wait_physics_frames(3)
	Input.action_release(&"move_left")
	await wait_physics_frames(3)
	var stopped_at: Vector2 = _player.position
	assert_eq(_player.velocity, Vector2.ZERO)
	assert_eq(_player.facing_direction, Vector2.LEFT)
	assert_eq(_player.animated_sprite.animation, &"idle_left")
	assert_eq(_player.interaction_area.position, Vector2(-24.0, -8.0))
	await wait_physics_frames(3)
	assert_eq(_player.position, stopped_at)


func test_diagonal_movement_does_not_increase_speed() -> void:
	Input.action_press(&"move_up")
	Input.action_press(&"move_right")
	await wait_physics_frames(3)
	assert_almost_eq(_player.velocity.length(), _player.move_speed, 0.001)
	assert_gt(_player.velocity.x, 0.0)
	assert_lt(_player.velocity.y, 0.0)
	assert_eq(_player.facing_direction, Vector2.UP)
	assert_eq(_player.animated_sprite.animation, &"walk_up")


func test_opposite_inputs_cancel_movement() -> void:
	Input.action_press(&"move_left")
	Input.action_press(&"move_right")
	await wait_physics_frames(3)
	assert_eq(_player.position, Vector2.ZERO)
	assert_eq(_player.velocity, Vector2.ZERO)
	assert_eq(_player.animated_sprite.animation, &"idle_down")


func test_world_collision_blocks_movement() -> void:
	var wall: StaticBody2D = StaticBody2D.new()
	wall.position = Vector2(48.0, -8.0)
	wall.collision_layer = 1
	wall.collision_mask = 2
	var collider: CollisionShape2D = CollisionShape2D.new()
	var shape: RectangleShape2D = RectangleShape2D.new()
	shape.size = Vector2(16.0, 128.0)
	collider.shape = shape
	wall.add_child(collider)
	add_child_autofree(wall)
	Input.action_press(&"move_right")
	await wait_physics_frames(36)
	assert_gt(_player.position.x, 20.0)
	assert_lte(_player.position.x, 28.0)
	assert_true(_player.is_on_wall())


func test_interaction_detects_only_requested_layer_and_emits_nearest_target() -> void:
	var near_target: Area2D = _add_target(Vector2(0.0, 16.0), 4)
	_add_target(Vector2(0.0, 24.0), 4)
	_add_target(Vector2(0.0, 16.0), 1)
	_add_target(Vector2(0.0, -48.0), 4)
	await wait_physics_frames(3)
	assert_eq(_player.interaction_area.get_overlapping_areas().size(), 2)
	var event: InputEventAction = InputEventAction.new()
	event.action = &"interact"
	event.pressed = true
	_player._unhandled_input(event)
	assert_signal_emitted_with_parameters(_player, &"interaction_requested", [near_target])
	assert_signal_emit_count(_player, &"interaction_requested", 1)


func test_interaction_without_target_does_not_emit() -> void:
	var event: InputEventAction = InputEventAction.new()
	event.action = &"interact"
	event.pressed = true
	_player._unhandled_input(event)
	assert_signal_not_emitted(_player, &"interaction_requested")


func test_house_instances_player_at_existing_entry_spawn_with_active_camera() -> void:
	var house: Node2D = HOUSE_SCENE.instantiate() as Node2D
	add_child_autofree(house)
	var house_player: Player = house.get_node("YSortRoot/Player") as Player
	var spawn: Marker2D = house.get_node("SpawnPoints/PlayerEntrySpawn") as Marker2D
	assert_eq(house_player.global_position, spawn.global_position)
	assert_true(house_player.camera.is_current())
	assert_true(house.get_node("YSortRoot").y_sort_enabled)
	for layer_name: String in ["FloorLayer", "FloorDetailsLayer", "WallsAndStairsLayer"]:
		assert_is(house.get_node(layer_name), TileMapLayer)
	assert_not_null(house.get_node("YSortRoot/State_Organized/Table"))
	assert_not_null(house.get_node("YSortRoot/State_Organized/PlantPot"))
	assert_not_null(house.get_node("YSortRoot/State_Chaotic"))


func _assert_movement(
	action: StringName, direction: Vector2, animation: StringName, detector_position: Vector2
) -> void:
	Input.action_press(action)
	await wait_physics_frames(3)
	assert_gt(_player.position.dot(direction), 0.0)
	assert_eq(_player.velocity, direction * _player.move_speed)
	assert_eq(_player.facing_direction, direction)
	assert_eq(_player.animated_sprite.animation, animation)
	assert_eq(_player.interaction_area.position, detector_position)


func _add_target(at: Vector2, layer: int) -> Area2D:
	var area: Area2D = Area2D.new()
	area.position = at
	area.collision_layer = layer
	area.collision_mask = 0
	var collider: CollisionShape2D = CollisionShape2D.new()
	var shape: RectangleShape2D = RectangleShape2D.new()
	shape.size = Vector2(8.0, 8.0)
	collider.shape = shape
	area.add_child(collider)
	add_child_autofree(area)
	return area


func _release_movement() -> void:
	for action: StringName in MOVE_ACTIONS:
		Input.action_release(action)
