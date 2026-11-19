class_name CutsceneCoordinator
extends Node
## Injetar HUD e raiz explicitamente: funciona também em telas Control sem Player.

signal started(sequence_id: StringName)
signal finished(completed: bool, reason: String)

var running: bool = false
var step_index: int = -1
var _sequence: CutsceneSequence
var _hud: GameplayHUD
var _root: Node
var _remaining: float = 0.0
var _waiting_dialogue: bool = false
var _skip_visuals: bool = false
var _tween: Tween
var _sound: AudioStreamPlayer
var _cameras: Dictionary[Camera2D, Vector2] = {}
var _animations: Dictionary[AnimatedSprite2D, Dictionary] = {}
var _animation_players: Dictionary[AnimationPlayer, Dictionary] = {}
var _alpha: float = 0.0


func start(sequence: CutsceneSequence, hud: GameplayHUD, scene_root: Node) -> bool:
	if running or not is_inside_tree() or sequence == null or sequence.id == &"" \
		or not is_instance_valid(hud) or not is_instance_valid(scene_root):
		return false
	if not hud.is_inside_tree() or not scene_root.is_inside_tree():
		return false
	for step: CutsceneStep in sequence.steps:
		if step == null:
			return false
	if not hud.begin_sequence(self):
		return false
	if not WorldState.scene_transition.begin_presentation(self):
		hud.end_sequence(self)
		return false
	_sequence = sequence
	_hud = hud
	_root = scene_root
	_remaining = 0.0
	_waiting_dialogue = false
	_skip_visuals = false
	step_index = -1
	_alpha = 0.0
	running = true
	_hud.dialogue_finished.connect(_on_dialogue_finished)
	_hud.sequence_skip_requested.connect(request_skip)
	_hud.tree_exiting.connect(_on_dependency_exiting)
	if _root != _hud:
		_root.tree_exiting.connect(_on_dependency_exiting)
	started.emit(sequence.id)
	return true


func _process(delta: float) -> void:
	if not running or _waiting_dialogue:
		return
	_remaining -= delta
	if _remaining <= 0.0:
		_next_step()


func request_skip() -> void:
	if not running:
		return
	_skip_visuals = true
	if _waiting_dialogue:
		return
	if step_index >= 0 and not _sequence.steps[step_index].skippable:
		return
	_finish_visual()
	_remaining = 0.0


func cancel() -> void:
	if running:
		_finish(false, "cancelled")


func _exit_tree() -> void:
	if running:
		_finish(false, "scene_exited")


func _next_step() -> void:
	_finish_visual()
	step_index += 1
	if step_index >= _sequence.steps.size():
		_finish(true, "")
		return
	var step: CutsceneStep = _sequence.steps[step_index]
	var visual: bool = step.kind not in [CutsceneStep.Kind.EFFECT, CutsceneStep.Kind.DIALOGUE]
	_remaining = step.duration
	if visual and _skip_visuals and step.skippable:
		# Fade/câmera atingem o resultado final mesmo quando pulados.
		_remaining = 0.0
	if not _execute(step):
		_finish(false, "Etapa inválida: %s/%d" % [_sequence.id, step_index])


func _execute(step: CutsceneStep) -> bool:
	if step.intense_effect and AudioManager.preferences.reduced_effects \
		and step.kind in [CutsceneStep.Kind.ANIMATION, CutsceneStep.Kind.CAMERA, CutsceneStep.Kind.FADE]:
		return true
	match step.kind:
		CutsceneStep.Kind.WAIT:
			return true
		CutsceneStep.Kind.EFFECT:
			_remaining = 0.0
			return _hud.dialogue_context.apply_once(step.effect_id,
				StringName("cutscene/%s/%d" % [_sequence.id, step_index]))
		CutsceneStep.Kind.DIALOGUE:
			_waiting_dialogue = true
			return _hud.start_dialogue(step.narrative, step.entry_id, self)
		CutsceneStep.Kind.FADE:
			if _remaining <= 0.0:
				_set_alpha(step.fade_alpha)
			else:
				_tween = create_tween()
				_tween.tween_method(_set_alpha, _alpha, step.fade_alpha, _remaining)
			return true
		CutsceneStep.Kind.CAMERA:
			var camera: Camera2D = _root.get_node_or_null(step.target_path) as Camera2D
			if camera == null:
				return false
			if not _cameras.has(camera):
				_cameras[camera] = camera.global_position
			if _remaining <= 0.0:
				camera.global_position = step.camera_position
			else:
				_tween = create_tween()
				_tween.tween_property(camera, ^"global_position", step.camera_position, _remaining)
			return true
		CutsceneStep.Kind.SOUND:
			if step.sound == null:
				return false
			if _sound == null:
				_sound = AudioStreamPlayer.new()
				_sound.bus = &"SFX"
				add_child(_sound)
			if _remaining > 0.0:
				_sound.stream = step.sound
				_sound.play()
			return true
		CutsceneStep.Kind.ANIMATION:
			return _play_animation(step)
	return false


