extends Node2D
## Prévia isolada da arte existente; não inicia nem avança a história.

var _walking: bool = false


func _ready() -> void:
	var directions: Array[Vector2] = [Vector2.DOWN, Vector2.UP, Vector2.LEFT, Vector2.RIGHT]
	for index: int in range($YSortRoot.get_child_count()):
		var actor: SaciActor = $YSortRoot.get_child(index) as SaciActor
		actor.show_form(&"whirlwind", directions[index])


func _unhandled_key_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.is_pressed() or event.is_echo():
		return
	var key: InputEventKey = event as InputEventKey
	if key.keycode not in [KEY_E, KEY_ENTER, KEY_SPACE]:
		return
	_walking = not _walking
	for actor: SaciActor in $YSortRoot.get_children():
		actor.play_action(&"walk" if _walking else &"idle")
	($UI/Screen/State as Label).text = "WALK — 5 frames a 8 FPS" if _walking else "IDLE — pose estática original"
	get_viewport().set_input_as_handled()
