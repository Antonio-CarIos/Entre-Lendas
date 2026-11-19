class_name DialogueSession
extends RefCounted
## Sessão pura: leitura e decisão são passos distintos; efeitos ocorrem ao concluir a fala.

signal started(entry_id: StringName)
signal changed()
signal finished(completed: bool, reason: String)

var active: bool = false
var entry: DialogueEntry
var pages: PackedStringArray = []
var page_index: int = 0
var revealed: bool = false
var context: DialogueContext
var page_limit: int = 190
var page_fits: Callable
var _catalog: Stage01Narrative
var _busy: bool = false


func _init(dialogue_context: DialogueContext) -> void:
	context = dialogue_context


func start(catalog: Stage01Narrative, entry_id: StringName) -> bool:
	if active or catalog == null or not catalog.get_validation_errors().is_empty():
		return false
	_catalog = catalog
	var first: DialogueEntry = catalog.find_entry(entry_id)
	if not _can_enter(first):
		return false
	active = true
	_load_entry(first)
	started.emit(entry_id)
	changed.emit()
	return true


func get_choices() -> Array[DialogueChoiceData]:
	var result: Array[DialogueChoiceData] = []
	if not active or entry == null:
		return result
	for choice: DialogueChoiceData in entry.choices:
		if context.allows(choice.condition_id) and context.allows_all(choice.conditions):
			result.append(choice)
	return result


func is_decision() -> bool:
	return active and page_index == pages.size() - 1 and not entry.choices.is_empty()


func reveal() -> void:
	if active and not revealed:
		revealed = true
		changed.emit()


func advance() -> bool:
	if not active or _busy:
		return false
	if not revealed:
		reveal()
		return true
	if page_index < pages.size() - 1:
		page_index += 1
		revealed = false
		changed.emit()
		return true
	if is_decision():
		return false
	_busy = true
	if not _commit_entry():
		_end(false, "Não foi possível aplicar os efeitos de " + String(entry.id))
	else:
		_follow(entry.next_id)
	_busy = false
	return true


func choose(choice_id: StringName) -> bool:
	if not active or _busy or not revealed or not is_decision():
		return false
	var selected: DialogueChoiceData
	for choice: DialogueChoiceData in get_choices():
		if choice.id == choice_id:
			selected = choice
	if selected == null:
		return false
	# Validar destino antes de conceder itens/alterar flags.
	if selected.next_id != &"" and not _can_enter(_catalog.find_entry(selected.next_id)):
		_end(false, "Resposta indisponível: " + String(selected.next_id))
		return false
	_busy = true
	var key: String = "%s/choice/%s" % [entry.id, selected.id]
	if not _commit_entry() or not _apply_effects(selected.effect_id, selected.effects, key):
		_end(false, "Não foi possível aplicar a resposta " + String(selected.id))
	else:
		# A condição do destino foi autorizada antes da resposta (que pode alterá-la).
		_follow(selected.next_id, true)
	_busy = false
	return true


func cancel() -> bool:
	if not active or _busy or not entry.cancel_allowed:
		return false
	_end(false, "cancelled")
	return true


## Falha externa/saída da cena pode encerrar até uma decisão obrigatória.
func abort(reason: String = "interrupted") -> void:
	if active:
		_end(false, reason)


func _can_enter(next: DialogueEntry) -> bool:
	if next == null or not context.allows(next.condition_id) or not context.allows_all(next.conditions):
		return false
	if not next.cancel_allowed and not next.choices.is_empty():
		for choice: DialogueChoiceData in next.choices:
			if context.allows(choice.condition_id) and context.allows_all(choice.conditions):
				return true
		return false
	return true


func _load_entry(next: DialogueEntry) -> void:
	entry = next
	pages = []
	if entry.pages.is_empty():
		pages = paginate(entry.text, page_limit, page_fits)
	else:
		for page: String in entry.pages:
			pages.append_array(paginate(page, page_limit, page_fits))
	page_index = 0
	revealed = false


func _follow(next_id: StringName, authorized: bool = false) -> void:
	if next_id == &"":
		_end(true, "")
		return
	var next: DialogueEntry = _catalog.find_entry(next_id)
	if next == null or (not authorized and not _can_enter(next)):
		_end(false, "Fala indisponível: " + String(next_id))
		return
	_load_entry(next)
	changed.emit()


func _commit_entry() -> bool:
	if not _apply_effects(&"", entry.effects, String(entry.id)):
		return false
	if entry.event_id != &"" and context.state.active:
		return context.state.has_event(entry.event_id) or context.state.record_event(entry.event_id)
	return true


func _apply_effects(first: StringName, rest: PackedStringArray, key: String) -> bool:
	if not context.apply_once(first, StringName(key + "/primary")):
		return false
	for index: int in range(rest.size()):
		if not context.apply_once(StringName(rest[index]), StringName("%s/%d" % [key, index])):
			return false
	return true


func _end(completed: bool, reason: String) -> void:
	active = false
	finished.emit(completed, reason)


static func paginate(text: String, max_characters: int = 190, fits: Callable = Callable()) -> PackedStringArray:
	var result: PackedStringArray = []
	var remaining: String = text
	max_characters = maxi(max_characters, 1)
	while not remaining.is_empty():
		var boundary: int = mini(remaining.length(), max_characters)
		if boundary < remaining.length():
			var word: int = maxi(remaining.rfind(" ", boundary), remaining.rfind("\n", boundary))
			if word > 0:
				boundary = word
		while fits.is_valid() and not bool(fits.call(remaining.substr(0, boundary))) and boundary > 1:
			var word: int = maxi(remaining.rfind(" ", boundary - 1), remaining.rfind("\n", boundary - 1))
			boundary = word if word > 0 else boundary - 1
		result.append(remaining.substr(0, boundary))
		remaining = remaining.substr(boundary).strip_edges(true, false)
	if result.is_empty():
		result.append("")
	return result