func _play_animation(step: CutsceneStep) -> bool:
	var target: Node = _root.get_node_or_null(step.target_path)
	if target is AnimatedSprite2D:
		var sprite: AnimatedSprite2D = target as AnimatedSprite2D
		if sprite.sprite_frames == null or not sprite.sprite_frames.has_animation(step.animation):
			return false
		if not _animations.has(sprite):
			_animations[sprite] = {"name": sprite.animation, "frame": sprite.frame,
				"progress": sprite.frame_progress, "playing": sprite.is_playing()}
		if _remaining > 0.0:
			sprite.play(step.animation)
		return true
	if target is AnimationPlayer:
		var animator: AnimationPlayer = target as AnimationPlayer
		if not animator.has_animation(step.animation):
			return false
		if not _animation_players.has(animator):
			var previous_position: float = animator.current_animation_position if animator.current_animation != "" else 0.0
			_animation_players[animator] = {"name": animator.current_animation,
				"position": previous_position, "playing": animator.is_playing()}
		if _remaining > 0.0:
			animator.play(step.animation)
		return true
	return false


func _on_dialogue_finished(completed: bool, reason: String) -> void:
	if not running or not _waiting_dialogue:
		return
	_waiting_dialogue = false
	_remaining = 0.0
	if not completed:
		_finish(false, reason)


func _on_dependency_exiting() -> void:
	if running:
		_finish(false, "dependency_exited")


func _set_alpha(value: float) -> void:
	_alpha = value
	WorldState.scene_transition.set_presentation_alpha(self, value)


func _finish_visual() -> void:
	if _tween != null and _tween.is_valid():
		# Concluir a interpolação antes de avançar/pular; kill sozinho deixaria o fade parcial.
		_tween.custom_step(10000.0)
		_tween.kill()
	_tween = null
	if is_instance_valid(_sound):
		_sound.stop()


func _finish(completed: bool, reason: String) -> void:
	if not running:
		return
	running = false
	_waiting_dialogue = false
	_finish_visual()
	for camera: Camera2D in _cameras:
		if is_instance_valid(camera):
			camera.global_position = _cameras[camera]
			camera.reset_smoothing()
	_cameras.clear()
	for sprite: AnimatedSprite2D in _animations:
		if is_instance_valid(sprite):
			var previous: Dictionary = _animations[sprite]
			sprite.play(previous["name"])
			sprite.set_frame_and_progress(previous["frame"], previous["progress"])
			if not previous["playing"]:
				sprite.pause()
	_animations.clear()
	for animator: AnimationPlayer in _animation_players:
		if is_instance_valid(animator):
			var previous: Dictionary = _animation_players[animator]
			if previous["name"] != "":
				animator.play(previous["name"])
				animator.seek(previous["position"], true)
				if not previous["playing"]:
					animator.pause()
			else:
				animator.stop()
	_animation_players.clear()
	WorldState.scene_transition.end_presentation(self)
	if is_instance_valid(_root) and _root != _hud and _root.tree_exiting.is_connected(_on_dependency_exiting):
		_root.tree_exiting.disconnect(_on_dependency_exiting)
	if is_instance_valid(_hud):
		_hud.dialogue_finished.disconnect(_on_dialogue_finished)
		_hud.sequence_skip_requested.disconnect(request_skip)
		_hud.tree_exiting.disconnect(_on_dependency_exiting)
		_hud.end_sequence(self)
	finished.emit(completed, reason)
