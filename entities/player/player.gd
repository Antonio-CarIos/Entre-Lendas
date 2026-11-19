class_name Player
extends CharacterBody2D
## Movimento top-down; a origem representa o ponto de contato dos pés com o chão.

signal interaction_requested(target: Area2D)

const INTERACTION_ORIGIN: Vector2 = Vector2(0.0, -8.0)

@export_range(1.0, 400.0, 1.0) var move_speed: float = 120.0
@export_range(16.0, 64.0, 1.0) var interaction_distance: float = 24.0

var facing_direction: Vector2 = Vector2.DOWN
var movement_enabled: bool = true

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var interaction_area: Area2D = $InteractionArea
@onready var camera: Camera2D = $Camera2D


func _ready() -> void:
	_update_presentation(Vector2.ZERO)
	camera.make_current()


func _physics_process(_delta: float) -> void:
	if not movement_enabled:
		velocity = Vector2.ZERO
		return
	var direction: Vector2 = Input.get_vector(
		&"move_left", &"move_right", &"move_up", &"move_down"
	)
	velocity = direction * move_speed
	_update_presentation(direction)
	move_and_slide()


func _unhandled_input(event: InputEvent) -> void:
	if not movement_enabled or not event.is_action_pressed(&"interact"):
		return
	var target: Area2D = _nearest_interactable()
	if target != null:
		interaction_requested.emit(target)
		get_viewport().set_input_as_handled()


func set_movement_enabled(enabled: bool) -> void:
	movement_enabled = enabled
	if not enabled:
		velocity = Vector2.ZERO
		_update_presentation(Vector2.ZERO)


func _update_presentation(direction: Vector2) -> void:
	if not direction.is_zero_approx():
		if absf(direction.x) > absf(direction.y):
			facing_direction = Vector2(signf(direction.x), 0.0)
		else:
			facing_direction = Vector2(0.0, signf(direction.y))

	var suffix: String = "down"
	match facing_direction:
		Vector2.UP:
			suffix = "up"
		Vector2.LEFT:
			suffix = "left"
		Vector2.RIGHT:
			suffix = "right"
	var prefix: String = "idle" if direction.is_zero_approx() else "walk"
	animated_sprite.play(StringName(prefix + "_" + suffix))
	interaction_area.position = INTERACTION_ORIGIN + facing_direction * interaction_distance


func _nearest_interactable() -> Area2D:
	var nearest: Area2D = null
	var nearest_distance: float = INF
	for area: Area2D in interaction_area.get_overlapping_areas():
		var distance: float = interaction_area.global_position.distance_squared_to(
			area.global_position
		)
		if distance < nearest_distance:
			nearest = area
			nearest_distance = distance
	return nearest
