extends GutTest
## Arte real, alinhamento, disponibilidade explícita e ator isolado do progresso.

const SCENE: PackedScene = preload("res://entities/folklore/saci/saci.tscn")
const VISUALS: SaciVisuals = preload("res://entities/folklore/saci/saci_visuals.tres")
const PREVIEW: PackedScene = preload("res://stages/stage_01_saci/saci_visual_preview.tscn")
const DIRECTIONS: Array[StringName] = [&"down", &"up", &"left", &"right"]


func test_real_files_map_to_all_eight_clips_without_clipping_or_resampling() -> void:
	var sources: Dictionary[String, bool] = {}
	for direction: StringName in DIRECTIONS:
		for action: StringName in [&"idle", &"walk"]:
			assert_true(VISUALS.supports(&"whirlwind", action, direction))
			var name_value: StringName = StringName("%s_%s" % [action,direction])
			var frames: SpriteFrames = VISUALS.whirlwind
			assert_eq(frames.get_frame_count(name_value), 1 if action == &"idle" else 5)
			assert_eq(frames.get_animation_speed(name_value), 8.0)
			assert_true(frames.get_animation_loop(name_value))
			var common_region: Rect2 = Rect2()
			var common_margin: Rect2 = Rect2()
			for index: int in range(frames.get_frame_count(name_value)):
				var frame: AtlasTexture = frames.get_frame_texture(name_value, index) as AtlasTexture
				assert_not_null(frame)
				var relative: String = "idle/%s.png" % direction if action == &"idle" else "walk_%s/frame_%03d.png" % [direction,index]
				assert_eq(frame.atlas.resource_path, "res://assets/art/characters/folklore/saci/" + relative)
				sources[frame.atlas.resource_path] = true
				assert_eq(frame.get_size(), Vector2(64,80))
				var original: Image = frame.atlas.get_image()
				var used: Rect2i = original.get_used_rect()
				assert_true(Rect2(Vector2.ZERO, frame.atlas.get_size()).encloses(frame.region))
				assert_true(Rect2i(frame.region).encloses(used), "Preservar todos os pixels de " + relative)
				var translated: Rect2 = Rect2(used)
				translated.position += frame.margin.position - frame.region.position
				assert_true(Rect2(Vector2.ZERO, frame.get_size()).encloses(translated))
				assert_true(frame.filter_clip)
				if index == 0:
					common_region = frame.region
					common_margin = frame.margin
				else:
					assert_eq(frame.region, common_region, "Recorte comum preserva a oscilação original")
					assert_eq(frame.margin, common_margin)
	assert_eq(sources.size(), 24)
	assert_eq(VISUALS.whirlwind.get_animation_names().size(), 8)


func test_source_audit_matches_native_dimensions_and_keeps_foot_anchor_at_origin() -> void:
	var audit: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://assets/art/characters/folklore/saci/ART_AUDIT.json")) as Dictionary
	assert_eq(audit["canvas"], [64.0,80.0])
	var clips: Array = audit["clips"] as Array
	assert_eq(clips.size(), 8)
	for value: Variant in clips:
		var clip: Dictionary = value as Dictionary
		var region: Array = clip["region"] as Array
		var margin: Array = clip["margin"] as Array
		var bottom: float = float(region[1]) + float(region[3])
		assert_eq(float(margin[1]) + bottom - float(region[1]), 80.0)
		var foot: float = float(clip["median_foot_x"]) - float(region[0]) + float(margin[0])
		assert_almost_eq(foot, 32.0, 0.5)
		for source_value: Variant in clip["frames"]:
			var source: Dictionary = source_value as Dictionary
			var texture: Texture2D = load(String(source["path"])) as Texture2D
			var size: Array = source["size"] as Array
			assert_eq(texture.get_size(), Vector2(float(size[0]),float(size[1])))
			var used: Rect2i = texture.get_image().get_used_rect()
			var source_used: Array = source["used_rect"] as Array
			assert_eq(used, Rect2i(int(source_used[0]),int(source_used[1]),int(source_used[2]),int(source_used[3])))


