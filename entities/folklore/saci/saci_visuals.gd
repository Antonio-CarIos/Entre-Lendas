class_name SaciVisuals
extends Resource
## Conjuntos separados: nunca usar o redemoinho como substituto da perna única.

@export var one_leg: SpriteFrames
@export var one_leg_canvas: Vector2i = Vector2i(32, 64)
@export var whirlwind: SpriteFrames
@export var whirlwind_canvas: Vector2i = Vector2i(64, 80)


func get_frames(form: StringName) -> SpriteFrames:
	match form:
		&"one_leg": return one_leg
		&"whirlwind": return whirlwind
	return null


func get_canvas(form: StringName) -> Vector2i:
	match form:
		&"one_leg": return one_leg_canvas
		&"whirlwind": return whirlwind_canvas
	return Vector2i.ZERO


func supports(form: StringName, action: StringName, direction: StringName) -> bool:
	var frames: SpriteFrames = get_frames(form)
	var canvas: Vector2i = get_canvas(form)
	var clip: StringName = StringName("%s_%s" % [action, direction])
	if frames == null or canvas.x <= 0 or canvas.y <= 0 or not frames.has_animation(clip):
		return false
	if frames.get_frame_count(clip) == 0 or frames.get_animation_speed(clip) <= 0.0:
		return false
	for index: int in range(frames.get_frame_count(clip)):
		var texture: Texture2D = frames.get_frame_texture(clip, index)
		if texture == null or texture.get_size() != Vector2(canvas):
			return false
		if texture is AtlasTexture:
			var atlas: AtlasTexture = texture as AtlasTexture
			if atlas.atlas == null or not Rect2(Vector2.ZERO, atlas.atlas.get_size()).encloses(atlas.region):
				return false
	return true


func has_directional_action(form: StringName, action: StringName) -> bool:
	for direction: StringName in [&"down", &"up", &"left", &"right"]:
		if not supports(form, action, direction):
			return false
	return true


func get_missing_conversation_clips() -> PackedStringArray:
	var missing: PackedStringArray = []
	for action: StringName in [&"appear", &"idle", &"talk", &"spin", &"depart"]:
		if not supports(&"one_leg", action, &"down"):
			missing.append("one_leg/%s_down" % action)
	return missing
