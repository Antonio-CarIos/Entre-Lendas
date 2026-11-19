extends GutTest
## Introdução real por teclado: leitura, efeitos, skip, falhas e chegada sob fade.

const INTRO: PackedScene = preload("res://stages/stage_01_saci/scene_01_book_intro.tscn")
const MENU: PackedScene = preload("res://ui/main_menu.tscn")
const CITY_PATH: String = "res://stages/stage_01_saci/santa_teresa_map.tscn"
const ART: String = "res://assets/art/ui/stage_01/book_intro/"

var _previous_scene: Node
var _previous_fade: float
var _intro: BookIntro


func before_each() -> void:
	_previous_scene = get_tree().current_scene
	_previous_fade = WorldState.scene_transition.fade_duration
	WorldState.scene_transition.fade_duration = 0.08
	WorldState.reset()
	watch_signals(WorldState.scene_transition)


func after_each() -> void:
	if WorldState.scene_transition.is_transitioning:
		await wait_for_signal(WorldState.scene_transition.transition_finished, 2.0)
	var current: Node = get_tree().current_scene
	get_tree().current_scene = _previous_scene
	if current != _previous_scene and is_instance_valid(current):
		current.queue_free()
	await wait_process_frames(2)
	WorldState.scene_transition.fade_duration = _previous_fade
	WorldState.reset()


func test_original_assets_composition_and_missing_pages_are_audited_without_fake_images() -> void:
	_live_intro()
	assert_eq((_intro.get_node("Fundo") as TextureRect).texture.resource_path, ART + "inicio.jpg")
	assert_eq(_intro.imagens_do_livro.size(), 1)
	assert_eq(_intro.imagens_do_livro[0].resource_path, ART + "livro_aberto.png")
	assert_eq(_intro.livro.material.get("shader").resource_path, ART + "book_transition.gdshader")
	assert_eq((_intro.get_node("Desfoque") as ColorRect).material.get("shader").resource_path,
		ART + "background_blur.gdshader")
	var material: ShaderMaterial = _intro.livro.material as ShaderMaterial
	assert_eq((material.get_shader_parameter(&"noise_tex") as Texture2D).resource_path, ART + "rasgo_1.webp")
	assert_eq(_intro.get_missing_art().size(), 5)
	for path: String in _intro.get_missing_art():
		assert_true(path.ends_with(".png"))
		assert_false(ResourceLoader.exists(path))
	assert_eq(_intro.step, BookIntro.Step.ROOM)
	assert_eq(_intro.clique_atual, -1)
	assert_eq(_intro.livro.modulate.a, 0.0)
	assert_string_contains((_intro.get_node("Interface/Help") as Label).text, "E/Enter")
	assert_eq(_intro.proxima_cena, CITY_PATH)
	assert_eq(_intro.arrival_spawn, &"PlayerEntrySpawn")
	assert_false(_intro.tela_preta.visible)


func test_keyboard_reads_all_book_entries_then_arrives_at_city_with_correct_phase_and_spawn() -> void:
	_live_intro()
	await _key(KEY_E)
	assert_eq(_intro.step, BookIntro.Step.COVER)
	await _settle()
	assert_eq(_intro.livro.modulate.a, 1.0)
	await _key(KEY_ENTER)
	await _settle()
	assert_eq(_intro.step, BookIntro.Step.READING)
	assert_eq(_intro.session.entry.id, &"book.open")
	var reading_session: DialogueSession = _intro.session
	var steps: Array[BookIntro.Step] = []
	_intro.step_changed.connect(func(step: BookIntro.Step) -> void: steps.append(step))
	var seen: Array[StringName] = []
	var guard: int = 0
	while reading_session.active and guard < 50:
		if _intro.session.entry.id not in seen:
			seen.append(_intro.session.entry.id)
		await _settle()
		await _key(KEY_E if guard % 2 == 0 else KEY_ENTER)
		guard += 1
	assert_eq(seen, [&"book.open", &"book.saci", &"book.light"])
	assert_has(steps, BookIntro.Step.DISSOLVING)
	if is_instance_valid(_intro) and _intro.step == BookIntro.Step.DISSOLVING:
		assert_true((_intro.get_node("Letras") as Control).visible)
	assert_true(WorldState.stage01.has_event(&"book_finished"))
	await wait_for_signal(WorldState.scene_transition.transition_finished, 2.0)
	_assert_city()
	assert_signal_emit_count(WorldState.scene_transition, &"transition_started", 1)


