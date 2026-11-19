class_name BookIntro
extends Control
## Livro da introdução: composição recebida, leitura por teclado e saída sob fade.

signal step_changed(step: Step)
signal departure_requested()

enum Step { ROOM, COVER, READING, DISSOLVING, LEAVING }

const NARRATIVE: Stage01Narrative = preload("res://core/dialogue/stage_01/stage_01_script.tres")
const PAGE_FILES: PackedStringArray = [
	"livro - abrindo.png", "livro - aberto completo.png", "livro - virando.png",
	"livro - virando 2.png", "livro - desmanche.png"
]

@export var imagens_do_livro: Array[Texture2D] = []
@export_dir var art_directory: String = "res://assets/art/ui/stage_01/book_intro"
@export_file("*.tscn") var proxima_cena: String = "res://stages/stage_01_saci/santa_teresa_map.tscn"
@export var arrival_spawn: StringName = &"PlayerEntrySpawn"
@export_range(0.01, 2.0) var page_duration: float = 0.3
@export_range(0.01, 4.0) var dissolve_duration: float = 1.2

var step: Step = Step.ROOM
# Nome preservado para compatibilidade com a cena e os testes anteriores do menu.
var clique_atual: int = -1
var trocando_pagina: bool = false
var encerrando: bool = false
var session: DialogueSession
var _art: Dictionary[int, Texture2D] = {}
var _missing_art: PackedStringArray = []
var _material: ShaderMaterial
var _tween: Tween
var _last_entry: StringName = &""
var _departure_failed: bool = false
var _opening_book: bool = false

@onready var desfoque: ColorRect = $Desfoque
@onready var livro: TextureRect = $Livro
@onready var tela_preta: ColorRect = $TelaPreta
@onready var _reading: DialogueView = $Interface/Reading
@onready var _title: Label = $Interface/Title
@onready var _help: Label = $Interface/Help
@onready var _letters: BookIntroLetters = $Letras
@onready var _skip_button: Button = $Interface/Skip


func _ready() -> void:
	AudioManager.set_scene_context(scene_file_path)
	_load_art()
	if livro.material is ShaderMaterial:
		_material = livro.material.duplicate() as ShaderMaterial
		livro.material = _material
		_material.set_shader_parameter(&"progress", 0.0)
		_material.set_shader_parameter(&"dissolve", 0.0)
		_material.set_shader_parameter(&"glow", 0.0)
	desfoque.modulate.a = 0.0
	livro.modulate.a = 0.0
	tela_preta.hide()
	_reading.hide()
	_letters.hide()
	_skip_button.pressed.connect(skip_intro)
	WorldState.scene_transition.transition_finished.connect(_on_transition_finished)
	if not WorldState.stage01.active:
		WorldState.stage01.begin()
	session = DialogueSession.new(DialogueContext.new(WorldState.stage01, WorldState.inventory))
	session.changed.connect(_on_page_changed)
	session.finished.connect(_on_reading_finished)
	resized.connect(_layout_book)
	_layout_book()
	_help.text = "E/Enter ou clique: abrir o livro • Esc: pular introdução"


func _exit_tree() -> void:
	if _tween != null and _tween.is_valid():
		_tween.kill()
	if session != null:
		session.finished.disconnect(_on_reading_finished)
		session.abort("scene_exited")