func test_unavailable_one_leg_and_special_actions_are_never_aliased_to_walking() -> void:
	assert_null(VISUALS.one_leg)
	assert_false(VISUALS.has_directional_action(&"one_leg", &"idle"))
	assert_eq(VISUALS.get_missing_conversation_clips().size(), 5)
	for action: StringName in [&"appear", &"talk", &"spin", &"depart", &"run"]:
		assert_false(VISUALS.supports(&"whirlwind", action, &"down"))
	assert_null(VISUALS.get_frames(&"unknown"))
	assert_eq(VISUALS.get_canvas(&"unknown"), Vector2i.ZERO)
	assert_false(VISUALS.supports(&"whirlwind", &"idle", &"side"))
	assert_true(VISUALS.has_directional_action(&"whirlwind", &"idle"))
	assert_true(VISUALS.has_directional_action(&"whirlwind", &"walk"))


func test_actor_starts_hidden_and_non_solid_with_a_small_foot_collider() -> void:
	var actor: SaciActor = _actor()
	assert_eq(actor.motion_mode, CharacterBody2D.MOTION_MODE_FLOATING)
	assert_true(actor.y_sort_enabled)
	assert_eq(actor.texture_filter, CanvasItem.TEXTURE_FILTER_NEAREST)
	assert_eq(actor.form, &"hidden")
	assert_false(actor.sprite.visible)
	assert_eq(actor.collision_layer, 0)
	assert_eq(actor.collision_mask, 0)
	var feet: CollisionShape2D = actor.get_node("CollisionShape2D") as CollisionShape2D
	assert_eq((feet.shape as RectangleShape2D).size, Vector2(20,12))
	assert_eq(feet.position, Vector2(0,-6))
	assert_true(feet.disabled)
	assert_false(actor.has_node("Camera2D"))


func test_actor_plays_real_directions_and_keeps_scale_and_foot_pivot() -> void:
	var actor: SaciActor = _actor()
	for direction: Vector2 in [Vector2.DOWN,Vector2.UP,Vector2.LEFT,Vector2.RIGHT]:
		assert_true(actor.show_form(&"whirlwind", direction))
		assert_eq(actor.form, &"whirlwind")
		assert_true(actor.sprite.visible)
		assert_eq(actor.sprite.offset, Vector2(0,-40))
		assert_eq(actor.sprite.scale, Vector2.ONE)
		var frame: Texture2D = actor.sprite.sprite_frames.get_frame_texture(actor.sprite.animation, 0)
		assert_eq(frame.get_size().y * 0.5 + actor.sprite.offset.y, 0.0)
		assert_false(actor.sprite.flip_h, "Existem arquivos reais dos dois lados")
		assert_eq(actor.sprite.animation, StringName("idle_" + String(SaciActor.direction_name(direction))))
		assert_true(actor.play_action(&"walk"))
		assert_eq(actor.sprite.animation, StringName("walk_" + String(SaciActor.direction_name(direction))))
	assert_true(actor.play_action(&"idle", Vector2.UP))
	assert_eq(actor.facing_direction, Vector2.UP)


func test_failed_action_hides_actor_and_emits_explicit_missing_art_without_placeholder() -> void:
	var actor: SaciActor = _actor()
	watch_signals(actor)
	assert_true(actor.show_form(&"whirlwind"))
	assert_false(actor.play_action(&"talk"))
	assert_eq(actor.form, &"hidden")
	assert_false(actor.sprite.visible)
	assert_signal_emitted_with_parameters(actor, &"visual_unavailable", [&"whirlwind",&"talk",&"down"])
	assert_false(actor.show_form(&"one_leg"))
	assert_signal_emitted_with_parameters(actor, &"visual_unavailable", [&"one_leg",&"idle",&"down"])
	assert_false(actor.show_form(&"unknown"))
	assert_eq(actor.collision_layer, 0)


func test_body_collision_can_be_disabled_for_choreography_and_hidden_body_never_blocks() -> void:
	var actor: SaciActor = _actor()
	actor.set_body_solid(true)
	assert_eq(actor.collision_layer, 0)
	assert_true(actor.show_form(&"whirlwind"))
	await wait_physics_frames(2)
	assert_eq(actor.collision_layer, 5)
	assert_eq(actor.collision_mask, 3)
	var feet: CollisionShape2D = actor.get_node("CollisionShape2D") as CollisionShape2D
	assert_false(feet.disabled)
	actor.set_body_solid(false)
	await wait_physics_frames(2)
	assert_eq(actor.collision_layer, 0)
	assert_eq(actor.collision_mask, 0)
	assert_true(feet.disabled)
	assert_true(actor.sprite.visible)
	actor.set_body_solid(true)
	actor.velocity = Vector2(100,20)
	actor.hide_actor()
	await wait_physics_frames(2)
	assert_true(feet.disabled)
	assert_eq(actor.velocity, Vector2.ZERO)
	assert_eq(actor.collision_layer, 0)


