class_name YardChicken
extends CharacterBody2D
## Passeios curtos ao redor da posição inicial, alternados com alimentação.

signal activity_changed(activity: Activity)

enum Activity { WALKING, EATING }

@export_range(1.0, 64.0, 1.0) var roam_radius: float = 24.0
@export_range(1.0, 32.0, 1.0) var walk_distance: float = 16.0
@export_range(1.0, 80.0, 1.0) var walk_speed: float = 9.0
@export_range(0.05, 10.0, 0.05) var eating_duration: float = 3.2
@export_range(0.0, 10.0, 0.1) var initial_eating_time: float = 0.0
@export var behavior_seed: int = 17

var activity: Activity = Activity.WALKING
var _home_position: Vector2
var _destination: Vector2
var _eating_time_left: float = 0.0
var _facing: Vector2 = Vector2.DOWN
var _random: RandomNumberGenerator = RandomNumberGenerator.new()

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D


func _ready() -> void:
	_home_position = global_position
	_random.seed = behavior_seed
	if initial_eating_time > 0.0:
		_begin_eating(initial_eating_time)
	else:
		_begin_walking()


func _physics_process(delta: float) -> void:
	if activity == Activity.EATING:
		_eating_time_left -= delta
		if _eating_time_left <= 0.0:
			_begin_walking()
		return
	var remaining: Vector2 = _destination - global_position
	if remaining.length() <= 0.5:
		_begin_eating()
		return
	velocity = remaining.normalized() * minf(walk_speed, remaining.length() / delta)
	move_and_slide()
	if get_slide_collision_count() > 0:
		_begin_eating()


func _begin_walking() -> void:
	var direction: Vector2 = Vector2.from_angle(_random.randf_range(0.0, TAU))
	var distance: float = _random.randf_range(walk_distance * 0.5, walk_distance)
	var offset: Vector2 = global_position + direction * distance - _home_position
	_destination = _home_position + offset.limit_length(roam_radius)
	var displacement: Vector2 = _destination - global_position
	_facing = Vector2(signf(displacement.x), 0.0) if absf(displacement.x) > absf(displacement.y) else Vector2(0.0, signf(displacement.y))
	var direction_name: StringName = &"down"
	if _facing == Vector2.UP:
		direction_name = &"up"
	elif _facing == Vector2.LEFT:
		direction_name = &"left"
	elif _facing == Vector2.RIGHT:
		direction_name = &"right"
	sprite.play(StringName("walk_" + String(direction_name)))
	activity = Activity.WALKING
	activity_changed.emit(activity)


func _begin_eating(duration: float = -1.0) -> void:
	velocity = Vector2.ZERO
	sprite.position = Vector2.ZERO
	sprite.play(&"eat_up" if _facing == Vector2.UP else &"eat_down")
	_eating_time_left = duration if duration >= 0.0 else eating_duration * _random.randf_range(0.75, 1.25)
	activity = Activity.EATING
	activity_changed.emit(activity)
