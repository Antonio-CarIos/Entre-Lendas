extends GutTest
## Menu real por teclado, reset de sessão, áudio e fade até a cutscene recebida.

const MENU: PackedScene = preload("res://ui/main_menu.tscn")
const PREFS_FILE: String = "user://test_main_menu.cfg"

var _previous_scene: Node
var _previous_volume: float
var _previous_mute: bool
var _previous_fade: float
var _previous_size: Vector2i


func before_each() -> void:
	_previous_scene = get_tree().current_scene
	_previous_volume = AudioServer.get_bus_volume_linear(0)
	_previous_mute = AudioServer.is_bus_mute(0)
	_previous_fade = WorldState.scene_transition.fade_duration
	_previous_size = get_tree().root.size
	WorldState.scene_transition.fade_duration = 0.12
	WorldState.reset()
	if FileAccess.file_exists(PREFS_FILE):
		DirAccess.remove_absolute(PREFS_FILE)
	get_tree().root.size = Vector2i(640, 360)


func after_each() -> void:
	if WorldState.scene_transition.is_transitioning:
		await wait_for_signal(WorldState.scene_transition.transition_finished, 2.0)
	var current: Node = get_tree().current_scene
	if current != _previous_scene:
		get_tree().current_scene = _previous_scene
		if is_instance_valid(current):
			current.queue_free()
		await wait_process_frames(2)
	AudioServer.set_bus_volume_linear(0, _previous_volume)
	AudioServer.set_bus_mute(0, _previous_mute)
	WorldState.scene_transition.fade_duration = _previous_fade
	WorldState.reset()
	get_tree().root.size = _previous_size
	if FileAccess.file_exists(PREFS_FILE):
		DirAccess.remove_absolute(PREFS_FILE)


func test_project_starts_at_menu_with_all_actions_and_original_cover() -> void:
	var menu: MainMenu = _live_menu()
	await wait_process_frames(2)
	assert_eq(ProjectSettings.get_setting("application/run/main_scene"), "res://ui/main_menu.tscn")
	var cover: TextureRect = menu.get_node("Cover") as TextureRect
	assert_eq(cover.texture.resource_path, "res://assets/art/menu/menu_cover.jpeg")
	assert_eq(cover.stretch_mode, TextureRect.STRETCH_KEEP_ASPECT_CENTERED)
	assert_eq(cover.size.x, menu.size.x)
	assert_lte(cover.get_global_rect().end.y, (menu.get_node("Main") as Control).get_global_rect().position.y)
	assert_eq((menu.get_node("Backdrop") as Control).get_global_rect(), menu.get_global_rect())
	assert_true((menu.get_node("Main/Margin/Buttons/NewGame") as Button).has_focus())
	var buttons: GridContainer = menu.get_node("Main/Margin/Buttons") as GridContainer
	assert_eq(buttons.get_child_count(), 4)
	assert_false(menu.has_node("Main/Margin/Buttons/Continue"))
	assert_eq(menu.page, MainMenu.Page.MAIN)


func test_keyboard_navigates_options_adjusts_audio_and_returns_to_same_button() -> void:
	var menu: MainMenu = _live_menu()
	await _tap_key(KEY_RIGHT)
	await _tap_key(KEY_E)
	assert_eq(menu.page, MainMenu.Page.OPTIONS)
	var slider: HSlider = menu.get_node("Options/Margin/Scroll/Content/Volume") as HSlider
	assert_true(slider.has_focus())
	await _tap_key(KEY_LEFT)
	assert_lt(slider.value, 100.0)
	assert_almost_eq(AudioServer.get_bus_volume_linear(0), slider.value / 100.0, 0.001)
	await _tap_key(KEY_DOWN)
	await _tap_key(KEY_ENTER)
	assert_true(AudioServer.is_bus_mute(0))
	for index: int in range(7):
		await _tap_key(KEY_DOWN)
	await _tap_key(KEY_E)
	assert_eq(menu.page, MainMenu.Page.MAIN)
	assert_true((menu.get_node("Main/Margin/Buttons/Options") as Button).has_focus())
	var restored: MenuPreferences = MenuPreferences.new()
	restored.file_path = PREFS_FILE
	restored.load_preferences()
	assert_true(restored.muted)
	assert_almost_eq(restored.master_volume, slider.value / 100.0, 0.001)


