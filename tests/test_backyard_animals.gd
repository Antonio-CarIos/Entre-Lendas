extends GutTest
## Animais do quintal: profundidade, alimentação, passeios locais e obstáculos.

const BACKYARD: PackedScene = preload("res://stages/stage_01_saci/house_backyard.tscn")
const CHICKEN: PackedScene = preload("res://entities/npcs/animals/chicken.tscn")


func test_fences_are_above_ground_and_behind_house_and_tree() -> void:
	var yard: Node2D = BACKYARD.instantiate() as Node2D
	add_child_autofree(yard)
	var tree: Node2D = yard.get_node("YSortRoot/State_Organized/Tree") as Node2D
	assert_eq(tree.position, Vector2(745, 196), "Y-Sort usa a base do tronco")
	assert_eq((tree.get_node("Sprite2D") as Sprite2D).global_position, Vector2(745, 44))
	assert_eq((tree.get_node("Sprite2D2") as Sprite2D).global_position, Vector2(745, 176))
	for node: Node in yard.get_node("YSortRoot/State_Organized").get_children():
		if not ("Fence" in node.name or node.name == &"Gate"):
			continue
		var fence: Node2D = node as Node2D
		for layer_name: String in ["FloorLayer", "FloorDetailsLayer", "GroundEdgesLayer"]:
			assert_lt((yard.get_node(layer_name) as Node2D).z_index, fence.z_index)
		for layer_name: String in ["WallsAndFenceLayer", "RoofLayer"]:
			assert_gt((yard.get_node(layer_name) as Node2D).z_index, fence.z_index)
		assert_gt(tree.z_index, fence.z_index)


func test_horse_eats_in_a_loop_without_moving_and_blocks_player() -> void:
	var yard: Node2D = BACKYARD.instantiate() as Node2D
	add_child_autofree(yard)
	var horse: StaticBody2D = yard.get_node("YSortRoot/Horse") as StaticBody2D
	var sprite: AnimatedSprite2D = horse.get_node("AnimatedSprite2D") as AnimatedSprite2D
	var start_position: Vector2 = horse.global_position
	assert_eq(start_position, Vector2(744, 600))
	assert_eq((yard.get_node("SpawnPoints/HorseSpawn") as Marker2D).global_position, start_position)
	assert_eq(sprite.animation, &"eating")
	assert_true(sprite.is_playing())
	assert_true(sprite.sprite_frames.get_animation_loop(&"eating"))
	assert_eq(sprite.sprite_frames.get_frame_count(&"eating"), 5)
	var frames_seen: Dictionary[int, bool] = {}
	for index: int in range(45):
		await wait_physics_frames(1)
		frames_seen[sprite.frame] = true
	assert_gt(frames_seen.size(), 1, "A animação avança de verdade")
	assert_eq(horse.global_position, start_position)
	var player: Player = yard.get_node("YSortRoot/Player") as Player
	assert_true(player.test_move(Transform2D(0.0, start_position + Vector2(-64, 0)), Vector2(64, 0)))


func test_two_chickens_use_aligned_directional_poses_and_eating_frames() -> void:
	var yard: Node2D = BACKYARD.instantiate() as Node2D
	add_child_autofree(yard)
	assert_eq(yard.find_children("*", "YardChicken", true, false).size(), 2)
	for node_name: String in ["Chicken", "Chicken2"]:
		var chicken: YardChicken = yard.get_node("YSortRoot/" + node_name) as YardChicken
		assert_eq(chicken.motion_mode, CharacterBody2D.MOTION_MODE_FLOATING)
		assert_eq(chicken.roam_radius, 24.0)
		assert_eq(chicken.sprite.offset, Vector2(0, -13))
		for direction: StringName in [&"up", &"down"]:
			var animation: StringName = StringName("eat_" + String(direction))
			assert_true(chicken.sprite.sprite_frames.get_animation_loop(animation))
			assert_eq(chicken.sprite.sprite_frames.get_frame_count(animation), 7)
			for index: int in range(7):
				var texture: AtlasTexture = chicken.sprite.sprite_frames.get_frame_texture(animation, index) as AtlasTexture
				assert_eq(texture.get_size(), Vector2(32, 32))
		for direction: StringName in [&"up", &"down", &"left", &"right"]:
			assert_true(chicken.sprite.sprite_frames.has_animation(StringName("idle_" + String(direction))))
			var animation: StringName = StringName("walk_" + String(direction))
			assert_true(chicken.sprite.sprite_frames.get_animation_loop(animation))
			assert_eq(chicken.sprite.sprite_frames.get_animation_speed(animation), 8.0)
			assert_eq(chicken.sprite.sprite_frames.get_frame_count(animation), 8)
			for index: int in range(8):
				var texture: AtlasTexture = chicken.sprite.sprite_frames.get_frame_texture(animation, index) as AtlasTexture
				assert_eq(texture.get_size(), Vector2(32, 32))
				assert_eq(texture.atlas.resource_path, "res://assets/art/characters/npcs/chicken/%s/frame_%03d.png" % [animation, index])
				assert_true(Rect2i(texture.region).encloses(texture.atlas.get_image().get_used_rect()), "Recorte preserva todos os pixels da caminhada")


