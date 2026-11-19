class_name SceneTransition
extends CanvasLayer
## Serviço persistente de fade, criado pelo WorldState sem um novo Autoload.

signal transition_started(scene_path: String)
signal transition_finished(scene_path: String)

const PLAYER_PATH: NodePath = ^"YSortRoot/Player"

@export_range(0.05, 2.0, 0.01) var fade_duration: float = 0.28

var is_transitioning: bool = false
var _curtain: ColorRect
var _presentation_owner: WeakRef


func _ready() -> void:
	layer = 100
	process_mode = Node.PROCESS_MODE_ALWAYS
	_curtain = ColorRect.new()
	_curtain.name = "Fade"
	_curtain.color = Color(0.0, 0.0, 0.0, 0.0)
	_curtain.mouse_filter = Control.MOUSE_FILTER_STOP
	_curtain.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_curtain)
	_curtain.hide()


func _input(_event: InputEvent) -> void:
	if is_transitioning:
		get_viewport().set_input_as_handled()


func travel_to(source: Node, player: Player, scene_path: String, spawn_name: StringName) -> bool:
	if is_transitioning or has_presentation() or source != get_tree().current_scene:
		return false
	if not is_instance_valid(player) or not player.movement_enabled:
		return false
	if not ResourceLoader.exists(scene_path, "PackedScene"):
		return false
	var destination: PackedScene = load(scene_path) as PackedScene
	if destination == null or not _has_destination(destination, spawn_name):
		return false
	is_transitioning = true
	player.set_movement_enabled(false)
	_curtain.color.a = 0.0
	_curtain.show()
	transition_started.emit(scene_path)
	# A troca nunca ocorre dentro da atualização de consultas da física.
	_travel.call_deferred(player, destination, spawn_name)
	return true


## Entrada entre telas sem Player (menu/livro). O reset só ocorre após validar o destino.
func open_scene(source: Node, scene_path: String, reset_session: bool = false) -> bool:
	if not is_instance_valid(source) or is_transitioning or has_presentation() or source != get_tree().current_scene:
		return false
	if not ResourceLoader.exists(scene_path, "PackedScene"):
		return false
	var destination: PackedScene = load(scene_path) as PackedScene
	if destination == null:
		return false
	var source_player: Player = source.get_node_or_null(PLAYER_PATH) as Player
	var restore_movement: bool = is_instance_valid(source_player) and source_player.movement_enabled
	is_transitioning = true
	_curtain.color.a = 0.0
	_curtain.show()
	transition_started.emit(scene_path)
	_open_scene.call_deferred(weakref(source), destination, reset_session, &"", &"", &"", restore_movement)
	return true


## Entrada de uma tela Control em um mapa, com progresso e spawn aplicados sob preto.
func open_map(source: Node, scene_path: String, spawn_name: StringName,
		next_phase: StringName = &"", completion_event: StringName = &"") -> bool:
	if not can_open_map(source, scene_path, spawn_name, next_phase):
		return false
	var destination: PackedScene = load(scene_path) as PackedScene
	var source_player: Player = source.get_node_or_null(PLAYER_PATH) as Player
	var restore_movement: bool = is_instance_valid(source_player) and source_player.movement_enabled
	is_transitioning = true
	_curtain.color.a = 0.0
	_curtain.show()
	transition_started.emit(scene_path)
	_open_scene.call_deferred(weakref(source), destination, false, spawn_name, next_phase, completion_event, restore_movement)
	return true


## Pré-validação sem fade ou progresso; a execução revalida antes de trocar a cena.
func can_open_map(source: Node, scene_path: String, spawn_name: StringName,
		next_phase: StringName = &"") -> bool:
	if not is_instance_valid(source) or is_transitioning or has_presentation() or source != get_tree().current_scene:
		return false
	if not _can_advance_phase(next_phase) or not ResourceLoader.exists(scene_path, "PackedScene"):
		return false
	var destination: PackedScene = load(scene_path) as PackedScene
	if destination == null or not _has_destination(destination, spawn_name):
		return false
	return true


func _can_advance_phase(next_phase: StringName) -> bool:
	return next_phase == &"" or (WorldState.stage01.active and
		Stage01State.NEXT_PHASES.get(WorldState.stage01.phase, &"") == next_phase)


## Reserva o mesmo fade para uma cutscene, inclusive em telas sem Player.
func has_presentation() -> bool:
	return _presentation_owner != null and is_instance_valid(_presentation_owner.get_ref())


func begin_presentation(owner: Node) -> bool:
	if is_transitioning or has_presentation() or not is_instance_valid(owner):
		return false
	_presentation_owner = weakref(owner)
	return true


func set_presentation_alpha(owner: Node, alpha: float) -> bool:
	if not has_presentation() or _presentation_owner.get_ref() != owner:
		return false
	_curtain.color.a = clampf(alpha, 0.0, 1.0)
	# O HUD deve continuar recebendo teclado para pular/decidir durante a apresentação.
	_curtain.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_curtain.visible = _curtain.color.a > 0.0
	return true


