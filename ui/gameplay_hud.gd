class_name GameplayHUD
extends CanvasLayer
## Interface modal: recebe pedidos do Player e mantém a coleta independente da UI.

signal travel_requested(scene_path: String, spawn_name: StringName)
signal dialogue_finished(completed: bool, reason: String)
signal sequence_skip_requested()

enum ModalMode { NONE, CONFIRM, NOTICE, INVENTORY, DOOR_CONFIRM, STORY, SEQUENCE }

@export var player_path: NodePath

var mode: ModalMode = ModalMode.NONE
var _player: Player
var _pending_item: CollectibleItem
var _pending_door: SceneDoor
var _restore_movement: bool = true
var dialogue_context: DialogueContext
var dialogue_session: DialogueSession
var _sequence_owner: Node

@onready var _shade: ColorRect = $Screen/Shade
@onready var _dialogue: Panel = $Screen/Dialogue
@onready var _text: Label = $Screen/Dialogue/Text
@onready var _yes: Button = $Screen/Dialogue/Yes
@onready var _no: Button = $Screen/Dialogue/No
@onready var _continue: Button = $Screen/Dialogue/Continue
@onready var _inventory_panel: InventoryPanel = $Screen/Inventory
@onready var _story: DialogueView = $Screen/Story


func _ready() -> void:
	dialogue_context = DialogueContext.new(WorldState.stage01, WorldState.inventory)
	WorldState.scene_transition.transition_started.connect(_on_transition_started)
	WorldState.stage01.changed.connect(_refresh_objective)
	_yes.pressed.connect(_confirm_selection)
	_no.pressed.connect(_close_modal)
	_continue.pressed.connect(_close_modal)
	if not player_path.is_empty():
		bind_player(get_node_or_null(player_path) as Player)
	_set_mode(ModalMode.NONE)


func _exit_tree() -> void:
	_inventory_panel.close_inventory()
	if dialogue_session != null:
		if dialogue_session.finished.is_connected(_on_dialogue_finished):
			dialogue_session.finished.disconnect(_on_dialogue_finished)
		dialogue_session.abort("scene_exited")
	if mode != ModalMode.NONE and is_instance_valid(_player):
		_player.set_movement_enabled(_restore_movement)


func _input(event: InputEvent) -> void:
	if WorldState.scene_transition.is_transitioning:
		get_viewport().set_input_as_handled()
		return
	if get_tree().paused:
		return
	if mode == ModalMode.STORY:
		_story.handle_input(event)
		get_viewport().set_input_as_handled()
		return
	if mode == ModalMode.SEQUENCE:
		if not event.is_echo() and (event.is_action_pressed(&"ui_cancel") \
			or event.is_action_pressed(&"interact") or event.is_action_pressed(&"ui_accept")):
			sequence_skip_requested.emit()
		get_viewport().set_input_as_handled()
		return
	if event.is_echo() and mode != ModalMode.INVENTORY:
		return
	if event.is_action_pressed(&"open_inventory"):
		if mode == ModalMode.INVENTORY:
			_close_modal()
		else:
			_pending_item = null
			_pending_door = null
			_set_mode(ModalMode.INVENTORY)
			_inventory_panel.open_inventory()
		get_viewport().set_input_as_handled()
	elif mode == ModalMode.INVENTORY and _inventory_panel.handle_input(event):
		get_viewport().set_input_as_handled()
	elif mode != ModalMode.NONE and event.is_action_pressed(&"ui_cancel"):
		_close_modal()
		get_viewport().set_input_as_handled()
	elif mode != ModalMode.NONE and event.is_action_pressed(&"interact"):
		if mode == ModalMode.NOTICE:
			_close_modal()
		elif mode in [ModalMode.CONFIRM, ModalMode.DOOR_CONFIRM]:
			if _no.has_focus():
				_close_modal()
			else:
				_confirm_selection()
		get_viewport().set_input_as_handled()


func bind_player(player: Player) -> void:
	if is_instance_valid(_player):
		if mode != ModalMode.NONE:
			_player.set_movement_enabled(_restore_movement)
		if _player.interaction_requested.is_connected(_on_interaction_requested):
			_player.interaction_requested.disconnect(_on_interaction_requested)
	_player = player
	if is_instance_valid(_player):
		_player.interaction_requested.connect(_on_interaction_requested)
		if mode != ModalMode.NONE:
			_restore_movement = _player.movement_enabled
			_player.set_movement_enabled(false)


func _on_interaction_requested(target: Area2D) -> void:
	if mode != ModalMode.NONE:
		return
	if target is DialogueInteractable:
		var conversation: DialogueInteractable = target as DialogueInteractable
		if conversation.narrative != null:
			if start_dialogue(conversation.narrative, conversation.entry_id):
				conversation.interacted.emit()
		else:
			show_notice(conversation.get_dialogue_text())
			conversation.interacted.emit()
		return
	if target is SceneDoor:
		_pending_door = target as SceneDoor
		if _pending_door.narrative != null:
			start_dialogue(_pending_door.narrative, _pending_door.entry_id)
			_pending_door = null
			return
		_text.text = _pending_door.question
		_set_mode(ModalMode.DOOR_CONFIRM)
		_yes.grab_focus()
		return
	if not target is CollectibleItem:
		return
	var collectible: CollectibleItem = target as CollectibleItem
	if collectible.collected or collectible.is_queued_for_deletion():
		return
	if collectible.item_data == null:
		return
	_pending_item = collectible
	_text.text = "Deseja pegar %s?" % collectible.item_data.display_name
	_set_mode(ModalMode.CONFIRM)
	_yes.grab_focus()


