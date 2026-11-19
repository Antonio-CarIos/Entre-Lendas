class_name MainMenu
extends Control
## Entrada do jogo. Somente Novo Jogo limpa a sessão; opções não alteram progresso.

signal new_game_started()

enum Page { MAIN, OPTIONS, CREDITS, QUIT, NEW_GAME_CONFIRM }

@export_file("*.tscn") var intro_scene_path: String = "res://stages/stage_01_saci/scene_01_book_intro.tscn"
@export_file("*.cfg") var preferences_path: String = "user://preferences.cfg"
## Ponto de integração do save da Task 2.22; não presume que um save já exista.
@export var new_game_confirmation_required: bool = false

var page: Page = Page.MAIN
var preferences: MenuPreferences = MenuPreferences.new()
var _starting: bool = false

@onready var _main: PanelContainer = $Main
@onready var _buttons: GridContainer = $Main/Margin/Buttons
@onready var _shade: ColorRect = $ModalShade
@onready var _options: PanelContainer = $Options
@onready var _credits: PanelContainer = $Credits
@onready var _confirm: PanelContainer = $Confirm
@onready var _volume: HSlider = $Options/Margin/Scroll/Content/Volume
@onready var _volume_value: Label = $Options/Margin/Scroll/Content/VolumeValue
@onready var _mute: CheckButton = $Options/Margin/Scroll/Content/Mute
@onready var _hint: Label = $Hint
@onready var _new_game: Button = $Main/Margin/Buttons/NewGame
@onready var _options_button: Button = $Main/Margin/Buttons/Options
@onready var _credits_button: Button = $Main/Margin/Buttons/Credits
@onready var _quit_button: Button = $Main/Margin/Buttons/Quit
@onready var _options_back: Button = $Options/Margin/Scroll/Content/Back
@onready var _credits_back: Button = $Credits/Margin/Content/Back
@onready var _confirm_text: Label = $Confirm/Margin/Content/Text
@onready var _confirm_yes: Button = $Confirm/Margin/Content/Choices/Yes
@onready var _confirm_no: Button = $Confirm/Margin/Content/Choices/No
@onready var _music_volume: HSlider = $Options/Margin/Scroll/Content/MusicVolume
@onready var _music_mute: CheckButton = $Options/Margin/Scroll/Content/MusicMute
@onready var _sfx_volume: HSlider = $Options/Margin/Scroll/Content/SFXVolume
@onready var _sfx_mute: CheckButton = $Options/Margin/Scroll/Content/SFXMute
@onready var _text_speed: HSlider = $Options/Margin/Scroll/Content/TextVolume
@onready var _reduced_effects: CheckButton = $Options/Margin/Scroll/Content/ReducedEffects


func _ready() -> void:
	if preferences_path == AudioManager.preferences.file_path:
		preferences = AudioManager.preferences
	preferences.file_path = preferences_path
	preferences.load_preferences()
	_apply_preferences()
	AudioManager.set_scene_context(scene_file_path)
	_volume.set_value_no_signal(preferences.master_volume * 100.0)
	_mute.set_pressed_no_signal(preferences.muted)
	_music_volume.set_value_no_signal(preferences.music_volume * 100.0)
	_music_mute.set_pressed_no_signal(preferences.music_muted)
	_sfx_volume.set_value_no_signal(preferences.sfx_volume * 100.0)
	_sfx_mute.set_pressed_no_signal(preferences.sfx_muted)
	_text_speed.set_value_no_signal(preferences.text_speed)
	_reduced_effects.set_pressed_no_signal(preferences.reduced_effects)
	_update_volume_label()
	_volume.value_changed.connect(_on_volume_changed)
	_mute.toggled.connect(_on_mute_toggled)
	_music_volume.value_changed.connect(_on_channel_changed.bind(&"music"))
	_sfx_volume.value_changed.connect(_on_channel_changed.bind(&"sfx"))
	_music_mute.toggled.connect(_on_channel_mute.bind(&"music"))
	_sfx_mute.toggled.connect(_on_channel_mute.bind(&"sfx"))
	_text_speed.value_changed.connect(_on_text_speed_changed)
	_reduced_effects.toggled.connect(_on_reduced_effects_changed)
	_new_game.pressed.connect(_on_new_game_pressed)
	_options_button.pressed.connect(show_page.bind(Page.OPTIONS))
	_credits_button.pressed.connect(show_page.bind(Page.CREDITS))
	_quit_button.pressed.connect(show_page.bind(Page.QUIT))
	_options_back.pressed.connect(show_page.bind(Page.MAIN))
	_credits_back.pressed.connect(show_page.bind(Page.MAIN))
	_confirm_no.pressed.connect(show_page.bind(Page.MAIN))
	_confirm_yes.pressed.connect(_on_confirmed)
	WorldState.scene_transition.transition_finished.connect(_on_transition_finished)
	resized.connect(_fit_layout)
	_fit_layout()
	show_page(Page.MAIN)