func test_credits_and_quit_confirmation_work_without_starting_or_clearing_game() -> void:
	var menu: MainMenu = _live_menu()
	WorldState.inventory.add_item(load("res://core/inventory/items/stage_01/fita_vermelha.tres") as ItemData)
	await _tap_key(KEY_DOWN)
	await _tap_key(KEY_DOWN)
	await _tap_key(KEY_E)
	assert_eq(menu.page, MainMenu.Page.CREDITS)
	var credits: RichTextLabel = menu.get_node("Credits/Margin/Content/Text") as RichTextLabel
	assert_string_contains(credits.text, "Anokolisa")
	assert_string_contains(credits.text, "Introdução do livro")
	await _tap_key(KEY_ESCAPE)
	assert_true((menu.get_node("Main/Margin/Buttons/Credits") as Button).has_focus())
	await _tap_key(KEY_RIGHT)
	await _tap_key(KEY_ENTER)
	assert_eq(menu.page, MainMenu.Page.QUIT)
	assert_true((menu.get_node("Confirm/Margin/Content/Choices/No") as Button).has_focus())
	await _tap_key(KEY_E)
	assert_eq(menu.page, MainMenu.Page.MAIN)
	assert_true(WorldState.inventory.has_item(&"fita_vermelha"))
	assert_false(WorldState.scene_transition.is_transitioning)


func test_new_game_enters_original_intro_once_clears_session_and_blocks_input_during_fade() -> void:
	# Manter a origem viva durante asserções mesmo com import/cache frio no headless.
	WorldState.scene_transition.fade_duration = 0.4
	var menu: MainMenu = _live_menu()
	WorldState.inventory.add_item(load("res://core/inventory/items/stage_01/fita_vermelha.tres") as ItemData)
	WorldState.mark_pickup_collected(&"test_pickup")
	WorldState.register_entity_outcome(&"saci", WorldStateLogic.Outcome.CAPTURE)
	watch_signals(menu)
	watch_signals(WorldState.scene_transition)
	await _tap_key(KEY_E)
	assert_true(WorldState.scene_transition.is_transitioning)
	assert_false(menu.request_new_game())
	assert_signal_emit_count(menu, &"new_game_started", 1)
	assert_signal_emit_count(WorldState.scene_transition, &"transition_started", 1)
	var mouse_press: InputEventMouseButton = InputEventMouseButton.new()
	mouse_press.button_index = MOUSE_BUTTON_LEFT
	mouse_press.pressed = true
	Input.parse_input_event(mouse_press)
	await wait_for_signal(WorldState.scene_transition.transition_finished, 2.0)
	var intro: Control = get_tree().current_scene as Control
	assert_eq(intro.scene_file_path, "res://stages/stage_01_saci/scene_01_book_intro.tscn")
	assert_eq(intro.get("clique_atual"), -1, "Clique do menu/fade não avança a introdução")
	assert_eq(intro.process_mode, Node.PROCESS_MODE_INHERIT)
	assert_true(WorldState.inventory.get_items().is_empty())
	assert_false(WorldState.is_pickup_collected(&"test_pickup"))
	assert_eq(WorldState.nature_balance, 0)
	assert_eq(WorldState.get_entity_outcome(&"saci"), WorldStateLogic.Outcome.UNDECIDED)
	assert_false(WorldState.scene_transition.is_transitioning)


func test_future_save_confirmation_can_be_cancelled_without_resetting_session() -> void:
	var menu: MainMenu = _live_menu()
	menu.new_game_confirmation_required = true
	WorldState.mark_pickup_collected(&"keep_me")
	assert_false(menu.request_new_game())
	assert_eq(menu.page, MainMenu.Page.NEW_GAME_CONFIRM)
	await _tap_key(KEY_ESCAPE)
	assert_eq(menu.page, MainMenu.Page.MAIN)
	assert_true(WorldState.is_pickup_collected(&"keep_me"))
	assert_false(WorldState.scene_transition.is_transitioning)


