class_name InventoryPanel
extends Control
## Navegação por teclado entre mochila, opções, leitura e confirmação de receita.

enum FocusZone { ITEMS, ACTIONS, DETAILS, CONFIRM, RESULT }

const BASE_SIZE: Vector2 = Vector2(640.0, 360.0)
const COLUMNS: int = 3
const MINIMUM_SLOTS: int = 9
const ACTION_LABELS: Dictionary[StringName, String] = {
	&"examine": "Examinar", &"read": "Ler", &"combine": "Combinar"
}

var focus_zone: FocusZone = FocusZone.ITEMS
var selected_index: int = 0
var _selected_id: StringName = &""
var _action_index: int = 0
var _confirm_yes: bool = false
var _items: Array[ItemData] = []
var _actions: Array[StringName] = []
var _slot_buttons: Array[Button] = []
var _icons: Array[TextureRect] = []
var _quantities: Array[Label] = []
var _action_buttons: Array[Button] = []
var _layout_positions: Dictionary[Control, Vector2] = {}
var journal_open: bool = false
var _section_focus: bool = false
var _section_index: int = 0

@onready var _slots: GridContainer = $SlotScroll/Slots
@onready var _tabs: HBoxContainer = $Options
@onready var _name: Label = $SelectedName
@onready var _category: Label = $Category
@onready var _count: Label = $Count
@onready var _info: Panel = $Info
@onready var _modal: Panel = $CenterModal
@onready var _modal_shade: ColorRect = $ModalShade
@onready var _modal_text: Label = $CenterModal/Text
@onready var _result_icon: TextureRect = $CenterModal/ResultIcon
@onready var _continue: Button = $CenterModal/Continue
@onready var _info_title: Label = $Info/Title
@onready var _body: RichTextLabel = $Info/Body
@onready var _hint: Label = $Hint
@onready var _confirmation: HBoxContainer = $CenterModal/Confirmation
@onready var _yes: Button = $CenterModal/Confirmation/Yes
@onready var _no: Button = $CenterModal/Confirmation/No
@onready var _journal: JournalPanel = $Journal
@onready var _section_hint: Label = $SectionHint


func _ready() -> void:
	WorldState.inventory.inventory_changed.connect(_refresh_inventory)
	WorldState.stage01.changed.connect(_update_journal_hint)
	_journal.section_requested.connect(_focus_sections)
	_ignore_mouse(self)
	for child: Node in get_children():
		if child is Control and child not in [$Background, _modal_shade, _modal]:
			var control: Control = child as Control
			_layout_positions[control] = control.position
	get_viewport().size_changed.connect(_fit_viewport)
	_fit_viewport()
	_refresh_inventory()
	_update_journal_hint()


func _fit_viewport() -> void:
	# Uma tela opaca independente da câmera, adaptada à viewport sem trocar o mapa.
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var viewport_size: Vector2 = get_viewport_rect().size
	var layout_scale: float = minf(viewport_size.x / BASE_SIZE.x, viewport_size.y / BASE_SIZE.y)
	var origin: Vector2 = (viewport_size - BASE_SIZE * layout_scale) * 0.5
	for control: Control in _layout_positions:
		control.scale = Vector2.ONE * layout_scale
		control.position = origin + _layout_positions[control] * layout_scale
	_modal.scale = Vector2.ONE * layout_scale
	_modal.position = (viewport_size - _modal.size * layout_scale) * 0.5


func open_inventory() -> void:
	_set_journal(false)
	focus_zone = FocusZone.ITEMS
	_action_index = 0
	_info.hide()
	_hide_modal()
	_fit_viewport()
	_refresh_inventory()