func end_presentation(owner: Node) -> void:
	if not has_presentation() or _presentation_owner.get_ref() != owner:
		return
	_presentation_owner = null
	_curtain.color.a = 0.0
	_curtain.hide()
	_curtain.mouse_filter = Control.MOUSE_FILTER_STOP


func _open_scene(source_ref: WeakRef, destination: PackedScene, reset_session: bool,
		spawn_name: StringName = &"", next_phase: StringName = &"", completion_event: StringName = &"",
		restore_movement: bool = true) -> void:
	var source: Node = source_ref.get_ref() as Node
	if not is_instance_valid(source) or source != get_tree().current_scene:
		_curtain.hide()
		is_transitioning = false
		transition_finished.emit("")
		return
	# Desativa input nas duas cenas durante o fade, inclusive callbacks de GUI.
	var previous_mode: Node.ProcessMode = source.process_mode
	source.process_mode = Node.PROCESS_MODE_DISABLED
	await _fade_to(1.0)
	# Revalidar antes da troca: uma alteração externa durante o fade não pode saltar fases.
	if not is_instance_valid(source) or source != get_tree().current_scene or not _can_advance_phase(next_phase):
		await _restore_source(source_ref.get_ref() as Node, previous_mode, restore_movement)
		return
	var error: Error = get_tree().change_scene_to_packed(destination)
	if error != OK:
		await _restore_source(source, previous_mode, restore_movement)
		return
	if reset_session:
		WorldState.start_new_game()
	if completion_event != &"":
		WorldState.stage01.record_event(completion_event)
	if next_phase != &"":
		WorldState.stage01.advance_to(next_phase)
	await get_tree().scene_changed
	var scene: Node = get_tree().current_scene
	var destination_mode: Node.ProcessMode = scene.process_mode
	scene.process_mode = Node.PROCESS_MODE_DISABLED
	var player: Player
	if spawn_name != &"":
		player = scene.get_node(PLAYER_PATH) as Player
		var marker: Marker2D = scene.get_node(NodePath("SpawnPoints/" + String(spawn_name))) as Marker2D
		player.global_position = marker.global_position
		player.facing_direction = marker.get_meta(&"facing_direction", Vector2.DOWN)
		player.set_movement_enabled(false)
		player.camera.reset_smoothing()
		player.camera.force_update_scroll()
		await get_tree().physics_frame
	await _fade_to(0.0)
	_curtain.hide()
	is_transitioning = false
	scene.process_mode = destination_mode
	if is_instance_valid(player):
		player.set_movement_enabled(true)
	transition_finished.emit(destination.resource_path)


func _restore_source(source: Node, previous_mode: Node.ProcessMode, restore_movement: bool) -> void:
	await _fade_to(0.0)
	if is_instance_valid(source):
		source.process_mode = previous_mode
		var source_player: Player = source.get_node_or_null(PLAYER_PATH) as Player
		if is_instance_valid(source_player):
			source_player.set_movement_enabled(restore_movement)
	_curtain.hide()
	is_transitioning = false
	transition_finished.emit("")


func _has_destination(scene: PackedScene, spawn_name: StringName) -> bool:
	var preview: Node = scene.instantiate()
	var valid: bool = (
		preview.get_node_or_null(PLAYER_PATH) is Player
		and preview.get_node_or_null(NodePath("SpawnPoints/" + String(spawn_name))) is Marker2D
	)
	preview.free()
	return valid


func _travel(old_player: Player, destination: PackedScene, spawn_name: StringName) -> void:
	await _fade_to(1.0)
	var error: Error = get_tree().change_scene_to_packed(destination)
	if error != OK:
		await _fade_to(0.0)
		_curtain.hide()
		is_transitioning = false
		if is_instance_valid(old_player):
			old_player.set_movement_enabled(true)
		transition_finished.emit("")
		return
	await get_tree().scene_changed
	var scene: Node = get_tree().current_scene
	var player: Player = scene.get_node(PLAYER_PATH) as Player
	var marker: Marker2D = scene.get_node(NodePath("SpawnPoints/" + String(spawn_name))) as Marker2D
	player.global_position = marker.global_position
	player.facing_direction = marker.get_meta(&"facing_direction", Vector2.DOWN)
	player.set_movement_enabled(false)
	player.camera.reset_smoothing()
	player.camera.force_update_scroll()
	# A física conhece a posição de chegada antes de revelar a nova cena.
	await get_tree().physics_frame
	await _fade_to(0.0)
	_curtain.hide()
	is_transitioning = false
	player.set_movement_enabled(true)
	transition_finished.emit(destination.resource_path)


func _fade_to(alpha: float) -> void:
	var tween: Tween = create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(_curtain, ^"color:a", alpha, fade_duration)
	await tween.finished