func _confirm_selection() -> void:
	if mode == ModalMode.DOOR_CONFIRM:
		_confirm_door()
		return
	if mode != ModalMode.CONFIRM:
		return
	if not is_instance_valid(_pending_item) or _pending_item.item_data == null:
		_close_modal()
		return
	var item: ItemData = _pending_item.item_data
	if not _pending_item.collect(WorldState.inventory):
		_close_modal()
		return
	_pending_item = null
	_text.text = (
		"Você coletou %s! Pressione TAB para abrir o inventário."
		% item.display_name
	)
	AudioManager.play_sfx(&"ui_confirm")
	_set_mode(ModalMode.NOTICE)
	_continue.grab_focus()


func request_door_confirmation(door: SceneDoor) -> void:
	if WorldState.scene_transition.is_transitioning:
		return
	if not is_instance_valid(door) or door.is_queued_for_deletion():
		return
	_on_interaction_requested(door)


func _confirm_door() -> void:
	if not is_instance_valid(_pending_door) or _pending_door.is_queued_for_deletion():
		_close_modal()
		return
	var scene_path: String = _pending_door.target_scene
	var spawn_name: StringName = _pending_door.target_spawn
	AudioManager.play_sfx(&"door_open")
	# Restaurar a movimentação permite ao serviço adquirir o bloqueio do fade.
	_close_modal()
	travel_requested.emit(scene_path, spawn_name)


func show_notice(message: String) -> void:
	if mode in [ModalMode.STORY, ModalMode.SEQUENCE] or WorldState.scene_transition.is_transitioning:
		return
	_text.text = message
	_set_mode(ModalMode.NOTICE)
	_continue.grab_focus()


func start_dialogue(catalog: Stage01Narrative, entry_id: StringName, owner: Node = null) -> bool:
	if WorldState.scene_transition.is_transitioning or get_tree().paused:
		return false
	if mode != ModalMode.NONE and not (mode == ModalMode.SEQUENCE and owner == _sequence_owner):
		return false
	var next: DialogueSession = DialogueSession.new(dialogue_context)
	next.page_limit = _story.get_page_limit()
	next.page_fits = _story.can_fit_page
	if not next.start(catalog, entry_id):
		return false
	dialogue_session = next
	dialogue_session.finished.connect(_on_dialogue_finished)
	_set_mode(ModalMode.STORY)
	_story.present(dialogue_session)
	return true


func begin_sequence(owner: Node) -> bool:
	if not is_instance_valid(owner) or mode != ModalMode.NONE or get_tree().paused \
		or WorldState.scene_transition.is_transitioning:
		return false
	_sequence_owner = owner
	_set_mode(ModalMode.SEQUENCE)
	return true


func end_sequence(owner: Node) -> void:
	if owner != _sequence_owner:
		return
	_sequence_owner = null
	if dialogue_session != null and dialogue_session.active:
		dialogue_session.abort("sequence_ended")
	_set_mode(ModalMode.NONE)


func _on_dialogue_finished(completed: bool, reason: String) -> void:
	_set_mode(ModalMode.SEQUENCE if is_instance_valid(_sequence_owner) else ModalMode.NONE)
	dialogue_finished.emit(completed, reason)


func _on_transition_started(_scene_path: String) -> void:
	# Viagem tem prioridade. Nunca reativar o Player que o serviço acabou de bloquear.
	if dialogue_session != null and dialogue_session.active:
		dialogue_session.abort("travel_started")
	if mode != ModalMode.NONE:
		_close_modal()
	if is_instance_valid(_player):
		_player.set_movement_enabled(false)


func _close_modal() -> void:
	_pending_item = null
	_pending_door = null
	_set_mode(ModalMode.NONE)
	var focused: Control = get_viewport().gui_get_focus_owner()
	if focused != null:
		focused.release_focus()


func _set_mode(next_mode: ModalMode) -> void:
	if mode == ModalMode.INVENTORY and next_mode != ModalMode.INVENTORY:
		_inventory_panel.close_inventory()
	if is_instance_valid(_player):
		if mode == ModalMode.NONE and next_mode != ModalMode.NONE:
			_restore_movement = _player.movement_enabled
		if next_mode != ModalMode.NONE:
			_player.set_movement_enabled(false)
		elif mode != ModalMode.NONE:
			_player.set_movement_enabled(_restore_movement)
	mode = next_mode
	_shade.visible = mode in [ModalMode.CONFIRM, ModalMode.NOTICE, ModalMode.DOOR_CONFIRM, ModalMode.STORY]
	_story.visible = mode == ModalMode.STORY
	_dialogue.visible = mode in [ModalMode.CONFIRM, ModalMode.DOOR_CONFIRM, ModalMode.NOTICE]
	_inventory_panel.visible = mode == ModalMode.INVENTORY
	_yes.visible = mode in [ModalMode.CONFIRM, ModalMode.DOOR_CONFIRM]
	_no.visible = mode in [ModalMode.CONFIRM, ModalMode.DOOR_CONFIRM]
	_continue.visible = mode == ModalMode.NOTICE
	_refresh_objective()


func _refresh_objective() -> void:
	var objective: Label = $Screen/Objective
	objective.text = "Objetivo: " + WorldState.stage01.objective
	objective.visible = mode == ModalMode.NONE and WorldState.stage01.active