func handle_input(event: InputEvent) -> bool:
	if event is InputEventMouse:
		return true
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_J or event.physical_keycode == KEY_J:
			_set_journal(not journal_open)
			return true
	if _section_focus:
		_handle_section_input(event)
		return true
	if journal_open:
		if not _journal.handle_input(event):
			_set_journal(false)
		return true
	if event.is_echo() and (event.is_action_pressed(&"interact") or event.is_action_pressed(&"ui_accept")):
		return true
	if event.is_action_pressed(&"ui_cancel"):
		match focus_zone:
			FocusZone.ITEMS:
				return false
			FocusZone.DETAILS:
				focus_zone = FocusZone.ACTIONS
				_info.hide()
			FocusZone.CONFIRM:
				focus_zone = FocusZone.ACTIONS
				_hide_modal()
			FocusZone.RESULT:
				focus_zone = FocusZone.ITEMS
				_hide_modal()
			_:
				focus_zone = FocusZone.ITEMS
		_update_highlights()
		return true
	var direction: Vector2i = Vector2i.ZERO
	if event.is_action_pressed(&"ui_left", true):
		direction = Vector2i.LEFT
	elif event.is_action_pressed(&"ui_right", true):
		direction = Vector2i.RIGHT
	elif event.is_action_pressed(&"ui_up", true):
		direction = Vector2i.UP
	elif event.is_action_pressed(&"ui_down", true):
		direction = Vector2i.DOWN
	if direction != Vector2i.ZERO:
		_navigate(direction)
		return true
	if event.is_action_pressed(&"interact") or event.is_action_pressed(&"ui_accept"):
		_activate()
		return true
	return false


func close_inventory() -> void:
	_journal.close_reading()


func _set_journal(open: bool) -> void:
	journal_open = open
	_section_focus = false
	focus_zone = FocusZone.ITEMS
	_journal.close_reading()
	for control: Control in _layout_positions:
		if control not in [_journal, _section_hint]:
			control.visible = not open
	_journal.visible = open
	_hide_modal()
	_info.hide()
	if open:
		_journal.open_journal()
	else:
		focus_zone = FocusZone.ITEMS
		_render_selection()
	_update_journal_hint()


func _update_journal_hint() -> void:
	if _section_focus:
		_section_hint.text = "←→: %s   E: abrir   Esc: voltar" % (
			"[Mochila] / Diário" if _section_index == 0 else "Mochila / [Diário]")
	else:
		_section_hint.text = "J: Mochila / Diário (%d novas)   Tab/I: fechar" % WorldState.journal.get_new_count()


func _focus_sections() -> void:
	_section_focus = true
	_section_index = int(journal_open)
	_update_journal_hint()


func _handle_section_input(event: InputEvent) -> void:
	if event.is_echo():
		return
	if event.is_action_pressed(&"ui_left") or event.is_action_pressed(&"ui_right"):
		_section_index = 1 - _section_index
	elif event.is_action_pressed(&"ui_cancel"):
		_section_focus = false
	elif event.is_action_pressed(&"ui_down"):
		_section_focus = false
	elif event.is_action_pressed(&"interact") or event.is_action_pressed(&"ui_accept"):
		_set_journal(_section_index == 1)
	_update_journal_hint()


func _navigate(direction: Vector2i) -> void:
	match focus_zone:
		FocusZone.ITEMS:
			if direction == Vector2i.UP and selected_index < COLUMNS:
				_focus_sections()
				return
			if _items.is_empty():
				return
			var target: int = selected_index
			if direction.x != 0:
				var column: int = selected_index % COLUMNS
				if column + direction.x >= 0 and column + direction.x < COLUMNS:
					target += direction.x
			else:
				target += direction.y * COLUMNS
			if target >= 0 and target < _items.size():
				selected_index = target
				_selected_id = _items[target].id
				_action_index = 0
				_render_selection()
				$SlotScroll.ensure_control_visible(_slot_buttons[target])
		FocusZone.ACTIONS:
			if direction.x != 0 and not _actions.is_empty():
				_action_index = posmod(_action_index + direction.x, _actions.size())
				_info.hide()
		FocusZone.DETAILS:
			var scroll: VScrollBar = _body.get_v_scroll_bar()
			scroll.value += float(direction.y) * 24.0
		FocusZone.CONFIRM:
			if direction.x != 0:
				_confirm_yes = not _confirm_yes
	_update_highlights()