func _input(event: InputEvent) -> void:
	if _starting or WorldState.scene_transition.is_transitioning:
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed(&"ui_cancel") and not event.is_echo():
		show_page(Page.QUIT if page == Page.MAIN else Page.MAIN)
	elif event.is_action_pressed(&"ui_up", true):
		_move_focus(-1)
	elif event.is_action_pressed(&"ui_down", true):
		_move_focus(1)
	elif page == Page.MAIN and event.is_action_pressed(&"ui_left", true):
		_move_focus(-1)
	elif page == Page.MAIN and event.is_action_pressed(&"ui_right", true):
		_move_focus(1)
	elif (event.is_action_pressed(&"interact") or event.is_action_pressed(&"ui_accept")) and not event.is_echo():
		var focused: Control = get_viewport().gui_get_focus_owner()
		if focused is BaseButton:
			var button: BaseButton = focused as BaseButton
			if button.toggle_mode:
				button.button_pressed = not button.button_pressed
			button.pressed.emit()
	else:
		return
	get_viewport().set_input_as_handled()


func show_page(next_page: Page) -> void:
	if _starting:
		return
	var previous: Page = page
	page = next_page
	_main.visible = page == Page.MAIN
	_shade.visible = page != Page.MAIN
	_options.visible = page == Page.OPTIONS
	_credits.visible = page == Page.CREDITS
	_confirm.visible = page in [Page.QUIT, Page.NEW_GAME_CONFIRM]
	_hint.text = "Direcionais: escolher   E/Enter: confirmar   Esc: voltar"
	match page:
		Page.MAIN:
			match previous:
				Page.OPTIONS:
					_options_button.grab_focus()
				Page.CREDITS:
					_credits_button.grab_focus()
				Page.QUIT:
					_quit_button.grab_focus()
				_:
					_new_game.grab_focus()
		Page.OPTIONS:
			_volume.grab_focus()
		Page.CREDITS:
			_credits_back.grab_focus()
		_:
			_confirm_text.text = (
				"Deseja sair de Entre Lendas?" if page == Page.QUIT
				else "Iniciar uma nova partida e substituir o progresso salvo?"
			)
			_confirm_no.grab_focus()
	_fit_layout.call_deferred()
	AudioManager.play_sfx(&"ui_confirm")


func request_new_game(confirmed: bool = false) -> bool:
	if _starting or WorldState.scene_transition.is_transitioning:
		return false
	if new_game_confirmation_required and not confirmed:
		show_page(Page.NEW_GAME_CONFIRM)
		return false
	if not WorldState.scene_transition.open_scene(self, intro_scene_path, true):
		_hint.text = "Não foi possível abrir a introdução. Tente novamente."
		return false
	_starting = true
	new_game_started.emit()
	return true


func _on_new_game_pressed() -> void:
	request_new_game()


func _on_confirmed() -> void:
	if page == Page.QUIT:
		get_tree().quit()
	elif page == Page.NEW_GAME_CONFIRM:
		request_new_game(true)


func _focusable_controls() -> Array[Control]:
	match page:
		Page.OPTIONS:
			return [_volume, _mute, _music_volume, _music_mute, _sfx_volume, _sfx_mute,
				_text_speed, _reduced_effects, _options_back]
		Page.CREDITS:
			return [_credits_back]
		Page.QUIT, Page.NEW_GAME_CONFIRM:
			return [_confirm_no, _confirm_yes]
		_:
			return [_new_game, _options_button, _credits_button, _quit_button]