func test_provided_pages_play_in_order_without_mutating_exported_array() -> void:
	var pages: Array[Texture2D] = []
	var cover: Texture2D = load(ART + "livro_aberto.png") as Texture2D
	for index: int in range(6):
		pages.append(cover.duplicate() as Texture2D)
	_live_intro(false, pages)
	assert_eq(_intro.get_missing_art().size(), 0)
	await _open_reading()
	assert_true(_intro.session.active)
	assert_eq(_intro.session.entry.id, &"book.open")
	assert_eq(_intro.livro.texture, pages[2])
	assert_eq(_intro.imagens_do_livro, pages)
	assert_eq(pages.size(), 6)
	_intro.session.reveal()
	_intro.avancar_animacao()
	await _settle()
	assert_eq(_intro.session.entry.id, &"book.saci")
	assert_eq(_intro.livro.texture, pages[3])


func test_removing_source_during_departure_cleans_fade_without_committing_story() -> void:
	_live_intro()
	_intro.skip_intro()
	_intro.queue_free()
	await wait_for_signal(WorldState.scene_transition.transition_finished, 2.0)
	assert_false(WorldState.scene_transition.is_transitioning)
	assert_false((WorldState.scene_transition.get_node("Fade") as ColorRect).visible)
	assert_eq(WorldState.stage01.phase, &"book_intro")
	assert_false(WorldState.stage01.has_event(&"book_finished"))


func test_single_press_reveals_text_without_advancing_and_echo_is_ignored() -> void:
	_live_intro()
	await _open_reading()
	assert_false(_intro.session.revealed)
	await _key(KEY_E)
	assert_true(_intro.session.revealed)
	assert_eq(_intro.session.entry.id, &"book.open")
	var echo: InputEventKey = InputEventKey.new()
	echo.keycode = KEY_E
	echo.pressed = true
	echo.echo = true
	Input.parse_input_event(echo)
	await wait_process_frames(1)
	assert_eq(_intro.session.entry.id, &"book.open")
	await _key(KEY_ENTER)
	assert_ne(_intro.session.entry.id, &"book.open")
	assert_false(WorldState.stage01.has_event(&"book_finished"))


func test_rapid_confirmations_cannot_advance_during_page_tween() -> void:
	_live_intro()
	_intro.page_duration = 0.2
	await _key(KEY_E)
	assert_true(_intro.trocando_pagina)
	for index: int in range(4):
		await _key(KEY_ENTER)
	assert_eq(_intro.step, BookIntro.Step.COVER)
	assert_eq(_intro.clique_atual, 0)
	await _settle()
	await _key(KEY_ENTER)
	assert_eq(_intro.step, BookIntro.Step.READING)
	assert_true(_intro.trocando_pagina)
	await _key(KEY_E)
	assert_false(_intro.session.revealed)
	assert_eq(_intro.session.entry.id, &"book.open")


func test_escape_skips_from_room_and_commits_only_required_progress_under_black() -> void:
	_live_intro()
	WorldState.scene_transition.fade_duration = 0.4
	_press(KEY_ESCAPE)
	await wait_process_frames(1)
	assert_true(WorldState.scene_transition.is_transitioning)
	assert_eq(WorldState.stage01.phase, &"book_intro", "Progresso não muda antes de cobrir a tela")
	assert_false(WorldState.stage01.has_event(&"book_finished"))
	var guard: int = 0
	while (get_tree().current_scene == null or get_tree().current_scene.scene_file_path != CITY_PATH) and guard < 180:
		await wait_process_frames(1)
		guard += 1
	assert_eq(WorldState.stage01.phase, &"scene_2_sunset")
	assert_true(WorldState.scene_transition.is_transitioning)
	var player: Player = get_tree().current_scene.get_node("YSortRoot/Player") as Player
	assert_false(player.movement_enabled)
	await wait_for_signal(WorldState.scene_transition.transition_finished, 2.0)
	_assert_city()
	assert_true(WorldState.stage01.has_event(&"book_finished"))
	assert_eq(WorldState.stage01.pistas_saci_lidas, 0)
	assert_true(WorldState.inventory.get_items().is_empty())


func test_escape_during_page_tween_cancels_presentation_and_travels_once() -> void:
	_live_intro()
	WorldState.scene_transition.fade_duration = 0.4
	_intro.page_duration = 0.5
	await _key(KEY_E)
	assert_true(_intro.trocando_pagina)
	_press(KEY_ESCAPE)
	await wait_process_frames(1)
	assert_true(_intro.encerrando)
	_press(KEY_ESCAPE)
	_press(KEY_E)
	_intro.skip_intro()
	assert_signal_emit_count(WorldState.scene_transition, &"transition_started", 1)
	await wait_for_signal(WorldState.scene_transition.transition_finished, 2.0)
	_assert_city()


