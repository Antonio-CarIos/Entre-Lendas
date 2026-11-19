class_name CutsceneStep
extends Resource
## Etapas visuais podem ser puladas. DIALOGUE e EFFECT sempre são executadas.

enum Kind { WAIT, ANIMATION, CAMERA, SOUND, FADE, EFFECT, DIALOGUE }

@export var kind: Kind = Kind.WAIT
@export var skippable: bool = true
## Somente apresentação cosmética (tremor/flash). Nunca marcar lógica/decisões.
@export var intense_effect: bool = false
@export_range(0.0, 60.0) var duration: float = 0.3
@export var target_path: NodePath
@export var animation: StringName = &""
@export var camera_position: Vector2 = Vector2.ZERO
@export var sound: AudioStream
@export_range(0.0, 1.0) var fade_alpha: float = 1.0
@export var effect_id: StringName = &""
@export var narrative: Stage01Narrative
@export var entry_id: StringName = &""