func _move_focus(direction: int) -> void:
	if page == Page.CREDITS:
		var credits_text: RichTextLabel = $Credits/Margin/Content/Text
		var scroll: VScrollBar = credits_text.get_v_scroll_bar()
		scroll.value += direction * 24.0
		return
	var controls: Array[Control] = _focusable_controls()
	var index: int = controls.find(get_viewport().gui_get_focus_owner())
	controls[posmod(index + direction, controls.size())].grab_focus()
	AudioManager.play_sfx(&"ui_move")


func _on_volume_changed(value: float) -> void:
	preferences.master_volume = value / 100.0
	_save_audio_preferences()
	_update_volume_label()


func _on_mute_toggled(toggled_on: bool) -> void:
	preferences.muted = toggled_on
	_save_audio_preferences()


func _save_audio_preferences() -> void:
	_apply_preferences()
	if preferences.save_preferences() != OK:
		_hint.text = "Opções aplicadas; não foi possível salvar as preferências."


func _apply_preferences() -> void:
	if preferences == AudioManager.preferences:
		AudioManager.refresh_preferences()
	else:
		preferences.apply_audio()


func _on_channel_changed(value: float, channel: StringName) -> void:
	if channel == &"music":
		preferences.music_volume = value / 100.0
	else:
		preferences.sfx_volume = value / 100.0
	_save_audio_preferences()
	_update_volume_label()


func _on_channel_mute(value: bool, channel: StringName) -> void:
	if channel == &"music":
		preferences.music_muted = value
	else:
		preferences.sfx_muted = value
	_save_audio_preferences()


func _on_text_speed_changed(value: float) -> void:
	preferences.text_speed = value
	_save_audio_preferences()
	_update_volume_label()


func _on_reduced_effects_changed(value: bool) -> void:
	preferences.reduced_effects = value
	_save_audio_preferences()


func _update_volume_label() -> void:
	_volume_value.text = "Volume geral: %d%%" % roundi(preferences.master_volume * 100.0)
	($Options/Margin/Scroll/Content/MusicValue as Label).text = "Música: %d%%" % roundi(preferences.music_volume * 100.0)
	($Options/Margin/Scroll/Content/SFXValue as Label).text = "Efeitos sonoros: %d%%" % roundi(preferences.sfx_volume * 100.0)
	($Options/Margin/Scroll/Content/TextValue as Label).text = "Texto: %d caracteres/s" % roundi(preferences.text_speed)


func _on_transition_finished(scene_path: String) -> void:
	if scene_path.is_empty():
		_starting = false
		show_page(Page.MAIN)
		_hint.text = "Não foi possível abrir a introdução. Tente novamente."


func _fit_layout() -> void:
	var compact: bool = size.x < 520.0
	_buttons.columns = 2 if compact else 4
	var menu_size: Vector2 = Vector2(minf(580.0, size.x - 24.0), 96.0 if compact else 56.0)
	_main.position = Vector2((size.x - menu_size.x) / 2.0, size.y - menu_size.y - 28.0)
	_main.size = menu_size
	# Mantém todos os personagens acima dos botões; o backdrop cobre a tela inteira.
	($Cover as TextureRect).offset_bottom = -menu_size.y - 32.0
	# A largura mínima resolve a altura de textos com autowrap antes de medir o painel.
	var text_width: float = minf(420.0, size.x - 24.0) - 24.0
	_confirm_text.custom_minimum_size.x = text_width
	for panel: PanelContainer in [_options, _credits, _confirm]:
		var panel_size: Vector2 = Vector2(minf(420.0, size.x - 24.0), minf(282.0, size.y - 52.0))
		if panel == _confirm:
			panel_size.y = minf(156.0, size.y - 52.0)
		panel_size = panel_size.max(panel.get_combined_minimum_size())
		panel.size = panel_size
		panel.position = (size - panel_size) / 2.0