func test_escape_during_reading_and_dissolution_does_not_duplicate_exit() -> void:
	_live_intro()
	await _open_reading()
	_intro.session.reveal()
	var reading_session: DialogueSession = _intro.session
	var steps: Array[BookIntro.Step] = []
	_intro.step_changed.connect(func(step: BookIntro.Step) -> void: steps.append(step))
	await _key(KEY_ESCAPE)
	assert_false(reading_session.active)
	assert_has(steps, BookIntro.Step.LEAVING)
	if WorldState.scene_transition.is_transitioning:
		await wait_for_signal(WorldState.scene_transition.transition_finished, 2.0)
	_assert_city()
	var city: Node = get_tree().current_scene
	get_tree().current_scene = _previous_scene
	city.queue_free()
	await wait_process_frames(2)
	WorldState.start_new_game()
	_live_intro()
	_intro.dissolve_duration = 1.0
	_intro.escurecer_tela()
	assert_eq(_intro.step, BookIntro.Step.DISSOLVING)
	await _key(KEY_ESCAPE)
	await wait_for_signal(WorldState.scene_transition.transition_finished, 2.0)
	_assert_city()
	assert_signal_emit_count(WorldState.scene_transition, &"transition_started", 2)


func test_missing_optional_art_and_missing_material_do_not_block_reading_or_exit() -> void:
	_live_intro(true)
	assert_eq(_intro.get_missing_art().size(), 5)
	assert_true(_intro.imagens_do_livro.is_empty())
	await _open_reading()
	assert_true(_intro.session.active)
	assert_eq(_intro.session.entry.id, &"book.open")
	assert_false(_intro.livro.visible)
	await _key(KEY_ESCAPE)
	await wait_for_signal(WorldState.scene_transition.transition_finished, 2.0)
	_assert_city()


func test_missing_destination_or_spawn_leaves_intro_usable_without_progress_change() -> void:
	_live_intro()
	_intro.proxima_cena = "res://stages/stage_01_saci/missing_city.tscn"
	await _key(KEY_ESCAPE)
	assert_false(_intro.encerrando)
	assert_false(WorldState.scene_transition.is_transitioning)
	assert_false(_intro.tela_preta.visible)
	assert_eq(WorldState.stage01.phase, &"book_intro")
	assert_false(WorldState.stage01.has_event(&"book_finished"))
	assert_string_contains((_intro.get_node("Interface/Help") as Label).text, "Não foi possível")
	_intro.proxima_cena = CITY_PATH
	_intro.arrival_spawn = &"MissingSpawn"
	await _key(KEY_ESCAPE)
	assert_false(WorldState.scene_transition.is_transitioning)
	assert_eq(WorldState.stage01.phase, &"book_intro")
	_intro.arrival_spawn = &"PlayerEntrySpawn"
	await _key(KEY_ESCAPE)
	await wait_for_signal(WorldState.scene_transition.transition_finished, 2.0)
	_assert_city()


func test_new_game_after_departure_restarts_book_with_fresh_material_and_no_shared_mutation() -> void:
	_live_intro()
	var first_material: ShaderMaterial = _intro.livro.material as ShaderMaterial
	first_material.set_shader_parameter(&"dissolve", 0.7)
	first_material.set_shader_parameter(&"progress", 0.8)
	_intro.skip_intro()
	await wait_for_signal(WorldState.scene_transition.transition_finished, 2.0)
	var city: Node = get_tree().current_scene
	var menu: MainMenu = MENU.instantiate() as MainMenu
	get_tree().root.add_child(menu)
	get_tree().current_scene = menu
	city.queue_free()
	WorldState.inventory.add_item(load("res://core/inventory/items/stage_01/fita_vermelha.tres") as ItemData)
	assert_true(menu.request_new_game())
	await wait_for_signal(WorldState.scene_transition.transition_finished, 2.0)
	var second: BookIntro = get_tree().current_scene as BookIntro
	assert_eq(second.step, BookIntro.Step.ROOM)
	assert_eq(second.clique_atual, -1)
	assert_false(second.trocando_pagina)
	assert_false(second.encerrando)
	assert_eq(second.imagens_do_livro.size(), 1)
	var second_material: ShaderMaterial = second.livro.material as ShaderMaterial
	assert_ne(second_material, first_material)
	assert_eq(float(second_material.get_shader_parameter(&"dissolve")), 0.0)
	assert_eq(float(second_material.get_shader_parameter(&"progress")), 0.0)
	assert_eq(second.livro.modulate.a, 0.0)
	assert_eq(WorldState.stage01.phase, &"book_intro")
	assert_false(WorldState.stage01.has_event(&"book_finished"))
	assert_true(WorldState.inventory.get_items().is_empty())