func test_optional_one_leg_bundle_can_be_bound_without_mutating_shared_visuals() -> void:
	# Textura sintética apenas em memória: valida a extensão, não representa arte final.
	var frames: SpriteFrames = SpriteFrames.new()
	frames.remove_animation(&"default")
	frames.add_animation(&"idle_down")
	var texture: GradientTexture2D = GradientTexture2D.new()
	texture.width = 32
	texture.height = 64
	frames.add_frame(&"idle_down", texture)
	var set: SaciVisuals = SaciVisuals.new()
	set.one_leg = frames
	var actor: SaciActor = _actor()
	actor.visuals = set
	assert_true(actor.show_form(&"one_leg"))
	assert_eq(actor.sprite.offset, Vector2(0,-32))
	assert_eq(texture.get_size().y * 0.5 + actor.sprite.offset.y, 0.0)
	assert_null(VISUALS.one_leg)
	assert_false(actor.play_action(&"talk"))
	assert_false(actor.sprite.visible)


func test_empty_null_wrong_size_and_out_of_bounds_clips_fail_validation() -> void:
	var set: SaciVisuals = SaciVisuals.new()
	var frames: SpriteFrames = SpriteFrames.new()
	frames.remove_animation(&"default")
	frames.add_animation(&"idle_down")
	set.one_leg = frames
	assert_false(set.supports(&"one_leg", &"idle", &"down"))
	frames.add_frame(&"idle_down", null)
	assert_false(set.supports(&"one_leg", &"idle", &"down"))
	var texture: GradientTexture2D = GradientTexture2D.new()
	texture.width = 32
	texture.height = 64
	frames.set_frame(&"idle_down", 0, texture)
	assert_true(set.supports(&"one_leg", &"idle", &"down"))
	texture.width = 64
	assert_false(set.supports(&"one_leg", &"idle", &"down"))
	var atlas: AtlasTexture = AtlasTexture.new()
	atlas.atlas = texture
	atlas.region = Rect2(60,0,32,64)
	frames.set_frame(&"idle_down", 0, atlas)
	assert_false(set.supports(&"one_leg", &"idle", &"down"))
	set.one_leg_canvas = Vector2i.ZERO
	assert_false(set.supports(&"one_leg", &"idle", &"down"))


func test_invalid_and_diagonal_facing_is_normalized_without_unknown_clip_names() -> void:
	assert_eq(SaciActor.direction_name(Vector2.ZERO), &"down")
	assert_eq(SaciActor.direction_name(Vector2(INF,0)), &"down")
	assert_eq(SaciActor.direction_name(Vector2(-2,1)), &"left")
	assert_eq(SaciActor.direction_name(Vector2(1,-2)), &"up")
	assert_eq(SaciActor.direction_name(Vector2(1,1)), &"down")
	assert_eq(SaciActor.direction_vector(&"unknown"), Vector2.DOWN)


func test_preview_uses_all_real_views_keyboard_and_never_starts_story() -> void:
	WorldState.reset()
	var before: Array[StringName] = WorldState.stage01.get_seen_events()
	var preview: Node2D = PREVIEW.instantiate() as Node2D
	add_child_autofree(preview)
	for actor: SaciActor in preview.get_node("YSortRoot").get_children():
		assert_eq(actor.form, &"whirlwind")
		assert_eq(actor.action, &"idle")
		assert_eq(actor.collision_layer, 0)
	var key: InputEventKey = InputEventKey.new()
	key.keycode = KEY_E
	key.physical_keycode = KEY_E
	key.pressed = true
	Input.parse_input_event(key)
	await wait_process_frames(2)
	key = InputEventKey.new()
	key.keycode = KEY_E
	key.physical_keycode = KEY_E
	Input.parse_input_event(key)
	await wait_process_frames(2)
	for actor: SaciActor in preview.get_node("YSortRoot").get_children():
		assert_eq(actor.action, &"walk")
	assert_true((preview.get_node("UI/Screen/Missing") as Label).text.contains("arte ausente"))
	assert_false(WorldState.stage01.active)
	assert_eq(WorldState.stage01.get_seen_events(), before)
	assert_true(WorldState.inventory.get_items().is_empty())


func _actor() -> SaciActor:
	var actor: SaciActor = SCENE.instantiate() as SaciActor
	add_child_autofree(actor)
	return actor
