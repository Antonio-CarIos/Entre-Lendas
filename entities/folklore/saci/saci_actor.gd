class_name SaciActor
extends CharacterBody2D
## Ator reutilizável de apresentação. Não altera fase, inventário ou controle do Player.

signal visual_unavailable(form: StringName, action: StringName, direction: StringName)
signal action_finished(action: StringName)

@export var visuals: SaciVisuals

var form: StringName = &"hidden"
var action: StringName = &""
var facing_direction: Vector2 = Vector2.DOWN
var body_solid: bool = false

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var _feet: CollisionShape2D = $CollisionShape2D


func _ready() -> void:
	sprite.animation_finished.connect(_on_animation_finished)
	hide_actor()


func show_form(next_form: StringName, facing: Vector2 = Vector2.DOWN) -> bool:
	return _present(next_form, &"idle", facing)


func play_action(next_action: StringName, facing: Vector2 = Vector2.ZERO) -> bool:
	return _present(form, next_action, facing_direction if facing == Vector2.ZERO else facing)


func hide_actor() -> void:
	velocity = Vector2.ZERO
	form = &"hidden"
	action = &""
	sprite.stop()
	sprite.visible = false
	_apply_body_policy()


## Cutscenes mantêm false para mover o ator sem prender a coreografia nos móveis.
func set_body_solid(enabled: bool) -> void:
	body_solid = enabled
	_apply_body_policy()


func _present(next_form: StringName, next_action: StringName, facing: Vector2) -> bool:
	var direction: StringName = direction_name(facing)
	if visuals == null or not visuals.supports(next_form, next_action, direction):
		hide_actor()
		visual_unavailable.emit(next_form, next_action, direction)
		return false
	form = next_form
	action = next_action
	facing_direction = direction_vector(direction)
	sprite.sprite_frames = visuals.get_frames(form)
	# AtlasTexture normaliza apenas transparência; escala da arte permanece 1:1.
	sprite.offset = Vector2(0, -float(visuals.get_canvas(form).y) * 0.5)
	sprite.flip_h = false
	sprite.visible = true
	sprite.play(StringName("%s_%s" % [action, direction]))
	_apply_body_policy()
	return true


func _apply_body_policy() -> void:
	var solid: bool = body_solid and form != &"hidden"
	# World + NPCs, como os animais existentes; Player usa Mask World.
	collision_layer = 5 if solid else 0
	collision_mask = 3 if solid else 0
	_feet.set_deferred(&"disabled", not solid)


func _on_animation_finished() -> void:
	if form != &"hidden":
		action_finished.emit(action)


static func direction_name(facing: Vector2) -> StringName:
	if not facing.is_finite() or facing.is_zero_approx():
		return &"down"
	if absf(facing.x) > absf(facing.y):
		return &"right" if facing.x > 0.0 else &"left"
	return &"down" if facing.y > 0.0 else &"up"


static func direction_vector(direction: StringName) -> Vector2:
	match direction:
		&"up": return Vector2.UP
		&"left": return Vector2.LEFT
		&"right": return Vector2.RIGHT
	return Vector2.DOWN
