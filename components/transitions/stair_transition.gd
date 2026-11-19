class_name StairTransition
extends Area2D
## Dispara apenas quando os pés entram na escada na direção da travessia.

signal transition_requested(player: Player, scene_path: String, spawn_name: StringName)

@export_file("*.tscn") var target_scene: String = ""
@export var target_spawn: StringName = &"PlayerEntrySpawn"
@export var travel_direction: Vector2 = Vector2.UP

var _requested: bool = false


func _ready() -> void:
	body_exited.connect(_on_body_exited)


func _physics_process(_delta: float) -> void:
	if _requested:
		return
	for body: Node2D in get_overlapping_bodies():
		if not body is Player:
			continue
		var player: Player = body as Player
		if player.movement_enabled and player.velocity.dot(travel_direction) > 0.0:
			_requested = true
			transition_requested.emit(player, target_scene, target_spawn)
			return


func _on_body_exited(body: Node2D) -> void:
	if body is Player:
		_requested = false
