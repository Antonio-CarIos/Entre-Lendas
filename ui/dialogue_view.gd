class_name DialogueView
extends PanelContainer
## Apresentação por teclado. Um evento revela OU avança OU decide, nunca mais de um.

@export_range(1.0, 200.0) var characters_per_second: float = 45.0
@export var cancel_hint: String = "Esc: voltar"

var session: DialogueSession
var selected_index: int = 0
var _elapsed: float = 0.0
var _page_key: String = ""

@onready var speaker_label: Label = $Margin/Column/Speaker
@onready var body_label: Label = $Margin/Column/Body
@onready var choices_box: VBoxContainer = $Margin/Column/Choices/Options
@onready var hint_label: Label = $Margin/Column/Hint


func _ready() -> void:
	AudioManager.preferences_changed.connect(_apply_accessibility)
	_apply_accessibility()


func _apply_accessibility() -> void:
	characters_per_second = AudioManager.preferences.text_speed


func get_page_limit() -> int:
	# Reservar espaço para escolhas e ajuda antes de paginar, inclusive em 320×240.
	var viewport_size: Vector2 = get_viewport_rect().size
	var width: float = maxf(120.0, viewport_size.x - 88.0)
	var height: float = maxf(16.0, viewport_size.y * 0.88 - 166.0)
	var font: Font = body_label.get_theme_font(&"font")
	var font_size: int = body_label.get_theme_font_size(&"font_size")
	var columns: int = maxi(1, int(width / font.get_string_size("M", HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x))
	var lines: int = maxi(1, int(height / font.get_height(font_size)))
	return clampi(columns * lines, 24, 190)


func can_fit_page(text: String) -> bool:
	var viewport_size: Vector2 = get_viewport_rect().size
	var font: Font = body_label.get_theme_font(&"font")
	var font_size: int = body_label.get_theme_font_size(&"font_size")
	var measured: Vector2 = font.get_multiline_string_size(text, HORIZONTAL_ALIGNMENT_LEFT,
		maxf(120.0, viewport_size.x - 88.0), font_size)
	return measured.y <= maxf(16.0, viewport_size.y * 0.88 - 166.0)


func present(next_session: DialogueSession) -> void:
	if session != null and session.changed.is_connected(_refresh):
		session.changed.disconnect(_refresh)
	session = next_session
	_page_key = ""
	selected_index = 0
	session.changed.connect(_refresh)
	_refresh()


func _process(delta: float) -> void:
	if not visible or session == null or not session.active or session.revealed:
		return
	_elapsed += delta
	body_label.visible_characters = int(_elapsed * characters_per_second)
	if body_label.visible_characters >= body_label.get_total_character_count():
		session.reveal()


func handle_input(event: InputEvent) -> bool:
	if session == null or not session.active:
		return false
	if event.is_echo():
		return true
	if event.is_action_pressed(&"ui_cancel"):
		session.cancel()
	elif event.is_action_pressed(&"interact") or event.is_action_pressed(&"ui_accept"):
		if not session.revealed or not session.is_decision():
			session.advance()
		else:
			var choices: Array[DialogueChoiceData] = session.get_choices()
			if not choices.is_empty():
				session.choose(choices[clampi(selected_index, 0, choices.size() - 1)].id)
	elif session.revealed and session.is_decision():
		var step: int = 0
		if event.is_action_pressed(&"ui_down") or event.is_action_pressed(&"ui_right"):
			step = 1
		elif event.is_action_pressed(&"ui_up") or event.is_action_pressed(&"ui_left"):
			step = -1
		var count: int = choices_box.get_child_count()
		if step != 0 and count > 0:
			selected_index = posmod(selected_index + step, count)
			(choices_box.get_child(selected_index) as Button).grab_focus()
	return true


func _refresh() -> void:
	if session == null or not session.active:
		return
	var key: String = "%s/%d" % [session.entry.id, session.page_index]
	if key != _page_key:
		_page_key = key
		_elapsed = 0.0
		selected_index = 0
		body_label.text = session.pages[session.page_index]
		body_label.visible_characters = 0
	if session.revealed:
		body_label.visible_characters = -1
	speaker_label.text = session.entry.speaker
	for child: Node in choices_box.get_children():
		child.free()
	var show_choices: bool = session.revealed and session.is_decision()
	if show_choices:
		for choice: DialogueChoiceData in session.get_choices():
			var button: Button = Button.new()
			button.text = choice.label
			button.alignment = HORIZONTAL_ALIGNMENT_LEFT
			button.mouse_filter = Control.MOUSE_FILTER_IGNORE
			button.pressed.connect(_choose.bind(choice.id))
			choices_box.add_child(button)
		if choices_box.get_child_count() > 0:
			selected_index = clampi(selected_index, 0, choices_box.get_child_count() - 1)
			(choices_box.get_child(selected_index) as Button).grab_focus()
	$Margin/Column/Choices.visible = show_choices
	var action: String = "E/Enter: escolher • ↑↓: opções" if show_choices else "E/Enter: continuar"
	if not session.revealed:
		action = "E/Enter: revelar texto"
	var back: String = " • " + cancel_hint if session.entry.cancel_allowed else ""
	hint_label.text = "%d/%d • %s%s" % [session.page_index + 1, session.pages.size(), action, back]


func _choose(choice_id: StringName) -> void:
	if session != null:
		session.choose(choice_id)
