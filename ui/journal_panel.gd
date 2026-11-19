class_name JournalPanel
extends Control
## O livro inicial guarda páginas da investigação; E confirma cada trecho da leitura.

signal section_requested()

enum Zone { PAGES, ACTIONS, EXAMINE, READING }

var zone: Zone = Zone.PAGES
var selected_id: StringName = &""
var selected_index: int = 0
var action_index: int = 0
var reading: DialogueSession
var _entries: Array[JournalEntry] = []
var _buttons: Array[Button] = []

@onready var _list: VBoxContainer = $PageScroll/Pages
@onready var _scroll: ScrollContainer = $PageScroll
@onready var _title: Label = $SelectedName
@onready var _origin: Label = $Origin
@onready var _progress: Label = $Progress
@onready var _options: HBoxContainer = $Options
@onready var _info: Panel = $Info
@onready var _info_title: Label = $Info/Title
@onready var _body: RichTextLabel = $Info/Body
@onready var _art: TextureRect = $Info/Illustration
@onready var _hint: Label = $Hint


func _ready() -> void:
	WorldState.stage01.changed.connect(_refresh)
	_refresh()


func open_journal() -> void:
	close_reading()
	zone = Zone.PAGES
	action_index = 0
	_refresh()


func close_reading() -> void:
	if reading != null:
		reading.abort("journal_closed")
	reading = null


func handle_input(event: InputEvent) -> bool:
	if event is InputEventMouse or event.is_echo():
		return true
	if event.is_action_pressed(&"ui_cancel"):
		if zone == Zone.PAGES:
			return false
		close_reading()
		zone = Zone.PAGES if zone == Zone.ACTIONS else Zone.ACTIONS
		_render_selection()
		return true
	var direction: Vector2i = Vector2i.ZERO
	if event.is_action_pressed(&"ui_up"):
		direction = Vector2i.UP
	elif event.is_action_pressed(&"ui_down"):
		direction = Vector2i.DOWN
	elif event.is_action_pressed(&"ui_left"):
		direction = Vector2i.LEFT
	elif event.is_action_pressed(&"ui_right"):
		direction = Vector2i.RIGHT
	if direction != Vector2i.ZERO:
		_navigate(direction)
		return true
	if event.is_action_pressed(&"interact") or event.is_action_pressed(&"ui_accept"):
		_activate()
	return true


func _navigate(direction: Vector2i) -> void:
	if zone == Zone.PAGES and direction == Vector2i.UP and selected_index == 0:
		section_requested.emit()
		return
	if _entries.is_empty():
		return
	match zone:
		Zone.PAGES:
			if direction.y != 0:
				selected_index = clampi(selected_index + direction.y, 0, _entries.size() - 1)
				selected_id = _entries[selected_index].id
				action_index = 0
				_scroll.ensure_control_visible(_buttons[selected_index])
			elif direction.x > 0:
				zone = Zone.ACTIONS
		Zone.ACTIONS:
			if direction.x != 0:
				action_index = posmod(action_index + direction.x, 2)
		Zone.EXAMINE:
			_body.get_v_scroll_bar().value += float(direction.y) * 24.0
	_render_selection()


func _activate() -> void:
	if _entries.is_empty():
		return
	match zone:
		Zone.PAGES:
			zone = Zone.ACTIONS
		Zone.ACTIONS:
			if action_index == 0:
				zone = Zone.EXAMINE
				_art.texture = _entries[selected_index].illustration
				_art.visible = _art.texture != null
				_info_title.text = "Página de Lendas do Brasil"
				_body.text = "Origem: %s.\n\nUma página guardada no livro. Escolha Ler para acompanhar o texto completo.\n\n%s" % [
					_entries[selected_index].origin,
					"Leitura concluída." if WorldState.journal.is_read(selected_id) else "Esta página ainda não foi lida."]
				_body.scroll_to_line(0)
			else:
				_begin_reading()
		Zone.READING:
			if reading != null and reading.active:
				reading.advance()
				_show_page()
			else:
				zone = Zone.ACTIONS
	_render_selection()