func test_chicken_alternates_walking_and_eating_within_its_home_radius() -> void:
	var chicken: YardChicken = CHICKEN.instantiate() as YardChicken
	chicken.walk_speed = 48.0
	chicken.walk_distance = 8.0
	chicken.roam_radius = 12.0
	chicken.eating_duration = 0.08
	add_child_autofree(chicken)
	var home: Vector2 = chicken.global_position
	var maximum_distance: float = 0.0
	var walking_samples: int = 0
	var eating_samples: int = 0
	var resumed_after_eating: bool = false
	var eating_was_stationary: bool = true
	var walking_animation_advanced: bool = false
	var animations_match_activity: bool = true
	var position_before: Vector2 = chicken.global_position
	var previous_activity: YardChicken.Activity = chicken.activity
	for index: int in range(180):
		await wait_physics_frames(1)
		maximum_distance = maxf(maximum_distance, chicken.global_position.distance_to(home))
		if chicken.activity == YardChicken.Activity.EATING:
			eating_samples += 1
			animations_match_activity = animations_match_activity and chicken.sprite.animation in [&"eat_up", &"eat_down"]
			if previous_activity == YardChicken.Activity.EATING:
				eating_was_stationary = eating_was_stationary and chicken.global_position.is_equal_approx(position_before)
		else:
			walking_samples += 1
			animations_match_activity = animations_match_activity and String(chicken.sprite.animation).begins_with("walk_")
			walking_animation_advanced = walking_animation_advanced or chicken.sprite.frame > 0
			resumed_after_eating = resumed_after_eating or eating_samples > 0
		position_before = chicken.global_position
		previous_activity = chicken.activity
	assert_gt(maximum_distance, 2.0, "A galinha sai da posição inicial")
	assert_lte(maximum_distance, chicken.roam_radius + 0.1)
	assert_gt(walking_samples, 0)
	assert_gt(eating_samples, 0)
	assert_true(resumed_after_eating, "O ciclo recomeça após comer")
	assert_true(eating_was_stationary)
	assert_true(animations_match_activity, "Caminhada e alimentação usam suas respectivas animações")
	assert_true(walking_animation_advanced, "Os frames de caminhada avançam durante o passeio")
	assert_eq(chicken.sprite.position, Vector2.ZERO, "O balanço provisório foi removido")


func test_chicken_stops_at_world_obstacles_instead_of_crossing_them() -> void:
	var enclosure: Node2D = Node2D.new()
	add_child_autofree(enclosure)
	var walls: StaticBody2D = StaticBody2D.new()
	enclosure.add_child(walls)
	for direction: Vector2 in [Vector2.LEFT, Vector2.RIGHT, Vector2.UP, Vector2.DOWN]:
		var shape: RectangleShape2D = RectangleShape2D.new()
		shape.size = Vector2(8, 128) if direction.x != 0.0 else Vector2(128, 8)
		var collision: CollisionShape2D = CollisionShape2D.new()
		collision.shape = shape
		collision.position = direction * 20.0
		walls.add_child(collision)
	await wait_physics_frames(2)
	var chicken: YardChicken = CHICKEN.instantiate() as YardChicken
	chicken.walk_speed = 48.0
	chicken.walk_distance = 32.0
	chicken.roam_radius = 64.0
	chicken.eating_duration = 0.08
	enclosure.add_child(chicken)
	var stayed_inside: bool = true
	var stopped_at_wall: bool = false
	for index: int in range(150):
		await wait_physics_frames(1)
		stayed_inside = stayed_inside and Rect2(-10.1, -8.1, 20.2, 24.2).has_point(chicken.position)
		stopped_at_wall = stopped_at_wall or chicken.get_slide_collision_count() > 0
	assert_true(stopped_at_wall, "O passeio encontra a colisão física")
	assert_true(stayed_inside, "A galinha permanece dentro das paredes")
