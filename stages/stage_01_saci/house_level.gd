class_name HouseLevel
extends Node2D
## Coordena portas e escadas dos mapas conectados à casa, com chegada sob o fade.

signal story_state_applied(visual_state: StringName)

@export_node_path("Marker2D") var initial_spawn_path: NodePath
## Habilitar quando as variantes e suas colisões forem preenchidas na Task 2.12.
@export var story_variants_ready: bool = false

var applied_story_state: StringName = &""

@onready var player: Player = $YSortRoot/Player
@onready var _hud: GameplayHUD = $GameplayHUD


func _ready() -> void:
	AudioManager.set_scene_context(scene_file_path)
	if not initial_spawn_path.is_empty():
		var spawn: Marker2D = get_node(initial_spawn_path) as Marker2D
		player.global_position = spawn.global_position
		player.facing_direction = spawn.get_meta(&"facing_direction", Vector2.DOWN)
	_hud.travel_requested.connect(_on_door_travel_requested)
	for node: Node in $Transitions.get_children():
		if node is StairTransition:
			(node as StairTransition).transition_requested.connect(_on_transition_requested)
		elif node is ThresholdDoor:
			(node as ThresholdDoor).confirmation_requested.connect(_on_threshold_confirmation)
	if WorldState.scene_transition.is_transitioning:
		player.set_movement_enabled(false)
	WorldState.stage01.changed.connect(apply_story_state)
	apply_story_state()


func apply_story_state() -> void:
	applied_story_state = WorldState.stage01.get_map_visual_state(StringName(scene_file_path.get_file().get_basename()))
	if applied_story_state == &"":
		return
	_apply_map_visual_state(applied_story_state)
	story_state_applied.emit(applied_story_state)


func _apply_map_visual_state(visual_state: StringName) -> void:
	# Grupos vazios existentes não substituem uma casa pronta: a arte virá em 2.12.
	if not story_variants_ready:
		return
	var chaotic: bool = visual_state == &"house_chaos"
	for variant: String in ["State_Organized", "State_Chaotic"]:
		var group: Node2D = get_node_or_null("YSortRoot/" + variant) as Node2D
		if group != null:
			var enabled: bool = chaotic == (variant == "State_Chaotic")
			group.visible = enabled
			# CollisionObject2D.DISABLE_MODE_REMOVE remove as colisões junto do grupo.
			group.process_mode = Node.PROCESS_MODE_INHERIT if enabled else Node.PROCESS_MODE_DISABLED


func _on_transition_requested(traveler: Player, scene_path: String, spawn_name: StringName) -> void:
	WorldState.scene_transition.travel_to(self, traveler, scene_path, spawn_name)


func _on_door_travel_requested(scene_path: String, spawn_name: StringName) -> void:
	if not WorldState.scene_transition.travel_to(self, player, scene_path, spawn_name):
		_hud.show_notice("Não foi possível atravessar esta porta agora.")


func _on_threshold_confirmation(door: SceneDoor, traveler: Player) -> void:
	if traveler == player:
		_hud.request_door_confirmation(door)