func _input(event: InputEvent) -> void:
	if event.is_echo() or WorldState.scene_transition.is_transitioning or step == Step.LEAVING:
		return
	if event.is_action_pressed(&"ui_cancel"):
		skip_intro()
		get_viewport().set_input_as_handled()
		return
	var clicked: bool = event is InputEventMouseButton and event.pressed \
		and (event as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT
	# Cliques no botão Pular pertencem à GUI, não viram a página por baixo dele.
	if clicked and _skip_button.get_global_rect().has_point((event as InputEventMouseButton).position):
		return
	if event.is_action_pressed(&"interact") or event.is_action_pressed(&"ui_accept") or clicked:
		avancar_animacao()
		get_viewport().set_input_as_handled()


func avancar_animacao() -> void:
	if trocando_pagina or encerrando or WorldState.scene_transition.is_transitioning:
		return
	if _departure_failed:
		_depart()
		return
	match step:
		Step.ROOM:
			clique_atual = 0
			_set_step(Step.COVER)
			_title.text = "Lendas do Brasil"
			_set_texture(_art.get(0))
			trocando_pagina = true
			_tween = create_tween().set_parallel(true)
			_tween.tween_property(desfoque, ^"modulate:a", 1.0, page_duration)
			_tween.tween_property(livro, ^"modulate:a", 1.0, page_duration)
			_tween.chain().tween_callback(_unlock_page)
			_help.text = "E/Enter: ler • Esc: pular introdução"
		Step.COVER:
			_start_reading()
		Step.READING:
			session.advance()


func skip_intro() -> void:
	if encerrando or WorldState.scene_transition.is_transitioning:
		return
	if _tween != null and _tween.is_valid():
		_tween.kill()
	# Pular apresentação não equivale a ler pistas nem concede itens.
	trocando_pagina = false
	_opening_book = false
	if session.active:
		session.abort("skipped")
	_depart()


func get_missing_art() -> PackedStringArray:
	return _missing_art.duplicate()


func _start_reading() -> void:
	_set_step(Step.READING)
	clique_atual = 1
	if _art.has(1) and _material != null:
		_opening_book = true
		virar_pagina(_art[1])
	else:
		_begin_text()


func _begin_text() -> void:
	session.page_limit = _reading.get_page_limit()
	session.page_fits = _reading.can_fit_page
	if not session.start(NARRATIVE, &"book.open"):
		_show_failure("Não foi possível abrir o texto. Esc: seguir para Santa Teresa.")
		return
	_reading.show()
	_reading.present(session)
	_help.text = "E/Enter: revelar ou avançar • Esc: pular introdução"


func _on_page_changed() -> void:
	if not session.active or session.entry.id == _last_entry:
		return
	_last_entry = session.entry.id
	clique_atual = 1 + NARRATIVE.get_scene_entries(&"scene_01").find(session.entry)
	var art_index: int = 2
	if session.entry.id == &"book.saci":
		art_index = 3
	elif session.entry.id == &"book.light":
		art_index = 4
		_title.text = "Saci-Pererê"
		if _material != null and not AudioManager.preferences.reduced_effects:
			_material.set_shader_parameter(&"glow", 0.3)
	virar_pagina(_art.get(art_index, _art.get(0)))


func virar_pagina(proxima_imagem: Texture2D) -> void:
	AudioManager.play_sfx(&"page_turn")
	if proxima_imagem == null:
		return
	trocando_pagina = true
	if _material != null:
		_material.set_shader_parameter(&"next_texture", proxima_imagem)
		_material.set_shader_parameter(&"progress", 0.0)
		_reading.modulate.a = 0.0
		_tween = create_tween().set_parallel(true)
		_tween.tween_property(_material, ^"shader_parameter/progress", 1.0, page_duration)
		_tween.tween_property(_reading, ^"modulate:a", 1.0, page_duration)
		_tween.chain().tween_callback(_finish_page.bind(proxima_imagem))
	else:
		_set_texture(proxima_imagem)
		_unlock_page()


func _finish_page(texture: Texture2D) -> void:
	_set_texture(texture)
	_material.set_shader_parameter(&"progress", 0.0)
	if _opening_book:
		_opening_book = false
		_begin_text()
	else:
		_unlock_page()


func _unlock_page() -> void:
	trocando_pagina = false


func _on_reading_finished(completed: bool, _reason: String) -> void:
	if completed:
		escurecer_tela()


func escurecer_tela() -> void:
	if encerrando or trocando_pagina:
		return
	trocando_pagina = true
	_set_step(Step.DISSOLVING)
	_reading.hide()
	_title.text = "As letras escapam das páginas…"
	_help.text = "Esc: seguir para Santa Teresa"
	_letters.visible = not AudioManager.preferences.reduced_effects
	_letters.progress = 0.0
	if _art.has(5):
		_set_texture(_art[5])
	_tween = create_tween().set_parallel(true)
	_tween.tween_property(_letters, ^"progress", 1.0, dissolve_duration)
	_tween.tween_property(livro, ^"modulate:a", 0.0, dissolve_duration)
	if _material != null and not AudioManager.preferences.reduced_effects:
		_tween.tween_property(_material, ^"shader_parameter/dissolve", 1.0, dissolve_duration)
		_tween.tween_property(_material, ^"shader_parameter/glow", 0.6, dissolve_duration * 0.5)
	_tween.chain().tween_callback(_depart)


func _depart() -> void:
	trocando_pagina = false
	if not WorldState.scene_transition.open_map(self, proxima_cena, arrival_spawn,
			&"scene_2_sunset", &"book_finished"):
		_show_failure("Não foi possível chegar à cidade. E/Enter ou Esc: tentar novamente.")
		return
	encerrando = true
	_departure_failed = false
	trocando_pagina = true
	_set_step(Step.LEAVING)
	_help.text = "Santa Teresa…"
	departure_requested.emit()


func _on_transition_finished(scene_path: String) -> void:
	if scene_path.is_empty() and encerrando:
		_show_failure("A viagem foi interrompida. E/Enter ou Esc: tentar novamente.")


func _show_failure(message: String) -> void:
	encerrando = false
	_departure_failed = true
	trocando_pagina = false
	_set_step(Step.ROOM)
	clique_atual = -1
	_reading.hide()
	_letters.hide()
	tela_preta.hide()
	livro.modulate.a = 1.0
	if _material != null:
		_material.set_shader_parameter(&"dissolve", 0.0)
	_help.text = message


func _set_step(next: Step) -> void:
	step = next
	step_changed.emit(step)


func _set_texture(texture: Texture2D) -> void:
	livro.texture = texture
	livro.visible = texture != null
	if _material != null and texture != null:
		_material.set_shader_parameter(&"next_texture", texture)


func _load_art() -> void:
	# Não alterar o Array exportado: várias instâncias podem compartilhar o Resource.
	for index: int in range(imagens_do_livro.size()):
		if imagens_do_livro[index] != null:
			_art[index] = imagens_do_livro[index]
	if not _art.has(0):
		var cover_path: String = art_directory.path_join("livro_aberto.png")
		if ResourceLoader.exists(cover_path, "Texture2D"):
			_art[0] = load(cover_path) as Texture2D
	for index: int in range(PAGE_FILES.size()):
		var path: String = art_directory.path_join(PAGE_FILES[index])
		if ResourceLoader.exists(path, "Texture2D"):
			if not _art.has(index + 1):
				_art[index + 1] = load(path) as Texture2D
		elif not _art.has(index + 1):
			_missing_art.append(path)


func _layout_book() -> void:
	var width: float = minf(535.2, maxf(120.0, size.x - 32.0))
	var height: float = width * 298.4 / 535.2
	livro.offset_left = -width * 0.5
	livro.offset_right = width * 0.5
	livro.offset_top = -height * 0.5
	livro.offset_bottom = height * 0.5
	_reading.anchor_top = 0.28 if size.x < 480.0 else 0.46
	_title.offset_left = 12.0 if size.x < 480.0 else 112.0
	_title.offset_right = -112.0