func test_missing_intro_does_not_clear_progress_or_leave_menu_locked() -> void:
	var menu: MainMenu = _live_menu()
	menu.intro_scene_path = "res://stages/stage_01_saci/nonexistent_intro.tscn"
	WorldState.mark_pickup_collected(&"keep_me")
	assert_false(menu.request_new_game())
	assert_true(WorldState.is_pickup_collected(&"keep_me"))
	assert_false(WorldState.scene_transition.is_transitioning)
	await _tap_key(KEY_RIGHT)
	await _tap_key(KEY_E)
	assert_eq(menu.page, MainMenu.Page.OPTIONS)


func test_menu_layout_stays_inside_landscape_portrait_and_ultrawide_viewports() -> void:
	# SubViewport testa o espaço lógico real; Window.size sofre o stretch do projeto.
	var viewport: SubViewport = SubViewport.new()
	viewport.size = Vector2i(640,360)
	add_child_autofree(viewport)
	var menu: MainMenu = MENU.instantiate() as MainMenu
	menu.preferences_path = PREFS_FILE
	viewport.add_child(menu)
	for viewport_size: Vector2i in [Vector2i(640,360), Vector2i(360,640), Vector2i(960,360), Vector2i(320,240)]:
		viewport.size = viewport_size
		await wait_process_frames(3)
		var bounds: Rect2 = Rect2(Vector2.ZERO, Vector2(viewport_size))
		assert_true(bounds.encloses((menu.get_node("Main") as Control).get_global_rect()), str(viewport_size))
		var last: Rect2 = Rect2()
		for node: Node in menu.get_node("Main/Margin/Buttons").get_children():
			var button: Button = node as Button
			assert_true(bounds.encloses(button.get_global_rect()))
			assert_false(last.intersects(button.get_global_rect()))
			last = button.get_global_rect()
		for page: MainMenu.Page in [MainMenu.Page.OPTIONS, MainMenu.Page.CREDITS, MainMenu.Page.QUIT]:
			menu.show_page(page)
			await wait_process_frames(2)
			var panel_name: String = "Options" if page == MainMenu.Page.OPTIONS else "Credits" if page == MainMenu.Page.CREDITS else "Confirm"
			assert_true(bounds.encloses((menu.get_node(panel_name) as Control).get_global_rect()), panel_name+str(viewport_size))
		menu.show_page(MainMenu.Page.MAIN)


func test_preferences_reject_wrong_types_and_clamp_out_of_range_volume() -> void:
	var config: ConfigFile = ConfigFile.new()
	config.set_value("audio", "master_volume", 5.0)
	config.set_value("audio", "muted", "yes")
	assert_eq(config.save(PREFS_FILE), OK)
	var prefs: MenuPreferences = MenuPreferences.new()
	prefs.file_path = PREFS_FILE
	prefs.load_preferences()
	assert_eq(prefs.master_volume, 1.0)
	assert_false(prefs.muted)
	config.set_value("audio", "master_volume", -2)
	config.save(PREFS_FILE)
	prefs.load_preferences()
	assert_eq(prefs.master_volume, 0.0)


func _live_menu() -> MainMenu:
	var menu: MainMenu = MENU.instantiate() as MainMenu
	menu.preferences_path = PREFS_FILE
	get_tree().root.add_child(menu)
	get_tree().current_scene = menu
	return menu


func _tap_key(key: Key) -> void:
	var press: InputEventKey = InputEventKey.new()
	press.keycode = key
	press.physical_keycode = key
	press.pressed = true
	Input.parse_input_event(press)
	await wait_process_frames(1)
	var release: InputEventKey = InputEventKey.new()
	release.keycode = key
	release.physical_keycode = key
	release.pressed = false
	Input.parse_input_event(release)
	await wait_process_frames(1)