func _activate() -> void:
	if _items.is_empty():
		return
	match focus_zone:
		FocusZone.ITEMS:
			focus_zone = FocusZone.ACTIONS
		FocusZone.ACTIONS:
			if _actions[_action_index] == &"combine":
				_request_combination()
			else:
				focus_zone = FocusZone.DETAILS
				_show_action()
		FocusZone.CONFIRM:
			_confirm_combination()
		FocusZone.RESULT:
			focus_zone = FocusZone.ITEMS
			_hide_modal()
	_update_highlights()


func _refresh_inventory() -> void:
	_items = WorldState.inventory.get_items()
	while _icons.size() < maxi(MINIMUM_SLOTS, _items.size()):
		_add_slot()
	selected_index = clampi(selected_index, 0, maxi(0, _items.size() - 1))
	for index: int in range(_items.size()):
		if _items[index].id == _selected_id:
			selected_index = index
			break
	for index: int in range(_icons.size()):
		_icons[index].texture = null
		_quantities[index].text = ""
		if index < _items.size():
			var item: ItemData = _items[index]
			_icons[index].texture = item.icon
			var quantity: int = WorldState.inventory.get_quantity(item.id)
			if quantity > 1:
				_quantities[index].text = str(quantity)
	_count.text = "%02d" % _items.size()
	_render_selection()


func _render_selection() -> void:
	for button: Button in _action_buttons:
		button.hide()
	_actions.clear()
	if _items.is_empty():
		_name.text = "Mochila vazia"
		_category.text = "A exploração começa lá fora."
		_info_title.text = "Sem objetos"
		_body.text = "Tudo que você recolher ficará guardado aqui."
		_info.hide()
		_hide_modal()
		focus_zone = FocusZone.ITEMS
	else:
		var item: ItemData = _items[selected_index]
		_selected_id = item.id
		_name.text = item.display_name
		_category.text = item.get_category_name()
		_actions = item.get_inventory_actions()
		_action_index = clampi(_action_index, 0, _actions.size() - 1)
		for index: int in range(_actions.size()):
			if index == _action_buttons.size():
				var new_button: Button = Button.new()
				new_button.custom_minimum_size = Vector2(120.0, 28.0)
				new_button.focus_mode = Control.FOCUS_NONE
				new_button.mouse_filter = Control.MOUSE_FILTER_IGNORE
				_tabs.add_child(new_button)
				_action_buttons.append(new_button)
			var action: StringName = _actions[index]
			var button: Button = _action_buttons[index]
			button.text = ACTION_LABELS[action]
			button.disabled = action == &"combine" and not _can_combine()
			button.show()
		if focus_zone == FocusZone.CONFIRM:
			if not _can_combine():
				focus_zone = FocusZone.ACTIONS
				_hide_modal()
		if focus_zone == FocusZone.DETAILS:
			_show_action()
		else:
			_info.hide()
	_update_highlights()


func _show_action() -> void:
	var item: ItemData = _items[selected_index]
	var action: StringName = _actions[_action_index]
	_info_title.text = ACTION_LABELS[action]
	match action:
		&"examine":
			_body.text = item.description
			if not item.insight_text.is_empty():
				_body.text += "\n\n" + item.insight_text
		&"read":
			_body.text = item.lore_text
	_info.show()
	_body.scroll_to_line(0)


func _can_combine() -> bool:
	if _items.is_empty():
		return false
	var item_id: StringName = _items[selected_index].id
	var partner: StringName = &"peneira" if item_id == &"fita_vermelha" else &"fita_vermelha"
	return WorldState.inventory.can_combine(item_id, partner)


func _request_combination() -> void:
	if not _can_combine():
		return
	focus_zone = FocusZone.CONFIRM
	_confirm_yes = false
	_info.hide()
	_modal_text.text = "Deseja combinar fita vermelha com peneira?"
	_result_icon.hide()
	_continue.hide()
	_confirmation.show()
	_modal_shade.show()
	_modal.show()