func test_map_entry_revalidates_story_state_if_it_changes_during_fade() -> void:
	_live_intro()
	_intro.skip_intro()
	assert_true(WorldState.stage01.advance_to(&"scene_2_sunset"))
	await wait_for_signal(WorldState.scene_transition.transition_finished, 2.0)
	assert_eq(get_tree().current_scene, _intro)
	assert_false(_intro.encerrando)
	assert_eq(_intro.process_mode, Node.PROCESS_MODE_INHERIT)
	assert_false((WorldState.scene_transition.get_node("Fade") as ColorRect).visible)
	assert_false(WorldState.stage01.has_event(&"book_finished"))


func test_book_text_and_controls_fit_landscape_portrait_and_small_viewports() -> void:
	var viewport: SubViewport = SubViewport.new()
	viewport.size = Vector2i(640,360)
	add_child_autofree(viewport)
	var intro: BookIntro = INTRO.instantiate() as BookIntro
	intro.page_duration = 0.01
	viewport.add_child(intro)
	intro.avancar_animacao()
	await wait_seconds(0.04)
	intro.avancar_animacao()
	await wait_seconds(0.04)
	for viewport_size: Vector2i in [Vector2i(640,360), Vector2i(360,640), Vector2i(960,360), Vector2i(320,240)]:
		viewport.size = viewport_size
		await wait_process_frames(3)
		var bounds: Rect2 = Rect2(Vector2.ZERO, Vector2(viewport_size))
		assert_true(bounds.encloses(intro.livro.get_global_rect()), str(viewport_size))
		var view: DialogueView = intro.get_node("Interface/Reading") as DialogueView
		assert_true(bounds.encloses(view.get_global_rect()), str(viewport_size))
		assert_true(bounds.encloses((intro.get_node("Interface/Skip") as Control).get_global_rect()))
		assert_true(bounds.encloses((intro.get_node("Interface/Help") as Control).get_global_rect()))
		assert_true(view.get_global_rect().encloses(view.body_label.get_global_rect()))
	viewport.queue_free()
	await wait_process_frames(2)


func _live_intro(without_art: bool = false, pages: Array[Texture2D] = []) -> void:
	_intro = INTRO.instantiate() as BookIntro
	_intro.page_duration = 0.02
	_intro.dissolve_duration = 0.15
	if without_art:
		_intro.art_directory = "res://tests/missing_book_art"
		_intro.imagens_do_livro = []
		(_intro.get_node("Livro") as TextureRect).material = null
	if not pages.is_empty():
		_intro.imagens_do_livro = pages
	get_tree().root.add_child(_intro)
	get_tree().current_scene = _intro


func _open_reading() -> void:
	await _key(KEY_E)
	await _settle()
	await _key(KEY_ENTER)
	await _settle()


func _settle() -> void:
	var deadline: int = Time.get_ticks_msec() + 2000
	while is_instance_valid(_intro) and _intro.trocando_pagina and Time.get_ticks_msec() < deadline:
		await wait_process_frames(1)


func _assert_city() -> void:
	var city: Node = get_tree().current_scene
	assert_eq(city.scene_file_path, CITY_PATH)
	assert_eq(WorldState.stage01.phase, &"scene_2_sunset")
	assert_true(WorldState.stage01.has_event(&"book_finished"))
	var player: Player = city.get_node("YSortRoot/Player") as Player
	var marker: Marker2D = city.get_node("SpawnPoints/PlayerEntrySpawn") as Marker2D
	assert_eq(player.global_position, marker.global_position)
	assert_eq(player.facing_direction, Vector2.UP)
	# Task 2.7: terminou o fade; agora a narração de chegada detém o movimento.
	assert_false(player.movement_enabled)
	var hud: GameplayHUD = city.get_node("GameplayHUD") as GameplayHUD
	assert_eq(hud.mode, GameplayHUD.ModalMode.STORY)
	assert_eq(hud.dialogue_session.entry.id, &"city.arrival")
	assert_true(player.camera.is_current())
	assert_eq(player.get_slide_collision_count(), 0)
	assert_eq((city.get_node("CityModulate") as CanvasModulate).color, Color("ffdfb3"))
	assert_false(WorldState.scene_transition.is_transitioning)
	assert_false((WorldState.scene_transition.get_node("Fade") as ColorRect).visible)


func _key(code: Key) -> void:
	var press: InputEventKey = InputEventKey.new()
	press.keycode = code
	press.physical_keycode = code
	press.pressed = true
	Input.parse_input_event(press)
	await wait_process_frames(1)
	var release: InputEventKey = InputEventKey.new()
	release.keycode = code
	release.physical_keycode = code
	Input.parse_input_event(release)
	await wait_process_frames(1)


func _press(code: Key) -> void:
	var press: InputEventKey = InputEventKey.new()
	press.keycode = code
	press.physical_keycode = code
	press.pressed = true
	Input.parse_input_event(press)
	var release: InputEventKey = InputEventKey.new()
	release.keycode = code
	release.physical_keycode = code
	Input.parse_input_event(release)