func _begin_reading() -> void:
	var catalog: Stage01Narrative = WorldState.journal.make_dialogue(selected_id)
	if catalog == null:
		return
	close_reading()
	reading = DialogueSession.new(DialogueContext.new(WorldState.stage01, WorldState.inventory))
	reading.page_limit = 180
	reading.page_fits = _fits_page
	if reading.start(catalog, _entries[selected_index].dialogue_id):
		zone = Zone.READING
		_show_page()


func _fits_page(text: String) -> bool:
	var font: Font = _body.get_theme_font(&"normal_font")
	var font_size: int = _body.get_theme_font_size(&"normal_font_size")
	var measured: Vector2 = font.get_multiline_string_size(text,
		HORIZONTAL_ALIGNMENT_LEFT, _body.size.x - 16.0, font_size)
	return measured.y <= _body.size.y - 8.0


func _show_page() -> void:
	if reading == null:
		return
	_art.hide()
	_body.text = reading.pages[reading.page_index]
	_body.scroll_to_line(0)
	_info_title.text = "%d/%d • %s" % [reading.page_index + 1, reading.pages.size(),
		"Lida" if not reading.active else "Leitura"]
	# Todo o trecho está visível. Avançar pela última página confirma a conclusão.
	reading.reveal()


func _refresh() -> void:
	_entries = WorldState.journal.get_entries()
	selected_index = clampi(selected_index, 0, maxi(0, _entries.size() - 1))
	for index: int in range(_entries.size()):
		if _entries[index].id == selected_id:
			selected_index = index
	for child: Node in _list.get_children():
		child.free()
	_buttons.clear()
	for entry: JournalEntry in _entries:
		var button: Button = Button.new()
		button.custom_minimum_size = Vector2(172.0, 40.0)
		button.add_theme_font_size_override(&"font_size", 12)
		button.text = ("LIDA • " if WorldState.journal.is_read(entry.id) else "NOVA • ") + entry.title
		button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		button.mouse_filter = Control.MOUSE_FILTER_IGNORE
		button.focus_mode = Control.FOCUS_NONE
		_list.add_child(button)
		_buttons.append(button)
	_progress.text = "%d/7 pistas lidas • %d novas" % [WorldState.stage01.pistas_saci_lidas,
		WorldState.journal.get_new_count()]
	_render_selection()
	if not _buttons.is_empty():
		_ensure_selection_visible.call_deferred()


func _ensure_selection_visible() -> void:
	if is_inside_tree() and selected_index < _buttons.size():
		_scroll.ensure_control_visible(_buttons[selected_index])


func _render_selection() -> void:
	_info.visible = zone in [Zone.EXAMINE, Zone.READING] and not _entries.is_empty()
	_options.visible = not _entries.is_empty()
	if _entries.is_empty():
		close_reading()
		zone = Zone.PAGES
		_title.text = "O livro espera novas histórias"
		_origin.text = "Explore para encontrar páginas."
	else:
		selected_id = _entries[selected_index].id
		_title.text = _entries[selected_index].title
		_origin.text = _entries[selected_index].origin
	for index: int in range(_buttons.size()):
		_buttons[index].add_theme_stylebox_override(&"normal", get_theme_stylebox(
			&"focus" if index == selected_index else &"normal", &"Button"))
	for index: int in range(_options.get_child_count()):
		(_options.get_child(index) as Button).add_theme_stylebox_override(&"normal",
			get_theme_stylebox(&"focus" if action_index == index and zone != Zone.PAGES else &"normal", &"Button"))
	_hint.text = "↑↓: páginas   ↑ no topo: seções   E: opções   J: mochila"
	if zone == Zone.ACTIONS:
		_hint.text = "←→: opções   E/Enter: confirmar   Esc: páginas"
	elif zone == Zone.EXAMINE:
		_hint.text = "↑↓: texto   Esc: opções   Tab: fechar"
	elif zone == Zone.READING:
		_hint.text = "E/Enter: próxima página   Esc: interromper   Tab: fechar" if reading.active \
			else "Leitura concluída   E/Enter/Esc: opções   Tab: fechar"