func _confirm_combination() -> void:
	if not _confirm_yes:
		focus_zone = FocusZone.ACTIONS
		_hide_modal()
		return
	var item_id: StringName = _items[selected_index].id
	var partner: StringName = &"peneira" if item_id == &"fita_vermelha" else &"fita_vermelha"
	if not WorldState.inventory.can_combine(item_id, partner):
		_refresh_inventory()
		return
	focus_zone = FocusZone.RESULT
	_selected_id = &"peneira_cruz"
	if not WorldState.inventory.combine_items(item_id, partner):
		focus_zone = FocusZone.ACTIONS
		_hide_modal()
		return
	_confirmation.hide()
	_modal_text.text = "Você combinou fita vermelha e peneira!\nO resultado é uma peneira com cruz."
	_result_icon.texture = InventorySystem.CROSS_SIEVE.icon
	_result_icon.show()
	_continue.show()
	_modal_shade.show()
	_modal.show()


func _hide_modal() -> void:
	_modal.hide()
	_modal_shade.hide()
	_confirmation.hide()


func _update_highlights() -> void:
	for index: int in range(_slot_buttons.size()):
		var style_name: StringName = &"focus" if index == selected_index and not _items.is_empty() else &"normal"
		_slot_buttons[index].add_theme_stylebox_override(
			&"normal", get_theme_stylebox(style_name, &"InventorySlot")
		)
		_slot_buttons[index].modulate = Color.WHITE if focus_zone == FocusZone.ITEMS else Color(0.8, 0.8, 0.8, 1.0)
	for index: int in range(_action_buttons.size()):
		var active: bool = index == _action_index and focus_zone in [FocusZone.ACTIONS, FocusZone.DETAILS]
		var style_name: StringName = &"focus" if active else &"normal"
		_action_buttons[index].add_theme_stylebox_override(
			&"normal", get_theme_stylebox(style_name, &"Button")
		)
	_yes.add_theme_stylebox_override(&"normal", get_theme_stylebox(&"focus" if _confirm_yes else &"normal", &"Button"))
	_no.add_theme_stylebox_override(&"normal", get_theme_stylebox(&"normal" if _confirm_yes else &"focus", &"Button"))
	match focus_zone:
		FocusZone.ITEMS:
			_hint.text = "Setas: escolher   ↑ no topo: seções   E: opções   Tab: fechar"
		FocusZone.ACTIONS:
			_hint.text = "Esquerda/direita: opções   E/Enter: confirmar   Esc: voltar"
		FocusZone.DETAILS:
			_hint.text = "Cima/baixo: ler texto   Esc: opções   Tab: fechar"
		FocusZone.CONFIRM:
			_hint.text = "Esquerda/direita: escolher   E/Enter: confirmar   Esc: cancelar"
		FocusZone.RESULT:
			_hint.text = "E/Enter: continuar   Tab: fechar"


func _add_slot() -> void:
	var button: Button = Button.new()
	button.name = "Slot%02d" % _icons.size()
	button.custom_minimum_size = Vector2(48.0, 48.0)
	button.theme_type_variation = &"InventorySlot"
	button.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.focus_mode = Control.FOCUS_NONE
	_slots.add_child(button)
	_slot_buttons.append(button)
	var icon: TextureRect = TextureRect.new()
	icon.name = "Icon"
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.position = Vector2(8.0, 8.0)
	icon.size = Vector2(32.0, 32.0)
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(icon)
	_icons.append(icon)
	var quantity: Label = Label.new()
	quantity.name = "Quantity"
	quantity.position = Vector2(28.0, 28.0)
	quantity.size = Vector2(16.0, 16.0)
	quantity.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	quantity.add_theme_font_size_override(&"font_size", 12)
	quantity.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(quantity)
	_quantities.append(quantity)


func _ignore_mouse(node: Node) -> void:
	if node is Control:
		(node as Control).mouse_filter = Control.MOUSE_FILTER_IGNORE
	for child: Node in node.get_children():
		_ignore_mouse(child)
